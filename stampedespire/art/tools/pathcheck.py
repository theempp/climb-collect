"""Rewrite only the PathCheck block of prototype/src/SS_Markers.luau from the current SS_Config path (P1 pace test:
the path changes without a Blender rebuild). Same points as build_mountain.py: every 100 studs, the outer lane
edges and the centre, as {d, x, bent world point of surf(d, x, 0)}. Effect markers are left untouched (they belong
to the old 4-zone mountain and are skipped while ShowGreybox is on)."""
import os, re
import sspath as SP

MARKERS = os.path.join(SP.ROOT, "prototype", "src", "SS_Markers.luau")


def hw(d):
    return SP.C["LaneCount"] * SP.lane_width(min(max(d, 0), SP.TOTAL)) / 2


def main():
    lines = ["\tPathCheck = {"]
    for d in range(-100, int(SP.TOTAL) + 101, 100):
        for x in (-hw(d), 0.0, hw(d)):
            w = SP.wsurf(d, x, 0)
            lines.append("\t\t{ %d, %.4f, Vector3.new(%.4f, %.4f, %.4f) }," % ((d, x) + tuple(w)))
    lines.append("\t},")
    src = open(MARKERS, encoding="utf-8").read()
    new, n = re.subn(r"\tPathCheck = \{\n.*?\n\t\},\n", lambda m: "\n".join(lines) + "\n", src, flags=re.S)
    assert n == 1, "PathCheck block not found"
    open(MARKERS, "w", newline="\n").write(new)
    print("PathCheck", len(lines) - 2, "points, total", SP.TOTAL, "min radius %.0f" % SP.min_radius())


if __name__ == "__main__":
    main()
