"""Ride/summit camera clearance against the built mountain (the Studio meshes use box collision, so
in-game raycasts can't see the real surface; this checks the same camera rule on the Blender meshes).
Usage: blender -b art/blender/ss_mountain.blend --python art/tools/cam_clearance.py [-- --straight]
Ride camera (SS_Ride rideCamera): surf(d - Back - lag, laneX * LaneFollow, Up), looking at the rider.
Checks: the camera is at least NEAR studs from any mesh, and the rider's head is visible from it.
Summit orbit: clearance only (it looks at the crown)."""
import bpy, math, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sspath as SP  # noqa: E402
import ssblend as S  # noqa: E402
from mathutils import Vector  # noqa: E402
from mathutils.bvhtree import BVHTree  # noqa: E402

src = open(SP.CFG, encoding="utf-8").read()
cam = re.search(r"Cam = \{(.*?)\n\t\}", src, re.S).group(1)


def cnum(k):
    return float(re.search(r"\b%s\s*=\s*([-\d.]+)" % k, cam).group(1))


BACK, UP, FOLLOW = cnum("Back"), cnum("Up"), cnum("LaneFollow")
SR, SH = cnum("SummitRadius"), cnum("SummitHeight")
NEAR = 2.0
LAGS = (0, 6, 12)  # extra studs the lerped camera trails at speed (v / Lag, up to ~78/7)

verts, polys, owner = [], [], []
dg = bpy.context.evaluated_depsgraph_get()
for ob in bpy.data.objects:
    if ob.type != "MESH" or ob.name.startswith("BG_"):
        continue
    me = ob.evaluated_get(dg).to_mesh()
    base = len(verts)
    verts += [ob.matrix_world @ v.co for v in me.vertices]
    for p in me.polygons:
        polys.append([base + i for i in p.vertices])
        owner.append(ob.name)
    ob.evaluated_get(dg).to_mesh_clear()
bvh = BVHTree.FromPolygons(verts, polys)
print("meshes", len(set(owner)), "polys", len(polys))


BENT = "--straight" not in sys.argv  # the build warps the mountain along the plan-view bends


def bl(p):
    return Vector(S.rb2bl(SP.warp(*p) if BENT else p))


def lane_x(lane, d):
    return (lane - (SP.C["LaneCount"] + 1) / 2) * SP.lane_width(d)


ride_n, near_fail, block_fail, min_clear, worst = 0, [], [], 1e9, None
# --fly H: also check a rider on a flyer gliding H studs up (SS_Config Fly max 22 + FlyBob 1.5)
LIFTS = (0.0,) + ((float(sys.argv[sys.argv.index("--fly") + 1]),) if "--fly" in sys.argv else ())
for d in range(0, int(SP.TOTAL) + 1, 4):
    for lane in range(1, SP.C["LaneCount"] + 1):
        x = lane_x(lane, d)
        for lift, lag in ((lf, lg) for lf in LIFTS for lg in LAGS):
            head = bl(SP.surf(d, x, 9.5 + lift))
            c = bl(SP.surf(d - BACK - lag, x * FOLLOW, UP + lift))
            ride_n += 1
            loc, nrm, idx, dist = bvh.find_nearest(c)
            if dist is not None and dist < min_clear:
                min_clear, worst = dist, (d, lane, lag, owner[idx])
            if dist is not None and dist < NEAR:
                near_fail.append((d, lane, lag, round(dist, 2), owner[idx]))
            v = head - c
            hit = bvh.ray_cast(c, v.normalized(), v.length - 0.5)
            if hit[0] is not None:
                block_fail.append((d, lane, lag, owner[hit[2]]))

centre = SP.surf(SP.TOTAL + 75, 0, 0)
orbit_min, orbit_fail = 1e9, []
for i in range(360):
    a = math.radians(i)
    p = bl((centre[0] + math.cos(a) * SR, centre[1] + SH, centre[2] + math.sin(a) * SR))
    loc, nrm, idx, dist = bvh.find_nearest(p)
    orbit_min = min(orbit_min, dist)
    if dist < NEAR:
        orbit_fail.append((i, round(dist, 2), owner[idx]))

print("RIDE samples=%d near<%.0f=%d blocked=%d min_clear=%.2f at %s" % (ride_n, NEAR, len(near_fail), len(block_fail), min_clear, worst))
for f in (near_fail + block_fail)[:20]:
    print("  FAIL", f)
print("SUMMIT samples=360 near=%d min_clear=%.1f" % (len(orbit_fail), orbit_min))
