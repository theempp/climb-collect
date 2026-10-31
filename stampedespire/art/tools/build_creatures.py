"""Zone-1 creature build (M8 prep, Blender, background):
  python art/tools/sample_creatures.py
  blender -b --factory-startup --python art/tools/build_creatures.py [-- --only elk]
Builds each zone-1 species from the r2-zone1-taiga sheet as one skinned, flat-shaded low-poly mesh on a
quadruped armature with four Actions (gallop, idle, swap_jump, faceplant; D9), saves
art/creatures/<species>.blend, a palette PNG and a preview render, and prints a JSON stats line per species.

Proportions: side-view measurements on Z1, in avatar heights (the R15 figure beside each animal; the sheet
labels it 6.5 ft = 1.98 m, so 1 A = 1.98 m). Lateral widths come from the only frontal view in the r2 set
(RR front view, elk mount): chest width / torso depth = 0.82, head width / head depth = 0.88, leg-centre
spacing = 0.47 x chest width. Colours: art/creatures/creature_tokens.json (sample_creatures.py) only.
Axes: forward -Y, up +Z, origin on the ground under the torso centre."""
import bpy, json, math, os, sys
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "art", "creatures")
TOK = json.load(open(os.path.join(OUT, "creature_tokens.json")))
A = 1.98  # metres per avatar height (Z1 "R15 AVATAR (6.5 FT)")
W_D, HEADW, LEGSP = 0.82, 0.88, 0.47  # RR front view ratios (see docstring)
FPS = 30
BUDGET_TRIS, BUDGET_BONES = 3000, 24  # M7: prototype/PERF-BUDGET.md
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ONLY = ARGS[ARGS.index("--only") + 1] if "--only" in ARGS else None

# Side-view measurements on Z1 (avatar heights). f = forward of torso centre, z = height.
# L torso length, hw/hr withers/rump top, belly underline, hump = t of the withers peak (0 rump .. 1 chest).
SPECIES = {
    "taiga_elk": dict(
        tok="elk", L=1.71, hw=1.49, hr=1.14, belly=0.61, hump=0.72, shag=0.10,
        head=((1.14, 1.33, 0.41), (1.55, 1.18, 0.14)), front=0.65, hind=-0.57,
        leg_r=(0.12, 0.035, 0.04), tail=((-0.86, 0.92), (-0.96, 0.72), 0.06),
        ears=((1.10, 1.50), 0.13, 0.05), antler="elk", mane=0.6),
    "woolly_reindeer": dict(
        tok="reindeer", L=1.51, hw=1.35, hr=1.12, belly=0.61, hump=0.70, shag=0.08,
        head=((0.98, 1.35, 0.36), (1.35, 1.20, 0.13)), front=0.63, hind=-0.47,
        leg_r=(0.11, 0.03, 0.035), tail=((-0.75, 1.00), (-0.83, 0.86), 0.05),
        ears=((0.96, 1.50), 0.12, 0.045), antler="reindeer", harness=True),
    "musk_ox_calfrunner": dict(
        tok="muskox", L=1.96, hw=1.62, hr=1.18, belly=0.38, hump=0.62, shag=0.14,
        head=((0.98, 1.10, 0.52), (1.34, 0.78, 0.28)), front=0.78, hind=-0.54,
        leg_r=(0.15, 0.05, 0.055), tail=((-0.70, 0.98), (-0.98, 0.54), 0.05),
        ears=None, horns=True, skirt=0.28, frost=0.35, socks=True),
    "snowshoe_hare_hound": dict(
        tok="hare", L=1.49, hw=1.16, hr=1.08, belly=0.57, hump=0.78, shag=0.06,
        head=((0.92, 1.27, 0.38), (1.35, 1.18, 0.14)), front=0.63, hind=-0.47,
        leg_r=(0.09, 0.025, 0.03), hind_r=(0.16, 0.04, 0.035), hare_foot=0.15,
        tail=((-0.82, 0.84), (-0.90, 0.86), 0.10),
        ears=((1.04, 1.43), 0.45, 0.075), long_ears=True, saddle=True),
    "pine_boar": dict(
        tok="boar", L=1.80, hw=1.45, hr=1.04, belly=0.41, hump=0.72, shag=0.12,
        head=((0.90, 0.92, 0.55), (1.37, 0.65, 0.17)), front=0.66, hind=-0.55,
        leg_r=(0.13, 0.04, 0.04), tail=((-0.75, 0.73), (-0.98, 0.53), 0.025),
        ears=((1.00, 1.12), 0.20, 0.06), tusks=True, frost=0.30, bristle=True),
}


def hexrgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]


def hsh(*a):  # deterministic 0..1 hash
    x = math.sin(sum((i + 1) * 12.9898 * v for i, v in enumerate(a)) + 78.233) * 43758.5453
    return x - math.floor(x)


def smooth(e0, e1, x):
    t = min(max((x - e0) / (e1 - e0), 0.0), 1.0)
    return t * t * (3 - 2 * t)


class MB:
    """Mesh builder: verts, faces with a palette token each, per-vertex bone weights."""

    def __init__(s):
        s.v, s.f, s.fc, s.w = [], [], [], []

    def vert(s, p, w):  # keeps the 2 heaviest influences (2 bones per vertex)
        w = sorted(((k, x) for k, x in w.items() if x > 1e-4), key=lambda kv: -kv[1])[:2]
        s.v.append(Vector(p))
        s.w.append(dict(w))
        return len(s.v) - 1

    def loop(s, pts, w):
        return [s.vert(p, w) for p in pts]

    def face(s, idx, tok):
        s.f.append(list(idx))
        s.fc.append(tok)

    def face_out(s, idx, tok, ref):  # add a face wound so its normal points away from ref
        a, b, c = (s.v[i] for i in idx[:3])
        if (b - a).cross(c - a).dot(s.centre(idx) - ref) < 0:
            idx = idx[::-1]
        s.face(idx, tok)

    def ring(s, c, u, v, ru, rv, n, w, jag=0.0, seed=0.0, rot=0.0):
        out = []
        for i in range(n):
            a = 2 * math.pi * i / n + rot
            k = 1.0 + (jag * (hsh(seed, i) * 2 - 1) if jag else 0.0)
            out.append(s.vert(c + u * (math.cos(a) * ru * k) + v * (math.sin(a) * rv * k), w))
        return out

    def bridge(s, r0, r1, tokfn):
        n = len(r0)
        for i in range(n):
            j = (i + 1) % n
            q = [r0[i], r0[j], r1[j], r1[i]]
            s.face(q, tokfn(q))

    def cap(s, r, tip, w, tok, flip=False):  # fan to tip; outward when the ring winds ccw about (tip - ring); flip: cw
        t = s.vert(tip, w)
        n = len(r)
        for i in range(n):
            j = (i + 1) % n
            s.face([r[i], r[j], t] if not flip else [r[j], r[i], t], tok)

    def centre(s, q):
        return sum((s.v[i] for i in q), Vector()) / len(q)

    def tube(s, pts, radii, wfn, tokfn, n=6, cap_end=True, cap_start=False, flat=1.0, seed=0.0, jag=0.0, rot=0.0):
        """Loft rings along a polyline; ring plane is perpendicular to the local direction.
        A radius may be a (across, along) pair: across = the world-X side of the ring. cap_end="flat" puts the
        cap tip in the ring plane (hoof soles)."""
        rings = []
        for k, p in enumerate(pts):
            p = Vector(p)
            d = (Vector(pts[min(k + 1, len(pts) - 1)]) - Vector(pts[max(k - 1, 0)])).normalized()
            u = Vector((1, 0, 0)) if abs(d.x) < 0.9 else Vector((0, 0, 1))
            u = (u - d * u.dot(d)).normalized()
            v = d.cross(u)
            ru, rv = radii[k] if isinstance(radii[k], tuple) else (radii[k], radii[k] * flat)
            rings.append(s.ring(p, u, v, ru, rv, n, wfn(k, p), jag, seed + k, rot))
        for a, b in zip(rings, rings[1:]):
            s.bridge(a, b, tokfn)
        rmax = lambda r: max(r) if isinstance(r, tuple) else r
        if cap_end:
            d = (Vector(pts[-1]) - Vector(pts[-2])).normalized()
            tip = s.centre(rings[-1]) if cap_end == "flat" else Vector(pts[-1]) + d * rmax(radii[-1]) * 0.6
            s.cap(rings[-1], tip, wfn(len(pts) - 1, Vector(pts[-1])), tokfn(rings[-1]))
        if cap_start:
            d = (Vector(pts[0]) - Vector(pts[1])).normalized()
            s.cap(rings[0], Vector(pts[0]) + d * rmax(radii[0]) * 0.6, wfn(0, Vector(pts[0])), tokfn(rings[0]), flip=True)
        return rings


def spline(pts, rad, per=2):
    """Catmull-Rom through traced control points (same path, smoother bends). Returns points, radii, and the
    float control index of each sample (for weight lookup)."""
    C = [Vector(p) for p in pts]
    out, rr, ks = [], [], []
    for i in range(len(C) - 1):
        p0, p1, p2, p3 = C[max(i - 1, 0)], C[i], C[i + 1], C[min(i + 2, len(C) - 1)]
        for s_ in range(per):
            t = s_ / per
            out.append(0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                              + (3 * p1 - p0 - 3 * p2 + p3) * t ** 3))
            rr.append(rad[i] + (rad[i + 1] - rad[i]) * t)
            ks.append(i + t)
    return out + [C[-1]], rr + [rad[-1]], ks + [len(C) - 1.0]


def tuft(m, base, d, ln, wid, w, tok, nrm):
    """Coat lock: a closed 4-sided spike rooted inside the surface, tip along d, flattened
    along nrm (the surface normal) so it lies on the coat and reads as a lock of hair, not a thorn."""
    d = d.normalized()
    u = nrm - d * nrm.dot(d)
    u = u.normalized() if u.length > 1e-4 else Vector((1, 0, 0))
    r = m.ring(base, u, d.cross(u), wid * 0.35, wid, 4, w)
    m.cap(r, base + d * ln, w, tok)
    m.face(r[::-1], tok)  # closed base: single-sided in Roblox, an open base shows as a hole where it pokes out


def lerpw(a, b, t):
    t = min(max(t, 0.0), 1.0)
    w = {}
    for k, x in a.items():
        w[k] = w.get(k, 0) + x * (1 - t)
    for k, x in b.items():
        w[k] = w.get(k, 0) + x * t
    return w


def P(f, z, x=0.0):  # avatar-unit side-view point -> metres (forward = -Y)
    return Vector((x * A, -f * A, z * A))


def profile(S):
    """Torso top/bottom lines (avatar units) as functions of t (0 rump .. 1 chest)."""
    hw, hr, belly = S["hw"], S["hr"], S["belly"]

    def top(tt):
        return hr + (hw - hr) * smooth(0.12, S["hump"], tt) - (hw - hr) * 0.25 * smooth(S["hump"], 1.0, tt)

    def bot(tt):
        return belly + 0.35 * (top(tt) - belly) * abs(2 * tt - 1) ** 3
    return top, bot


def leg_joints(S):
    """Rest-pose joints per leg (hip/shoulder, elbow/stifle, knee/hock, fetlock, ground) in metres."""
    top, bot = profile(S)
    L = S["L"]
    chest_w = W_D * (top(0.9) - bot(0.9))
    legs = {}
    for end, f0 in (("f", S["front"]), ("h", S["hind"])):
        tt = (f0 + L / 2) / L
        ztop, b = bot(tt) + 0.35 * (top(tt) - bot(tt)), bot(tt)
        for side, sn in ((-1, "l"), (1, "r")):
            x = side * LEGSP * chest_w / 2
            if end == "f":
                j = [(f0, ztop), (f0 - 0.04, b * 0.62), (f0, b * 0.28), (f0 + 0.01, 0.06), (f0 + 0.02, 0.0)]
            elif S.get("hare_foot"):  # hare: long hind foot reaching forward from the hock
                j = [(f0, ztop), (f0 + 0.10, b * 0.60), (f0 - 0.14, b * 0.36), (f0 - 0.14 + S["hare_foot"], 0.04),
                     (f0 - 0.12 + S["hare_foot"] * 1.6, 0.02)]
            else:
                j = [(f0, ztop), (f0 + 0.08, b * 0.62), (f0 - 0.08, b * 0.30), (f0 - 0.06, 0.06), (f0 - 0.05, 0.0)]
            legs[end + sn] = (b, [P(a, z, x) for a, z in j])
    return legs


# Head shape stations along the measured base->nose axis: (u, top, bottom, upper width, lower width, lift), each a
# multiplier on the measured depth envelope (hd at the base -> nd at the nose). Read off the Z1 head silhouettes:
# deer = brow over the eye, jaw angle below it, long muzzle ending in a nose pad; ox = broad brow boss, deep jaw,
# blunt nose; boar = cheek, long wedge snout ending in a flat disc; hare = round skull, puffed cheeks, short muzzle.
HEADS = {
    "deer": [(0.0, .60, .55, .60, .60, 0), (0.10, 1.0, .95, .95, .90, 0), (0.26, 1.08, 1.12, 1.02, .95, 0),
             (0.42, .98, .95, .86, .88, 0), (0.60, .92, .85, .74, .76, -.04), (0.78, .95, .80, .72, .70, -.06),
             (0.92, 1.0, .80, .74, .66, -.08), (1.0, .78, .60, .58, .50, -.10)],
    "ox": [(0.0, .62, .60, .62, .62, 0), (0.12, 1.05, 1.0, 1.0, .95, 0), (0.30, 1.10, 1.08, 1.05, 1.0, 0),
           (0.50, 1.0, 1.0, .92, .95, 0), (0.70, .95, .98, .85, .90, 0), (0.88, .95, .95, .85, .85, 0),
           (1.0, .75, .70, .70, .65, 0)],
    "boar": [(0.0, .62, .60, .62, .62, 0), (0.12, 1.02, 1.0, .95, 1.0, 0), (0.30, 1.06, 1.05, .95, 1.05, 0),
             (0.50, .92, .95, .78, .86, 0), (0.72, .92, .95, .80, .82, 0), (0.90, 1.0, 1.0, .90, .90, 0),
             (0.97, 1.05, 1.05, .95, .95, 0), (1.0, 1.0, 1.0, .90, .90, 0)],
    "hare": [(0.0, .60, .55, .62, .62, 0), (0.12, 1.0, .95, .98, .98, 0), (0.34, 1.08, 1.05, 1.0, 1.12, 0),
             (0.56, 1.08, 1.0, .95, 1.05, 0), (0.74, 1.15, 1.05, 1.05, 1.05, 0), (0.88, 1.15, .95, 1.0, .90, 0),
             (0.97, .95, .78, .85, .72, 0)],
}
HEAD_STYLE = {"elk": "deer", "reindeer": "deer", "muskox": "ox", "boar": "boar", "hare": "hare"}


def hexa(m, pts, tok, w, bevel=False):
    """Closed six-sided block from 8 corners: a0..a3 (one end), b0..b3 (other end), same winding. Rigid: every
    corner carries the same weights (style study rule 2). bevel: marks the verts for the edge chamfer (rule 3)."""
    idx = [m.vert(p, w) for p in pts]
    if bevel:
        m.bev.update(idx)
    c = sum((Vector(p) for p in pts), Vector()) / 8
    a, b = idx[:4], idx[4:]
    for q in (a, b[::-1], [a[0], a[1], b[1], b[0]], [a[1], a[2], b[2], b[1]], [a[2], a[3], b[3], b[2]],
              [a[3], a[0], b[0], b[3]]):
        m.face_out(q, tok, c)


def frame(d, ref=None):
    """Side (u) and up (v) axes across direction d; u prefers world X so blocks stay square to the body."""
    d = d.normalized()
    u = Vector(ref) if ref is not None else (Vector((1, 0, 0)) if abs(d.x) < 0.9 else Vector((0, 0, 1)))
    u = (u - d * u.dot(d)).normalized()
    return u, d.cross(u)


def beam(m, p0, p1, r0, r1, tok, w, bevel=False, ref=None):
    """Block from p0 to p1; r = (half across, half up) at each end (a taper makes a wedge)."""
    p0, p1 = Vector(p0), Vector(p1)
    u, v = frame(p1 - p0, ref)
    rect = lambda p, r: [p + u * r[0] + v * r[1], p - u * r[0] + v * r[1], p - u * r[0] - v * r[1], p + u * r[0] - v * r[1]]
    hexa(m, rect(p0, r0) + rect(p1, r1), tok, w, bevel)


def chain(m, pts, rads, tok, w, bevel=False):
    """Stepped horn / antler / tusk: one square block per segment, each a touch fatter at its root so the
    steps read (block-built rule 5)."""
    for k in range(len(pts) - 1):
        r0, r1 = rads[k], max(rads[k + 1], rads[k] * 0.55)
        beam(m, pts[k], pts[k + 1] + (pts[k + 1] - pts[k]).normalized() * r1 * 0.5, (r0, r0), (r1, r1), tok, w, bevel)


def build(name, S):
    """Block-built creature (art/creatures/STYLE-STUDY.md): bevelled box/wedge parts, one token per part, each
    part rigid on one bone. Every block sits on the Z1-measured envelope (profile/leg_joints/head/tail/ears)."""
    t = S["tok"]
    pal = {}

    def T(k):
        key = t + "." + k
        assert key in TOK, key
        pal[key] = TOK[key]["hex"]
        return key

    L = S["L"]
    rump_f = -L / 2
    top, bot = profile(S)
    t_front, t_hind = (S["front"] + L / 2) / L, (S["hind"] + L / 2) / L
    m = MB()
    m.bev = set()

    def tbone(tt):  # rigid torso parts: hips / spine / chest by station
        return {"hips": 1} if tt < 0.36 else ({"spine": 1} if tt < 0.62 else {"chest": 1})

    def half_w(tt):  # lateral half-width (m): RR ratio on the measured depth, swelling over shoulder and haunch
        tc = min(max(tt, 0.0), 1.0)
        mass = 0.10 * math.exp(-((tt - t_front) / 0.11) ** 2) + 0.13 * math.exp(-((tt - t_hind) / 0.12) ** 2)
        return (top(tc) - bot(tc)) / 2 * A * W_D * (1 + mass)

    def coat_tok(h, tt=0.5):  # same 3-step height ramp as before; elk mane over the chest
        if S.get("mane") and tt >= S["mane"]:
            return T("mane_shadow") if h < 0.35 else T("mane")
        return T("coat_shadow") if h < 0.3 else (T("coat") if h < 0.72 else T("coat_light"))

    # ---- torso: segments rump -> chest, each three stacked blocks (belly / flank / back = the 3-step ramp);
    # the flank block is widest, so the ramp reads as stepped bands like the games' banded parts
    TT = [-0.04, 0.10, 0.26, 0.44, 0.62, 0.80, 0.94, 1.03]
    LAYERS = [(0.0, 0.30, 0.84), (0.30, 0.72, 1.0), (0.72, 1.0, 0.88)]  # (h0, h1, width factor)

    def rect_at(tt, h0, h1, wf, grow=0.0):
        tc = min(max(tt, 0.0), 1.0)
        e = min(tt + 0.06, 1.05 - tt)
        rnd = 0.78 + 0.22 * min(e / 0.12, 1.0)  # rump and brisket blocks step in
        z0, z1 = bot(tc), top(tc)
        mid, hh = (z0 + z1) / 2, (z1 - z0) / 2 * rnd
        za, zb = mid - hh + 2 * hh * h0 - grow / A, mid - hh + 2 * hh * h1 + grow / A
        x = half_w(tt) * wf * rnd + grow
        f = rump_f + tt * L
        return [P(f, zb, x / A), P(f, zb, -x / A), P(f, za, -x / A), P(f, za, x / A)]

    for a, b in zip(TT, TT[1:]):
        tm = (a + b) / 2
        for li, (h0, h1, wf) in enumerate(LAYERS):
            hexa(m, rect_at(a, h0, h1, wf) + rect_at(b, h0, h1, wf), coat_tok((h0 + h1) / 2, tm), tbone(tm), bevel=True)
            if S.get("skirt") and li == 0:  # musk ox: the long-hair skirt hangs below the belly as a lower block
                pass
        if S.get("bristle") and 0.3 < tm < 1.0:  # boar: raised spine ridge under the bristle crest
            hexa(m, rect_at(a, 0.92, 1.06, 0.45) + rect_at(b, 0.92, 1.06, 0.45), T("coat_shadow"), tbone(tm))
    # back ridge strip along the spine; it breaks over the spine bone head (t 0.4), where
    # export_creatures.py probes the back height for the rider seat
    RS = [0.08, 0.24, 0.40, 0.56, 0.74, 0.92]
    for a, b in zip(RS, RS[1:]):
        tm = (a + b) / 2
        hexa(m, rect_at(a, 0.96, 1.035, 0.2) + rect_at(b, 0.96, 1.035, 0.2), coat_tok(0.9, tm), tbone(tm))

    (hbf, hbz, hd), (nf, nz, nd) = S["head"]

    # ---- neck: two blocks from inside the chest to the back of the skull (neck_r as before)
    neck_r = 0.36 * (top(0.95) - bot(0.95))
    nb = P(L / 2 - 0.16, top(0.95) - neck_r - 0.02)
    hB, hN = P(hbf, hbz), P(nf, nz)
    nm = nb.lerp(hB, 0.5)
    ntok = T("mane") if S.get("mane") else T("coat")
    beam(m, nb, nm, (neck_r * A * W_D * 1.05, neck_r * A * 1.05), (neck_r * A * W_D * 0.92, neck_r * A * 0.92),
         ntok, {"neck": 1}, True, ref=(1, 0, 0))
    beam(m, nm - (hB - nb) * 0.06, hB, (neck_r * A * W_D * 0.92, neck_r * A * 0.92),
         (hd * 0.5 * A * HEADW * 0.8, hd * 0.5 * A * 0.85), ntok, {"neck": 1}, True, ref=(1, 0, 0))

    # ---- head: skull, muzzle, jaw, nose pad, brow; sizes from the HEADS stations (Z1 head silhouettes)
    hdir = (hN - hB).normalized()
    hLen = (hN - hB).length
    X = Vector((1, 0, 0))
    hup = hdir.cross(X)
    st = HEADS[HEAD_STYLE[t]]
    hw_ = {"head": 1}

    def hmul(u):
        for a, b in zip(st, st[1:]):
            if a[0] <= u <= b[0]:
                k = (u - a[0]) / (b[0] - a[0])
                return tuple(x + (y - x) * k for x, y in zip(a[1:], b[1:]))
        return st[-1][1:] if u > st[-1][0] else st[0][1:]

    def hD(u):
        return (hd + (nd - hd) * min(max(u, 0.0), 1.0) ** 0.8) * 0.5 * A

    def hbox(u0, u1, z0, z1, wmul, tok, bevel=True, lift=0.0):
        """Head block between stations u0..u1; z0/z1 = bottom/top as multiples of the local half-depth envelope."""
        pts = []
        for u in (u0, u1):
            tp, bt, wu, wl, lf = hmul(min(max(u, 0), 1))
            D = hD(u)
            c = hB + hdir * (u * hLen) + hup * ((lf + lift) * D)
            wdt = D * HEADW * (wu + wl) / 2 * wmul
            zt, zb = z1 * D * (tp if z1 > 0 else bt), z0 * D * (bt if z0 < 0 else tp)
            pts += [c + X * wdt + hup * zt, c - X * wdt + hup * zt, c - X * wdt + hup * zb, c + X * wdt + hup * zb]
        hexa(m, pts, tok, hw_, bevel)

    style = HEAD_STYLE[t]
    split = {"deer": 0.46, "ox": 0.55, "boar": 0.40, "hare": 0.58}[style]
    hbox(-0.04, split, -0.95, 1.0, 1.0, T("coat"))  # skull
    hbox(split - 0.04, 0.93, -0.30, 0.95, 0.88, T("coat"))  # muzzle (upper)
    hbox(0.18, 0.86, -0.95, -0.25, 0.80, T("coat_shadow"))  # jaw / cheek underside
    nose = {"elk": "muzzle", "boar": "snout"}.get(t, "coat_shadow")
    hbox(0.90, 1.02, -0.62, 0.90, 0.80 if t != "boar" else 0.95, T(nose))  # nose pad / boar snout disc
    hbox(0.20, split, 0.80, 1.12, 1.06, T("coat_light" if t != "elk" else "coat"), bevel=False)  # brow block
    # eyes: dark block on each side of the skull with a frost catchlight (owner 2026-10-29: Z1-sampled)
    ue = split * 0.72
    tp, bt, wu, wl, lf = hmul(ue)
    De = hD(ue)
    ec = hB + hdir * (ue * hLen) + hup * ((lf + 0.30) * De)
    es = 0.16 * hd * A
    for side in (-1, 1):
        sx = X * side * (De * HEADW * (wu + wl) / 2 + es * 0.25)
        p0 = ec + sx - X * side * es * 0.6
        beam(m, p0, p0 + X * side * es * 0.9, (es * 0.95, es * 0.8), (es * 0.95, es * 0.8), T("eye"), hw_, ref=hdir)
        g0 = ec + sx + X * side * es * 0.2 + hdir * es * 0.35 + hup * es * 0.3
        beam(m, g0, g0 + X * side * es * 0.25, (es * 0.3, es * 0.3), (es * 0.3, es * 0.3), T("eye_glint"), hw_, ref=hdir)

    # ---- ears: tapered wedges on the ear bones
    if S.get("ears"):
        (ef, ez), el, er = S["ears"]
        for side in (-1, 1):
            hx = hd * 0.5 * HEADW * 0.7 * side
            bn = {"ear_l" if side < 0 else "ear_r": 1}
            base = P(ef, ez, hx)
            if S.get("long_ears"):
                tip = P(ef - 0.15 + 0.17 * (side > 0), ez + el * 0.9, hx + 0.06 * side)
                mid = base.lerp(tip, 0.55)
                beam(m, base, mid, (er * A * 0.35, er * A * 0.9), (er * A * 0.4, er * A * 1.1), T("coat"), bn, True, ref=hdir)
                beam(m, mid, tip, (er * A * 0.4, er * A * 1.1), (er * A * 0.25, er * A * 0.45), T("ear_tip"), bn, True, ref=hdir)
            else:
                tip = P(ef - el * 0.4, ez + el * 0.6, hx + el * 0.7 * side)
                beam(m, base, tip, (er * A * 0.4, er * A * 0.9), (er * A * 0.2, er * A * 0.35), T("coat"), bn, True, ref=(0, 1, 0))

    # ---- tail
    (tf0, tz0), (tf1, tz1), trad = S["tail"]
    if t == "hare":  # puff: two crossed cubes
        c = P(tf0, tz0)
        r = trad * A
        beam(m, c + Vector((0, r * 0.9, 0)), c - Vector((0, r * 0.9, 0)), (r * 0.9, r * 0.9), (r * 0.9, r * 0.9),
             T("coat_light"), {"tail_1": 1}, True)
        beam(m, c + Vector((0, 0, r)), c - Vector((0, 0, r)), (r * 0.7, r * 1.05), (r * 0.7, r * 1.05), T("coat_light"),
             {"tail_1": 1})
    else:
        p0, p2 = P(tf0 + 0.06, tz0), P(tf1, tz1)
        p1 = P((tf0 + tf1) / 2, (tz0 + tz1) / 2 + 0.04)
        tt_ = T("coat_shadow") if t != "reindeer" else T("coat_light")
        beam(m, p0, p1, (trad * A * 1.3, trad * A * 1.4), (trad * A, trad * A), tt_, {"tail_1": 1}, True)
        beam(m, p1, p2, (trad * A, trad * A), (trad * A * 0.55, trad * A * 0.55), tt_, {"tail_2": 1}, True)

    # ---- legs: upper / lower / cannon blocks on the Z1 joints, a darker hoof block split in two toes
    for nm_, (b, J) in leg_joints(S).items():
        hind = nm_[0] == "h"
        r_up, r_lo, r_hf = S["hind_r"] if (hind and S.get("hind_r")) else S["leg_r"]
        up, lo, ft = nm_ + "_upper", nm_ + "_lower", nm_ + "_foot"

        def legtok(z):
            z /= A
            if z < b * 0.3:
                if S.get("socks"):
                    return T("sock")
                return T("leg") if t == "elk" else (T("coat_light") if t in ("hare", "reindeer") else T("coat_shadow"))
            if t == "elk" and z < b * 0.65:
                return T("leg")
            return T("coat_shadow") if t != "hare" else T("coat")

        top_ = J[0] + Vector((0, 0, 0.08 * A))
        beam(m, top_, J[1], (r_up * A * 1.05, r_up * A * 1.35), (r_up * A * 0.8, r_up * A * 0.95),
             legtok(top_.lerp(J[1], 0.5).z), {up: 1}, True)
        beam(m, J[1], J[2], (r_lo * A * 1.2, r_lo * A * 1.45), (r_lo * A * 0.95, r_lo * A * 1.05),
             legtok(J[1].lerp(J[2], 0.5).z), {lo: 1}, True)
        beam(m, J[2], J[3], (r_lo * A * 0.85, r_lo * A * 0.9), (r_hf * A * 0.9, r_hf * A * 0.95),
             legtok(J[2].lerp(J[3], 0.5).z), {ft: 1}, True)
        sole = J[3].copy()
        sole.z = 0.0
        if t == "hare":  # long snowshoe paw + three claw toes
            r_hf *= 1.7
            toe = J[4].copy()
            toe.z = 0.0
            heel = sole + (sole - toe).normalized() * r_hf * A * 0.6
            beam(m, heel + Vector((0, 0, r_hf * A * 0.55)), toe + Vector((0, 0, r_hf * A * 0.45)),
                 (r_hf * A * 1.1, r_hf * A * 0.55), (r_hf * A * 1.0, r_hf * A * 0.45), legtok(0.0), {ft: 1}, True,
                 ref=(1, 0, 0))
            for k in (-1, 0, 1):
                c = toe + Vector((k * r_hf * A * 0.6, 0, r_hf * A * 0.18))
                beam(m, c, c + Vector((0, -r_hf * A * 0.5, -0.0)), (r_hf * A * 0.22, r_hf * A * 0.18),
                     (r_hf * A * 0.14, r_hf * A * 0.1), T("claw"), {ft: 1}, ref=(1, 0, 0))
        else:  # cloven hoof: two toe blocks with a gap, flat sole on the ground
            hz = 0.075 * A
            for k in (-1, 1):
                c0 = sole + Vector((k * r_hf * A * 0.52, r_hf * A * 0.35, 0))
                c1 = sole + Vector((k * r_hf * A * 0.52, -r_hf * A * 1.15, 0))
                pts = []
                for c, hh in ((c0, hz), (c1, hz * 0.6)):
                    pts += [c + Vector((r_hf * A * 0.47, 0, hh)), c + Vector((-r_hf * A * 0.47, 0, hh)),
                            c + Vector((-r_hf * A * 0.5, 0, 0)), c + Vector((r_hf * A * 0.5, 0, 0))]
                hexa(m, pts, T("hoof"), {ft: 1}, True)

    # ---- species features
    def hang(p, ln, wid, tok, w, tilt=Vector((0, 0.25, 0))):  # one hanging coat lock block
        d = (Vector((0, 0, -1)) + tilt).normalized()
        beam(m, p, p + d * ln, (wid * 0.42, wid * 0.42), (wid * 0.26, wid * 0.26), tok, w, ref=(1, 0, 0))

    def under_torso(t0, t1, n, x_side, h, ln, wid, tokf):
        for i in range(n):
            tt = t0 + (t1 - t0) * (i + 0.5) / n
            z = bot(min(max(tt, 0), 1)) + (top(min(max(tt, 0), 1)) - bot(min(max(tt, 0), 1))) * h
            x = x_side * half_w(tt) * (0.84 if h < 0.3 else 1.0) * 0.9 / A
            k = 0.8 + 0.4 * hsh(i, x_side, h)
            hang(P(rump_f + tt * L, z + 0.03, x), ln * A * k, wid * A, tokf(i), tbone(tt))

    if S.get("mane"):  # elk ruff: rows of hanging locks under the neck and brisket (Z1 x 245-310)
        mt = lambda i: T("mane_shadow") if hsh(i, 7.7) < 0.35 else T("mane")
        for i in range(5):
            p = nb.lerp(hB, 0.1 + 0.18 * i) - Vector((0, 0, neck_r * A * 0.8))
            for sx in (-0.5, 0.5):
                hang(p + X * sx * neck_r * A * W_D, 0.17 * A * (0.8 + 0.4 * hsh(i, sx)), 0.13 * A, mt(i + sx), {"neck": 1})
        for xs in (-0.55, 0.0, 0.55):
            under_torso(S["mane"] + 0.02, 1.0, 3, xs, 0.02, 0.15, 0.14, mt)
    if t in ("reindeer", "hare"):  # pale throat ruff
        ln, wd = (0.15, 0.08) if t == "reindeer" else (0.10, 0.065)
        for i in range(4):
            p = nb.lerp(hB, 0.1 + 0.22 * i) - Vector((0, 0, neck_r * A * 0.8))
            for sx in (-0.45, 0.45):
                hang(p + X * sx * neck_r * A * W_D, ln * A * (0.8 + 0.4 * hsh(i, sx)), wd * A, T("coat_light"), {"neck": 1})
    if S.get("skirt"):  # musk ox: long-hair skirt hanging along both flanks to the measured hem, + beard
        for xs in (-1, 1):
            under_torso(0.06, 0.98, 9, xs, 0.12, S["skirt"] * 0.0 + 0.24, 0.13,
                        lambda i: T("coat_shadow") if i % 2 else T("coat"))
        under_torso(0.15, 0.9, 5, 0, 0.0, 0.16, 0.16, lambda i: T("coat_shadow"))
        for i in range(3):
            u = 0.35 + 0.15 * i
            c = hB + hdir * (u * hLen) - hup * (hD(u) * 0.9)
            hang(c, 0.18 * A, 0.10 * A, T("coat_shadow"), hw_, tilt=Vector((0, 0.3, 0)))
    if S.get("frost"):  # frosted back: flat frost tiles on the back blocks (Z1 frosted back / bristles)
        for i in range(22):
            tt = 0.10 + 0.86 * hsh(i, 2.2)
            if hsh(i, 5.5) > S["frost"] * 2.2:
                continue
            tc = min(max(tt, 0), 1)
            x = (hsh(i, 3.3) * 2 - 1) * half_w(tt) * 0.6 / A
            p = P(rump_f + tt * L, top(tc) * (1.0 if not S.get("bristle") else 1.0), x)
            sz = 0.08 * A * (0.8 + 0.5 * hsh(i, 4.4))
            beam(m, p - Vector((0, sz, -0.004 * A)), p + Vector((0, sz, 0.004 * A)), (sz * 0.8, 0.012 * A),
                 (sz * 0.8, 0.012 * A), T("frost"), tbone(tt), ref=(1, 0, 0))
    if S.get("bristle"):  # boar: crest of upright wedges along spine and neck, some frosted
        for i in range(10):
            tt = 0.22 + 0.80 * i / 9
            if 0.33 < tt < 0.5:  # rider seat (spine bone head, t 0.4) stays clear
                continue
            tc = min(tt, 1.0)
            p = P(rump_f + tt * L, top(tc) + 0.04, 0)
            hgt = 0.12 * A * (0.8 + 0.4 * hsh(i, 1.1))
            tok = T("frost") if hsh(i, 6.2) < S["frost"] else T("coat_shadow")
            beam(m, p - Vector((0, 0, 0.04 * A)), p + Vector((0, hgt * 0.6, hgt)), (0.035 * A, 0.06 * A),
                 (0.01 * A, 0.015 * A), tok, tbone(min(tt, 0.99)), ref=(1, 0, 0))
        for i in range(4):
            p = nb.lerp(hB, 0.15 + 0.22 * i) + Vector((0, 0, neck_r * A * 0.85))
            hgt = 0.11 * A
            beam(m, p, p + Vector((0, hgt * 0.7, hgt)), (0.03 * A, 0.05 * A), (0.01 * A, 0.012 * A),
                 T("frost") if hsh(i, 9.2) < S["frost"] else T("coat_shadow"), {"neck": 1}, ref=(1, 0, 0))

    hbP, nP = hB, hN
    if S.get("antler") == "elk":  # big frost-tipped rack as stepped blocks (Z1 x 430-710)
        for side in (-1, 1):
            base = hbP + Vector((side * hd * 0.25 * A, 0, hd * 0.45 * A))
            bm = [base, base + Vector((side * 0.18 * A, 0.10 * A, 0.15 * A)), base + Vector((side * 0.30 * A, 0.28 * A, 0.30 * A)),
                  base + Vector((side * 0.34 * A, 0.48 * A, 0.40 * A)), base + Vector((side * 0.30 * A, 0.62 * A, 0.48 * A))]
            chain(m, bm, [0.045 * A, 0.038 * A, 0.031 * A, 0.024 * A, 0.014 * A], T("antler"), hw_)
            for bi, dv in [(1, (0.05, -0.30, 0.12)), (2, (0.06, -0.24, 0.16)), (2, (0.10, -0.04, 0.18)),
                           (3, (0.06, -0.16, 0.14)), (3, (0.10, 0.05, 0.12))]:
                p0 = bm[bi]
                p1 = p0 + Vector((side * dv[0] * A, dv[1] * A, dv[2] * A))
                chain(m, [p0, p0.lerp(p1, 0.5) + Vector((0, 0, 0.03 * A)), p1], [0.024 * A, 0.018 * A, 0.01 * A], T("antler"), hw_)
    if S.get("antler") == "reindeer":
        for side in (-1, 1):
            base = hbP + Vector((side * hd * 0.25 * A, 0, hd * 0.45 * A))
            bm = [base, base + Vector((side * 0.08 * A, 0.06 * A, 0.20 * A)), base + Vector((side * 0.14 * A, 0.20 * A, 0.36 * A)),
                  base + Vector((side * 0.12 * A, 0.32 * A, 0.46 * A))]
            chain(m, bm, [0.034 * A, 0.028 * A, 0.021 * A, 0.011 * A], T("antler"), hw_)
            for bi, dv in ((1, (0.03, -0.18, 0.12)), (2, (0.04, -0.14, 0.14))):
                p0 = bm[bi]
                chain(m, [p0, p0 + Vector((side * dv[0] * A, dv[1] * A, dv[2] * A))], [0.018 * A, 0.01 * A], T("antler"), hw_)
    if S.get("horns"):  # musk ox: brow boss block + stepped horns curling down and forward (Z1 x 1150-1225)
        c = hbP + Vector((0, -0.05 * A, hd * 0.42 * A))
        beam(m, c - X * 0.2 * A, c + X * 0.2 * A, (0.09 * A, 0.06 * A), (0.09 * A, 0.06 * A), T("horn"), hw_, True, ref=(0, 1, 0))
        for side in (-1, 1):
            sx = side * A
            pts = [c + Vector((0.14 * sx, 0.02 * A, -0.02 * A)), c + Vector((0.24 * sx, 0.0, -0.18 * A)),
                   c + Vector((0.22 * sx, -0.10 * A, -0.30 * A)), c + Vector((0.20 * sx, -0.24 * A, -0.24 * A)),
                   c + Vector((0.22 * sx, -0.32 * A, -0.10 * A))]
            chain(m, pts, [0.075 * A, 0.06 * A, 0.046 * A, 0.032 * A, 0.014 * A], T("horn"), hw_)
    if S.get("tusks"):
        for side in (-1, 1):
            c = nP + Vector((side * nd * 0.45 * A, 0.10 * A, -nd * 0.2 * A))
            pts = [c, c + Vector((side * 0.04 * A, -0.06 * A, 0.04 * A)), c + Vector((side * 0.06 * A, -0.07 * A, 0.13 * A)),
                   c + Vector((side * 0.06 * A, -0.02 * A, 0.20 * A))]
            chain(m, pts, [0.032 * A, 0.026 * A, 0.018 * A, 0.008 * A], T("tusk"), hw_)

    # ---- tack: thin slab blocks hugging the torso blocks
    def band(tt, wid, tok, bells=0):
        g = 0.025 * A
        a, b = tt - wid / 2 / L, tt + wid / 2 / L
        hexa(m, rect_at(a, -0.02, 1.02, 1.0, g) + rect_at(b, -0.02, 1.02, 1.0, g), T(tok), tbone(tt))
        for i in range(bells):  # sled bells: small cubes along the lower front of the collar
            h = 0.12 + 0.6 * i / max(bells - 1, 1)
            for xs in (-1, 1):
                r = rect_at(b, h, h, 1.0, g)
                p = (r[0] if xs > 0 else r[1]) + Vector((xs * 0.02 * A, -0.01 * A, 0))
                beam(m, p - Vector((0, 0.02 * A, 0)), p + Vector((0, 0.02 * A, 0)), (0.022 * A, 0.022 * A),
                     (0.022 * A, 0.022 * A), T("bell"), tbone(tt), ref=(1, 0, 0))

    def pad(t0, t1, wf, thick, tok, lift=0.0):  # flat block on the back (saddle seat / back pad / cantle / pommel)
        r0, r1 = rect_at(t0, 1.0, 1.0, wf), rect_at(t1, 1.0, 1.0, wf)
        up0, up1 = Vector((0, 0, lift * A)), Vector((0, 0, (lift + thick) * A))
        pts = [r0[0] + up1, r0[1] + up1, r0[1] + up0 - Vector((0, 0, 0.03 * A)), r0[0] + up0 - Vector((0, 0, 0.03 * A)),
               r1[0] + up1, r1[1] + up1, r1[1] + up0 - Vector((0, 0, 0.03 * A)), r1[0] + up0 - Vector((0, 0, 0.03 * A))]
        hexa(m, pts, T(tok), tbone((t0 + t1) / 2), True)

    def flap(t0, t1, h0, h1, tok):  # side slab (saddle flaps, harness side panels)
        g = 0.03 * A
        for xs in (0, 1):
            r0, r1 = rect_at(t0, h0, h1, 1.0, g), rect_at(t1, h0, h1, 1.0, g)
            i0, i1 = (0, 3) if xs == 0 else (1, 2)
            o = Vector((0.025 * A * (1 if xs == 0 else -1), 0, 0))
            pts = [r0[i0] + o, r0[i0], r0[i1], r0[i1] + o, r1[i0] + o, r1[i0], r1[i1], r1[i1] + o]
            hexa(m, pts, T(tok), tbone((t0 + t1) / 2))

    def head_band(u, wid, tok):
        g = 0.02 * A
        pts = []
        for uu in (u - wid / 2, u + wid / 2):
            tp, bt, wu, wl, lf = hmul(uu)
            D = hD(uu)
            c = hB + hdir * (uu * hLen) + hup * (lf * D)
            wdt = D * HEADW * max(wu, wl) * 0.9 + g
            pts += [c + X * wdt + hup * (D * tp * 0.97 + g), c - X * wdt + hup * (D * tp * 0.97 + g),
                    c - X * wdt - hup * (D * bt + g), c + X * wdt - hup * (D * bt + g)]
        hexa(m, pts, T(tok), hw_)

    if S.get("harness"):  # reindeer: girth, breast collar with bells, back pad, side panels, halter
        band(0.52, 0.07, "leather")
        band(0.95, 0.08, "leather", bells=5)
        pad(0.55, 0.70, 0.75, 0.05, "leather")
        flap(0.62, 0.90, 0.40, 0.52, "leather")
        head_band(0.72, 0.06, "leather")
        head_band(0.20, 0.06, "leather")
    if S.get("saddle"):  # hare-hound: seat, raised cantle and pommel, flaps, girth and breast strap
        band(0.68, 0.07, "strap")
        band(0.96, 0.06, "strap")
        pad(0.58, 0.78, 0.80, 0.09, "saddle")
        pad(0.565, 0.625, 0.70, 0.10, "saddle", 0.05)
        pad(0.74, 0.795, 0.50, 0.09, "saddle", 0.05)
        flap(0.61, 0.75, 0.38, 0.80, "saddle")
    return m, pal


# ------------------------------------------------------------------ armature
def make_armature(S, legs):
    L, hw, hr, belly = S["L"], S["hw"], S["hr"], S["belly"]
    (hbf, hbz, hd), (nf, nz, nd) = S["head"]
    mid = (hw + hr) / 2 * 0.5 + belly * 0.5
    bones = {  # name: (head, tail, parent)
        "root": (P(0, 0), P(0, 0.25), None),
        "hips": (P(-L * 0.1, mid), P(-L / 2, mid), "root"),
        "spine": (P(-L * 0.1, mid), P(L * 0.15, mid + 0.04), "hips"),
        "chest": (P(L * 0.15, mid + 0.04), P(L / 2 - 0.1, mid + 0.1), "spine"),
        "neck": (P(L / 2 - 0.12, (hw + mid) / 2), P(hbf, hbz), "chest"),
        "head": (P(hbf, hbz), P(nf, nz), "neck"),
    }
    (tf0, tz0), (tf1, tz1), _ = S["tail"]
    bones["tail_1"] = (P(tf0, tz0), P((tf0 + tf1) / 2, (tz0 + tz1) / 2 + 0.04), "hips")
    bones["tail_2"] = (P((tf0 + tf1) / 2, (tz0 + tz1) / 2 + 0.04), P(tf1, tz1 - 0.001), "tail_1")
    for nm, j in legs.items():
        par = "chest" if nm[0] == "f" else "hips"
        bones[nm + "_upper"] = (j[0], j[1], par)
        bones[nm + "_lower"] = (j[1], j[2], nm + "_upper")
        bones[nm + "_foot"] = (j[2], j[4], nm + "_lower")
    if S.get("ears"):
        (ef, ez), el, er = S["ears"]
        for side, bn in ((-1, "ear_l"), (1, "ear_r")):
            hx = hd * 0.5 * HEADW * 0.7 * side
            b = P(ef, ez, hx)
            bones[bn] = (b, b + Vector((0, 0, el * 0.8 * A)), "head")
    arm = bpy.data.armatures.new("Rig")
    ob = bpy.data.objects.new("Rig", arm)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    for nm, (h, tl, par) in bones.items():
        eb = arm.edit_bones.new(nm)
        eb.head, eb.tail = h, tl
        d = (tl - h).normalized()
        eb.align_roll(Vector((1, 0, 0)).cross(d))  # local X = world X: +rot.x means "front/bottom swings down/back"
    for nm, (h, tl, par) in bones.items():
        if par:
            arm.edit_bones[nm].parent = arm.edit_bones[par]
    bpy.ops.object.mode_set(mode="OBJECT")
    for b in arm.bones:  # check the roll trick held for sagittal bones
        if not b.name.startswith("ear"):
            assert (b.matrix_local.to_3x3().col[0] - Vector((1, 0, 0))).length < 1e-3, b.name
    for pb in ob.pose.bones:
        pb.rotation_mode = "XYZ"
    return ob


# ------------------------------------------------------------------ animation
def clip(ob, name, frames, fn, loop):
    ob.animation_data_create()
    ob.animation_data.action = None
    for f in frames:
        for pb in ob.pose.bones:
            pb.rotation_euler = (0, 0, 0)
            pb.location = (0, 0, 0)
        fn(f, {pb.name: pb for pb in ob.pose.bones})
        for pb in ob.pose.bones:
            pb.keyframe_insert("rotation_euler", frame=f)
            if pb.name == "root":
                pb.keyframe_insert("location", frame=f)
    act = ob.animation_data.action
    act.name = name
    act.use_fake_user = True
    act.use_frame_range = True
    act.frame_start, act.frame_end = frames[0], frames[-1]
    act.use_cyclic = loop
    return act


def legs_of(pb):
    return [n[:2] for n in pb if n.endswith("_upper")]


def anim_gallop(f, pb, S, n=24):
    p = f / n
    phase = {"hl": 0.0, "hr": 0.08, "fl": 0.5, "fr": 0.58}  # transverse gallop footfall order
    w = 2 * math.pi
    for lg in legs_of(pb):
        q = (p + phase[lg]) % 1.0
        swing = -0.55 * math.cos(w * q)  # +: leg back (stance push), -: reaching forward
        flex = max(0.0, math.sin(w * (q - 0.5))) if q > 0.5 else 0.0  # recovery phase tucks the lower leg
        pb[lg + "_upper"].rotation_euler.x = swing
        if lg[0] == "f":
            pb[lg + "_lower"].rotation_euler.x = 1.3 * flex
            pb[lg + "_foot"].rotation_euler.x = 0.6 * flex
        else:
            pb[lg + "_lower"].rotation_euler.x = -0.9 * flex
            pb[lg + "_foot"].rotation_euler.x = 0.9 * flex
    pb["root"].location.y = 0.05 * A * max(0.0, math.sin(w * (p - 0.15)))  # one suspension per stride
    pb["root"].rotation_euler.x = 0.07 * math.sin(w * p)
    pb["spine"].rotation_euler.x = -0.06 * math.sin(w * p)
    pb["chest"].rotation_euler.x = -0.05 * math.sin(w * p)
    pb["neck"].rotation_euler.x = -0.12 * math.sin(w * p + 0.6)
    pb["head"].rotation_euler.x = 0.08 * math.sin(w * p + 0.6)
    pb["tail_1"].rotation_euler.x = -0.25 * math.sin(w * p - 0.8)
    pb["tail_2"].rotation_euler.x = -0.2 * math.sin(w * p - 1.4)
    for e in ("ear_l", "ear_r"):
        if e in pb:
            pb[e].rotation_euler.x = 0.35  # ears laid back at speed


def anim_idle(f, pb, S, n=60):
    p = f / n
    w = 2 * math.pi
    pb["chest"].rotation_euler.x = 0.015 * math.sin(w * p)
    pb["spine"].rotation_euler.x = -0.01 * math.sin(w * p)
    pb["neck"].rotation_euler.x = 0.05 * math.sin(w * p + 1.0)
    pb["head"].rotation_euler.z = 0.10 * math.sin(w * p)
    pb["tail_1"].rotation_euler.z = 0.25 * math.sin(w * 2 * p)
    pb["tail_2"].rotation_euler.z = 0.3 * math.sin(w * 2 * p - 0.7)
    flick = math.sin(math.pi * min(max((f - 30) / 6, 0), 1))
    for e, s in (("ear_l", 1), ("ear_r", 0.4)):
        if e in pb:
            pb[e].rotation_euler.x = 0.35 * flick * s


def key_blend(f, keys):
    """keys: [(frame, value)] -> smooth interpolated value."""
    for (f0, v0), (f1, v1) in zip(keys, keys[1:]):
        if f0 <= f <= f1:
            return v0 + (v1 - v0) * smooth(0, 1, (f - f0) / (f1 - f0))
    return keys[-1][1]


def anim_jump(f, pb, S):
    crouch = key_blend(f, [(0, 0), (4, 1), (7, 0), (14, 0), (16, 0.7), (20, 0)])
    air = key_blend(f, [(0, 0), (4, 0), (10, 1), (15, 0), (20, 0)])
    tuck = key_blend(f, [(0, 0), (5, 0), (9, 1), (13, 0.3), (20, 0)])
    pb["root"].location.y = (-0.08 * crouch + 0.40 * air) * A
    pb["root"].rotation_euler.x = key_blend(f, [(0, 0), (4, 0.08), (7, -0.18), (11, 0.0), (15, 0.12), (20, 0)])
    for lg in legs_of(pb):
        front = lg[0] == "f"
        pb[lg + "_upper"].rotation_euler.x = (-0.7 if front else 0.6) * tuck + (0.2 if front else -0.3) * crouch
        pb[lg + "_lower"].rotation_euler.x = (1.4 if front else -1.0) * tuck + (0.3 if front else -0.5) * crouch
        pb[lg + "_foot"].rotation_euler.x = (0.6 if front else 1.0) * tuck + 0.3 * crouch
    pb["neck"].rotation_euler.x = -0.15 * air
    pb["tail_1"].rotation_euler.x = -0.4 * air
    for e in ("ear_l", "ear_r"):
        if e in pb:
            pb[e].rotation_euler.x = 0.4 * air


def anim_faceplant(f, pb, S):
    pitch = key_blend(f, [(0, 0), (5, 0.25), (10, 0.62), (13, 0.55), (16, 0.6), (26, 0.6), (34, 0.05), (48, 0)])
    buckle = key_blend(f, [(0, 0), (6, 1), (26, 1), (34, 0.2), (48, 0)])
    pb["root"].rotation_euler.x = pitch
    pb["root"].location.y = key_blend(f, [(0, 0), (5, 0.04 * A), (10, -0.12 * A), (26, -0.12 * A), (34, 0), (48, 0)])
    for lg in legs_of(pb):
        if lg[0] == "f":  # forelegs fold back under the chest
            pb[lg + "_upper"].rotation_euler.x = 0.9 * buckle - pitch
            pb[lg + "_lower"].rotation_euler.x = 1.6 * buckle
            pb[lg + "_foot"].rotation_euler.x = 0.4 * buckle
        else:  # hind legs kick up and back as the rump rises
            pb[lg + "_upper"].rotation_euler.x = -pitch + 0.5 * buckle
            pb[lg + "_lower"].rotation_euler.x = -0.4 * buckle
    pb["neck"].rotation_euler.x = 0.45 * buckle
    pb["head"].rotation_euler.x = 0.3 * buckle
    shake = key_blend(f, [(0, 0), (34, 0), (36, 1), (44, 1), (48, 0)])
    pb["head"].rotation_euler.z = 0.35 * shake * math.sin((f - 34) * 1.6)
    pb["tail_1"].rotation_euler.x = -0.6 * buckle
    for e in ("ear_l", "ear_r"):
        if e in pb:
            pb[e].rotation_euler.x = 0.5 * buckle - 0.3 * shake * math.sin((f - 34) * 1.6)


CLIPS = [  # name, frames, loop
    ("gallop", list(range(0, 25, 2)), True),
    ("idle", list(range(0, 61, 4)), True),
    ("swap_jump", list(range(0, 21)), False),
    ("faceplant", list(range(0, 49, 2)), False),
]


# ------------------------------------------------------------------ assemble
def palette_image(name, pal):
    keys = list(pal.keys())
    sw = 8
    img = bpy.data.images.new(name + "_palette", len(keys) * sw, sw, alpha=False)
    # byte image in sRGB: pixel floats are stored as-is, so the PNG holds the token hex exactly
    img.pixels = [v for k in range(sw) for kk in keys for _ in range(sw) for v in hexrgb(pal[kk]) + [1.0]]
    path = os.path.join(OUT, name + "_palette.png")
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    img.pack()
    return img, {k: ((i + 0.5) / len(keys), 0.5) for i, k in enumerate(keys)}


def run(name, S):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.fps = FPS
    sc.unit_settings.system = "METRIC"
    m, pal = build(name, S)
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in m.v], [], m.f)
    me.validate()
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)
    for p in me.polygons:
        p.use_smooth = False
    img, uvs = palette_image(name, pal)
    uvl = me.uv_layers.new(name="UVMap")
    for p, tok in zip(me.polygons, m.fc):
        for li in p.loop_indices:
            uvl.data[li].uv = uvs[tok]
    mat = bpy.data.materials.new(name + "_mat")
    nt = mat.node_tree
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    bsdf = nt.nodes["Principled BSDF"]
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    me.materials.append(mat)
    legs = {nm: J for nm, (b, J) in leg_joints(S).items()}
    rig = make_armature(S, legs)
    for bn in rig.data.bones.keys():
        ob.vertex_groups.new(name=bn)
    for i, w in enumerate(m.w):
        tot = sum(w.values())
        for bn, x in w.items():
            if x > 0:
                ob.vertex_groups[bn].add([i], x / tot, "ADD")
    # edge chamfer on the main blocks (STYLE-STUDY rule 3), applied so the export sees plain geometry
    bg = ob.vertex_groups.new(name="bevel")
    bg.add(sorted(m.bev), 1.0, "REPLACE")
    bv = ob.modifiers.new("Bevel", "BEVEL")
    bv.offset_type, bv.width_pct, bv.segments = "PERCENT", 5, 1
    bv.limit_method, bv.vertex_group = "VGROUP", "bevel"
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier=bv.name)
    ob.vertex_groups.remove(ob.vertex_groups["bevel"])
    ob.parent = rig
    mod = ob.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    acts = {}
    for cname, frames, loop in CLIPS:
        fn = {"gallop": anim_gallop, "idle": anim_idle, "swap_jump": anim_jump, "faceplant": anim_faceplant}[cname]
        acts[cname] = clip(rig, cname, frames, lambda f, pb, fn=fn: fn(f, pb, S), loop)
    # NLA: one muted track per clip so all four are visible; idle stays active
    for cname, act in acts.items():
        tr = rig.animation_data.nla_tracks.new()
        tr.name = cname
        tr.strips.new(cname, int(act.frame_start), act)
        tr.mute = True
    rig.animation_data.action = acts["idle"]
    # stats
    me.calc_loop_triangles()
    tris = len(me.loop_triangles)
    nb = len(rig.data.bones)
    assert tris <= BUDGET_TRIS and nb <= BUDGET_BONES, (name, tris, nb)
    unweighted = sum(1 for v in me.vertices if not v.groups)
    assert unweighted == 0, unweighted
    assert all(len(v.groups) <= 2 for v in me.vertices), "more than 2 bone influences"
    dims = ob.dimensions
    stats = dict(species=name, tris=tris, bones=nb, verts=len(me.vertices), clips={k: [a.frame_start, a.frame_end, a.use_cyclic] for k, a in acts.items()},
                 size_m=[round(dims.x, 2), round(dims.y, 2), round(dims.z, 2)], palette=pal)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, name + ".blend"), compress=True)
    print("STATS " + json.dumps(stats))
    return stats


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for nm, sp in SPECIES.items():
        if ONLY and ONLY not in nm:
            continue
        run(nm, sp)
