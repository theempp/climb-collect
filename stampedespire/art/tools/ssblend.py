"""Blender helpers for the Stampede Spire build. Geometry is authored in Roblox world space
(Y up, climb along -Z) and converted on the way in: Blender (x, y, z) = Roblox (-x, z, y).
FBX export (forward -Z, up Y, baked) plus Studio's importer (which turns the file 180 degrees about Y)
lands it back on the original Roblox coordinates (verified with ss_test.fbx, 2026-10-29)."""
import bpy, bmesh, json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from make_atlas import RAMPS, RAMPS10, ROWH, NROWS, NROWS10, PAL  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
EXPORT = os.path.join(ROOT, "art", "export")
# SS_SECTIONS=1 (set by build_sections.py before import): the 10-section atlas with the r3 rows
SECTIONS = os.environ.get("SS_SECTIONS") == "1"
ATLAS = os.path.join(EXPORT, "ss_atlas10.png" if SECTIONS else "ss_atlas.png")
ROW = {name: i for i, (name, _) in enumerate(RAMPS10 if SECTIONS else RAMPS)}
ATLAS_H = ROWH * (NROWS10 if SECTIONS else NROWS)


def rb2bl(p):
    return (-p[0], p[2], p[1])


def uv_for(row, shade):
    """UV inside a ramp row. shade 0 = dark end, 1 = light end."""
    shade = min(max(shade, 0.02), 0.98)
    v = 1 - (ROW[row] * ROWH + ROWH / 2) / ATLAS_H
    return (shade, v)


class MB:
    """Mesh builder: faces carry a ramp row and a shade per corner (Roblox-space points)."""

    def __init__(self):
        self.v, self.f, self.uv = [], [], []
        self.idx = {}

    def vert(self, p, weld=True):
        key = (round(p[0], 3), round(p[1], 3), round(p[2], 3)) if weld else None
        if weld and key in self.idx:
            return self.idx[key]
        self.v.append(rb2bl(p))
        i = len(self.v) - 1
        if weld:
            self.idx[key] = i
        return i

    def face(self, pts, row, shades):
        if isinstance(shades, (int, float)):
            shades = [shades] * len(pts)
        ids = [self.vert(p) for p in pts]
        if len(set(ids)) < 3:
            return
        self.f.append(ids)
        self.uv.append([uv_for(row, s) for s in shades])

    def tris(self):
        return sum(len(f) - 2 for f in self.f)

    def merge(self, other):
        for f, uv in zip(other.f, other.uv):
            ids = [self.vert(tuple_bl2rb(other.v[i])) for i in f]
            self.f.append(ids)
            self.uv.append(uv)


def tuple_bl2rb(p):
    return (-p[0], p[2], p[1])


_mat = None


def atlas_material():
    global _mat
    if _mat:
        return _mat
    m = bpy.data.materials.new("SS_Atlas")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(ATLAS, check_existing=True)
    tex.interpolation = "Linear"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.9
    _mat = m
    return m


MANIFEST = {}
# Plan-view bend (milestone 5): geometry is authored straight and warped here, on the way into Blender.
# WARP maps a straight Roblox point to the bent one (sspath.warp); None keeps the straight build.
WARP = None


def warped(verts, rigid=False):
    """Blender-space verts after the bend warp. rigid: move the whole mesh by its centre's warp (backdrop
    peaks stay undeformed and keep their place beside the mountain)."""
    if WARP is None:
        return verts
    rb = [tuple_bl2rb(p) for p in verts]
    if rigid:
        c = [(min(p[i] for p in rb) + max(p[i] for p in rb)) / 2 for i in range(3)]
        w = WARP(*c)
        return [rb2bl((p[0] + w[0] - c[0], p[1], p[2] + w[2] - c[2])) for p in rb]
    return [rb2bl(WARP(*p)) for p in rb]


def build(name, mb, coll, fidelity="Automatic", material="SmoothPlastic", extra=None, rigid=False):
    """Create an object from a builder, origin at its bounds centre. Records the manifest entry."""
    if not mb.f:
        return None
    verts = warped(mb.v, rigid)
    xs = [p[0] for p in verts]; ys = [p[1] for p in verts]; zs = [p[2] for p in verts]
    c = ((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2)
    me = bpy.data.meshes.new(name)
    me.from_pydata([(p[0] - c[0], p[1] - c[1], p[2] - c[2]) for p in verts], [], mb.f)
    uvl = me.uv_layers.new(name="UVMap")
    li = 0
    for poly, uvs in zip(me.polygons, mb.uv):
        for k, _ in enumerate(poly.loop_indices):
            uvl.data[poly.loop_indices[k]].uv = uvs[k]
        poly.use_smooth = False
    me.validate()
    me.materials.append(atlas_material())
    ob = bpy.data.objects.new(name, me)
    ob.location = c
    coll.objects.link(ob)
    size = (max(xs) - min(xs), max(zs) - min(zs), max(ys) - min(ys))  # Roblox X, Y, Z
    extra = dict(extra or {})
    if extra.get("color") in PAL:
        extra["color"] = PAL[extra["color"]]
    MANIFEST[name] = {
        "pos": [round(v, 3) for v in tuple_bl2rb(c)], "size": [round(s, 3) for s in size], "tris": mb.tris(),
        "fidelity": fidelity, "material": material, **(extra or {}),
    }
    for s in size:
        if s > 2048:
            raise ValueError("%s is %.0f studs, over the 2048 part limit" % (name, s))
    if mb.tris() > 10000:
        raise ValueError("%s has %d tris (cap 10k)" % (name, mb.tris()))
    return ob


def collection(name, parent=None):
    c = bpy.data.collections.new(name)
    (parent or bpy.context.scene.collection).children.link(c)
    return c


def export_fbx(coll, path):
    bpy.ops.object.select_all(action="DESELECT")
    for ob in coll.all_objects:
        ob.select_set(True)
    bpy.ops.export_scene.fbx(
        filepath=path, use_selection=True, apply_unit_scale=True, global_scale=0.01, apply_scale_options="FBX_SCALE_NONE",
        axis_forward="-Z", axis_up="Y", bake_space_transform=True, object_types={"MESH"},
        mesh_smooth_type="FACE", path_mode="COPY", embed_textures=True, use_mesh_modifiers=True,
    )


def write_manifest(path):
    json.dump(MANIFEST, open(path, "w"), indent=0)
