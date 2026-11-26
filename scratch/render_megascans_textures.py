import bpy
import bmesh
import math
import os
from mathutils import Vector

OUT_DIR = "/Users/kobujang/Desktop/cording/LAST_TRENCH/assets/textures"
MS_DIR = "/Users/kobujang/Desktop/cording/LAST_TRENCH/scratch/megascans"


def get_bounds(objs):
    min_v = Vector((1e9, 1e9, 1e9))
    max_v = Vector((-1e9, -1e9, -1e9))
    bpy.context.view_layer.update()
    for m in objs:
        for corner in m.bound_box:
            wc = m.matrix_world @ Vector(corner)
            min_v.x = min(min_v.x, wc.x)
            min_v.y = min(min_v.y, wc.y)
            min_v.z = min(min_v.z, wc.z)
            max_v.x = max(max_v.x, wc.x)
            max_v.y = max(max_v.y, wc.y)
            max_v.z = max(max_v.z, wc.z)
    return min_v, max_v


def setup_ortho_studio(ortho_scale, center_x, center_z):
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGB'

    cam_data = bpy.data.cameras.new("OrthoCam")
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = ortho_scale
    cam_obj = bpy.data.objects.new("OrthoCam", cam_data)
    cam_obj.location = (center_x, -5.0, center_z)
    cam_obj.rotation_euler = (math.radians(90.0), 0.0, 0.0)
    bpy.context.collection.objects.link(cam_obj)
    scene.camera = cam_obj

    world = bpy.data.worlds.new("MudWorld")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (0.12, 0.11, 0.09, 1.0)
    bg.inputs["Strength"].default_value = 0.85
    scene.world = world

    key_data = bpy.data.lights.new("KeyLight", type='SUN')
    key_data.energy = 3.4
    key_data.color = (1.0, 0.96, 0.90)
    key_obj = bpy.data.objects.new("KeyLight", key_data)
    key_obj.rotation_euler = (math.radians(42.0), math.radians(15.0), math.radians(-28.0))
    bpy.context.collection.objects.link(key_obj)

    fill_data = bpy.data.lights.new("FillLight", type='AREA')
    fill_data.energy = 140.0
    fill_data.size = 4.0
    fill_data.color = (0.80, 0.88, 1.0)
    fill_obj = bpy.data.objects.new("FillLight", fill_data)
    fill_obj.location = (center_x + 2.0, -3.5, center_z + 1.0)
    fill_obj.rotation_euler = (math.radians(78.0), 0.0, math.radians(35.0))
    bpy.context.collection.objects.link(fill_obj)


def apply_camera_normal_override():
    """Replaces scene materials with an Emission tangent-space normal shader (cam facing +Y -> +X right, +Z up, -Y depth)."""
    mat = bpy.data.materials.new("NormalPassMat")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()

    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    geo = nt.nodes.new("ShaderNodeNewGeometry")

    # Separate XYZ of world normal (X=right, Y=-depth, Z=up) -> Map to Godot Tangent Normal RGB (X, Z, -Y)*0.5 + 0.5
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(geo.outputs["Normal"], sep.inputs["Vector"])

    # R = 0.5 + 0.5 * X, G = 0.5 + 0.5 * Z, B = 0.5 - 0.5 * Y
    comb = nt.nodes.new("ShaderNodeCombineXYZ")
    for idx, src_socket, mult in [(0, sep.outputs["X"], 0.5), (1, sep.outputs["Z"], 0.5), (2, sep.outputs["Y"], -0.5)]:
        m = nt.nodes.new("ShaderNodeMath")
        m.operation = 'MULTIPLY_ADD'
        m.inputs[1].default_value = mult
        m.inputs[2].default_value = 0.5
        nt.links.new(src_socket, m.inputs[0])
        nt.links.new(m.outputs["Value"], comb.inputs[idx])

    nt.links.new(comb.outputs["Vector"], em.inputs["Color"])
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])

    bpy.context.scene.view_settings.view_transform = 'Standard'
    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH':
            obj.data.materials.clear()
            obj.data.materials.append(mat)


def render_sandbag_and_normal():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    glb_path = os.path.join(MS_DIR, "sandbag_barrier_udtvegsfa_mid.glb")
    bpy.ops.import_scene.gltf(filepath=glb_path)

    base_meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    min_v, max_v = get_bounds(base_meshes)
    h = max_v.z - min_v.z
    w = max_v.x - min_v.x

    for r in range(3):
        for c in [-1, 0, 1]:
            if r == 0 and c == 0:
                continue
            for src in base_meshes:
                dup = src.copy()
                dup.data = src.data
                bpy.context.collection.objects.link(dup)
                dup.matrix_world = src.matrix_world.copy()
                dup.matrix_world.translation += Vector((c * w * 0.92 + (0.25 if r % 2 else 0.0), 0.0, r * h * 0.84))

    center_z = min_v.z + h * 1.25
    setup_ortho_studio(ortho_scale=h * 1.45, center_x=0.0, center_z=center_z)

    out_albedo = os.path.join(OUT_DIR, "tex_sandbag_stacked.png")
    bpy.context.scene.render.filepath = out_albedo
    bpy.ops.render.render(write_still=True)

    apply_camera_normal_override()
    out_normal = os.path.join(OUT_DIR, "tex_sandbag_stacked_normal.png")
    bpy.context.scene.render.filepath = out_normal
    bpy.ops.render.render(write_still=True)
    print("Rendered Megascans sandbag albedo + normal")


def render_concrete_and_bunker():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    glb_path = os.path.join(MS_DIR, "concrete_barrier_sdsbo_mid.glb")
    bpy.ops.import_scene.gltf(filepath=glb_path)

    base_meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    min_v, max_v = get_bounds(base_meshes)
    h = max_v.z - min_v.z
    w = max_v.x - min_v.x

    for r in range(3):
        for c in [-1, 0, 1]:
            if r == 0 and c == 0:
                continue
            for src in base_meshes:
                dup = src.copy()
                dup.data = src.data
                bpy.context.collection.objects.link(dup)
                dup.matrix_world = src.matrix_world.copy()
                dup.matrix_world.translation += Vector((c * w * 0.95 + (0.3 if r % 2 else 0.0), 0.0, r * h * 0.90))

    center_z = min_v.z + h * 1.25
    setup_ortho_studio(ortho_scale=h * 1.45, center_x=0.0, center_z=center_z)

    out_albedo = os.path.join(OUT_DIR, "tex_trench_wall_gabion.png")
    bpy.context.scene.render.filepath = out_albedo
    bpy.ops.render.render(write_still=True)

    # Also render tex_base_bunker.png with reinforced steel armor slit + bolts!
    mat_steel = bpy.data.materials.new("BunkerSteel")
    mat_steel.use_nodes = True
    bsdf = mat_steel.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (0.05, 0.055, 0.06, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.85
    bsdf.inputs["Roughness"].default_value = 0.35

    # Add dark armored firing slit in upper center of bunker texture
    mesh = bpy.data.meshes.new("BunkerSlit")
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=(w * 0.55, 0.2, h * 0.22), verts=bm.verts)
    bm.to_mesh(mesh)
    bm.free()
    slit_obj = bpy.data.objects.new("BunkerSlit", mesh)
    slit_obj.location = (0.0, -0.35, center_z + h * 0.22)
    slit_obj.data.materials.append(mat_steel)
    bpy.context.collection.objects.link(slit_obj)

    out_bunker = os.path.join(OUT_DIR, "tex_base_bunker.png")
    bpy.context.scene.render.filepath = out_bunker
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(slit_obj, do_unlink=True)

    apply_camera_normal_override()
    out_normal = os.path.join(OUT_DIR, "tex_trench_wall_gabion_normal.png")
    bpy.context.scene.render.filepath = out_normal
    bpy.ops.render.render(write_still=True)
    print("Rendered Megascans concrete wall albedo + normal + bunker")


if __name__ == "__main__":
    render_sandbag_and_normal()
    render_concrete_and_bunker()
