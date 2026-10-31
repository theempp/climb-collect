"""Bend check-in renders (milestone 5): a top view of the whole mountain and ride-camera views through each
bend, on the bent build. Usage: blender -b <dir>/ss_mountain.blend --python art/tools/bend_preview.py -- OUTDIR [--straight]"""
import bpy, math, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sspath as SP  # noqa: E402
import ssblend as S  # noqa: E402
from mathutils import Vector  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:]
out = argv[0]
BENT = "--straight" not in argv
tag = "bent" if BENT else "straight"
os.makedirs(out, exist_ok=True)
sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "TEXTURE"
sc.display.shading.show_shadows = True
w = bpy.data.worlds.new("W")
w.color = (0.55, 0.65, 0.8)
sc.world = w
cd = bpy.data.cameras.new("Cam")
cd.clip_end = 40000
cam = bpy.data.objects.new("Cam", cd)
sc.collection.objects.link(cam)
sc.camera = cam


def pt(d, x=0.0, h=0.0):
    p = SP.surf(d, x, h)
    return Vector(S.rb2bl(SP.warp(*p) if BENT else p))


def look(p, t):
    cam.location = p
    cam.rotation_euler = (t - p).to_track_quat("-Z", "Y").to_euler()


# top view: orthographic, straight down, whole mountain (backdrop hidden)
bg = bpy.data.collections.get("SS_Backdrop")
if bg:
    bg.hide_render = True
cd.type = "ORTHO"
cd.ortho_scale = 4600
sc.render.resolution_x, sc.render.resolution_y = 900, 1800
mid = pt(SP.TOTAL / 2)
cam.location = (mid.x, mid.y, 6000)
cam.rotation_euler = (0, 0, math.radians(180))
sc.render.filepath = os.path.join(out, "top_%s.png" % tag)
bpy.ops.render.render(write_still=True)
if bg:
    bg.hide_render = False

# ride camera (SS_Ride rule: Back 24, Up 10, look 55 ahead) in the middle lane, through each bend
cd.type = "PERSP"
cd.lens = 18
sc.render.resolution_x, sc.render.resolution_y = 1280, 640
for d in (560, 760, 1860, 2060, 3160, 3360):
    look(pt(d - 24, 0, 10), pt(d + 55, 0, 4))
    sc.render.filepath = os.path.join(out, "ride_%s_%04d.png" % (tag, d))
    bpy.ops.render.render(write_still=True)
# high chase view over the S-bend in zone 2
look(pt(1550, 0, 220), pt(2250, 0, 0))
sc.render.filepath = os.path.join(out, "chase_%s_z2.png" % tag)
bpy.ops.render.render(write_still=True)
print("BEND PREVIEW OK", out)
