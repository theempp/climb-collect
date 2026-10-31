"""Terrain review renders: fixed high/side cameras that expose zone-border steps and terrain edges.
Usage: blender -b <dir>/ss_mountain.blend --python art/tools/review_views.py -- OUTDIR
Writes OUTDIR/view_*.png (Workbench, atlas colours, light haze so silhouettes read)."""
import bpy, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sspath as SP  # noqa: E402
import ssblend as S  # noqa: E402
from mathutils import Vector  # noqa: E402

out = sys.argv[sys.argv.index("--") + 1]
os.makedirs(out, exist_ok=True)
sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "TEXTURE"
sc.display.shading.show_backface_culling = False
sc.render.resolution_x, sc.render.resolution_y = 1280, 640
w = bpy.data.worlds.new("W")
w.color = (0.55, 0.65, 0.8)
sc.world = w
cd = bpy.data.cameras.new("Cam")
cd.clip_end = 40000
cd.lens = 24
cam = bpy.data.objects.new("Cam", cd)
sc.collection.objects.link(cam)
sc.camera = cam
bg = bpy.data.collections.get("SS_Backdrop")
if bg:  # backdrop peaks would block the outside cameras; these views judge the terrain only
    bg.hide_render = True


def shot(name, eye, look):
    p, t = Vector(S.rb2bl(eye)), Vector(S.rb2bl(look))
    cam.location = p
    cam.rotation_euler = (t - p).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(out, "view_%s.png" % name)
    bpy.ops.render.render(write_still=True)


def at(d, x=0.0, h=0.0):
    y, z = SP.centre(d)
    return (x, y + h, z)


B2, B3, TOP = SP.starts[2], SP.starts[3], SP.TOTAL
# 1. summit high, looking down the ridge (the shot that showed the zone 3/4 block)
shot("summit_down", at(TOP + 60, 200, 180), at(B3 - 300, 0, -150))
# 2. side views across the zone 3->4 and 2->3 borders
shot("side_b34", at(B3, 1600, 250), at(B3, 0, -50))
shot("side_b23", at(B2, -1600, 250), at(B2, 0, 0))
# 3. outer terrain edge from outside, low and high
shot("edge_out_z3", at(B3 - 400, 1700, 150), at(B3 - 400, 700, -200))
shot("edge_out_z4", at(B3 + 500, -1700, 150), at(B3 + 500, -700, -300))
# 4. start edge seen from the spawn looking back downhill, and a mid-zone-1 vista
shot("start_back", at(40, 0, 25), at(-900, 0, -100))
shot("ends_low", at(-900, 900, -250), at(400, 300, 0))
shot("vista_z1", at(300, 700, 220), at(1600, 0, 200))
print("VIEWS OK", out)
