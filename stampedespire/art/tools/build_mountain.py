"""Stampede Spire mountain build (Blender, background):
  blender -b --factory-startup --python art/tools/build_mountain.py
Builds the whole mountain procedurally on the SS_Path centreline (read from SS_Config via sspath.py),
saves art/blender/ss_mountain.blend, exports one FBX per zone plus the backdrop to art/export/, writes
art/export/ss_manifest.json (placement + Studio material per mesh) and prototype/src/SS_Markers.luau.
Palette: every colour comes from the LOOKDEV atlas ramps (make_atlas.py)."""
import bpy, json, math, os, random, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sspath as SP  # noqa: E402
import ssblend as S  # noqa: E402
from mathutils import Matrix, Vector, noise  # noqa: E402
from mathutils.bvhtree import BVHTree  # noqa: E402

ROOT = S.ROOT
random.seed(20261029)
bpy.ops.wm.read_factory_settings(use_empty=True)

LC = SP.C["LaneCount"]
EDGE = 6.0  # berm beyond the outer lane; the terrain meets the track here
B1, B2, B3 = SP.starts[1], SP.starts[2], SP.starts[3]
TOP = SP.TOTAL
SUMMIT_D = TOP + 75  # centre of the summit plateau (path is flat past TOP + SummitFlat)
BL = 70.0  # half-width of the terrain/colour blend across zone borders
PREVIEW = "--preview" in sys.argv
# --outdir DIR: write the .blend, FBXs, manifest and markers into DIR instead of the repo (variant builds)
OUTDIR = sys.argv[sys.argv.index("--outdir") + 1] if "--outdir" in sys.argv else None
BLEND_DIR = OUTDIR or os.path.join(ROOT, "art", "blender")
EXPORT_DIR = OUTDIR or S.EXPORT
MARKERS_PATH = os.path.join(OUTDIR, "SS_Markers.luau") if OUTDIR else os.path.join(ROOT, "prototype", "src", "SS_Markers.luau")
SUMMIT_Z = SP.centre(SUMMIT_D)[1]
# --straight: skip the plan-view bend warp (milestone 5); everything is authored straight either way
if "--straight" not in sys.argv:
    S.WARP = SP.warp


def V(x, y, z):
    return Vector((x, y, z))


def hw(d):
    return LC * SP.lane_width(min(max(d, 0), TOP)) / 2


def ss(e0, e1, x):
    if e1 == e0:
        return 1.0 if x >= e1 else 0.0
    return SP.smooth((x - e0) / (e1 - e0))


def n3(x, y, z=0.0):
    return noise.noise(V(x, y, z))


def fbm(x, y, z=0.0, o=4):
    return noise.fractal(V(x, y, z), 1.0, 2.0, o) * 0.6


def ridged(x, y, z=0.0):
    return noise.ridged_multi_fractal(V(x, y, z), 1.0, 2.0, 4, 1.0, 2.0) * 0.5


def zone_w(d):
    t1, t2, t3 = ss(B1 - BL, B1 + BL, d), ss(B2 - BL, B2 + BL, d), ss(B3 - BL, B3 + BL, d)
    return [1 - t1, t1 * (1 - t2), t2 * (1 - t3), t3]


def centre(d):
    y, z = SP.centre(d)
    return y, z


# ---------------------------------------------------------------- height-only zone blend
# zone_w stays as is (scatter acceptance and the random sequence depend on it). Heights blend over a
# window whose half-width grows with s: near the lanes the zone look still switches within ~70 studs,
# far out (where the profiles differ by 400-770 studs) the change spreads over several hundred studs so
# no border reads as a slab. Half-widths come from the measured profile differences (|dh| * 0.75 / W
# stays under ~1, i.e. ~45 degrees, at every s).
def _hw_b1(s):
    return 70 + 100 * ss(10, 45, s) + 260 * ss(150, 800, s)


def _hw_b2(s):
    return 70 + 100 * ss(10, 40, s) + 190 * ss(150, 420, s)


def _hw_b3(s):
    return 70 + 90 * ss(50, 130, s) + 190 * ss(110, 260, s) + 160 * ss(260, 700, s)


HB = ((B1, _hw_b1), (B2, _hw_b2), (B3, _hw_b3))


def height_w(d, s):
    """Height-only zone weights: each border blends over its s-dependent half-width."""
    t1, t2, t3 = (ss(B - f(max(s, 0.0)), B + f(max(s, 0.0)), d) for B, f in HB)
    return [1 - t1, t1 * (1 - t2), t2 * (1 - t3), t3]


START_D = -420.0  # first terrain row (the track starts at -150; a deck fills the centre strip behind it)
SKIRT = 750.0  # skirt bottom sits this far below the path centreline (300 under the backdrop peak bases)
_PD0, _PD1 = SP.MIN + 1, SP.MAX - 2  # sspath's centreline table clamps outside this range


def centre_x(d):
    """centre() extended past the path table along the end tangents, for terrain only (clamped, every
    terrain row before d=-300 collapsed onto one z). Track, props' RNG and the backdrop keep centre()."""
    if _PD0 <= d <= _PD1:
        return SP.centre(d)
    e = _PD0 if d < _PD0 else _PD1
    y, z = SP.centre(e)
    a = SP.slope(e)
    return y + (d - e) * math.sin(a), z - (d - e) * math.cos(a)


# ---------------------------------------------------------------- terrain height (relative to track)
def prof1(x, d, s, side):  # snowfields rising into forested hills
    drift = 2.5 * fbm(x / 45, d / 45, 1)
    hills = 26 * fbm(x / 260, d / 260, 2) + 70 * max(0.0, fbm(x / 640 + 3, d / 640, 3))
    return -1.5 + ss(0, 22, s) * (2.0 + drift) + 0.10 * s + 95 * ss(140, 900, s) + hills * ss(40, 260, s)


def prof2(x, d, s, side):  # towering ice walls, plateau rim on top
    wall_h = 165 + 80 * fbm(d / 210, side * 5.0, 4) + 35 * fbm(d / 70, side * 7.0 + 2, 5)
    foot = s - 3 - 5 * (n3(d / 30, side * 3.0, 6) + 1)
    cols = 7 * n3(d / 9, side * 3.1, 7) * ss(4, 26, foot) * (1 - ss(40, 70, s))
    wall = wall_h * ss(0, 24, foot) + cols
    rim = 0.3 * max(0.0, s - 50) + 18 * fbm(x / 110, d / 110, 8) * ss(40, 80, s) + 260 * ridged(x / 280, d / 280, 16) * ss(90, 450, s)
    return -1.5 + 1.5 * ss(0, 4, s) + wall + rim


def prof3(x, d, s, side):  # rugged basalt with jagged ridges
    bank = 3.5 * ss(0, 9, s) + 2 * fbm(x / 20, d / 20, 9) * ss(0, 15, s)
    ridge = 230 * ridged(x / 260, d / 260, 10) * ss(70, 380, s)
    rough = 12 * fbm(x / 55, d / 55, 11) * ss(12, 70, s)
    return -1.5 + bank + 0.18 * s + ridge + rough


def prof4(x, d, s, side):  # knife ridge: the path rides the crest, the world drops away
    lip = 1.5 * ss(0, 3, s) + 2.5 * fbm(x / 15, d / 15, 12) * (1 - ss(0, 30, s))
    drop = -390 * ss(6, 240, s) - 0.05 * s
    peaks = 300 * max(0.0, ridged(x / 300, d / 300, 13) - 0.15) * ss(240, 620, s)
    rough = 18 * fbm(x / 80, d / 80, 14) * ss(20, 120, s)
    return -1.5 + lip + drop + peaks + rough


PROFS = [prof1, prof2, prof3, prof4]


def hrel(x, d):
    s = abs(x) - (hw(d) + EDGE)
    side = 1.0 if x >= 0 else -1.0
    if s < 0:
        h = -1.5
    else:
        h = sum(w * PROFS[k](x, d, s, side) for k, w in enumerate(height_w(d, s)) if w > 1e-4)
    # summit plateau: flat crown around SUMMIT_D
    yd, zd = centre(d)
    r = math.hypot(x, zd - SUMMIT_Z)
    pw = 1 - ss(115, 175, r)
    if pw > 0:
        flat = -1.5 + 1.2 * fbm(x / 30, d / 30, 15) * ss(0, 30, abs(x) - hw(d) - EDGE)
        h = h * (1 - pw) + flat * pw
    return h


# ---------------------------------------------------------------- built surface
# Props stand on the triangulated terrain, not on hrel(): far out the S_LIST columns are 50-130 studs apart,
# so the mesh misses ridges the analytic height has (pines floated or sank by up to ~17 studs).
SURF = {"mbs": [], "bvh": None, "rows": []}


def surf_freeze():
    """Called once every terrain chunk and deck exists; from then on ground() follows the built mesh."""
    vs, fs = [], []
    row_of_v = {round(S.uv_for(r, 0.5)[1], 6): r for r in S.ROW}
    for mb in SURF["mbs"]:
        o = len(vs)
        vs += [S.tuple_bl2rb(p) for p in mb.v]
        fs += [[i + o for i in f] for f in mb.f]
        SURF["rows"] += [row_of_v[round(uv[0][1], 6)] for uv in mb.uv]
    SURF["bvh"] = BVHTree.FromPolygons(vs, fs)


def surf_hit(x, z):
    """(height, atlas row) of the built terrain at world (x, z); (None, None) before surf_freeze() / off it."""
    if SURF["bvh"] is None:
        return None, None
    hit = SURF["bvh"].ray_cast(Vector((x, 20000.0, z)), Vector((0, -1, 0)))
    return (None, None) if hit[0] is None else (hit[0].y, SURF["rows"][hit[2]])


def surf_y(x, z):
    return surf_hit(x, z)[0]


def surf_zone(x, z):
    """Zone (0-3) of the paint actually under world (x, z), from the hit face's row ("z3_ground" -> 2)."""
    row = surf_hit(x, z)[1]
    return None if row is None else int(row[1]) - 1


def ground(x, d):
    y, z = centre_x(d)
    sy = surf_y(x, z)
    return V(x, y + hrel(x, d) if sy is None else sy, z)


# ---------------------------------------------------------------- painting
def zone_pick(d, x):
    # paint seam: unchanged beside the lanes (+-35), frays up to +-180 far out so flank seams are not ruler
    # lines; far out near B3 it lags up to 100 studs so zone 4 snow/rock never lands on still-ridged basalt
    f = min(max(abs(x) - (hw(d) + EDGE), 0.0), 400.0)
    j = 35 * n3(x / 60, d / 60, 20) + 0.45 * f * n3(x / 190, d / 190, 22) - 0.25 * f * ss(B2 + 500, B3, d)
    w = zone_w(d + j)
    return max(range(4), key=lambda k: w[k])


SKIRT_ROW = ("z1_rock", "z2_ledge", "z3_obsidian", "z4_rock")


def skirt_zone(d, x, band=0):
    # matches the terrain paint at the rim; lower bands shift a little so the colour change steps like strata
    return zone_pick(d + 60 * band * n3(d / 90 + x / 90, band * 1.7 + 0.5, 25), x)


SKIRT_MARGIN = 110.0  # levels below the rim hang this far under the blurred edge height (measured max gap 97)
SKIRT_LEAN = 0.35  # outward run per stud of drop: the skirt reads as the massif's flank, not a box wall
# heavy blur of the edge height (a cross of samples, +-240 studs along d and x): the levels below the rim
# then slope evenly along the edge, so the flank breaks into broad facets instead of 8-stud stripes. It is a
# pure function of the corner, so skirts that share a corner or a chunk seam agree exactly.
SKIRT_BLUR = [(0, 0)] + [(k * 40, 0) for k in range(-6, 7) if k] + [(0, k * 40) for k in range(-6, 7) if k]
# M6 strata: levels below the rim as (t, ledge). A ledge level sits just under the one above it and juts out,
# so the flank steps like broken rock strata (a lit bench, then a steep face). Ledge width, level height and
# in/out drift are low-frequency noise of the corner's position (pure functions: shared corners still agree).
SKIRT_LV = ((0.05, 0), (0.07, 1), (0.15, 0), (0.175, 1), (0.29, 0), (0.315, 1), (0.43, 0), (0.455, 1), (0.6, 0), (0.63, 1),
            (0.8, 0), (0.83, 1), (1.0, 0))
SKIRT_COL = 44.0  # below the rim the skirt keeps a column only every ~44 studs: broad facets, no 8-stud stripes


def skirt_band(t):
    """Paint band (0 rim, 1 middle, 2 foot) for the colour-strata shift of skirt_zone."""
    return 0 if t < 0.1 else (1 if t < 0.5 else 2)


def skirt_pt(c, t, out, yr=None, k=0, ledge=0):
    """Point at level t (0 = terrain edge, 1 = SKIRT below the path) under edge corner c, pushed along `out`.
    k: level index (seeds its low-frequency in/out drift); ledge: this level juts out as a bench."""
    p, d = c["p"], c["d"]
    if t == 0:
        return p
    yc = centre_x(d)[0]
    if yr is None:
        yr = yc + sum(hrel(p.x + ox, d + od) for ox, od in SKIRT_BLUR) / len(SKIRT_BLUR)
    yr = min(yr - SKIRT_MARGIN, p.y - 5)  # start below the rim (blur - rim never exceeds ~100 studs)
    yb = yc - SKIRT
    if 0 < t < 1:  # strata wander up/down a little along the edge (never past the neighbouring levels)
        t += 0.018 * n3(p.x / 340, p.z / 340, 26.0 + 1.3 * (k - ledge))  # a bench moves with its stratum
    y = yr + (yb - yr) * t
    o = (yr - y) * SKIRT_LEAN + 45 * n3(p.x / 420, p.z / 420, 23.5 + 3 * t) * min(1.0, 4 * t)  # broad bulges only
    o += 26 * n3(p.x / 520, p.z / 520, 30.0 + 1.7 * (k - ledge)) * min(1.0, 6 * t)  # stratum in/out drift
    if ledge:
        o += 16 + 14 * n3(p.x / 380, p.z / 380, 40.0 + 1.1 * k)  # bench width 2-30 studs
    return V(p.x + out.x * o, y, p.z + out.z * o)


def skirt_col(c, out, yr):
    """Every level under corner c, rim first. Offsets never pull back more than 3 studs per level (no deep
    overhangs); pure function of the corner."""
    col, prev = [c["p"]], None
    for k, (t, ledge) in enumerate(SKIRT_LV):
        q = skirt_pt(c, t, out, yr, k + 1, ledge)
        if prev is not None:
            dp = (q - V(c["p"].x, q.y, c["p"].z)).dot(out)
            if dp < prev - 3:
                q = q + out * (prev - 3 - dp)
                dp = prev - 3
            prev = dp
        else:
            prev = (q - V(c["p"].x, q.y, c["p"].z)).dot(out)
        col.append(q)
    return col


def skirt(mb, tops, outward, zk_of, corner_out=None):
    """Rock flank from a run of terrain edge corners down to SKIRT below the path, facing `outward`.
    corner_out: {index: direction} for corners shared with another skirt (same direction there = no crack).
    The rim follows every terrain corner; the levels below use a sparse subset of columns (both ends always
    kept, so seams and shared corners match) and the rim band fans down onto them."""
    corner_out = corner_out or {}
    n = len(tops)
    keep, run = [0], 0.0
    for i in range(1, n):
        run += (tops[i]["p"] - tops[i - 1]["p"]).length
        if i == n - 1 or run >= SKIRT_COL:
            # don't leave a sliver before the last column
            if i < n - 1 and sum((tops[j]["p"] - tops[j - 1]["p"]).length for j in range(i + 1, n)) < SKIRT_COL * 0.5:
                continue
            keep.append(i)
            run = 0.0
    cols = {}
    for i in keep:
        c = tops[i]
        yr = centre_x(c["d"])[0] + sum(hrel(c["p"].x + ox, c["d"] + od) for ox, od in SKIRT_BLUR) / len(SKIRT_BLUR)
        cols[i] = skirt_col(c, corner_out.get(i, outward), yr)
    ts = (0.0,) + tuple(t for t, _ in SKIRT_LV)
    ledges = (0,) + tuple(l for _, l in SKIRT_LV)

    def shade(pt, k, m):
        t = ts[k]
        sh = 0.46 - 0.4 * t + 0.08 * (1 - t) * n3(pt.x / 90, pt.z / 90, 24)
        sh += 0.05 * n3(pt.x / 400, pt.z / 400, 50.0 + 2.3 * k)  # each stratum a touch lighter/darker, smoothly
        return sh + (0.06 * (1 - t) if m else 0.0)  # benches catch the light

    def put(q, row, sh):
        if (q[1] - q[0]).cross(q[2] - q[0]).dot(outward) < 0:
            q, sh = q[::-1], sh[::-1]
        mb.face([tuple(c) for c in q], row, sh)

    for a, b in zip(keep, keep[1:]):
        A, B = cols[a], cols[b]
        dm, xm = (tops[a]["d"] + tops[b]["d"]) / 2, (tops[a]["p"].x + tops[b]["p"].x) / 2
        # rim band: the fine rim fans down onto the two sparse level-1 corners
        row = SKIRT_ROW[zk_of(dm, xm, 0)]
        mid = (a + b) // 2
        for i in range(a, b):
            lo = A[1] if i < mid else B[1]
            put([tops[i]["p"], tops[i + 1]["p"], lo], row,
                [shade(tops[i]["p"], 0, 0), shade(tops[i + 1]["p"], 0, 0), shade(lo, 1, 0)])
        put([tops[mid]["p"], B[1], A[1]], row, [shade(tops[mid]["p"], 0, 0), shade(B[1], 1, 0), shade(A[1], 1, 0)])
        for k in range(1, len(ts) - 1):
            row = SKIRT_ROW[zk_of(dm, xm, skirt_band((ts[k] + ts[k + 1]) / 2))]
            m = ledges[k + 1]  # the face down onto a ledge level is the lit bench
            put([A[k], B[k], B[k + 1], A[k + 1]], row,
                [shade(tops[a]["p"], k, m), shade(tops[b]["p"], k, m), shade(tops[b]["p"], k + 1, m),
                 shade(tops[a]["p"], k + 1, m)])


def terrain_paint(zk, ny, hr, d, x, summit, soft=False):
    """(row, shade) for a terrain corner/face. soft (zone 1 far field): rock near the snow threshold runs to
    the light end of its ramp (far_treeline, next to snow_shadow), so far rock patches fade into the snow."""
    n = n3(x / 23, d / 23, 21)
    if summit or zk == 3:
        if ny < 0.62:
            return "z4_rock", 0.35 + 0.35 * (n * 0.5 + 0.5)
        return "z4_snow", 0.45 + 0.5 * ss(0.62, 1.0, ny) + 0.06 * n
    if zk == 0:
        if ny < 0.7:
            return "z1_rock", 0.3 + 0.4 * (n * 0.5 + 0.5) + (0.5 * ss(0.45, 0.7, ny) if soft else 0.0)
        return "z1_snow", 0.3 + 0.62 * ss(0.7, 1.0, ny) + 0.06 * n
    if zk == 1:
        if ny < 0.62:
            return "z2_ice", 0.08 + 0.85 * min(max(hr / 230, 0), 1) + 0.07 * n
        return "z2_snow", 0.45 + 0.45 * ss(0.62, 1.0, ny) + 0.06 * n
    if ny < 0.78:
        return "z3_obsidian", 0.25 + 0.45 * (n * 0.5 + 0.5)
    return "z3_ground", 0.2 + 0.45 * (n * 0.5 + 0.5)


S_LIST = [-4, 0, 1.5, 3, 4.5, 6, 8, 10, 12.5, 15, 18, 21, 25, 30, 36, 43, 51, 60, 70, 82, 96, 112, 130, 152, 178,
          208, 244, 286, 334, 390, 454, 528, 612, 708, 820, 950]
# zone 1 (M6): far columns halved (a midpoint in every gap from s=96 out), so the far snowfield's rock patches
# are half as wide. Its last row against the coarser zone 2 chunk keeps the midpoints on the straight edge.
S_FINE = sorted(set(S_LIST) | {(a + b) / 2 for a, b in zip(S_LIST, S_LIST[1:]) if a >= 96})


def terrain_chunk(name, d0, d1, side, coll, step=8.0, start=False, end=False, fine=False, seam_end=False):
    """fine: zone 1 far-field detail (S_FINE columns, smoothed far paint); seam_end: the last row meets a
    coarse chunk, so its extra columns are placed on the coarse edge (no T-junction cracks)."""
    mb = S.MB()
    slist = S_FINE if fine else S_LIST
    n = max(1, int(round((d1 - d0) / step)))
    ds = [d0 + (d1 - d0) * i / n for i in range(n + 1)]
    grid = []
    for d in ds:
        E = hw(d) + EDGE
        row = []
        for s in slist:
            x = side * (E + s)
            p = ground(x, d)
            row.append({"p": p, "d": d, "x": x, "hr": hrel(x, d) + 1.5})
        grid.append(row)
    R, Cn = len(grid), len(slist)
    if seam_end:
        last = grid[-1]
        for j, s in enumerate(slist):
            if s not in S_LIST:
                a, b = last[j - 1], last[j + 1]
                f = (s - slist[j - 1]) / (slist[j + 1] - slist[j - 1])
                last[j]["p"] = a["p"].lerp(b["p"], f)
                last[j]["hr"] = a["hr"] + (b["hr"] - a["hr"]) * f
    for i in range(R):
        for j in range(Cn):
            a, b = grid[max(i - 1, 0)][j]["p"], grid[min(i + 1, R - 1)][j]["p"]
            c, e = grid[i][max(j - 1, 0)]["p"], grid[i][min(j + 1, Cn - 1)]["p"]
            nr = (b - a).cross(e - c)
            if nr.length > 0:
                nr.normalize()
            grid[i][j]["ny"] = abs(nr.y)
    yc, zc = centre(SUMMIT_D)
    QN = {}
    for i in range(R - 1):
        for j in range(Cn - 1):
            qn = (grid[i + 1][j + 1]["p"] - grid[i][j]["p"]).cross(grid[i + 1][j]["p"] - grid[i][j + 1]["p"])
            QN[i, j] = abs(qn.normalized().y) if qn.length > 0 else 1.0
    for i in range(R - 1):
        for j in range(Cn - 1):
            q = [grid[i][j], grid[i][j + 1], grid[i + 1][j + 1], grid[i + 1][j]]
            tris = ([q[0], q[1], q[2]], [q[0], q[2], q[3]]) if (i + j) % 2 == 0 else ([q[0], q[1], q[3]], [q[1], q[2], q[3]])
            qn = (q[2]["p"] - q[0]["p"]).cross(q[3]["p"] - q[1]["p"])  # whole-quad normal (diagonal cross)
            qny = abs(qn.normalized().y) if qn.length > 0 else 1.0
            for t in tris:
                pts = [c["p"] for c in t]
                fn = (pts[1] - pts[0]).cross(pts[2] - pts[0])
                if fn.y < 0:
                    t = t[::-1]
                    pts = pts[::-1]
                    fn = -fn
                if fn.length == 0:
                    continue
                fn.normalize()
                dc = sum(c["d"] for c in t) / 3
                xc = sum(c["x"] for c in t) / 3
                pc = sum(pts, Vector()) / 3
                summit = math.hypot(xc, pc.z - zc) < 150 and dc > TOP
                zk = zone_pick(dc, xc)
                # far out the quads are long and thin and their split alternates, so face normals zigzag:
                # both halves of a quad take rock/snow from the quad's normal there, or slopes near a threshold stripe
                far = abs(xc) - hw(dc) - EDGE >= 100
                nyd = fn.y if not far else qny
                if fine and far:  # zone 1: the quad's normal blended with its 8 neighbours' (no lone rock specks)
                    nb = [QN[a, b] for a in range(i - 1, i + 2) for b in range(j - 1, j + 2) if (a, b) in QN]
                    nyd = 0.5 * qny + 0.5 * sum(nb) / len(nb)
                soft = fine and far
                row, _ = terrain_paint(zk, nyd, 0, dc, xc, summit, soft)
                shades = []
                for c in t:
                    r2, sh = terrain_paint(zk, min(c["ny"], fn.y + 0.15), c["hr"], c["d"], c["x"], summit, soft)
                    shades.append(sh if r2 == row else terrain_paint(zk, nyd, c["hr"], c["d"], c["x"], summit, soft)[1])
                mb.face([tuple(p) for p in pts], row, shades)
    # skirts: close every exposed edge so the heightfield reads as solid ground from outside/below
    c0, c1 = V(side, 0, 1).normalized(), V(side, 0, -1).normalized()  # shared corner directions
    corners = {}
    if start:
        corners[0] = c0
        skirt(mb, grid[0], V(0, 0, 1), skirt_zone, {Cn - 1: c0})
    if end:
        corners[R - 1] = c1
        skirt(mb, grid[-1], V(0, 0, -1), skirt_zone, {Cn - 1: c1})
    skirt(mb, [grid[i][-1] for i in range(R)], V(side, 0, 0), skirt_zone, corners)
    SURF["mbs"].append(mb)
    return S.build(name, mb, coll, extra={"kind": "terrain", "castShadow": True})


# ---------------------------------------------------------------- track
STYLE = [  # berm height, lane row, lane shades (edge, centre), groove row/shade, berm row, berm shades (outer, top, inner)
    {"bh": 2.2, "lane": "z1_snow", "ls": (0.6, 0.74), "groove": ("z1_snow", 0.28), "berm": "z1_snow", "bs": (0.35, 0.96, 0.55)},
    {"bh": 3.0, "lane": "z2_snow", "ls": (0.42, 0.55), "groove": ("z2_ice", 0.3), "berm": "z2_bridge", "bs": (0.25, 0.9, 0.45)},
    {"bh": 1.8, "lane": "z3_ground", "ls": (0.42, 0.58), "groove": ("z3_obsidian", 0.12), "berm": "z3_obsidian", "bs": (0.15, 0.62, 0.3)},
    {"bh": 1.3, "lane": "z4_snow", "ls": (0.72, 0.9), "groove": ("z4_rock", 0.55), "berm": "z4_rock", "bs": (0.25, 0.7, 0.45)},
]


def cross_section(d, zk):
    st = STYLE[zk]
    lw = SP.lane_width(min(max(d, 0), TOP))
    h = LC * lw / 2
    bh = st["bh"]
    br, (bo, bt, bi) = st["berm"], st["bs"]
    left = [(-(h + EDGE + 0.5), -2.6, br, bo), (-(h + 4.5), bh, br, bt), (-(h + 2.5), bh, br, bt), (-(h + 0.6), 0.15, br, bi)]
    pts = list(left)
    pts.append((-h, 0, st["lane"], st["ls"][0]))
    for i in range(LC):
        c = -h + (i + 0.5) * lw
        pts.append((c, 0, st["lane"], st["ls"][1]))
        if i < LC - 1:
            b = -h + (i + 1) * lw
            pts += [(b - 0.45, 0, st["lane"], st["ls"][0]), (b, -0.14, st["groove"][0], st["groove"][1]),
                    (b + 0.45, 0, st["lane"], st["ls"][0])]
    pts.append((h, 0, st["lane"], st["ls"][0]))
    pts += [(-x, y, r, s) for (x, y, r, s) in reversed(left)]
    return pts


def track_chunk(name, d0, d1, zk, coll, step=4.0):
    mb = S.MB()
    st = STYLE[zk]
    groove, berm = st["groove"][0], st["berm"]
    n = max(1, int(round((d1 - d0) / step)))
    ds = [d0 + (d1 - d0) * i / n for i in range(n + 1)]
    secs = [cross_section(d, zk) for d in ds]
    for i in range(n):
        A, Bs = secs[i], secs[i + 1]
        da, db = ds[i], ds[i + 1]
        half = LC * SP.lane_width(min(max(da, 0), TOP)) / 2 + 0.01
        for k in range(len(A) - 1):
            pa, pb = A[k], A[k + 1]
            if pa[1] < 0 and pb[1] < 0:
                row, kind = berm, "b"
            elif pa[1] < 0 or pb[1] < 0:
                row, kind = (groove, "g") if abs(pa[0]) < half and abs(pb[0]) < half else (berm, "b")
            elif abs(pa[0]) > half or abs(pb[0]) > half:
                row, kind = berm, "b"
            else:
                row, kind = st["lane"], "l"

            def corner(sec, j, d):
                x, hgt, r, sh = sec[j]
                if kind == "g" and hgt >= 0:
                    sh = st["ls"][0] - 0.1
                elif kind == "b" and r != berm:
                    sh = st["bs"][2]
                return SP.surf(d, x, hgt), sh + 0.05 * n3(x / 6, d / 11, 30)

            c = [corner(A, k, da), corner(A, k + 1, da), corner(Bs, k + 1, db), corner(Bs, k, db)]
            mb.face([c[0][0], c[2][0], c[3][0]], row, [c[0][1], c[2][1], c[3][1]])
            mb.face([c[0][0], c[1][0], c[2][0]], row, [c[0][1], c[1][1], c[2][1]])
    fix_up(mb)
    return S.build(name, mb, coll, extra={"kind": "track", "castShadow": False})


# ---------------------------------------------------------------- primitives (Roblox space)
def rot_y(a):
    return Matrix.Rotation(a, 3, "Y")


def tilt(axis_angle, amount):
    ax = V(math.cos(axis_angle), 0, math.sin(axis_angle))
    return Matrix.Rotation(amount, 3, ax)


def ring(c, r, y, sides, a0, M=None, jit=0.0, seed=0.0):
    out = []
    for i in range(sides):
        a = a0 + 2 * math.pi * i / sides
        rr = r * (1 + jit * n3(seed, i * 1.7, 40))
        v = V(math.cos(a) * rr, y, math.sin(a) * rr)
        out.append(c + (M @ v if M else v))
    return out


def band(mb, lo, hi, row, slo, shi, alt=0.0):
    n = len(lo)
    for i in range(n):
        j = (i + 1) % n
        a = alt if i % 2 else 0.0
        # outward-facing: lo[i] -> lo[j] -> hi[j] -> hi[i] seen from outside is clockwise in XZ, so reverse
        mb.face([lo[i], hi[i], hi[j], lo[j]], row, [slo + a, shi + a, shi + a, slo + a])


def cap(mb, pts, apex, row, s_lo, s_hi, alt=0.0):
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        a = alt if i % 2 else 0.0
        mb.face([pts[i], apex, pts[j]], row, [s_lo + a, s_hi + a, s_lo + a])


def fan_top(mb, pts, row, s):
    c = sum(pts, Vector()) / len(pts)
    for i in range(len(pts)):
        mb.face([pts[i], c, pts[(i + 1) % len(pts)]], row, s)


def check_winding(mb_test=True):
    """Outward normals: a unit 6-sided band must face away from its axis."""
    mb = S.MB()
    lo = ring(V(0, 0, 0), 1, 0, 6, 0)
    hi = ring(V(0, 0, 0), 1, 1, 6, 0)
    band(mb, lo, hi, "z1_snow", 0.5, 0.5)
    v0 = [S.tuple_bl2rb(mb.v[i]) for i in mb.f[0]]
    p = [V(*a) for a in v0]
    nrm = (p[1] - p[0]).cross(p[2] - p[0])
    cen = sum(p, Vector()) / len(p)
    return nrm.dot(V(cen.x, 0, cen.z)) > 0


OUTWARD = check_winding()


def band_o(mb, lo, hi, row, slo, shi, alt=0.0):
    if OUTWARD:
        band(mb, lo, hi, row, slo, shi, alt)
    else:
        band(mb, hi, lo, row, shi, slo, alt)


def cap_o(mb, pts, apex, row, s_lo, s_hi, alt=0.0):
    # apex above: outward means the same rotational sense as band_o's bottom edge
    if OUTWARD:
        cap(mb, pts, apex, row, s_lo, s_hi, alt)
    else:
        cap(mb, pts[::-1], apex, row, s_lo, s_hi, alt)


def pine(mb, base, height, rad, seed):
    a0 = random.uniform(0, 6.28)
    tr = height * 0.13
    band_o(mb, ring(base, rad * 0.11, -2, 5, a0), ring(base, rad * 0.09, tr, 5, a0), "z1_rock", 0.15, 0.3)
    tiers = 3 if height < 40 else 4
    for t in range(tiers):
        f = t / tiers
        y0 = tr + f * height * 0.78
        th = height * (0.42 - 0.06 * t)
        r = rad * (1 - 0.22 * t)
        lo = ring(base, r, y0, 7, a0 + t, jit=0.12, seed=seed + t)
        mid = ring(base, r * 0.55, y0 + th * 0.42, 7, a0 + t, jit=0.1, seed=seed + t + 0.5)
        band_o(mb, lo, mid, "z1_pine", 0.1, 0.55, alt=0.06)
        cap_o(mb, mid, base + V(0, y0 + th, 0), "z1_snow", 0.55, 0.97, alt=0.05)


ICO = None


def ico():
    global ICO
    if ICO is None:
        import bmesh
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
        vs = [tuple(v.co) for v in bm.verts]
        fs = [[v.index for v in f.verts] for f in bm.faces]
        bm.free()
        ICO = (vs, fs)
    return ICO


def boulder(mb, base, size, row_rock, row_snow, seed, snow_ny=0.55, sink=0.35):
    vs, fs = ico()
    M = rot_y(random.uniform(0, 6.28))
    pts = []
    for (x, y, z) in vs:  # Blender-space unit sphere; axes don't matter for a blob
        k = 1 + 0.28 * n3(x * 1.3 + seed, y * 1.3, z * 1.3)
        v = V(x * size.x * k, y * size.y * k, z * size.z * k)
        pts.append(base + M @ v - V(0, size.y * sink * 2, 0) + V(0, size.y, 0) * (1 - sink))
    c0 = base + V(0, size.y * (1 - 3 * sink), 0)
    for f in fs:
        p = [pts[i] for i in f]
        nrm = (p[1] - p[0]).cross(p[2] - p[0])
        cen = sum(p, Vector()) / 3
        if nrm.dot(cen - c0) < 0:
            p = p[::-1]
            nrm = -nrm
        nrm.normalize()
        if row_snow and nrm.y > snow_ny:
            mb.face(p, row_snow, [0.6 + 0.35 * nrm.y] * 3)
        else:
            mb.face(p, row_rock, [0.2 + 0.35 * (nrm.y * 0.5 + 0.5)] * 3)


def shard(mb, base, height, rad, sides, lean_dir, lean, row, s_lo, s_hi, mid_f=0.55, sink=2.0):
    M = tilt(lean_dir, lean)
    a0 = random.uniform(0, 6.28)
    lo = ring(base, rad, -sink, sides, a0, M, 0.15, random.random() * 9)
    mid = ring(base, rad * mid_f, height * 0.5, sides, a0 + 0.2, M, 0.2, random.random() * 9)
    band_o(mb, lo, mid, row, s_lo, (s_lo + s_hi) / 2, alt=0.08)
    cap_o(mb, mid, base + M @ V(0, height, 0), row, (s_lo + s_hi) / 2, s_hi, alt=0.08)


def crystal(mb, base, height, rad, lean_dir, lean, row="z4_crystal"):
    M = tilt(lean_dir, lean)
    a0 = random.uniform(0, 6.28)
    lo = ring(base, rad, -3, 6, a0, M)
    hi = ring(base, rad, height * 0.74, 6, a0, M)
    # Z4 sheet crystals: every other facet catches the light (crystal_glint), the rest sit in crystal_deep
    band_o(mb, lo, hi, row, 0.1, 0.55, alt=0.38)
    cap_o(mb, hi, base + M @ V(0, height, 0), row, 0.6, 0.98, alt=0.3)


def column(mb, base, height, rad, top_row, side_row):
    a0 = 0.0
    lo = ring(base, rad, -3, 6, a0)
    hi = ring(base, rad, height, 6, a0)
    band_o(mb, lo, hi, side_row, 0.05, 0.3, alt=0.06)
    c = base + V(0, height + rad * 0.15, 0)
    cap_o(mb, hi, c, top_row, 0.45, 0.6)


class Batcher:
    """Packs many small props into MeshParts of <= cap tris, flushing in placement order."""

    def __init__(self, prefix, coll, extra, cap=9000, fixup=False):
        self.prefix, self.coll, self.extra, self.cap, self.fixup = prefix, coll, extra, cap, fixup
        self.mb, self.n = S.MB(), 0
        self.span = None

    def add(self, fn, *a, **k):
        before = (list(self.mb.v), list(self.mb.f), list(self.mb.uv), dict(self.mb.idx))
        fn(self.mb, *a, **k)
        if self.mb.tris() > self.cap:
            self.mb.v, self.mb.f, self.mb.uv, self.mb.idx = before
            self.flush()
            fn(self.mb, *a, **k)

    def flush(self):
        if self.mb.f:
            if self.fixup:
                fix_up(self.mb)
            self.n += 1
            S.build("%s_%02d" % (self.prefix, self.n), self.mb, self.coll, extra=self.extra)
        self.mb = S.MB()


def batch_props(prefix, coll, items, extra, cap=9000):
    """items: list of (sortkey, fn, args). Built in sortkey order so batches stay spatially compact."""
    b = Batcher(prefix, coll, extra, cap)
    for _, fn, args in sorted(items, key=lambda t: t[0]):
        mb_tris = b.mb.tris()
        tmp = S.MB()
        fn(tmp, *args)
        if mb_tris + tmp.tris() > cap:
            b.flush()
        fn(b.mb, *args)
    b.flush()


# ---------------------------------------------------------------- zone dressing
MARK = {"Vents": [], "Plumes": [], "Shafts": [], "Bridges": [], "Crystals": [], "Summit": None, "Lava": []}
CLUSTERS = []  # (base, scale) of every zone 4 crystal cluster, for the glow accents
LIP = []  # (base, side) of the small clusters on the ridge lip beside the lanes


def scatter(d0, d1, smin, smax, count, accept=None, tries=20):
    out = []
    for _ in range(count * tries):
        if len(out) >= count:
            break
        d = random.uniform(d0, d1)
        side = random.choice((-1, 1))
        s = smin + (smax - smin) * random.random() ** 1.6
        x = side * (hw(d) + EDGE + s)
        if accept and not accept(x, d, s):
            continue
        out.append((x, d, s))
    return out


def zone1(coll):
    items = []

    def dens(x, d, s):
        if zone_w(d)[0] < 0.6:
            return False
        p = 0.35 + 0.8 * fbm(x / 170, d / 170, 50)
        if s > 450:
            p *= 0.6
        return random.random() < p

    for (x, d, s) in scatter(-420, 1040, 9, 900, 620, dens):
        g = ground(x, d)
        h = random.uniform(24, 46) * (1.25 if s > 200 else 1.0)
        items.append((d * 3 + (0 if x < 0 else 1e5), pine, (g, h, h * 0.27, random.random() * 50)))
    batch_props("Z1_Pines", coll, items, {"kind": "pines", "castShadow": True})

    rocks = []
    for (x, d, s) in scatter(-300, 1020, 2, 400, 170, lambda x, d, s: zone_w(d)[0] > 0.5):
        g = ground(x, d)
        sz = random.uniform(2.5, 7) * (2.2 if s > 60 else 1.0)
        rocks.append((d, boulder, (g, V(sz * 1.3, sz * 0.8, sz), "z1_rock", "z1_snow", random.random() * 30)))
    batch_props("Z1_Rocks", coll, rocks, {"kind": "rocks", "castShadow": True})

    # frozen river: a ribbon winding down the left snowfield
    mb = S.MB()
    prev = None
    for i in range(0, 121):
        d = -420 + i * 12
        x = -(hw(d) + EDGE + 260 + 90 * math.sin(d / 240) + 40 * n3(d / 120, 0, 55))
        w = 26 + 10 * n3(d / 90, 1, 56)
        a, b = ground(x - w / 2, d) + V(0, 0.6, 0), ground(x + w / 2, d) + V(0, 0.6, 0)
        if prev:
            mb.face([prev[0], a, b, prev[1]][::-1] if False else [prev[0], prev[1], b, a], "z1_ice", [0.45, 0.7, 0.75, 0.5])
        prev = (a, b)
    fix_up(mb)
    S.build("Z1_River", mb, coll, extra={"kind": "river", "castShadow": False})


def fix_up(mb):
    """Flip any face whose normal points down (ribbons laid on the ground must face up)."""
    for k, f in enumerate(mb.f):
        p = [V(*S.tuple_bl2rb(mb.v[i])) for i in f]
        if (p[1] - p[0]).cross(p[2] - p[0]).y < 0:
            mb.f[k] = f[::-1]
            mb.uv[k] = mb.uv[k][::-1]


def zone2(coll):
    # ice shards along the wall feet and on the rims
    items = []
    for (x, d, s) in scatter(B1 + 40, B2 - 20, 1, 30, 260):
        g = ground(x, d)
        h = random.uniform(5, 22)
        side = 1 if x > 0 else -1
        lean_dir = -side * math.pi / 2 + random.uniform(-0.5, 0.5)  # tilt() leans toward (-sin a, 0, cos a): away from the lanes
        items.append((d, shard, (g, h, h * 0.18, 5, lean_dir, random.uniform(0.05, 0.4), "z2_ice", 0.25, 0.98)))
    for (x, d, s) in scatter(B1 + 60, B2 - 40, 55, 300, 120):
        g = ground(x, d)
        h = random.uniform(15, 45)
        items.append((d, shard, (g, h, h * 0.2, 5, random.uniform(0, 6.28), random.uniform(0, 0.3), "z2_ice", 0.35, 0.98)))
    batch_props("Z2_Shards", coll, items, {"kind": "ice", "castShadow": True})

    ledges = []
    for (x, d, s) in scatter(B1 + 20, B2, 0, 3, 70):  # wall foot only: higher up the wall they read as floating
        g = ground(x, d)
        sz = random.uniform(3, 7)
        ledges.append((d, boulder, (g, V(sz * 1.4, sz * 0.7, sz * 1.1), "z2_ledge", "z2_snow", random.random() * 30, 0.6)))
    batch_props("Z2_Ledges", coll, ledges, {"kind": "rocks", "castShadow": True})

    # ice bridges over the canyon
    for bi, db in enumerate((B1 + 230, B1 + 490, B1 + 760)):
        mb = S.MB()
        y0, z0 = centre(db)
        E = hw(db) + EDGE
        span = E + 40
        rise = random.uniform(48, 70)
        thick, width = 9, 16
        segs = 18
        rings_ = []
        for i in range(segs + 1):
            u = -1 + 2 * i / segs
            x = u * span
            yb = y0 + rise + 14 * (1 - u * u) + 3 * n3(u * 3, bi, 60)
            th = thick * (1 + 0.6 * u * u)
            sec = [V(x, yb - th, z0 + width / 2), V(x, yb + th * 0.4, z0 + width / 2 + 2), V(x, yb + th * 0.55, z0),
                   V(x, yb + th * 0.4, z0 - width / 2 - 2), V(x, yb - th, z0 - width / 2), V(x, yb - th * 1.15, z0)]
            rings_.append(sec)
        for i in range(segs):
            A, Bv = rings_[i], rings_[i + 1]
            for k in range(6):
                j = (k + 1) % 6
                row = "z2_snow" if k in (1, 2) else "z2_bridge"
                shd = [0.85, 0.95] if row == "z2_snow" else [0.3, 0.7]
                q = [A[k], A[j], Bv[j], Bv[k]]
                nrm = (q[1] - q[0]).cross(q[2] - q[0])
                mid = sum(q, Vector()) / 4
                ax = (A[0] + A[3]) / 2 * 0.5 + (Bv[0] + Bv[3]) / 2 * 0.5
                if nrm.dot(mid - V(mid.x, ax.y, ax.z)) < 0:
                    q = q[::-1]
                mb.face(q, row, [shd[0], shd[1], shd[1], shd[0]])
        # icicles hanging under the arch
        for _ in range(26):
            u = random.uniform(-0.75, 0.75)
            x = u * span
            yb = y0 + rise + 14 * (1 - u * u) - thick * (1 + 0.6 * u * u)
            L = random.uniform(3, 11)
            top = V(x, yb + 1, z0 + random.uniform(-6, 6))
            lo = ring(top, random.uniform(0.6, 1.4), 0, 5, random.random())
            cap_o(mb, lo[::-1], top + V(0, -L, 0), "z2_bridge", 0.6, 0.98)
        S.build("Z2_Bridge_%d" % (bi + 1), mb, coll, extra={"kind": "bridge", "castShadow": True})
        MARK["Bridges"].append([0, round(y0 + rise, 1), round(z0, 1)])
    # light shafts: canyon-top openings above the track
    for d in range(int(B1 + 120), int(B2 - 60), 130):
        y0, z0 = centre(d)
        MARK["Shafts"].append([round(random.uniform(-10, 10), 1), round(y0 + 190, 1), round(z0, 1)])


def lava_ribbon(mb, x, d, length, width, drift):
    pts = []
    for i in range(int(length / 6)):
        d2 = d - i * 6
        x += drift * 6 + 4 * n3(d2 / 30, x / 30, 70)
        if abs(x) < hw(d2) + EDGE + 3:
            break
        pts.append((x, d2))
    prev = None
    for i, (x2, d2) in enumerate(pts):
        w = width * (1 - 0.6 * i / max(len(pts), 1)) * (0.7 + 0.5 * (n3(i * 0.4, x2 / 9, 71) + 1) / 2)
        a, b = ground(x2 - w, d2) + V(0, 0.45, 0), ground(x2 + w, d2) + V(0, 0.45, 0)
        if prev:
            mb.face([prev[0], prev[1], b, a], "z3_lava", [0.6, 0.6, 0.95, 0.95])
        prev = (a, b)


# ---------------------------------------------------------------- zone 3 basalt (M6: fused masses)
SQ3 = math.sqrt(3.0)
HEX_NB = [(1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1)]  # lattice step across hex side i (faces 30+60i deg)


def basalt_mass(g, r, hbase, nk, rng):
    """A fused basalt mass: hex prisms packed edge to edge on a lattice (shared faces coincide), heights
    stepping in terraces over the blob, the whole mass leaning one way. Returns the data basalt_build needs."""
    R = r * 1.5  # hex circumradius (chunkier than the old posts)
    e1, e2 = V(SQ3 * R * math.cos(math.pi / 6), 0, SQ3 * R * math.sin(math.pi / 6)), V(0, 0, SQ3 * R)
    Rb = r * 1.8 * math.sqrt(nk) * 0.9  # same footprint as the old cluster
    ph = rng.uniform(0, 6.28)
    tilt_dir = rng.uniform(0, 6.28)
    tilt_amt = rng.uniform(-0.45, 0.45)
    lean_a = rng.uniform(0, 6.28)
    lean = rng.choice((0.0, 0.0, 0.06, 0.12, 0.2))  # a third of the masses lean
    L = V(math.cos(lean_a), 0, math.sin(lean_a)) * math.tan(lean)
    step = max(1.6, 0.2 * hbase)
    n = int(Rb / (SQ3 * R)) + 2
    cells = {}
    for i in range(-n, n + 1):
        for j in range(-n, n + 1):
            off = e1 * i + e2 * j
            dist = off.length
            ang = math.atan2(off.z, off.x)
            edge = Rb * (1 + 0.32 * math.sin(2 * ang + ph) + 0.18 * math.sin(3 * ang - 2 * ph))
            if dist > edge:
                continue
            c = g + off
            d2 = SP.d_at_z(c.z)
            if abs(c.x) - R < hw(d2) + EDGE + 1.5:  # the whole prism stays off the track
                continue
            u = dist / max(edge, 1e-3)
            h = hbase * (1.1 - 0.65 * u ** 1.6) + hbase * tilt_amt * (off.x * math.cos(tilt_dir) + off.z * math.sin(tilt_dir)) / Rb
            h += hbase * 0.45 * n3(c.x / (3.5 * R) + ph, c.z / (3.5 * R), 60)  # blocks of columns rise and fall together
            h = max(2.0, round(h / step) * step + (rng.uniform(-0.5, 0.5) * step if rng.random() < 0.4 else 0.0))
            cells[(i, j)] = (c, h)
    # no lone posts: drop cells with fewer than two neighbours (twice, so stragglers go too)
    for _ in range(2):
        cells = {k: v for k, v in cells.items() if sum((k[0] + a, k[1] + b) in cells for a, b in HEX_NB) >= 2}
    return {"g": g, "R": R, "L": L, "cells": cells}


def basalt_build(mb, m):
    assert OUTWARD  # faces below are wound in band()/cap() order
    g, R, L, cells = m["g"], m["R"], m["L"], m["cells"]

    def at_y(xz, y):  # a lattice line, sheared by the lean relative to the mass base: shared faces stay shared
        return V(xz.x + L.x * (y - g.y), y, xz.z + L.z * (y - g.y))

    gy = {}
    for k, (c, h) in cells.items():
        sy = surf_y(c.x, c.z)
        gy[k] = c.y if sy is None else sy
    for k, (c, h) in cells.items():
        top = gy[k] + h
        ring_xz = [V(c.x + R * math.cos(math.pi / 3 * i), 0, c.z + R * math.sin(math.pi / 3 * i)) for i in range(6)]
        bot = []
        for q in ring_xz:  # every foot corner sits 3 studs into its own ground (no downhill gap)
            sy = surf_y(q.x, q.z)
            bot.append((sy if sy is not None else gy[k]) - 3)
        hi = [at_y(q, top) for q in ring_xz]
        for i in range(6):
            j = (i + 1) % 6
            nb = (k[0] + HEX_NB[i][0], k[1] + HEX_NB[i][1])
            lo_i, lo_j = bot[i], bot[j]
            if nb in cells:
                ntop = gy[nb] + cells[nb][1]
                if ntop >= top - 0.05:
                    continue  # hidden inside the mass
                lo_i, lo_j = max(lo_i, ntop), max(lo_j, ntop)
            a = 0.06 if i % 2 else 0.0
            mb.face([at_y(ring_xz[i], lo_i), hi[i], hi[j], at_y(ring_xz[j], lo_j)], "z3_obsidian",
                    [0.05 + a, 0.3 + a, 0.3 + a, 0.05 + a])  # band() order: outward (OUTWARD is True)
        apex = at_y(V(c.x, 0, c.z), top + R * 0.15)
        for i in range(6):
            j = (i + 1) % 6
            mb.face([hi[i], apex, hi[j]], "z3_ground", [0.45, 0.6, 0.45])


def zone3(coll):
    items = []
    for (x, d, s) in scatter(B2 + 30, B3 - 10, 6, 700, 300, lambda x, d, s: zone_w(d)[2] > 0.6):
        g = ground(x, d)
        h = random.uniform(18, 50) * (1 + s / 220)
        h = min(h, 190)
        side = 1 if x > 0 else -1
        lean_dir = -side * math.pi / 2 + random.uniform(-0.6, 0.6)
        items.append((d, shard, (g, h, h * random.uniform(0.14, 0.24), 5, lean_dir, random.uniform(0.05, 0.45),
                                 "z3_obsidian", 0.08, 0.72, 0.5)))
    batch_props("Z3_Spires", coll, items, {"kind": "obsidian", "castShadow": True})

    cols = []
    for (x, d, s) in scatter(B2 + 20, B3 - 10, 12, 260, 46, lambda x, d, s: zone_w(d)[2] > 0.6):
        g = ground(x, d)
        r = random.uniform(2.6, 4.2)
        hbase = random.uniform(5, 12) * (1 + s / 120)
        nk = random.randint(9, 19)
        # pre-M6 sunflower layout: kept only to draw the same random numbers (later props and the backdrop
        # stay where they were); the fused mass below uses its own generator seeded from this cluster
        for k in range(nk):
            a = k * 2.4
            rr = r * 1.8 * math.sqrt(k)
            px, pz = g.x + math.cos(a) * rr, g.z + math.sin(a) * rr
            if abs(px) < hw(SP.d_at_z(pz)) + EDGE + 1.5:
                continue
            random.uniform(0.7, 1.15)
        cl = basalt_mass(g, r, hbase, nk, random.Random(int(abs(x) * 1000) * 7919 + int(d * 10)))
        if cl:
            cols.append((d, lambda mb, cl=cl: basalt_build(mb, cl), ()))
    batch_props("Z3_Basalt", coll, cols, {"kind": "basalt", "castShadow": True})

    # lava: cracks down the slopes, plus glowing seams on the track curbs
    lav = []
    for (x, d, s) in scatter(B2 + 80, B3, 20, 500, 60, lambda x, d, s: zone_w(d)[2] > 0.7):
        lav.append((d, lava_ribbon, (x, d, random.uniform(60, 260), random.uniform(1.2, 3.5), random.uniform(-0.15, 0.15))))
        MARK["Lava"].append([round(x, 1), round(ground(x, d).y + 2, 1), round(ground(x, d).z, 1)])
    mb = S.MB()
    for side in (-1, 1):
        prev = None
        for i in range(0, 251):
            d = B2 + i * 4
            h = hw(d)
            a = SP.surf(d, side * (h + 3.2), STYLE[2]["bh"] + 0.06)
            b = SP.surf(d, side * (h + 3.8), STYLE[2]["bh"] + 0.06)
            a, b = V(*a), V(*b)
            if prev:
                mb.face([prev[0], prev[1], b, a], "z3_lava", 0.8)
            prev = (a, b)
    fix_up(mb)
    lav.append((0, lambda m, src=mb: m.merge(src), ()))
    b = Batcher("Z3_Lava", coll, {"kind": "lava", "castShadow": False, "material": "Neon", "color": "z3.lava_orange"}, fixup=True)
    for _, fn, args in sorted(lav, key=lambda t: t[0]):
        tmp = S.MB()
        fn(tmp, *args)
        if b.mb.tris() + tmp.tris() > 9000:
            b.flush()
        fn(b.mb, *args)
    b.flush()

    vents = []
    for (x, d, s) in scatter(B2 + 40, B3 - 30, 10, 140, 22, lambda x, d, s: zone_w(d)[2] > 0.7):
        g = ground(x, d)

        def vent(mb, g=g):
            r = random.uniform(4, 7)
            lo = ring(g, r, -1.5, 8, 0)
            hi = ring(g, r * 0.45, 2.6, 8, 0)
            band_o(mb, lo, hi, "z3_ground", 0.2, 0.55)
            cap_o(mb, hi, g + V(0, 1.4, 0), "z3_obsidian", 0.05, 0.02)
        vents.append((d, vent, ()))
        MARK["Vents"].append([round(g.x, 1), round(g.y + 2.6, 1), round(g.z, 1)])
    batch_props("Z3_Vents", coll, vents, {"kind": "vents", "castShadow": True})
    for (x, d, s) in scatter(B2 + 50, B3, 200, 600, 9):
        g = ground(x, d)
        MARK["Plumes"].append([round(g.x, 1), round(g.y + 5, 1), round(g.z, 1)])


def crystal_cluster(mb, g, scale, n, out_dir=None, zone=None):
    """zone: drop crystals whose own base is not on that paint zone (same random draws either way)."""
    lead = random.uniform(0, 6.28) if out_dir is None else out_dir
    for k in range(n):
        h = scale * random.uniform(0.45, 1.0) * (1.0 if k == 0 else 0.75)
        b = g + V(random.uniform(-0.3, 0.3) * scale * 0.3, 0, random.uniform(-0.3, 0.3) * scale * 0.3)
        sy = surf_y(b.x, b.z)  # each crystal on its own ground: cluster bases span 20+ studs of slope
        crystal(mb if zone is None or surf_zone(b.x, b.z) == zone else S.MB(), b if sy is None else V(b.x, sy, b.z),
                h, h * random.uniform(0.11, 0.17), lead + (k * 2.1 if out_dir is None else random.uniform(-0.7, 0.7)),
                0.0 if k == 0 else random.uniform(0.2, 0.6))


def crystal_ghost(mb, *a):
    """Draws the same random numbers as crystal_cluster but builds nothing (keeps later props in place)."""
    crystal_cluster(S.MB(), *a)


def zone4(coll):
    items = []
    for (x, d, s) in scatter(B3 + 20, TOP, 1, 22, 120, lambda x, d, s: zone_w(d)[3] > 0.6):
        g = ground(x, d)
        LIP.append((g, 1 if x > 0 else -1))
        items.append((d, crystal_cluster, (g, random.uniform(4, 13), random.randint(2, 5), -(1 if x > 0 else -1) * math.pi / 2)))
    for (x, d, s) in scatter(B3 + 40, TOP + 60, 40, 700, 110, lambda x, d, s: zone_w(d)[3] > 0.6):
        g = ground(x, d)
        sc = random.uniform(25, 80) * (1 + s / 400)
        on4 = zone_pick(d, x) == 3  # far out the zone 4 paint lags B3: no crystals on zone 3 basalt
        if on4:
            CLUSTERS.append((g, min(sc, 220)))
        items.append((d, crystal_cluster if on4 else crystal_ghost, (g, min(sc, 220), random.randint(3, 7), None, 3)))
        if sc > 60 and on4:
            MARK["Crystals"].append([round(g.x, 1), round(g.y + sc * 0.4, 1), round(g.z, 1)])
    batch_props("Z4_Crystals", coll, items, {"kind": "crystal", "castShadow": False})

    rocks = []
    for (x, d, s) in scatter(B3 + 10, TOP, 0, 18, 80, lambda x, d, s: zone_w(d)[3] > 0.5):
        g = ground(x, d)
        sz = random.uniform(2, 5)
        rocks.append((d, boulder, (g, V(sz * 1.3, sz * 0.8, sz), "z4_rock", "z4_snow", random.random() * 30)))
    batch_props("Z4_Rocks", coll, rocks, {"kind": "rocks", "castShadow": True})

    # summit crown: a ring of great crystals around the plateau, one spire at its heart
    yc, zc = centre(SUMMIT_D)
    mb = S.MB()
    for k in range(11):
        a = k / 11 * 2 * math.pi + 0.2
        r = random.uniform(92, 112)
        x, z = math.cos(a) * r, zc + math.sin(a) * r
        d2 = SP.d_at_z(z)
        if abs(x) < 30 and z > zc:  # keep the arrival side open
            continue
        sy = surf_y(x, z)
        g = V(x, ground(x, d2).y if sy is None else sy, z)
        h = random.uniform(70, 150)
        crystal(mb, g, h, h * 0.13, a - math.pi / 2, random.uniform(0.15, 0.35))  # lean outward
        crystal(mb, g + V(4, 0, 3), h * 0.55, h * 0.09, a - math.pi / 2 + 0.6, 0.5)
    crystal(mb, V(0, yc - 1.5, zc - 10), 130, 13, 0, 0)
    for k in range(5):
        crystal(mb, V(0, yc - 1.5, zc - 10), random.uniform(40, 70), 6, k * 1.26, 0.45)
    S.build("Z4_Crown", mb, coll, extra={"kind": "crystal", "castShadow": True})
    MARK["Summit"] = [0, round(yc, 1), round(zc, 1)]
    glow_accents(coll, yc, zc)


def glow_accents(coll, yc, zc):
    """Neon accent crystals (the sheet's crystals glow, Z4 crystal_glint). A separate RNG keeps every
    other mesh identical to what is already imported."""
    rng = random.Random(4004)
    saved = random.getstate()  # crystal() draws its rotation from the global RNG
    mb = S.MB()
    for g, sc in CLUSTERS:
        for _ in range(rng.randint(1, 3)):
            h = sc * rng.uniform(0.25, 0.5)
            off = V(rng.uniform(-1, 1) * sc * 0.18, 0, rng.uniform(-1, 1) * sc * 0.18)
            b, a, lean = g + off, rng.uniform(0, 6.28), rng.uniform(0.2, 0.7)
            sy = surf_y(b.x, b.z)  # on its own ground, not the cluster centre's height
            if sy is not None and surf_zone(b.x, b.z) == 3:
                crystal(mb, V(b.x, sy, b.z), h, h * 0.1, a, lean)
    for g, side in LIP:  # one glowing shard per lip cluster, leaning away from the lanes: seen from the ride
        h = rng.uniform(3, 7)
        b = g + V(side * rng.uniform(0.5, 2), 0, rng.uniform(-2, 2))
        sy = surf_y(b.x, b.z)
        crystal(mb, b if sy is None else V(b.x, sy, b.z), h, h * 0.13, -side * math.pi / 2, rng.uniform(0.2, 0.5))
    for k in range(9):  # a glowing ring at the foot of the summit spire
        a = k / 9 * 2 * math.pi
        crystal(mb, V(math.cos(a) * 20, yc - 1.5, zc - 10 + math.sin(a) * 20), rng.uniform(18, 34), 2.6, a - math.pi / 2, 0.5)
    random.setstate(saved)
    S.build("Z4_Glow", mb, coll, extra={"kind": "crystal", "castShadow": False, "material": "Neon", "color": "z4.crystal_glint"})


# ---------------------------------------------------------------- backdrop
def mountain(mb, base, R, Hm, row_lo, row_hi, seed, snowline=0.55):
    sides, rings_n = 26, 7
    prev = None
    a0 = random.uniform(0, 6.28)
    for k in range(rings_n + 1):
        t = k / rings_n
        if k == rings_n:
            apex = base + V(R * 0.05 * n3(seed, 1, 80), Hm, R * 0.05 * n3(seed, 2, 80))
            sh_lo = 0.55 if t - 1 / rings_n < snowline else 0.85
            for i in range(sides):
                j = (i + 1) % sides
                row = row_hi if t - 1 / rings_n >= snowline - 0.1 else row_lo
                mb.face([prev[i], prev[j], apex][::-1] if not OUTWARD else [prev[i], apex, prev[j]], row,
                        [0.7 + 0.2 * n3(i, seed, 81), 0.98, 0.7 + 0.2 * n3(j, seed, 81)])
            break
        cur = []
        for i in range(sides):
            a = a0 + 2 * math.pi * i / sides
            rr = R * (1 - t) ** 1.15 * (1 + 0.25 * n3(math.cos(a) * 1.5 + seed, math.sin(a) * 1.5, t * 2 + 82))
            yy = Hm * t ** 0.85 * (1 + 0.12 * n3(i * 0.7, seed, 83 + t))
            cur.append(base + V(math.cos(a) * rr, yy, math.sin(a) * rr))
        if prev:
            for i in range(sides):
                j = (i + 1) % sides
                tm = t - 0.5 / rings_n
                row = row_hi if tm > snowline + 0.08 * n3(i * 0.5, seed, 84) else row_lo
                lo_s = 0.15 + 0.6 * tm if row == row_lo else 0.6 + 0.35 * tm
                hi_s = lo_s + 0.12
                alt = 0.1 * n3(i * 1.3, seed, 85)
                q = [prev[i], cur[i], cur[j], prev[j]]
                if not OUTWARD:
                    q = q[::-1]
                mb.face(q, row, [lo_s + alt, hi_s + alt, hi_s + alt, lo_s + alt])
        prev = cur


def backdrop(coll):
    specs = []
    FAR = [("z1_far", "z1_snow"), ("z2_ice", "z2_snow"), ("z3_far", "z3_obsidian"), ("z4_far", "z4_snow")]
    for side in (-1, 1):
        d = -600
        while d < TOP + 900:
            zk = SP.zone_of(min(max(d, 0), TOP - 1))
            y0, z0 = centre(min(d, TOP + 200))
            dist = random.uniform(1250, 2900)
            R = random.uniform(550, 780)
            top_y = {0: random.uniform(700, 1500), 1: random.uniform(800, 1500), 2: random.uniform(700, 1300),
                     3: random.uniform(500, 950)}[zk]
            base_y = min(y0 - 450, top_y - 400)
            Hm = min(1750, top_y - base_y)
            specs.append((zk, V(side * dist, base_y, z0 + random.uniform(-150, 150)), R, Hm))
            d += random.uniform(380, 620)
    # behind the start and beyond the summit
    for i in range(7):
        specs.append((0, V(random.uniform(-2600, 2600), -500, random.uniform(1300, 2700)), random.uniform(600, 780),
                      random.uniform(1300, 1750)))
    yt, zt = centre(TOP)
    for i in range(8):
        specs.append((3, V(random.uniform(-2800, 2800), yt - 1100, zt - random.uniform(1300, 2900)),
                      random.uniform(600, 780), random.uniform(900, 1500)))
    mb, k = S.MB(), 0
    for i, (zk, base, R, Hm) in enumerate(sorted(specs, key=lambda s: (s[1].z, s[1].x))):
        one = S.MB()
        mountain(one, base, R, Hm, FAR[zk][0], FAR[zk][1], random.random() * 50, 0.5 if zk != 2 else 0.8)
        k += 1
        S.build("BG_Peak_%02d" % k, one, coll, fidelity="Performance",
                extra={"kind": "backdrop", "castShadow": False, "zone": zk + 1}, rigid=True)


# ---------------------------------------------------------------- main
def deck(name, d0, n, row, shades, coll, start=False, end=False):
    mb = S.MB()
    rows = []
    for i in range(n + 1):
        d = d0 + i * 10
        xs = [-hw(d) - EDGE - 4, -8, 0, 8, hw(d) + EDGE + 4]
        rows.append([{"p": ground(x, d), "d": d} for x in xs])
    for i in range(n):
        for j in range(4):
            a0, a1, b0, b1 = rows[i][j]["p"], rows[i][j + 1]["p"], rows[i + 1][j]["p"], rows[i + 1][j + 1]["p"]
            mb.face([a0, b0, b1, a1], row, shades)
    fix_up(mb)
    if start:
        skirt(mb, rows[0], V(0, 0, 1), skirt_zone)
    if end:
        skirt(mb, rows[-1], V(0, 0, -1), skirt_zone)
    SURF["mbs"].append(mb)
    S.build(name, mb, coll, extra={"kind": "terrain", "castShadow": True})


def main():
    zc = [S.collection("SS_Zone%d" % (k + 1)) for k in range(4)]
    bg = S.collection("SS_Backdrop")
    # track: one chunk per 250 studs, each in a single zone's style
    edges = [-150] + [250 * i for i in range(1, 16)] + [TOP + SP.C["SummitFlat"]]
    for i in range(len(edges) - 1):
        d0, d1 = edges[i], edges[i + 1]
        zk = SP.zone_of(max(d0, 0))
        track_chunk("Z%d_Track_%02d" % (zk + 1, i + 1), d0, d1, zk, zc[zk])
    # terrain: 500-stud chunks per side; start apron in zone 1, summit plateau in zone 4
    spans = [(-420, 0, 0), (0, 500, 0), (500, B1, 0), (B1, B1 + 500, 1), (B1 + 500, B2, 1), (B2, B2 + 500, 2),
             (B2 + 500, B3, 2), (B3, B3 + 500, 3), (B3 + 500, TOP, 3), (TOP, TOP + 260, 3)]
    for (d0, d1, zk) in spans:
        for side, tag in ((-1, "L"), (1, "R")):
            terrain_chunk("Z%d_Terrain_%s_%d" % (zk + 1, tag, int(d0)), d0, d1, side, zc[zk],
                          start=d0 == spans[0][0], end=d1 == spans[-1][1], fine=zk == 0, seam_end=zk == 0 and d1 == B1)
    # decks under the centre strip where there is no track (terrain chunks only cover the sides):
    # the summit plateau, and the start apron behind the first track chunk
    deck("Z4_SummitDeck", TOP + SP.C["SummitFlat"] - 1, 22, "z4_snow", [0.8, 0.85, 0.9, 0.82], zc[3], end=True)
    deck("Z1_StartDeck", START_D, 28, "z1_snow", [0.62, 0.7, 0.78, 0.66], zc[0], start=True)
    surf_freeze()
    zone1(zc[0])
    zone2(zc[1])
    zone3(zc[2])
    zone4(zc[3])
    backdrop(bg)

    os.makedirs(BLEND_DIR, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BLEND_DIR, "ss_mountain.blend"))
    for k in range(4):
        S.export_fbx(zc[k], os.path.join(EXPORT_DIR, "ss_zone%d.fbx" % (k + 1)))
    S.export_fbx(bg, os.path.join(EXPORT_DIR, "ss_backdrop.fbx"))
    S.write_manifest(os.path.join(EXPORT_DIR, "ss_manifest.json"))
    # --patch NAME[,NAME]: also export just those meshes to ss_patch.fbx (re-import a fix without a full zone)
    if "--patch" in sys.argv:
        names = [n for n in sys.argv[sys.argv.index("--patch") + 1].split(",") if n]
        pc = S.collection("SS_Patch")
        for n in names:
            pc.objects.link(bpy.data.objects[n])
        S.export_fbx(pc, os.path.join(EXPORT_DIR, "ss_patch.fbx"))
        print("PATCH", names)
    write_markers()
    tot = sum(m["tris"] for m in S.MANIFEST.values())
    print("BUILD OK meshes=%d tris=%d outward=%s" % (len(S.MANIFEST), tot, OUTWARD))
    for k in range(4):
        n = [m for nm, m in S.MANIFEST.items() if nm.startswith("Z%d_" % (k + 1))]
        print(" zone%d meshes=%d tris=%d" % (k + 1, len(n), sum(m["tris"] for m in n)))
    n = [m for nm, m in S.MANIFEST.items() if nm.startswith("BG_")]
    print(" backdrop meshes=%d tris=%d" % (len(n), sum(m["tris"] for m in n)))


def write_markers():
    def vec(p):
        if S.WARP:
            p = [round(v, 1) for v in S.WARP(*p)]
        return "Vector3.new(%s, %s, %s)" % tuple(p)

    lines = ["-- Generated by art/tools/build_mountain.py: effect anchor points on the Blender mountain",
             "-- (ReplicatedStorage.SS_Markers). Data only; do not hand-edit, rebuild instead.", "return {"]
    for k in ("Vents", "Plumes", "Shafts", "Bridges", "Crystals", "Lava"):
        lines.append("\t%s = {" % k)
        for p in MARK[k]:
            lines.append("\t\t%s," % vec(p))
        lines.append("\t},")
    lines.append("\tSummit = %s," % vec(MARK["Summit"]))
    # BOT cross-check of the Python and Luau path twins: {d, x, bent world point of surf(d, x, 0)}
    lines.append("\tPathCheck = {")
    for d in range(-100, int(TOP) + 101, 100):
        for x in (-hw(d), 0.0, hw(d)):
            w = S.WARP(*SP.surf(d, x, 0)) if S.WARP else SP.surf(d, x, 0)
            lines.append("\t\t{ %d, %.4f, Vector3.new(%.4f, %.4f, %.4f) }," % ((d, x) + tuple(w)))
    lines.append("\t},")
    lines.append("}")
    open(MARKERS_PATH, "w", newline="\n").write("\n".join(lines) + "\n")


if "--no-main" not in sys.argv:  # --no-main: import the module's functions without building
    main()
