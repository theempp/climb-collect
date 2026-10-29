"""Audit v5 route-spline data against design/v5-trails-and-mountain-plan.md acceptance checks 1 and 4.

Usage: python tools/spline_audit.py routes.json
Input: {"walkSpeed": 12, "routes": {"<name>": {
    "segments": [{"type": "ledge", "length": 120, "width": 3, "open": false, "dir": 35}, ...],
    "hazards":  [{"at": 410, "tell": 2.5}, ...],
    "rests":    [{"at": 300, "len": 8}, ...]}}}
`dir` = heading in degrees; `at`/`len` are path distances in studs. Exit code 1 if any check fails.
"""
import json, sys

NARROW_MAX = 5.0      # studs; "tight" trail
NARROW_MIN_SHARE = 0.80
OPEN_MAX_SHARE = 0.15
MAX_SWITCHBACK_RUN = 60.0   # studs of straight run on an alternating-heading pattern
HAZARD_GAP_S = (60.0, 90.0)
MIN_TELL_S = 2.0


def audit(name, r, speed):
    segs, out = r["segments"], []
    total = sum(s["length"] for s in segs)
    narrow = sum(s["length"] for s in segs if s["width"] <= NARROW_MAX)
    opn = sum(s["length"] for s in segs if s.get("open"))
    out.append(("narrow share", narrow / total >= NARROW_MIN_SHARE, f"{narrow/total:.0%} (>= {NARROW_MIN_SHARE:.0%})"))
    out.append(("open share", opn / total <= OPEN_MAX_SHARE, f"{opn/total:.0%} (<= {OPEN_MAX_SHARE:.0%})"))

    # switchback: consecutive straight segments whose heading flips by >120 deg, run > limit
    bad = 0
    for a, b in zip(segs, segs[1:]):
        flip = abs((b.get("dir", 0) - a.get("dir", 0) + 180) % 360 - 180) > 120
        if flip and a["length"] > MAX_SWITCHBACK_RUN and b["length"] > MAX_SWITCHBACK_RUN:
            bad += 1
    out.append(("switchback runs", bad == 0, f"{bad} long straight reversals"))

    hz = sorted(r.get("hazards", []), key=lambda h: h["at"])
    rests = r.get("rests", [])
    gaps = [(b["at"] - a["at"]) / speed for a, b in zip(hz, hz[1:])]
    lo, hi = HAZARD_GAP_S
    out.append(("hazard spacing", all(lo <= g <= hi for g in gaps),
                f"{len(hz)} hazards, gaps {min(gaps):.0f}-{max(gaps):.0f}s" if gaps else f"{len(hz)} hazards"))
    out.append(("hazard tell", all(h["tell"] >= MIN_TELL_S for h in hz), f"min tell {min((h['tell'] for h in hz), default=0):.1f}s"))
    on_rest = [h for h in hz for q in rests if q["at"] <= h["at"] <= q["at"] + q.get("len", 0)]
    out.append(("none on rests", not on_rest, f"{len(on_rest)} on rest ledges"))
    return total, out


def main(path):
    d = json.load(open(path))
    speed = d.get("walkSpeed", 12)
    ok = True
    for name, r in d["routes"].items():
        total, res = audit(name, r, speed)
        print(f"{name}: {total:.0f} studs, walk {total/speed/60:.1f} min")
        for label, passed, info in res:
            ok &= passed
            print(f"  {'PASS' if passed else 'FAIL'}  {label}: {info}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main(sys.argv[1])
