"""Python twin of prototype/src/SS_Path.luau, used by the Blender build.
Reads the zone table and path tunables straight from SS_Config.luau (single source of truth).
Coordinates are Roblox world space (Y up, climb along -Z)."""
import math, os, re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CFG = os.path.join(ROOT, "prototype", "src", "SS_Config.luau")


def _num(src, key):
    return float(re.search(r"\b%s\s*=\s*([-\d.]+)" % key, src).group(1))


def load_config():
    src = open(CFG, encoding="utf-8").read()
    zones = []
    for m in re.finditer(r'\{\s*Name\s*=\s*"([^"]+)",\s*Length\s*=\s*([\d.]+),\s*SlopeDeg\s*=\s*([\d.]+),\s*LaneWidth\s*=\s*([\d.]+)', src):
        zones.append({"Name": m.group(1), "Length": float(m.group(2)), "SlopeDeg": float(m.group(3)), "LaneWidth": float(m.group(4))})
    return {
        "Zones": zones,
        "NarrowRamp": _num(src, "NarrowRamp"),
        "LaneCount": int(_num(src, "LaneCount")),
        "SlopeBlend": _num(src, "SlopeBlend"),
        "SummitFlat": _num(src, "SummitFlat"),
        "Bends": [{"At": float(a), "Len": float(l), "Deg": float(g)} for a, l, g in re.findall(
            r"\{\s*At\s*=\s*([-\d.]+),\s*Len\s*=\s*([-\d.]+),\s*Deg\s*=\s*([-\d.]+)\s*\}", src)],
    }


C = load_config()
Z = C["Zones"]
starts, acc = [], 0.0
for z in Z:
    starts.append(acc)
    acc += z["Length"]
TOTAL = acc
MIN, MAX = -300, int(acc) + 300


def smooth(a):
    a = min(max(a, 0.0), 1.0)
    return a * a * (3 - 2 * a)


def slope(d):
    deg = Z[0]["SlopeDeg"]
    for i in range(1, len(Z)):
        deg += (Z[i]["SlopeDeg"] - Z[i - 1]["SlopeDeg"]) * smooth((d - starts[i] + C["SlopeBlend"] / 2) / C["SlopeBlend"])
    deg -= Z[-1]["SlopeDeg"] * smooth((d - acc) / C["SummitFlat"])
    return math.radians(deg)


ys, zs = {0: 0.0}, {0: 0.0}
for i in range(0, MAX):
    a = slope(i + 0.5)
    ys[i + 1], zs[i + 1] = ys[i] + math.sin(a), zs[i] - math.cos(a)
for i in range(0, MIN, -1):
    a = slope(i - 0.5)
    ys[i - 1], zs[i - 1] = ys[i] - math.sin(a), zs[i] + math.cos(a)


def zone_of(d):
    k = 0
    for i in range(1, len(Z)):
        if d >= starts[i]:
            k = i
    return k


def zone_end(k):
    return starts[k] + Z[k]["Length"]


def lane_width(d):
    k = zone_of(d)
    w = Z[k]["LaneWidth"]
    if k + 1 < len(Z):
        a = (d - (zone_end(k) - C["NarrowRamp"])) / C["NarrowRamp"]
        if a > 0:
            w += (Z[k + 1]["LaneWidth"] - w) * min(a, 1)
    return w


def centre(d):
    """(y, z) of the centreline at d."""
    d = min(max(d, MIN), MAX - 1)
    i = math.floor(d)
    f = d - i
    return ys[i] + (ys[i + 1] - ys[i]) * f, zs[i] + (zs[i + 1] - zs[i]) * f


def surf(d, x=0.0, h=0.0):
    """World point (x, y, z) at distance d, sideways x, height h along the surface normal."""
    y, z = centre(d)
    a = slope(min(max(d, MIN), MAX - 1))
    # local up = (0, cos a, sin a); forward = (0, sin a, -cos a)
    return (x, y + h * math.cos(a), z + h * math.sin(a))


def d_at_z(zw):
    """Distance d whose centreline sits at world z (plan position)."""
    lo, hi = MIN, MAX - 1
    while hi - lo > 1:
        m = (lo + hi) // 2
        if zs[m] > zw:
            lo = m
        else:
            hi = m
    f = (zs[lo] - zw) / (zs[lo] - zs[hi])
    return lo + f


def ground_y(zw):
    """Centreline height at world z."""
    return centre(d_at_z(zw))[0]


# ---------------------------------------------------------------- plan-view bends (milestone 5)
# The mountain is built straight (centreline along -Z) and then warped: a straight point's z picks the
# distance d along the path (d_at_z), its x becomes a sideways offset from the bent centreline at that d,
# and its height is kept. SS_Path.luau does the same (warp / unwarp); keep the two in step.
BENDS = C["Bends"]


def heading(d):
    """Plan heading (radians) at d; 0 = straight up the mountain (-Z), positive turns toward +X."""
    return math.radians(sum(b["Deg"] * smooth((d - b["At"] + b["Len"] / 2) / b["Len"]) for b in BENDS))


px, pz = {0: 0.0}, {0: 0.0}
for i in range(0, MAX):
    h, a = zs[i] - zs[i + 1], heading(i + 0.5)
    px[i + 1], pz[i + 1] = px[i] + h * math.sin(a), pz[i] - h * math.cos(a)
for i in range(0, MIN, -1):
    h, a = zs[i - 1] - zs[i], heading(i - 0.5)
    px[i - 1], pz[i - 1] = px[i] - h * math.sin(a), pz[i] + h * math.cos(a)


def plan(d):
    """(x, z, heading) of the bent centreline at d (table range)."""
    i = math.floor(d)
    f = d - i
    return px[i] + (px[i + 1] - px[i]) * f, pz[i] + (pz[i + 1] - pz[i]) * f, heading(d)


def warp(x, y, z):
    """Straight-built Roblox point -> bent world point. Past either end of the table the path is extended
    along its end heading."""
    if z > zs[MIN]:
        e, fwd = MIN, zs[MIN] - z
    elif z < zs[MAX - 1]:
        e, fwd = MAX - 1, zs[MAX - 1] - z
    else:
        e, fwd = d_at_z(z), 0.0
    cx, cz, a = plan(e)
    s, c = math.sin(a), math.cos(a)
    return cx + fwd * s + x * c, y, cz - fwd * c + x * s


def wsurf(d, x=0.0, h=0.0):
    """surf() on the bent path."""
    return warp(*surf(d, x, h))


def min_radius():
    best = 1e9
    for b in BENDS:
        if b["Deg"]:
            best = min(best, b["Len"] / (1.5 * math.radians(abs(b["Deg"]))))
    return best


if __name__ == "__main__":
    print("zones", [z["Name"] for z in Z], "total", TOTAL)
    for d in (0, 960, 1000, 1040, 2000, 3000, 4000, 4040, 4100):
        print(d, "slope %.2f" % math.degrees(slope(d)), "y %.2f z %.2f" % centre(d), "lane %.2f" % lane_width(d))
    print("bends", BENDS, "min radius %.0f" % min_radius())
    for d in range(0, int(TOTAL) + 201, 250):
        x, z, a = plan(d)
        print("plan", d, "x %.1f z %.1f heading %.1f" % (x, z, math.degrees(a)))
