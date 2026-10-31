"""Wraps the zone-4 skybox images (make_sky.py) as textures on three tiny quads, so the 3D importer uploads them.
Image uploads through the Asset Manager sat in moderation for hours (M6); importer-embedded textures load at once.
blender -b --python art/tools/make_sky_fbx.py  ->  art/export/ss_sky.fbx (SkyQuad_side / _up / _down)"""
import os
import bpy

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SKY = os.path.join(ROOT, "art", "export", "sky")
bpy.ops.wm.read_factory_settings(use_empty=True)
for i, face in enumerate(("side", "up", "down")):
    mesh = bpy.data.meshes.new("SkyQuad_" + face)
    mesh.from_pydata([(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0)], [], [(0, 1, 2, 3)])
    uv = mesh.uv_layers.new()
    for li, co in enumerate([(0, 0), (1, 0), (1, 1), (0, 1)]):
        uv.data[li].uv = co
    mat = bpy.data.materials.new("Sky_" + face)
    mat.use_nodes = True
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.join(SKY, "z4_%s.png" % face))
    mat.node_tree.links.new(tex.outputs["Color"], mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
    mesh.materials.append(mat)
    ob = bpy.data.objects.new("SkyQuad_" + face, mesh)
    ob.location = (i * 2, 0, 0)
    bpy.context.scene.collection.objects.link(ob)
bpy.ops.export_scene.fbx(filepath=os.path.join(ROOT, "art", "export", "ss_sky.fbx"), path_mode="COPY", embed_textures=True)
print("SKYFBX done")
