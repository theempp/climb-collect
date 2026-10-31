"""Preview renders of the zone-1 creatures (read-only on the .blends; nothing is saved):
  blender -b --factory-startup --python art/tools/render_creatures.py
  python art/tools/render_creatures.py      (system Python + PIL: assembles the 2x2 grids)
For each art/creatures/<species>.blend: one 3/4 view plus a pose strip (idle, gallop, swap_jump apex,
faceplant impact) -> art/creatures/renders/<species>.png. Backdrop, ground and sun use Z1 LOOKDEV tokens
(sky_horizon, snow_mid, sun_glow) so the preview reads in its zone's light."""
import glob, math, os
try:
    import bpy
    from mathutils import Vector
except ImportError:
    bpy = None

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CR = os.path.join(ROOT, "art", "creatures")
RD = os.path.join(CR, "renders")
Z1 = {"sky_horizon": "#A5B8D5", "snow_mid": "#DEE3EE", "sun_glow": "#FAF9F6"}  # art/LOOKDEV.md zone 1
POSES = [("idle", 0, "idle"), ("gallop", 6, "gallop"), ("swap_jump", 10, "swap_jump"), ("faceplant", 12, "faceplant")]


def lin(h):
    c = [int(h.lstrip("#")[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]


def shoot(path, sc, cam, ob, yaw, elev=12.0):
    bb = [ob.matrix_world @ Vector(c) for c in ob.bound_box]
    lo = Vector([min(v[i] for v in bb) for i in range(3)])
    hi = Vector([max(v[i] for v in bb) for i in range(3)])
    ctr, rad = (lo + hi) / 2, (hi - lo).length / 2
    d = Vector((math.sin(math.radians(yaw)) * math.cos(math.radians(elev)),
                -math.cos(math.radians(yaw)) * math.cos(math.radians(elev)), math.sin(math.radians(elev))))
    cam.location = ctr + d * rad * 3.2
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main():
    os.makedirs(RD, exist_ok=True)
    for bf in sorted(glob.glob(os.path.join(CR, "*.blend"))):
        name = os.path.splitext(os.path.basename(bf))[0]
        bpy.ops.wm.open_mainfile(filepath=bf)
        sc = bpy.context.scene
        sc.render.engine = "BLENDER_EEVEE"
        sc.render.resolution_x, sc.render.resolution_y = 900, 700
        sc.view_settings.view_transform = "Standard"
        w = bpy.data.worlds.new("w")
        w.color = lin(Z1["sky_horizon"])
        w.use_nodes = True
        w.node_tree.nodes["Background"].inputs[0].default_value = lin(Z1["sky_horizon"]) + [1]
        w.node_tree.nodes["Background"].inputs[1].default_value = 0.3
        sc.world = w
        sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
        sun.data.color = lin(Z1["sun_glow"])
        sun.data.energy = 3.5
        sun.rotation_euler = Vector((-0.55, 0.35, -0.75)).to_track_quat("-Z", "Y").to_euler()  # key light on the camera side
        sc.collection.objects.link(sun)
        bpy.ops.mesh.primitive_plane_add(size=60)
        gm = bpy.data.materials.new("snow")
        gm.diffuse_color = lin(Z1["snow_mid"]) + [1]
        gm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = lin(Z1["snow_mid"]) + [1]
        bpy.context.object.data.materials.append(gm)
        cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
        cam.data.lens = 50
        sc.collection.objects.link(cam)
        sc.camera = cam
        rig = bpy.data.objects["Rig"]
        mesh = bpy.data.objects[name]
        for tr in rig.animation_data.nla_tracks:
            tr.mute = True
        for i, (act, fr, lab) in enumerate(POSES):
            rig.animation_data.action = bpy.data.actions[act]
            sc.frame_set(fr)
            shoot(os.path.join(RD, "_%s_%d.png" % (name, i)), sc, cam, mesh, 62 if i == 0 else 90)
    print("RENDERED")


def strip(name):  # 2x2 grid: idle 3/4 view, gallop, swap_jump apex, faceplant impact (side views)
    from PIL import Image, ImageDraw
    W = Image.new("RGB", (1800, 1400))
    for i, (act, fr, lab) in enumerate(POSES):
        p = os.path.join(RD, "_%s_%d.png" % (name, i))
        W.paste(Image.open(p).convert("RGB"), ((i % 2) * 900, (i // 2) * 700))
        ImageDraw.Draw(W).text(((i % 2) * 900 + 12, (i // 2) * 700 + 10), "%s  %s f%d" % (name, lab, fr), fill="black")
        os.remove(p)
    W.save(os.path.join(RD, name + ".png"))



if bpy:
    main()
else:
    for f in sorted(glob.glob(os.path.join(CR, "*.blend"))):
        strip(os.path.splitext(os.path.basename(f))[0])
