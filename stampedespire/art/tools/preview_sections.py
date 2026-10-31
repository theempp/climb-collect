"""Look-dev renders of the 10-section build (Workbench, atlas colours, backface culling on so flipped faces
show as holes). Ride-camera shots on the bent path, plus a side view per section.
Usage: blender -b art/export/sections/ss_sections.blend --python art/tools/preview_sections.py -- OUTDIR [d ...]"""
import bpy, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sspath as SP  # noqa: E402
import ssblend as S  # noqa: E402
from mathutils import Vector  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
out = argv[0]
os.makedirs(out, exist_ok=True)
starts = SP.starts
shots = [float(a) for a in argv[1:]] or [starts[k] + SP.Z[k]["Length"] * f for k in range(len(starts)) for f in (0.3, 0.75)]

sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "TEXTURE"
sc.display.shading.show_backface_culling = True
sc.display.shading.show_shadows = True
sc.render.resolution_x, sc.render.resolution_y = 1280, 640
world = bpy.data.worlds.new("W")
world.color = (0.55, 0.65, 0.8)
sc.world = world
cd = bpy.data.cameras.new("Cam")
cd.clip_end = 40000
cd.lens = 22
cam = bpy.data.objects.new("Cam", cd)
sc.collection.objects.link(cam)
sc.camera = cam


def aim(p, t):
    pb, tb = Vector(S.rb2bl(p)), Vector(S.rb2bl(t))
    cam.location = pb
    cam.rotation_euler = (tb - pb).to_track_quat("-Z", "Y").to_euler()


def shot(name):
    sc.render.filepath = os.path.join(out, name)
    bpy.ops.render.render(write_still=True)


for d in shots:
    k = SP.zone_of(max(d, 0))
    aim(SP.wsurf(d - 24, 0, 10), SP.wsurf(d + 60, 0, 4))  # SS_Config Cam Back 24 / Up 10
    shot("ride_s%02d_%05d.png" % (k + 1, d))
for k in range(len(starts)):  # high side view: above the tallest walls/peaks, looking down across the middle
    d = starts[k] + SP.Z[k]["Length"] / 2
    aim(SP.wsurf(d - 350, 700, 650), SP.wsurf(d, 0, 0))
    shot("side_s%02d.png" % (k + 1))
print("PREVIEW OK", out)
