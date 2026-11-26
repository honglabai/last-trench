import bpy
import math
import os
from mathutils import Vector

OUT_DIR = "/Users/kobujang/Desktop/cording/LAST_TRENCH/assets/textures"
MS_DIR = "/Users/kobujang/Desktop/cording/LAST_TRENCH/scratch/megascans"
MS_MUD_DIR = os.path.join(MS_DIR, "trampled_mud_ground")


def get_bounds(objs):
    min_v = Vector((1e9, 1e9, 1e9))
    max_v = Vector((-1e9, -1e9, -1e9))
    bpy.context.view_layer.update()
    for m in objs:
        for corner in m.bound_box:
            wc = m.matrix_world @ Vector(corner)
            min_v.x = min(min_v.x, wc.x); min_v.y = min(min_v.y, wc.y); min_v.z = min(min_v.z, wc.z)
            max_v.x = max(max_v.x, wc.x); max_v.y = max(max_v.y, wc.y); max_v.z = max(max_v.z, wc.z)
    return min_v, max_v


def setup_topdown_ortho(ortho_scale, center_x=0.0, center_y=0.0):
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGB'

    cam_data = bpy.data.cameras.new("TopCam")
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = ortho_scale
    cam = bpy.data.objects.new("TopCam", cam_data)
    cam.location = (center_x, center_y, 5.0)
    cam.rotation_euler = (0.0, 0.0, 0.0)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam

    world = bpy.data.worlds.new("TrenchWorld")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (0.12, 0.10, 0.08, 1.0)
    bg.inputs["Strength"].default_value = 0.85
    scene.world = world

    sun_d = bpy.data.lights.new("Sun", type='SUN')
    sun_d.energy = 3.5
    sun_d.color = (1.0, 0.96, 0.90)
    sun = bpy.data.objects.new("Sun", sun_d)
    sun.rotation_euler = (math.radians(38), math.radians(22), math.radians(-25))
    bpy.context.collection.objects.link(sun)

    fill_d = bpy.data.lights.new("Fill", type='AREA')
    fill_d.energy = 150.0
    fill_d.size = 4.0
    fill_d.color = (0.82, 0.88, 1.0)
    fill = bpy.data.objects.new("Fill", fill_d)
    fill.location = (center_x + 1.5, center_y - 1.5, 3.5)
    fill.rotation_euler = (math.radians(20), math.radians(20), 0.0)
    bpy.context.collection.objects.link(fill)


def add_mud_backdrop(size=6.0):
    bpy.ops.mesh.primitive_plane_add(size=size, location=(0, 0, -0.02))
    plane = bpy.context.active_object
    mat = bpy.data.materials.new("MudBackMat")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    tex_col = nt.nodes.new("ShaderNodeTexImage")
    tex_col.image = bpy.data.images.load(os.path.join(MS_MUD_DIR, "Trampled_Mud_Ground_vbokfcjlw_2K_BaseColor.jpg"))
    nt.links.new(tex_col.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.9
    plane.data.materials.append(mat)


def apply_topdown_normal_override():
    """Tangent-space normal map for top-down camera (X=right, Y=up, Z=depth toward cam)."""
    mat = bpy.data.materials.new("TopNormalMat")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(geo.outputs["Normal"], sep.inputs["Vector"])

    comb = nt.nodes.new("ShaderNodeCombineXYZ")
    for idx, src_socket, mult in [(0, sep.outputs["X"], 0.5), (1, sep.outputs["Y"], 0.5), (2, sep.outputs["Z"], 0.5)]:
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


def render_duckboard():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    glb = os.path.join(MS_DIR, "military_trenches_equipment_duckboard_wood_m_02_ydxpbhws_mid.glb")
    bpy.ops.import_scene.gltf(filepath=glb)

    base = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    min_v, max_v = get_bounds(base)
    w = max_v.x - min_v.x
    d = max_v.y - min_v.y

    # Tile 2x3 duckboard sections over Megascans mud backdrop
    for r in [-1, 0, 1]:
        for c in [-1, 0, 1]:
            if r == 0 and c == 0:
                continue
            for src in base:
                dup = src.copy()
                dup.data = src.data
                bpy.context.collection.objects.link(dup)
                dup.matrix_world = src.matrix_world.copy()
                dup.matrix_world.translation += Vector((c * w * 0.98, r * d * 1.04, 0.0))

    add_mud_backdrop(size=6.0)
    setup_topdown_ortho(ortho_scale=1.18, center_x=0.0, center_y=0.0)

    bpy.context.scene.render.filepath = os.path.join(OUT_DIR, "tex_trench_duckboard.png")
    bpy.ops.render.render(write_still=True)

    apply_topdown_normal_override()
    bpy.context.scene.render.filepath = os.path.join(OUT_DIR, "tex_trench_duckboard_normal.png")
    bpy.ops.render.render(write_still=True)
    print("Rendered Megascans duckboard albedo + normal")


def render_corrugated_wall():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    glb = os.path.join(MS_DIR, "military_trenches_sheet_metal_corrugated_02_ydzmfhvs_mid.glb")
    bpy.ops.import_scene.gltf(filepath=glb)

    base = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    min_v, max_v = get_bounds(base)
    w = max_v.x - min_v.x
    d = max_v.y - min_v.y

    # Tile 3x3 corrugated steel sheets seamlessly
    for r in [-1, 0, 1]:
        for c in [-1, 0, 1]:
            if r == 0 and c == 0:
                continue
            for src in base:
                dup = src.copy()
                dup.data = src.data
                bpy.context.collection.objects.link(dup)
                dup.matrix_world = src.matrix_world.copy()
                dup.matrix_world.translation += Vector((c * w * 0.90, r * d * 0.88, 0.0))

    add_mud_backdrop(size=6.0)
    setup_topdown_ortho(ortho_scale=1.15, center_x=0.0, center_y=0.0)

    bpy.context.scene.render.filepath = os.path.join(OUT_DIR, "tex_trench_wall_gabion.png")
    bpy.ops.render.render(write_still=True)

    apply_topdown_normal_override()
    bpy.context.scene.render.filepath = os.path.join(OUT_DIR, "tex_trench_wall_gabion_normal.png")
    bpy.ops.render.render(write_still=True)
    print("Rendered Megascans corrugated metal trench wall albedo + normal")


if __name__ == "__main__":
    render_duckboard()
    render_corrugated_wall()
