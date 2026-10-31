"""Quick look-dev renders of ss_mountain.blend (Workbench, atlas colours, backface culling on so
flipped faces show as holes). Usage: blender -b art/blender/ss_mountain.blend --python art/tools/preview_mountain.py -- OUTDIR [d ...]"""
import bpy, math, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sspath as SP  # noqa: E402
import ssblend as S  # noqa: E402
from mathutils import Vector  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
out = argv[0] if argv else os.path.join(S.ROOT, "art", "export", "preview")
os.makedirs(out, exist_ok=True)
shots = [float(a) for a in argv[1:]] or [60, 900, 1400, 2300, 2700, 3400, 3950]

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
cam_data = bpy.data.cameras.new("Cam")
cam_data.clip_end = 30000
cam_data.lens = 22
cam = bpy.data.objects.new("Cam", cam_data)
sc.collection.objects.link(cam)
sc.camera = cam


def place(d, back=18, up=9, look=60, side=0.0):
    p = SP.surf(d - back, side, up)
    t = SP.surf(d + look, 0, 2)
    pb, tb = Vector(S.rb2bl(p)), Vector(S.rb2bl(t))
    cam.location = pb
    cam.rotation_euler = (tb - pb).to_track_quat("-Z", "Y").to_euler()


for d in shots:
    place(d)
    sc.render.filepath = os.path.join(out, "ride_%04d.png" % d)
    bpy.ops.render.render(write_still=True)
# wide vista: from the side of zone 1 looking up the whole mountain
p = Vector(S.rb2bl((900, 500, 900)))
t = Vector(S.rb2bl((0, 500, -2400)))
cam.location = p
cam.rotation_euler = (t - p).to_track_quat("-Z", "Y").to_euler()
sc.render.filepath = os.path.join(out, "vista.png")
bpy.ops.render.render(write_still=True)
# summit looking back down
y, z = SP.centre(SP.TOTAL + 60)
p = Vector(S.rb2bl((60, y + 45, z + 40)))
t = Vector(S.rb2bl((0, y - 250, z + 900)))
cam.location = p
cam.rotation_euler = (t - p).to_track_quat("-Z", "Y").to_euler()
sc.render.filepath = os.path.join(out, "summit_back.png")
bpy.ops.render.render(write_still=True)
print("PREVIEW OK", out)
