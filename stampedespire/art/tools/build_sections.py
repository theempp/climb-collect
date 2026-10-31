"""Stampede Spire 10-section mountain build (Blender, background):
  blender -b --factory-startup --python art/tools/build_sections.py -- --outdir art/export/sections
Builds the 17,960-stud, 10-biome mountain (SECTIONS-PLAN rev 2) on the SS_Path centreline. Reuses the
signed-off machinery of build_mountain.py (skirts, raycast prop grounding, batching, track, backdrop shape)
by importing it with --no-main and swapping its zone tables for 10 biomes. Sections 1/3/6/10 keep the
signed-off zone 1-4 looks; 2/4/5/7/8/9 are new, every colour from the r3 rows of ss_atlas10.png
(make_atlas.RAMPS_R3, art/LOOKDEV.md). Writes into --outdir only: ss_sections.blend, ss_sNN.fbx,
ss_backdrop.fbx, ss_manifest.json, SS_Markers.luau."""
import math, os, random, sys

os.environ["SS_SECTIONS"] = "1"  # ssblend: 64-row atlas with the r3 rows (must be set before the import)
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
if "--no-main" not in sys.argv:
    sys.argv.append("--no-main")
    _RUN = True
else:
    _RUN = False
import build_mountain as BM  # noqa: E402  (resets the scene, seeds the RNG, sets the bend warp)
from build_mountain import (V, ss, n3, fbm, ridged, hw, ground, centre, centre_x, ring, band_o, cap_o, boulder,  # noqa: E402
                            shard, crystal, Batcher, scatter, fix_up, EDGE, TOP, SUMMIT_D, S_LIST)
import sspath as SP  # noqa: E402
import ssblend as S  # noqa: E402
from mathutils import Vector  # noqa: E402

OUTDIR = sys.argv[sys.argv.index("--outdir") + 1] if "--outdir" in sys.argv else os.path.join(S.EXPORT, "sections")
NB = len(SP.Z)
assert NB == 10, "SS_Config must hold the 10 sections"
KEYS = ("taiga", "rime", "crevasse", "icecave", "springs", "obsidian", "storm", "spires", "cloudsea", "aurora")
OLD = {0: 0, 2: 1, 5: 2, 9: 3}  # sections whose look is a signed-off zone 1-4 (build_mountain index)
STARTS = list(SP.starts)
ENDS = [SP.zone_end(k) for k in range(NB)]
LENS = [SP.Z[k]["Length"] for k in range(NB)]
BL = BM.BL


def terr(h, step, sharp):
    """Terrace a height: flat treads every `step`, risers over the last `sharp` of each step."""
    n = h / step
    i = math.floor(n)
    return step * (i + ss(1 - sharp, 1.0, n - i))


# ---------------------------------------------------------------- new biome profiles (height above the track)
def prof_rime(x, d, s, side):  # S2: forest floor rising gently into fogged, wooded hills
    bank = ss(0, 18, s) * (1.5 + 2.0 * fbm(x / 40, d / 40, 101))
    hills = 22 * fbm(x / 200, d / 200, 102) * ss(30, 200, s) + 60 * max(0.0, fbm(x / 520 + 5, d / 520, 103)) * ss(150, 600, s)
    return -1.5 + bank + 0.14 * s + 70 * ss(120, 800, s) + hills


def prof_cave(x, d, s, side):  # S4: stepped ice shelves at the foot of tall cave walls
    foot = s - 2 - 3 * (n3(d / 25, side * 3.3, 110) + 1)
    wall_h = 140 + 60 * fbm(d / 160, side * 4.1, 111) + 25 * fbm(d / 50, side * 6.3, 112)
    wall = wall_h * ss(0, 18, foot)
    wall = terr(min(wall, 36.0), 7.0, 0.35) + max(0.0, wall - 36.0)  # S4 stepped frozen shelves
    rim = 0.25 * max(0.0, s - 40) + 160 * ridged(x / 240, d / 240, 113) * ss(80, 400, s)
    return -1.5 + 1.0 * ss(0, 3, s) + wall + rim


SPR_STEP, SPR_SHARP = 8.0, 0.3


def spring_raw(x, d, s):
    # low-frequency wander only, so each terrace reads as one long curved shelf instead of speckle
    return 0.28 * s + 14 * fbm(x / 240, d / 240, 120) * ss(15, 120, s) + 90 * ss(250, 800, s)


def prof_springs(x, d, s, side):  # S5: travertine terraces stepping up from the track
    return -1.5 + 1.2 * ss(0, 6, s) + terr(spring_raw(x, d, s), SPR_STEP, SPR_SHARP) * ss(4, 14, s)


def prof_storm(x, d, s, side):  # S7: jagged storm-rock peaks
    bank = 2.5 * ss(0, 8, s) + 2 * fbm(x / 18, d / 18, 130) * ss(0, 14, s)
    peaks = 420 * ridged(x / 300, d / 300, 131) * ss(60, 500, s)
    crags = 30 * fbm(x / 60, d / 60, 132) * ss(10, 80, s)
    return -1.5 + bank + 0.22 * s + peaks + crags


def prof_spires(x, d, s, side):  # S8: snowy slopes with flat-topped rust mesas (hoodoos are props)
    drift = ss(0, 15, s) * (1.5 + 2 * fbm(x / 35, d / 35, 140))
    mesa = 90 * ss(0.15, 0.25, fbm(x / 350, d / 350, 141)) * ss(200, 500, s)
    return -1.5 + drift + 0.08 * s + 30 * fbm(x / 240, d / 240, 142) * ss(20, 200, s) + mesa


def prof_cloud(x, d, s, side):  # S9: snow ridge, the world drops into the cloud sea
    lip = 1.5 * ss(0, 3, s) + 2 * fbm(x / 15, d / 15, 150) * (1 - ss(0, 30, s))
    drop = -330 * ss(8, 260, s) - 0.05 * s
    peaks = 380 * max(0.0, ridged(x / 320, d / 320, 151) - 0.25) * ss(260, 650, s)
    return -1.5 + lip + drop + peaks + 14 * fbm(x / 80, d / 80, 152) * ss(20, 120, s)


PROFS = [BM.prof1, prof_rime, BM.prof2, prof_cave, prof_springs, BM.prof3, prof_storm, prof_spires, prof_cloud, BM.prof4]


# ---------------------------------------------------------------- zone weights over 9 borders
def _weights(ts):
    return [(ts[k - 1] if k else 1.0) * (1 - ts[k] if k < NB - 1 else 1.0) for k in range(NB)]


def zone_w(d):
    return _weights([ss(B - BL, B + BL, d) for B in STARTS[1:]])


def _border_hw(i):
    """Height-blend half-width over s for border i (between sections i-1 and i): 0.75 x the largest profile
    difference there (the slope rule build_mountain's hand-tuned widths followed), never narrower outward,
    capped so neighbouring windows never overlap."""
    B, pa, pb = STARTS[i], PROFS[i - 1], PROFS[i]
    tab, run = [], 0.0
    for s in [v for v in S_LIST if v >= 0]:
        m = 0.0
        for dd in (-150, -50, 50, 150):
            d = B + dd
            for side in (-1, 1):
                x = side * (hw(d) + EDGE + s)
                m = max(m, abs(pa(x, d, s, side) - pb(x, d, s, side)))
        run = max(run, 70.0, 0.75 * m)
        tab.append((s, run))
    cap = 0.45 * min(LENS[i - 1], LENS[i] if i < NB - 1 else 1e9)

    def f(s):
        if s <= tab[0][0]:
            return min(tab[0][1], cap)
        for (s0, w0), (s1, w1) in zip(tab, tab[1:]):
            if s <= s1:
                return min(w0 + (w1 - w0) * (s - s0) / (s1 - s0), cap)
        return min(tab[-1][1], cap)
    return f


HBW = [None] + [_border_hw(i) for i in range(1, NB)]


def height_w(d, s):
    s = max(s, 0.0)
    return _weights([ss(STARTS[i] - HBW[i](s), STARTS[i] + HBW[i](s), d) for i in range(1, NB)])


def zone_pick(d, x):
    f = min(max(abs(x) - (hw(d) + EDGE), 0.0), 400.0)
    w = zone_w(d + 35 * n3(x / 60, d / 60, 20) + 0.45 * f * n3(x / 190, d / 190, 22))
    return max(range(NB), key=lambda k: w[k])


ROW_SEC = {"z1": 0, "s2": 1, "z2": 2, "s4": 3, "s5": 4, "z3": 5, "s7": 6, "s8": 7, "s9": 8, "z4": 9}


def surf_zone(x, z):
    row = BM.surf_hit(x, z)[1]
    return None if row is None else ROW_SEC[row[:2]]


# ---------------------------------------------------------------- paint
OLD_PAINT = BM.terrain_paint


def paint_rime(ny, hr, d, x, n):
    if ny < 0.72:
        return "s2_rock", 0.3 + 0.4 * (n * 0.5 + 0.5)
    return "s2_snow", 0.3 + 0.6 * ss(0.72, 1.0, ny) + 0.06 * n


def paint_cave(ny, hr, d, x, n):
    if ny < 0.6:
        return "s4_ice", 0.08 + 0.85 * min(max(hr / 180, 0), 1) + 0.07 * n
    return "s4_floor", 0.35 + 0.5 * ss(0.6, 1.0, ny) + 0.06 * n


def paint_springs(ny, hr, d, x, n):
    s = abs(x) - (hw(d) + EDGE)
    raw = spring_raw(x, d, max(s, 0.0)) / SPR_STEP
    f = raw % 1.0
    if ny < 0.8:  # risers: cream lip at the top, orange mineral drips streaking down to the foot (S5 x 700-1340)
        fr = min(max((f - (1 - SPR_SHARP)) / SPR_SHARP, 0.0), 1.0) if f > 0.5 else 1.0
        return "s5_trav", 0.15 + 0.75 * fr + 0.18 * n3(x / 5, d / 5, 122)
    if 12 < s < 420 and n3(math.floor(raw) * 1.7, d / 260, 121) > -0.45:  # one decision per terrace stretch
        if f < 0.12:
            return "s5_trav", 0.9  # the pool's cream rim over the terrace below
        if f < 1 - SPR_SHARP - 0.05:
            return "s5_pool", 0.9 - 0.65 * math.sin(math.pi * (f - 0.12) / (0.83 - SPR_SHARP - 0.12))
    return "s5_snow", 0.4 + 0.5 * ss(0.8, 1.0, ny) + 0.06 * n


def paint_storm(ny, hr, d, x, n):
    if ny < 0.74:
        return "s7_rock", 0.15 + 0.55 * (n * 0.5 + 0.5) + 0.2 * min(max(hr / 400, 0), 1)
    return "s7_snow", 0.35 + 0.55 * ss(0.74, 1.0, ny) + 0.06 * n


def paint_spires(ny, hr, d, x, n):
    if ny < 0.7:  # banded sandstone strata
        return "s8_spire", 0.3 + 0.3 * (0.5 + 0.5 * math.sin(hr / 5.5 + 0.8 * n))
    return "s8_snow", 0.4 + 0.5 * ss(0.7, 1.0, ny) + 0.06 * n


def paint_cloud(ny, hr, d, x, n):
    if ny < 0.66:
        return "s9_rock", 0.2 + 0.5 * (n * 0.5 + 0.5)
    return "s9_snow", 0.35 + 0.6 * ss(0.66, 1.0, ny) + 0.06 * n


NEW_PAINT = {1: paint_rime, 3: paint_cave, 4: paint_springs, 6: paint_storm, 7: paint_spires, 8: paint_cloud}


def terrain_paint(zk, ny, hr, d, x, summit, soft=False):
    if summit:
        return OLD_PAINT(3, ny, hr, d, x, True, soft)
    if zk in OLD:
        return OLD_PAINT(OLD[zk], ny, hr, d, x, False, soft)
    return NEW_PAINT[zk](ny, hr, d, x, n3(x / 23, d / 23, 21))


SKIRT_ROW = ("z1_rock", "s2_rock", "z2_ledge", "s4_rock", "s5_trav", "z3_obsidian", "s7_rock", "s8_spire", "s9_rock", "z4_rock")
_ST = BM.STYLE
STYLE = [
    _ST[0],
    {"bh": 2.0, "lane": "s2_snow", "ls": (0.55, 0.7), "groove": ("s2_snow", 0.25), "berm": "s2_snow", "bs": (0.35, 0.95, 0.55)},
    _ST[1],
    {"bh": 2.6, "lane": "s4_floor", "ls": (0.5, 0.7), "groove": ("s4_floor", 0.15), "berm": "s4_ice", "bs": (0.3, 0.85, 0.5)},
    {"bh": 2.0, "lane": "s5_snow", "ls": (0.6, 0.75), "groove": ("s5_trav", 0.3), "berm": "s5_trav", "bs": (0.4, 0.95, 0.6)},
    _ST[2],
    {"bh": 1.8, "lane": "s7_snow", "ls": (0.55, 0.72), "groove": ("s7_rock", 0.2), "berm": "s7_rock", "bs": (0.2, 0.7, 0.4)},
    {"bh": 1.8, "lane": "s8_snow", "ls": (0.6, 0.78), "groove": ("s8_spire", 0.3), "berm": "s8_spire", "bs": (0.3, 0.8, 0.5)},
    {"bh": 1.4, "lane": "s9_snow", "ls": (0.6, 0.8), "groove": ("s9_rock", 0.3), "berm": "s9_rock", "bs": (0.25, 0.7, 0.45)},
    _ST[3],
]

# swap build_mountain's 4-zone tables for the 10 sections (its functions look these up at call time)
BM.PROFS, BM.zone_w, BM.height_w, BM.zone_pick, BM.surf_zone = PROFS, zone_w, height_w, zone_pick, surf_zone
BM.terrain_paint, BM.SKIRT_ROW, BM.STYLE = terrain_paint, SKIRT_ROW, STYLE

# ---------------------------------------------------------------- terrain chunks with per-section column lists
S_SPRING = sorted(set(S_LIST) | set(range(12, 300, 6)))  # terraces need ~6-stud columns out to s=300


def slist_of(k):
    return BM.S_FINE if k == 0 else (S_SPRING if k == 4 else S_LIST)


def _seam(row, slist):
    """Columns not in S_LIST sit on the straight edge between their S_LIST neighbours (no T-junction cracks)."""
    keep = [j for j, s in enumerate(slist) if s in S_LIST]
    for j, s in enumerate(slist):
        if s in S_LIST:
            continue
        a = max(i for i in keep if i < j)
        b = min(i for i in keep if i > j)
        f = (s - slist[a]) / (slist[b] - slist[a])
        row[j]["p"] = row[a]["p"].lerp(row[b]["p"], f)
        row[j]["hr"] = row[a]["hr"] + (row[b]["hr"] - row[a]["hr"]) * f


def terrain_chunk(name, d0, d1, side, coll, k, step=8.0, start=False, end=False, seam_start=False, seam_end=False):
    """build_mountain.terrain_chunk (same grid, paint and skirts) with a per-section column list and the
    seam rows handled at either end."""
    slist = slist_of(k)
    fine = k == 0
    mb = S.MB()
    n = max(1, int(round((d1 - d0) / step)))
    ds = [d0 + (d1 - d0) * i / n for i in range(n + 1)]
    grid = []
    for d in ds:
        E = hw(d) + EDGE
        row = []
        for s in slist:
            x = side * (E + s)
            row.append({"p": ground(x, d), "d": d, "x": x, "hr": BM.hrel(x, d) + 1.5})
        grid.append(row)
    if seam_start:
        _seam(grid[0], slist)
    if seam_end:
        _seam(grid[-1], slist)
    R, Cn = len(grid), len(slist)
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
            qn = (q[2]["p"] - q[0]["p"]).cross(q[3]["p"] - q[1]["p"])
            qny = abs(qn.normalized().y) if qn.length > 0 else 1.0
            for t in tris:
                pts = [c["p"] for c in t]
                fn = (pts[1] - pts[0]).cross(pts[2] - pts[0])
                if fn.y < 0:
                    t, pts, fn = t[::-1], pts[::-1], -fn
                if fn.length == 0:
                    continue
                fn.normalize()
                dc = sum(c["d"] for c in t) / 3
                xc = sum(c["x"] for c in t) / 3
                pc = sum(pts, Vector()) / 3
                summit = math.hypot(xc, pc.z - zc) < 150 and dc > TOP
                zk = zone_pick(dc, xc)
                far = abs(xc) - hw(dc) - EDGE >= 100
                nyd = fn.y if not far else qny
                if fine and far:
                    nb = [QN[a, b] for a in range(i - 1, i + 2) for b in range(j - 1, j + 2) if (a, b) in QN]
                    nyd = 0.5 * qny + 0.5 * sum(nb) / len(nb)
                soft = fine and far
                row, _ = terrain_paint(zk, nyd, 0, dc, xc, summit, soft)
                shades = []
                for c in t:
                    r2, sh = terrain_paint(zk, min(c["ny"], fn.y + 0.15), c["hr"], c["d"], c["x"], summit, soft)
                    shades.append(sh if r2 == row else terrain_paint(zk, nyd, c["hr"], c["d"], c["x"], summit, soft)[1])
                mb.face([tuple(p) for p in pts], row, shades)
    c0, c1 = V(side, 0, 1).normalized(), V(side, 0, -1).normalized()
    corners = {}
    if start:
        corners[0] = c0
        BM.skirt(mb, grid[0], V(0, 0, 1), BM.skirt_zone, {Cn - 1: c0})
    if end:
        corners[R - 1] = c1
        BM.skirt(mb, grid[-1], V(0, 0, -1), BM.skirt_zone, {Cn - 1: c1})
    BM.skirt(mb, [grid[i][-1] for i in range(R)], V(side, 0, 0), BM.skirt_zone, corners)
    BM.SURF["mbs"].append(mb)
    return S.build(name, mb, coll, extra={"kind": "terrain", "castShadow": True, "section": k + 1})


# ---------------------------------------------------------------- shared props
def pine_rows(mb, base, height, rad, seed, trunk="z1_rock", needles="z1_pine", snow="z1_snow"):
    """build_mountain.pine with its rows as parameters."""
    a0 = random.uniform(0, 6.28)
    tr = height * 0.13
    band_o(mb, ring(base, rad * 0.11, -2, 5, a0), ring(base, rad * 0.09, tr, 5, a0), trunk, 0.15, 0.3)
    tiers = 3 if height < 40 else 4
    for t in range(tiers):
        f = t / tiers
        y0 = tr + f * height * 0.78
        th = height * (0.42 - 0.06 * t)
        r = rad * (1 - 0.22 * t)
        lo = ring(base, r, y0, 7, a0 + t, jit=0.12, seed=seed + t)
        mid = ring(base, r * 0.55, y0 + th * 0.42, 7, a0 + t, jit=0.1, seed=seed + t + 0.5)
        band_o(mb, lo, mid, needles, 0.1, 0.55, alt=0.06)
        cap_o(mb, mid, base + V(0, y0 + th, 0), snow, 0.55, 0.97, alt=0.05)


SPAN = 1800.0  # batch extent limit per axis (part limit 2048; the bend warp moves points a little)


def _extent(mb):
    if not mb.v:
        return 0.0
    return max(max(p[i] for p in mb.v) - min(p[i] for p in mb.v) for i in range(3))


def batch_props(prefix, coll, items, extra, cap=9000):
    """build_mountain.batch_props, also flushing before a batch would grow past SPAN studs on any axis
    (sections here run up to 3,120 studs, longer than any old zone)."""
    b = Batcher(prefix, coll, extra, cap)
    for _, fn, args in sorted(items, key=lambda t: t[0]):
        st = random.getstate()
        tmp = S.MB()
        fn(tmp, *args)
        merged = S.MB()
        merged.v = list(b.mb.v) + list(tmp.v)
        if b.mb.tris() + tmp.tris() > cap or _extent(merged) > SPAN:
            b.flush()
        random.setstate(st)  # build it again with the same draws
        fn(b.mb, *args)
    b.flush()


def acc(k, lim=0.6):
    return lambda x, d, s: zone_w(d)[k] > lim


MARK_NEW = {"Steam": [], "Bolts": [], "CaveLights": [], "Gusts": []}


def mk(p, dy=0.0):
    return [round(p.x, 1), round(p.y + dy, 1), round(p.z, 1)]


# ---------------------------------------------------------------- signed-off biomes (build_mountain zone1-4 on a section's range)
def dress_taiga(k, coll):
    d0, d1 = -420, ENDS[k]
    items = []

    def dens(x, d, s):
        if zone_w(d)[k] < 0.6:
            return False
        p = 0.35 + 0.8 * fbm(x / 170, d / 170, 50)
        return random.random() < (p * 0.6 if s > 450 else p)

    for (x, d, s) in scatter(d0, d1 + 40, 9, 900, int(620 * (d1 - d0) / 1460), dens):
        g = ground(x, d)
        h = random.uniform(24, 46) * (1.25 if s > 200 else 1.0)
        items.append((d * 3 + (0 if x < 0 else 1e5), BM.pine, (g, h, h * 0.27, random.random() * 50)))
    batch_props("S01_Pines", coll, items, {"kind": "pines", "castShadow": True})
    rocks = []
    for (x, d, s) in scatter(-300, d1 - 20, 2, 400, 160, acc(k, 0.5)):
        sz = random.uniform(2.5, 7) * (2.2 if s > 60 else 1.0)
        rocks.append((d, boulder, (ground(x, d), V(sz * 1.3, sz * 0.8, sz), "z1_rock", "z1_snow", random.random() * 30)))
    batch_props("S01_Rocks", coll, rocks, {"kind": "rocks", "castShadow": True})
    mb, prev = S.MB(), None
    for i in range(0, int((d1 - 40 + 420) / 12) + 1):  # frozen river down the left snowfield
        d = -420 + i * 12
        x = -(hw(d) + EDGE + 260 + 90 * math.sin(d / 240) + 40 * n3(d / 120, 0, 55))
        w = 26 + 10 * n3(d / 90, 1, 56)
        a, b = ground(x - w / 2, d) + V(0, 0.6, 0), ground(x + w / 2, d) + V(0, 0.6, 0)
        if prev:
            mb.face([prev[0], prev[1], b, a], "z1_ice", [0.45, 0.7, 0.75, 0.5])
        prev = (a, b)
    fix_up(mb)
    S.build("S01_River", mb, coll, extra={"kind": "river", "castShadow": False})


def dress_crevasse(k, coll):
    d0, d1 = STARTS[k], ENDS[k]
    items = []
    for (x, d, s) in scatter(d0 + 40, d1 - 20, 1, 30, 300):
        h = random.uniform(5, 22)
        side = 1 if x > 0 else -1
        items.append((d, shard, (ground(x, d), h, h * 0.18, 5, -side * math.pi / 2 + random.uniform(-0.5, 0.5),
                                 random.uniform(0.05, 0.4), "z2_ice", 0.25, 0.98)))
    for (x, d, s) in scatter(d0 + 60, d1 - 40, 55, 300, 140):
        h = random.uniform(15, 45)
        items.append((d, shard, (ground(x, d), h, h * 0.2, 5, random.uniform(0, 6.28), random.uniform(0, 0.3), "z2_ice", 0.35, 0.98)))
    batch_props("S03_Shards", coll, items, {"kind": "ice", "castShadow": True})
    ledges = []
    for (x, d, s) in scatter(d0 + 20, d1, 0, 3, 80):
        sz = random.uniform(3, 7)
        ledges.append((d, boulder, (ground(x, d), V(sz * 1.4, sz * 0.7, sz * 1.1), "z2_ledge", "z2_snow", random.random() * 30, 0.6)))
    batch_props("S03_Ledges", coll, ledges, {"kind": "rocks", "castShadow": True})
    for bi, off in enumerate((230, 520, 820, 1060)):
        arch(coll, "S03_Bridge_%d" % (bi + 1), d0 + off, random.uniform(48, 70), "z2_bridge", "z2_snow", 26, 11)
        BM.MARK["Bridges"].append([0, round(centre(d0 + off)[0] + 60, 1), round(centre(d0 + off)[1], 1)])
    for d in range(int(d0 + 120), int(d1 - 60), 130):
        y0, z0 = centre(d)
        BM.MARK["Shafts"].append([round(random.uniform(-10, 10), 1), round(y0 + 190, 1), round(z0, 1)])


def arch(coll, name, db, rise, row, top_row, n_icicles, ice_len, width=16, thick=9, extra_span=40, segs=18, glow=None):
    """build_mountain's ice bridge across the canyon at db, parameterised (rows, icicle count/length)."""
    mb = S.MB()
    y0, z0 = centre(db)
    span = hw(db) + EDGE + extra_span
    rings_ = []
    for i in range(segs + 1):
        u = -1 + 2 * i / segs
        x = u * span
        yb = y0 + rise + 14 * (1 - u * u) + 3 * n3(u * 3, db / 97, 60)
        th = thick * (1 + 0.6 * u * u)
        rings_.append([V(x, yb - th, z0 + width / 2), V(x, yb + th * 0.4, z0 + width / 2 + 2), V(x, yb + th * 0.55, z0),
                       V(x, yb + th * 0.4, z0 - width / 2 - 2), V(x, yb - th, z0 - width / 2), V(x, yb - th * 1.15, z0)])
    for i in range(segs):
        A, Bv = rings_[i], rings_[i + 1]
        for kk in range(6):
            j = (kk + 1) % 6
            r = top_row if kk in (1, 2) else row
            shd = [0.85, 0.95] if r == top_row else [0.3, 0.7]
            q = [A[kk], A[j], Bv[j], Bv[kk]]
            nrm = (q[1] - q[0]).cross(q[2] - q[0])
            mid = sum(q, Vector()) / 4
            ax = (A[0] + A[3]) / 2 * 0.5 + (Bv[0] + Bv[3]) / 2 * 0.5
            if nrm.dot(mid - V(mid.x, ax.y, ax.z)) < 0:
                q = q[::-1]
            mb.face(q, r, [shd[0], shd[1], shd[1], shd[0]])
    for _ in range(n_icicles):
        u = random.uniform(-0.75, 0.75)
        x = u * span
        yb = y0 + rise + 14 * (1 - u * u) - thick * (1 + 0.6 * u * u)
        L = random.uniform(3, ice_len)
        top = V(x, yb + 1, z0 + random.uniform(-width / 2 + 2, width / 2 - 2))
        cap_o(mb, ring(top, random.uniform(0.6, 1.4) * (ice_len / 11) ** 0.5, 0, 5, random.random())[::-1], top + V(0, -L, 0), row, 0.6, 0.98)
    S.build(name, mb, coll, extra={"kind": "bridge", "castShadow": True})
    return y0, z0, span


def dress_obsidian(k, coll):
    d0, d1 = STARTS[k], ENDS[k]
    items = []
    for (x, d, s) in scatter(d0 + 30, d1 - 10, 6, 700, 360, acc(k)):
        h = min(random.uniform(18, 50) * (1 + s / 220), 190)
        side = 1 if x > 0 else -1
        items.append((d, shard, (ground(x, d), h, h * random.uniform(0.14, 0.24), 5, -side * math.pi / 2 + random.uniform(-0.6, 0.6),
                                 random.uniform(0.05, 0.45), "z3_obsidian", 0.08, 0.72, 0.5)))
    batch_props("S06_Spires", coll, items, {"kind": "obsidian", "castShadow": True})
    cols = []
    for (x, d, s) in scatter(d0 + 20, d1 - 10, 12, 260, 56, acc(k)):
        g = ground(x, d)
        cl = BM.basalt_mass(g, random.uniform(2.6, 4.2), random.uniform(5, 12) * (1 + s / 120), random.randint(9, 19),
                            random.Random(int(abs(x) * 1000) * 7919 + int(d * 10)))
        cols.append((d, lambda mb, cl=cl: BM.basalt_build(mb, cl), ()))
    batch_props("S06_Basalt", coll, cols, {"kind": "basalt", "castShadow": True})
    lav = []
    for (x, d, s) in scatter(d0 + 80, d1, 20, 500, 72, acc(k, 0.7)):
        lav.append((d, BM.lava_ribbon, (x, d, random.uniform(60, 260), random.uniform(1.2, 3.5), random.uniform(-0.15, 0.15))))
        BM.MARK["Lava"].append(mk(ground(x, d), 2))
    mb = S.MB()
    for side in (-1, 1):
        prev = None
        for i in range(0, int(LENS[k] / 4) + 1):
            d = d0 + i * 4
            h = hw(d)
            a = V(*SP.surf(d, side * (h + 3.2), STYLE[k]["bh"] + 0.06))
            b = V(*SP.surf(d, side * (h + 3.8), STYLE[k]["bh"] + 0.06))
            if prev:
                mb.face([prev[0], prev[1], b, a], "z3_lava", 0.8)
            prev = (a, b)
    fix_up(mb)
    b = Batcher("S06_Lava", coll, {"kind": "lava", "castShadow": False, "material": "Neon", "color": "z3.lava_orange"}, fixup=True)
    for _, fn, args in sorted(lav, key=lambda t: t[0]) + [(0, lambda m, src=mb: m.merge(src), ())]:
        tmp = S.MB()
        fn(tmp, *args)
        if b.mb.tris() + tmp.tris() > 9000:
            b.flush()
        fn(b.mb, *args)
    b.flush()
    vents = []
    for (x, d, s) in scatter(d0 + 40, d1 - 30, 10, 140, 26, acc(k, 0.7)):
        g = ground(x, d)

        def vent(mb, g=g):
            r = random.uniform(4, 7)
            band_o(mb, ring(g, r, -1.5, 8, 0), ring(g, r * 0.45, 2.6, 8, 0), "z3_ground", 0.2, 0.55)
            cap_o(mb, ring(g, r * 0.45, 2.6, 8, 0), g + V(0, 1.4, 0), "z3_obsidian", 0.05, 0.02)
        vents.append((d, vent, ()))
        BM.MARK["Vents"].append(mk(g, 2.6))
    batch_props("S06_Vents", coll, vents, {"kind": "vents", "castShadow": True})
    for (x, d, s) in scatter(d0 + 50, d1, 200, 600, 11):
        BM.MARK["Plumes"].append(mk(ground(x, d), 5))


def dress_aurora(k, coll):
    d0 = STARTS[k]
    items = []
    for (x, d, s) in scatter(d0 + 20, TOP, 1, 22, 150, acc(k)):
        g = ground(x, d)
        BM.LIP.append((g, 1 if x > 0 else -1))
        items.append((d, BM.crystal_cluster, (g, random.uniform(4, 13), random.randint(2, 5), -(1 if x > 0 else -1) * math.pi / 2)))
    for (x, d, s) in scatter(d0 + 40, TOP + 60, 40, 700, 140, acc(k)):
        g = ground(x, d)
        sc = min(random.uniform(25, 80) * (1 + s / 400), 220)
        on = zone_pick(d, x) == k
        if on:
            BM.CLUSTERS.append((g, sc))
        items.append((d, BM.crystal_cluster if on else BM.crystal_ghost, (g, sc, random.randint(3, 7), None, k)))
        if sc > 60 and on:
            BM.MARK["Crystals"].append(mk(g, sc * 0.4))
    batch_props("S10_Crystals", coll, items, {"kind": "crystal", "castShadow": False})
    rocks = []
    for (x, d, s) in scatter(d0 + 10, TOP, 0, 18, 100, acc(k, 0.5)):
        sz = random.uniform(2, 5)
        rocks.append((d, boulder, (ground(x, d), V(sz * 1.3, sz * 0.8, sz), "z4_rock", "z4_snow", random.random() * 30)))
    batch_props("S10_Rocks", coll, rocks, {"kind": "rocks", "castShadow": True})
    yc, zc = centre(SUMMIT_D)
    mb = S.MB()
    for kk in range(11):  # summit crown
        a = kk / 11 * 2 * math.pi + 0.2
        r = random.uniform(92, 112)
        x, z = math.cos(a) * r, zc + math.sin(a) * r
        if abs(x) < 30 and z > zc:
            continue
        sy = BM.surf_y(x, z)
        g = V(x, ground(x, SP.d_at_z(z)).y if sy is None else sy, z)
        h = random.uniform(70, 150)
        crystal(mb, g, h, h * 0.13, a - math.pi / 2, random.uniform(0.15, 0.35))
        crystal(mb, g + V(4, 0, 3), h * 0.55, h * 0.09, a - math.pi / 2 + 0.6, 0.5)
    crystal(mb, V(0, yc - 1.5, zc - 10), 130, 13, 0, 0)
    for kk in range(5):
        crystal(mb, V(0, yc - 1.5, zc - 10), random.uniform(40, 70), 6, kk * 1.26, 0.45)
    S.build("S10_Crown", mb, coll, extra={"kind": "crystal", "castShadow": True})
    BM.MARK["Summit"] = [0, round(yc, 1), round(zc, 1)]
    rng = random.Random(4004)  # glow accents (build_mountain.glow_accents, zone index -> k)
    saved = random.getstate()
    glow = []  # (sort key = -z, crystal args): batched, the section is longer than one part
    for g, sc in BM.CLUSTERS:
        for _ in range(rng.randint(1, 3)):
            h = sc * rng.uniform(0.25, 0.5)
            b = g + V(rng.uniform(-1, 1) * sc * 0.18, 0, rng.uniform(-1, 1) * sc * 0.18)
            a, lean = rng.uniform(0, 6.28), rng.uniform(0.2, 0.7)
            sy = BM.surf_y(b.x, b.z)
            if sy is not None and surf_zone(b.x, b.z) == k:
                glow.append((-b.z, crystal, (V(b.x, sy, b.z), h, h * 0.1, a, lean)))
    for g, side in BM.LIP:
        h = rng.uniform(3, 7)
        b = g + V(side * rng.uniform(0.5, 2), 0, rng.uniform(-2, 2))
        sy = BM.surf_y(b.x, b.z)
        glow.append((-b.z, crystal, (b if sy is None else V(b.x, sy, b.z), h, h * 0.13, -side * math.pi / 2, rng.uniform(0.2, 0.5))))
    for kk in range(9):
        a = kk / 9 * 2 * math.pi
        glow.append((-zc, crystal, (V(math.cos(a) * 20, yc - 1.5, zc - 10 + math.sin(a) * 20), rng.uniform(18, 34), 2.6, a - math.pi / 2, 0.5)))
    batch_props("S10_Glow", coll, glow, {"kind": "crystal", "castShadow": False, "material": "Neon", "color": "z4.crystal_glint"})
    random.setstate(saved)
    for (x, d, s) in scatter(TOP - 900, TOP, 30, 400, 12):  # peak wind gusts (M10 anchors)
        MARK_NEW["Gusts"].append(mk(ground(x, d), 6))


# ---------------------------------------------------------------- new biomes
def birch(mb, base, height, rad):
    """S2 birch: white trunk with dark bark marks (S2 x 920-990), a few bare rimed branches near the top."""
    a0 = random.uniform(0, 6.28)
    segs = 6
    prev = ring(base, rad, -2, 6, a0)
    for i in range(segs):
        y = height * (i + 1) / segs
        cur = ring(base + V(0.04 * y * math.cos(a0), 0, 0.04 * y * math.sin(a0)), rad * (1 - 0.55 * (i + 1) / segs), y, 6, a0)
        mark = random.random() < 0.35
        band_o(mb, prev, cur, "s2_birch", 0.04 if mark else 0.55, 0.12 if mark else 0.85, alt=0.05)
        prev = cur
    cap_o(mb, prev, base + V(0, height * 1.06, 0), "s2_birch", 0.6, 0.9)
    for _ in range(random.randint(5, 8)):  # bare rimed branches, reaching up and out (S2 x 2050-2200)
        y = height * random.uniform(0.45, 0.92)
        a = random.uniform(0, 6.28)
        L = height * random.uniform(0.14, 0.26)
        shard(mb, base + V(0, y, 0), L, rad * 0.32, 3, a, random.uniform(0.6, 1.0), "s2_birch", 0.6, 0.95, 0.5, 0.0)
        tip = base + V(0, y, 0) + V(-math.sin(a), 0, math.cos(a)) * L * 0.55 + V(0, L * 0.6, 0)  # tilt() leans toward (-sin a, 0, cos a)
        shard(mb, tip, L * 0.5, rad * 0.16, 3, a + random.uniform(-0.8, 0.8), random.uniform(0.3, 0.7), "s2_birch", 0.7, 0.98, 0.5, 0.0)


def fern(mb, base, size):
    """S2 rime-frosted fern clump: a fan of thin pale fronds (S2 x 1950-2250)."""
    for i in range(random.randint(5, 8)):
        shard(mb, base, size * random.uniform(0.6, 1.0), size * 0.09, 3, i * 1.1 + random.uniform(-0.3, 0.3),
              random.uniform(0.7, 1.15), "s2_fir", 0.55, 0.98, 0.4, 0.3)


def dress_rime(k, coll):
    d0, d1 = STARTS[k], ENDS[k]
    trees = []

    def dens(x, d, s):
        return zone_w(d)[k] > 0.6 and random.random() < 0.45 + 0.7 * fbm(x / 150, d / 150, 104)

    for (x, d, s) in scatter(d0 - 20, d1 + 20, 6, 700, 700, dens):
        g = ground(x, d)
        if random.random() < 0.45:
            h = random.uniform(45, 85)
            trees.append((d * 3 + (0 if x < 0 else 1e5), birch, (g, h, random.uniform(1.8, 2.8))))
        else:
            h = random.uniform(28, 55) * (1.2 if s > 200 else 1.0)
            trees.append((d * 3 + (0 if x < 0 else 1e5), pine_rows, (g, h, h * 0.27, random.random() * 50, "s2_rock", "s2_fir", "s2_snow")))
    batch_props("S02_Trees", coll, trees, {"kind": "pines", "castShadow": True})
    small = []
    for (x, d, s) in scatter(d0, d1, 1, 60, 260, acc(k)):
        small.append((d, fern, (ground(x, d), random.uniform(2.5, 5))))
    for (x, d, s) in scatter(d0, d1, 3, 260, 90, acc(k)):
        sz = random.uniform(3, 8) * (2.0 if s > 60 else 1.0)
        small.append((d, boulder, (ground(x, d), V(sz * 1.3, sz * 0.85, sz), "s2_rock", "s2_snow", random.random() * 30)))
    batch_props("S02_Floor", coll, small, {"kind": "rocks", "castShadow": True})


def dress_cave(k, coll):
    d0, d1 = STARTS[k], ENDS[k]
    # ice ceiling: arches close together in two tunnel runs, lone arches between (S4 stalactite ceiling)
    ds = list(range(int(d0 + 140), int(d0 + 470), 55)) + [int(d0 + 640)] + list(range(int(d0 + 800), int(d1 - 120), 60))
    for i, d in enumerate(ds):
        # underside over the lanes stays >= 56 studs up (flyers glide at <= 22 + bob, camera ~10 above the rider)
        y0, z0, span = arch(coll, "S04_Arch_%02d" % (i + 1), d, random.uniform(66, 80), "s4_ice", "s4_ice", 34, 9,
                            width=random.uniform(26, 40), thick=11, extra_span=55)
        BM.MARK["Shafts"].append([round(random.uniform(-8, 8), 1), round(y0 + 110, 1), round(z0 + 30, 1)])
    items = []
    for (x, d, s) in scatter(d0 + 20, d1 - 20, 1, 24, 320, acc(k)):  # ice spikes along the wall feet
        h = random.uniform(5, 20)
        side = 1 if x > 0 else -1
        items.append((d, shard, (ground(x, d), h, h * 0.2, 5, -side * math.pi / 2 + random.uniform(-0.5, 0.5),
                                 random.uniform(0.05, 0.35), "s4_ice", 0.3, 0.98)))
    for (x, d, s) in scatter(d0 + 20, d1 - 20, 2, 40, 70, acc(k)):  # rounded snow-ice boulders (S4 floor)
        sz = random.uniform(2.5, 6)
        items.append((d, boulder, (ground(x, d), V(sz * 1.3, sz * 0.8, sz), "s4_rock", "s4_floor", random.random() * 30)))
    batch_props("S04_Ice", coll, items, {"kind": "ice", "castShadow": True})
    glow, moss = [], []
    for (x, d, s) in scatter(d0 + 40, d1 - 40, 3, 30, 60, acc(k)):  # glowing crystal clusters (S4 x 2050-2140)
        g = ground(x, d)
        glow.append((d, glow_cluster, (g, random.uniform(5, 12), random.randint(3, 6), -(1 if x > 0 else -1) * math.pi / 2)))
        MARK_NEW["CaveLights"].append(mk(g, 6))
    for (x, d, s) in scatter(d0 + 20, d1 - 20, 2, 26, 50, acc(k)):  # glowing moss beds (S4 x 900-1100)
        moss.append((d, moss_bed, (x, d, random.uniform(4, 9))))
    batch_props("S04_Crystal", coll, glow, {"kind": "crystal", "castShadow": False, "material": "Neon", "color": "s4.ice_glow"})
    batch_props("S04_Moss", coll, moss, {"kind": "moss", "castShadow": False, "material": "Neon", "color": "s4.moss_glow"})


def glow_cluster(mb, g, scale, n, out_dir):
    for i in range(n):
        h = scale * random.uniform(0.45, 1.0) * (1.0 if i == 0 else 0.7)
        b = g + V(random.uniform(-1, 1) * scale * 0.12, 0, random.uniform(-1, 1) * scale * 0.12)
        sy = BM.surf_y(b.x, b.z)
        crystal(mb, b if sy is None else V(b.x, sy, b.z), h, h * random.uniform(0.11, 0.16), out_dir + random.uniform(-0.8, 0.8),
                0.0 if i == 0 else random.uniform(0.2, 0.6), "s4_glow")


def moss_bed(mb, x, d, r):
    """A low glowing patch hugging the floor (no taller than 0.6 studs)."""
    pts = []
    for i in range(9):
        a = i / 9 * 2 * math.pi
        rr = r * (1 + 0.35 * n3(x / 7 + math.cos(a), d / 7 + math.sin(a), 160))
        px, pd = x + math.cos(a) * rr, d + math.sin(a) * rr
        if abs(px) < hw(pd) + EDGE:
            px = math.copysign(hw(pd) + EDGE, x)
        pts.append(ground(px, pd) + V(0, 0.35, 0))
    c = ground(x, d) + V(0, 0.6, 0)
    for i in range(9):
        mb.face([pts[i], c, pts[(i + 1) % 9]], "s4_glow", [0.1, 0.3, 0.1])
    fix_up(mb)


def dress_springs(k, coll):
    d0, d1 = STARTS[k], ENDS[k]
    trees = []
    for (x, d, s) in scatter(d0, d1, 280, 900, 260, acc(k)):  # snowy pines behind the terraces (S5 x 1400-1700)
        g = ground(x, d)
        h = random.uniform(26, 48) * (1.2 if s > 450 else 1.0)
        trees.append((d * 3 + (0 if x < 0 else 1e5), pine_rows, (g, h, h * 0.27, random.random() * 50, "s5_pine", "s5_pine", "s5_snow")))
    batch_props("S05_Pines", coll, trees, {"kind": "pines", "castShadow": True})
    rocks = []
    for (x, d, s) in scatter(d0, d1, 1, 14, 90, acc(k)):  # snow-capped travertine lumps on the bank
        sz = random.uniform(2, 5)
        rocks.append((d, boulder, (ground(x, d), V(sz * 1.4, sz * 0.7, sz), "s5_trav", "s5_snow", random.random() * 30)))
    batch_props("S05_Rocks", coll, rocks, {"kind": "rocks", "castShadow": True})
    n = 0
    for (x, d, s) in scatter(d0 + 30, d1 - 30, 20, 380, 400, acc(k)):  # steam over pool treads (S5 plumes)
        g = ground(x, d)
        row = BM.surf_hit(g.x, g.z)[1]
        if row == "s5_pool":
            MARK_NEW["Steam"].append(mk(g, 1))
            n += 1
            if n >= 40:
                break


def dress_storm(k, coll):
    d0, d1 = STARTS[k], ENDS[k]
    items = []
    for (x, d, s) in scatter(d0 + 20, d1 - 10, 4, 500, 300, acc(k)):  # jagged crags
        h = min(random.uniform(12, 40) * (1 + s / 200), 160)
        side = 1 if x > 0 else -1
        items.append((d, shard, (ground(x, d), h, h * random.uniform(0.18, 0.3), 5, -side * math.pi / 2 + random.uniform(-0.7, 0.7),
                                 random.uniform(0.05, 0.35), "s7_rock", 0.05, 0.75, 0.5)))
    for (x, d, s) in scatter(d0, d1, 1, 120, 140, acc(k)):
        sz = random.uniform(2.5, 7) * (2 if s > 40 else 1)
        items.append((d, boulder, (ground(x, d), V(sz * 1.3, sz * 0.8, sz), "s7_rock", "s7_snow", random.random() * 30)))
    batch_props("S07_Crags", coll, items, {"kind": "rocks", "castShadow": True})
    best = []
    for (x, d, s) in scatter(d0, d1, 250, 900, 400, acc(k)):  # lightning targets: the highest far peaks
        best.append((BM.hrel(x, d), x, d))
    for h, x, d in sorted(best, reverse=True)[:14]:
        MARK_NEW["Bolts"].append(mk(ground(x, d)))
    for (x, d, s) in scatter(d0, d1, 20, 300, 10):
        MARK_NEW["Gusts"].append(mk(ground(x, d), 6))


def hoodoo(mb, base, height, rad):
    """S8 rust sandstone hoodoo: stacked bulging drums in banded strata, snow on every ledge and the cap."""
    a0 = random.uniform(0, 6.28)
    lean = V(random.uniform(-0.06, 0.06), 0, random.uniform(-0.06, 0.06))
    nseg = random.randint(4, 6)
    y, prev = -3.0, ring(base, rad * 1.15, -3, 7, a0, jit=0.12, seed=random.random() * 9)
    for i in range(nseg):
        y1 = height * (i + 1) / nseg
        r1 = rad * (1.0 - 0.35 * (i + 1) / nseg) * random.uniform(0.75, 1.15)
        c = base + lean * y1
        mid = ring(c, r1 * 1.12, (y + y1) / 2, 7, a0, jit=0.15, seed=random.random() * 9)
        top = ring(c, r1, y1, 7, a0, jit=0.1, seed=random.random() * 9)
        sh = 0.25 + 0.5 * (0.5 + 0.5 * math.sin(i * 1.9 + a0))  # each drum its own stratum
        band_o(mb, prev, mid, "s8_spire", sh - 0.15, sh + 0.1, alt=0.06)
        band_o(mb, mid, top, "s8_spire", sh, sh - 0.12, alt=0.06)
        if i < nseg - 1:
            ledge = ring(c, r1 * 0.85, y1 + 0.6, 7, a0)
            band_o(mb, top, ledge, "s8_snow", 0.75, 0.95)
            prev = ledge
        else:
            cap_o(mb, top, c + V(0, y1 + height * 0.04, 0), "s8_snow", 0.7, 0.98)
        y = y1


def dress_spires(k, coll):
    d0, d1 = STARTS[k], ENDS[k]
    items = []
    for (x, d, s) in scatter(d0 + 20, d1 - 20, 25, 650, 150, acc(k)):  # hoodoo clusters
        g = ground(x, d)
        for j in range(random.randint(1, 4)):
            off = V(random.uniform(-1, 1), 0, random.uniform(-1, 1)) * (0 if j == 0 else random.uniform(12, 28))
            p = g + off
            sy = BM.surf_y(p.x, p.z)
            h = random.uniform(30, 75) * (1 + s / 300) * (1.0 if j == 0 else 0.7)
            items.append((d, hoodoo, (p if sy is None else V(p.x, sy, p.z), min(h, 230), h * random.uniform(0.11, 0.17))))
    for (x, d, s) in scatter(d0, d1, 2, 60, 80, acc(k)):  # rounded rust boulders (S8 x 1690-2020)
        sz = random.uniform(2.5, 7)
        items.append((d, boulder, (ground(x, d), V(sz * 1.3, sz * 0.9, sz), "s8_spire", "s8_snow", random.random() * 30)))
    batch_props("S08_Hoodoos", coll, items, {"kind": "rocks", "castShadow": True})
    for i, off in enumerate((0.35, 0.72)):  # natural arches beside the road (S8 x 1400-1650)
        d = d0 + LENS[k] * off
        side = 1 if i == 0 else -1
        natural_arch(coll, "S08_Arch_%d" % (i + 1), d, side)
    for (x, d, s) in scatter(d0, d1, 20, 300, 10):
        MARK_NEW["Gusts"].append(mk(ground(x, d), 6))


def natural_arch(coll, name, d, side):
    """A sandstone arch standing parallel to the road at s 90-150: two legs and a bowed lintel."""
    mb = S.MB()
    s0 = random.uniform(90, 150)
    x = side * (hw(d) + EDGE + s0)
    span, rise, segs = random.uniform(70, 110), random.uniform(55, 80), 16
    axis = []
    for i in range(segs + 1):  # centreline in the plane x = const: legs sunk 6 into the ground, crown at rise
        u = -1 + 2 * i / segs
        g = ground(x, d + u * span / 2)
        axis.append((V(x, g.y - 6 + (rise + 6) * math.sqrt(max(0.0, 1 - u * u)), g.z), 8 + 10 * u * u))
    rings_ = []
    for i, (p, th) in enumerate(axis):  # 6-sided cross-section perpendicular to the centreline
        t = (axis[min(i + 1, segs)][0] - axis[max(i - 1, 0)][0]).normalized()
        n1 = V(1, 0, 0)
        n2 = t.cross(n1).normalized()
        rings_.append([p + (n1 * math.cos(a) + n2 * math.sin(a)) * th * (1.25 if math.cos(a) ** 2 < 0.25 else 1.0)
                       for a in (2 * math.pi * kk / 6 + 0.5 for kk in range(6))])
    for i in range(segs):
        A, Bv = rings_[i], rings_[i + 1]
        cen = (axis[i][0] + axis[i + 1][0]) / 2
        sh = 0.3 + 0.4 * (0.5 + 0.5 * math.sin(i * 0.9))  # banded strata along the span
        for kk in range(6):
            j = (kk + 1) % 6
            q = [A[kk], A[j], Bv[j], Bv[kk]]
            nrm = (q[1] - q[0]).cross(q[2] - q[0])
            if nrm.dot(sum(q, Vector()) / 4 - cen) < 0:
                q, nrm = q[::-1], -nrm
            up = nrm.normalized().y > 0.6
            mb.face(q, "s8_snow" if up else "s8_spire", [0.85] * 4 if up else [sh - 0.1, sh + 0.1, sh + 0.1, sh - 0.1])
    S.build(name, mb, coll, extra={"kind": "rocks", "castShadow": True})


def dress_cloud(k, coll):
    d0, d1 = STARTS[k], ENDS[k]
    items = []
    for (x, d, s) in scatter(d0, d1, 1, 40, 150, acc(k)):  # exposed brown rock on the ridge (S9 x 1600-2200)
        sz = random.uniform(2, 6)
        items.append((d, boulder, (ground(x, d), V(sz * 1.4, sz * 0.8, sz), "s9_rock", "s9_snow", random.random() * 30)))
    batch_props("S09_Rocks", coll, items, {"kind": "rocks", "castShadow": True})
    # cloud sea: puffy cloud tops 170 below the ridge, out past the backdrop peak bases (S9 y 100-330)
    for side, tag in ((-1, "L"), (1, "R")):
        dd = d0 - 120
        i = 0
        while dd < d1 + 150:
            e = min(dd + 500, d1 + 150)
            for (s0, s1, cs, part) in ((40, 1500, 28, "N"), (1500, 3000, 90, "F")):
                cloud_chunk(coll, "S09_Cloud_%s%s_%02d" % (tag, part, i), dd, e, side, s0, s1, cs, d0, d1)
            dd, i = e, i + 1


def cloud_chunk(coll, name, d0c, d1c, side, s0, s1, cs, d0, d1):
    mb = S.MB()
    nd = max(1, int(round((d1c - d0c) / cs)))
    ns = max(1, int(round((s1 - s0) / cs)))
    grid = []
    for i in range(nd + 1):
        d = d0c + (d1c - d0c) * i / nd
        y0, z0 = centre_x(d)
        sink = 300 * (1 - ss(d0 - 120, d0 + 150, d)) + 300 * ss(d1 - 250, d1 + 120, d)  # ends dive under the neighbours
        row = []
        for j in range(ns + 1):
            s = s0 + (s1 - s0) * j / ns
            x = side * (hw(min(max(d, 0), TOP)) + EDGE + s)
            # billows: broad rounded mounds (smoothstep of low-frequency noise) with small lumps on top
            puff = 42 * ss(-0.1, 0.45, fbm(x / 180, d / 180, 170)) + 12 * abs(n3(x / 40, d / 40, 171)) + 4 * n3(x / 14, d / 14, 172)
            row.append((V(x, y0 - 170 - sink + puff, z0), puff))
        grid.append(row)
    for i in range(nd):
        for j in range(ns):
            q = [grid[i][j], grid[i][j + 1], grid[i + 1][j + 1], grid[i + 1][j]]
            # S9: billow tops cloud_lit, troughs cloud_shadow
            mb.face([p for p, _ in q], "s9_cloud", [0.05 + 0.93 * min(max(h / 50, 0), 1) for _, h in q])
    fix_up(mb)
    S.build(name, mb, coll, extra={"kind": "cloud", "castShadow": False, "collide": False})


DRESS = [dress_taiga, dress_rime, dress_crevasse, dress_cave, dress_springs, dress_obsidian, dress_storm, dress_spires,
         dress_cloud, dress_aurora]
FAR = [("z1_far", "z1_snow"), ("s2_far", "s2_snow"), ("z2_ice", "z2_snow"), ("s4_far", "s4_ice"), ("s5_far", "s5_snow"),
       ("z3_far", "z3_obsidian"), ("s7_far", "s7_snow"), ("s8_far", "s8_snow"), ("s9_far", "s9_snow"), ("z4_far", "z4_snow")]
PEAK_TOP = [(600, 1300), (500, 1100), (700, 1300), (600, 1100), (600, 1200), (500, 1000), (800, 1500), (300, 700),
            (-100, 400), (-300, 250)]  # peak top above the path centreline at that d, per biome


def backdrop(coll):
    specs = []
    for side in (-1, 1):
        d = -600
        while d < TOP + 900:
            zk = SP.zone_of(min(max(d, 0), TOP - 1))
            y0, z0 = centre(min(d, TOP + 200))
            top_y = y0 + random.uniform(*PEAK_TOP[zk])
            base_y = min(y0 - 450, top_y - 400)
            specs.append((zk, V(side * random.uniform(1250, 2900), base_y, z0 + random.uniform(-150, 150)),
                          random.uniform(550, 780), min(1750, top_y - base_y)))
            d += random.uniform(380, 620)
    for _ in range(7):
        specs.append((0, V(random.uniform(-2600, 2600), -500, random.uniform(1300, 2700)), random.uniform(600, 780), random.uniform(1300, 1750)))
    yt, zt = centre(TOP)
    for _ in range(8):
        specs.append((NB - 1, V(random.uniform(-2800, 2800), yt - 1100, zt - random.uniform(1300, 2900)), random.uniform(600, 780),
                      random.uniform(900, 1500)))
    for i, (zk, base, R, Hm) in enumerate(sorted(specs, key=lambda s: (s[1].z, s[1].x))):
        one = S.MB()
        BM.mountain(one, base, R, Hm, FAR[zk][0], FAR[zk][1], random.random() * 50, 0.8 if zk == 5 else 0.5)
        S.build("BG_Peak_%02d" % (i + 1), one, coll, fidelity="Performance",
                extra={"kind": "backdrop", "castShadow": False, "zone": zk + 1}, rigid=True)


# ---------------------------------------------------------------- main
def _cuts(a, b, size):
    n = max(1, int(math.ceil((b - a) / size - 1e-6)))
    return [(a + (b - a) * i / n, a + (b - a) * (i + 1) / n) for i in range(n)]


def main():
    cols = [S.collection("SS_S%02d" % (k + 1)) for k in range(NB)]
    bg = S.collection("SS_Backdrop")
    SF = SP.C["SummitFlat"]
    grid = [float(v) for v in range(250, int(TOP), 250) if all(abs(v - B) >= 60 for B in STARTS[1:])]
    edges = sorted(set([-150.0, TOP + SF] + grid + STARTS[1:]))
    for i in range(len(edges) - 1):
        d0, d1 = edges[i], edges[i + 1]
        zk = SP.zone_of(max(d0, 0))
        BM.track_chunk("S%02d_Track_%03d" % (zk + 1, i + 1), d0, d1, zk, cols[zk])
    spans = []
    for k in range(NB):
        a = -420.0 if k == 0 else STARTS[k]
        b = TOP + 260 if k == NB - 1 else ENDS[k]
        spans += [(d0, d1, k) for d0, d1 in _cuts(a, b, 250 if k == 4 else 500)]
    for i, (d0, d1, k) in enumerate(spans):
        prev_k = spans[i - 1][2] if i else k
        next_k = spans[i + 1][2] if i + 1 < len(spans) else k
        for side, tag in ((-1, "L"), (1, "R")):
            terrain_chunk("S%02d_Terrain_%s_%d" % (k + 1, tag, int(d0)), d0, d1, side, cols[k], k,
                          start=i == 0, end=i == len(spans) - 1,
                          seam_start=slist_of(prev_k) != slist_of(k), seam_end=slist_of(next_k) != slist_of(k))
    BM.deck("S10_SummitDeck", TOP + SF - 1, 22, "z4_snow", [0.8, 0.85, 0.9, 0.82], cols[NB - 1], end=True)
    BM.deck("S01_StartDeck", BM.START_D, 28, "z1_snow", [0.62, 0.7, 0.78, 0.66], cols[0], start=True)
    BM.surf_freeze()
    for k in range(NB):
        DRESS[k](k, cols[k])
        print("dressed", k + 1, KEYS[k], flush=True)
    backdrop(bg)

    os.makedirs(OUTDIR, exist_ok=True)
    import bpy
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTDIR, "ss_sections.blend"))
    for k in range(NB):
        S.export_fbx(cols[k], os.path.join(OUTDIR, "ss_s%02d.fbx" % (k + 1)))
    S.export_fbx(bg, os.path.join(OUTDIR, "ss_backdrop.fbx"))
    S.write_manifest(os.path.join(OUTDIR, "ss_manifest.json"))
    BM.MARKERS_PATH = os.path.join(OUTDIR, "SS_Markers.luau")
    _write_markers()
    tot = sum(m["tris"] for m in S.MANIFEST.values())
    print("BUILD OK meshes=%d tris=%d" % (len(S.MANIFEST), tot))
    for k in range(NB):
        n = [m for nm, m in S.MANIFEST.items() if nm.startswith("S%02d_" % (k + 1))]
        print(" s%02d %-9s meshes=%3d tris=%7d" % (k + 1, KEYS[k], len(n), sum(m["tris"] for m in n)))
    n = [m for nm, m in S.MANIFEST.items() if nm.startswith("BG_")]
    print(" backdrop meshes=%d tris=%d" % (len(n), sum(m["tris"] for m in n)))


def _write_markers():
    """build_mountain.write_markers plus the new marker lists."""
    real = BM.write_markers
    keys_old = ("Vents", "Plumes", "Shafts", "Bridges", "Crystals", "Lava")
    real()
    src = open(BM.MARKERS_PATH).read().rstrip().rstrip("}")
    vec = lambda p: "Vector3.new(%s, %s, %s)" % tuple(round(v, 1) for v in S.WARP(*p))  # noqa: E731
    add = []
    for k in MARK_NEW:
        add.append("\t%s = {" % k)
        add += ["\t\t%s," % vec(p) for p in MARK_NEW[k]]
        add.append("\t},")
    assert all(k not in keys_old for k in MARK_NEW)
    open(BM.MARKERS_PATH, "w", newline="\n").write(src + "\n".join(add) + "\n}\n")


if _RUN:
    main()
