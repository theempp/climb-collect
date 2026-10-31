"""Exports each creature .blend (art/creatures) as one FBX for the Roblox 3D importer: skinned mesh + rig, with
the 4 clips laid end to end on one baked timeline (the importer reads one animation per file; SS splits it
back into clips by the ranges in art/export/creatures/clips.json).
blender -b --factory-startup --python art/tools/export_creatures.py
Scale: 1 A (avatar height) = 1.98 m on the r2 sheets (art/creatures/README.md) = AVATAR_STUDS in game."""
import bpy, json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "art", "creatures")
OUT = os.path.join(ROOT, "art", "export", "creatures")
AVATAR_M, AVATAR_STUDS = 1.98, 5.2  # R15 avatar height in studs (measured in Play: HRP-based rig, ~5.2)
CLIPS = [("gallop", True), ("idle", True), ("swap_jump", False), ("faceplant", False)]
GAP = 16  # rest frames between clips on the shared timeline
SPECIES = ["taiga_elk", "woolly_reindeer", "musk_ox_calfrunner", "snowshoe_hare_hound", "pine_boar"]

os.makedirs(OUT, exist_ok=True)
ranges = {}
for name in SPECIES:
    bpy.ops.wm.open_mainfile(filepath=os.path.join(SRC, name + ".blend"))
    rig = bpy.data.objects["Rig"]
    ad = rig.animation_data
    ad.action = None
    for t in ad.nla_tracks:
        t.mute = True
    track = ad.nla_tracks.new()
    track.name = "timeline"
    f, rr = 0, {}
    fps = bpy.context.scene.render.fps
    for clip, loop in CLIPS:
        act = bpy.data.actions[clip]
        a0, a1 = act.frame_range
        s = track.strips.new(clip, int(f), act)
        s.extrapolation = "NOTHING"
        rr[clip] = {"start": f / fps, "stop": (f + a1 - a0) / fps, "loop": loop}
        f += (a1 - a0) + GAP
    sc = bpy.context.scene
    sc.frame_start, sc.frame_end = 0, int(f - GAP)
    # seat: top of the back above the spine bone, relative to the mesh bounding-box centre (= the MeshPart
    # origin in Roblox), in studs; fwd is Blender +Y (the head is at -Y)
    sc.frame_set(0)
    ad.action = bpy.data.actions["idle"]
    sc.frame_set(0)
    mesh = bpy.data.objects[name]
    vs = [mesh.matrix_world @ v.co for v in mesh.data.vertices]
    lo = [min(v[i] for v in vs) for i in range(3)]
    hi = [max(v[i] for v in vs) for i in range(3)]
    sp = rig.matrix_world @ rig.data.bones["spine"].head_local
    back = max(v.z for v in vs if abs(v.y - sp.y) < 0.15 and abs(v.x) < 0.3)
    k = AVATAR_STUDS / AVATAR_M
    rr["_seat"] = {"up": (back - (lo[2] + hi[2]) / 2) * k, "fwd": (sp.y - (lo[1] + hi[1]) / 2) * k,
                   "headY": (rig.matrix_world @ rig.data.bones["head"].head_local).y - (lo[1] + hi[1]) / 2}
    ad.action = None
    ranges[name] = rr
    bpy.ops.object.select_all(action="DESELECT")
    for ob in (rig, bpy.data.objects[name]):
        ob.select_set(True)
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(OUT, name + ".fbx"), use_selection=True, object_types={"ARMATURE", "MESH"},
        apply_unit_scale=True, global_scale=0.01 * AVATAR_STUDS / AVATAR_M, apply_scale_options="FBX_SCALE_NONE",
        axis_forward="-Z", axis_up="Y", bake_space_transform=False, add_leaf_bones=False,
        mesh_smooth_type="FACE", path_mode="COPY", embed_textures=True, use_mesh_modifiers=False,
        bake_anim=True, bake_anim_use_all_actions=False, bake_anim_use_nla_strips=False,
        bake_anim_force_startend_keying=True, bake_anim_step=1.0, bake_anim_simplify_factor=0.0,
    )
    print("CREATURE", name, sc.frame_end, "frames")
json.dump({"avatarStuds": AVATAR_STUDS, "fps": 30, "clips": ranges}, open(os.path.join(OUT, "clips.json"), "w"), indent=1)
print("CREATURES done", len(SPECIES))
