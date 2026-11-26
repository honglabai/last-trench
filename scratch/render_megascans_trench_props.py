import bpy
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
        for c in m.bound_box:
            wc = m.matrix_world @ Vector(c)
            min_v.x = min(min_v.x, wc.x); min_v.y = min(min_v.y, wc.y); min_v.z = min(min_v.z, wc.z)
            max_v.x = max(max_v.x, wc.x); max_v.y = max(max_v.y, wc.y); max_v.z = max(max_v.z, wc.z)
    return min_v, max_v


def setup_render(res_x, res_y, transparent=True):
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = res_x
    scene.render.resolution_y = res_y
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = transparent
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA' if transparent else 'RGB'

    world = bpy.data.worlds.new("StudioWorld")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (0.14, 0.12, 0.10, 1.0)
    bg.inputs["Strength"].default_value = 0.9
    scene.world = world

    sun_d = bpy.data.lights.new("Sun", type='SUN')
    sun_d.energy = 3.8
    sun_d.color = (1.0, 0.96, 0.90)
    sun = bpy.data.objects.new("Sun", sun_d)
    sun.rotation_euler = (math.radians(42), math.radians(15), math.radians(-28))
    bpy.context.collection.objects.link(sun)

    fill_d = bpy.data.lights.new("Fill", type='AREA')
    fill_d.energy = 160.0
    fill_d.size = 4.0
    fill_d.color = (0.82, 0.88, 1.0)
    fill = bpy.data.objects.new("Fill", fill_d)
    fill.location = (2.0, -3.5, 1.5)
    fill.rotation_euler = (math.radians(78), 0, math.radians(35))
    bpy.context.collection.objects.link(fill)


def render_barbed_wire():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    glb = os.path.join(MS_DIR, "military_trenches_wire_barbed_set_zjtmfhciy_mid.glb")
    bpy.ops.import_scene.gltf(filepath=glb)
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    min_v, max_v = get_bounds(meshes)
    # Frame the middle ~2.8m wide barbed wire section cleanly at 1024x512
    cx = (min_v.x + max_v.x) * 0.5
    cz = (min_v.z + max_v.z) * 0.5

    setup_render(1024, 512, transparent=True)
    cam_d = bpy.data.cameras.new("WireCam")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = 2.6
    cam = bpy.data.objects.new("WireCam", cam_d)
    cam.location = (cx, -4.0, cz + 0.05)
    cam.rotation_euler = (math.radians(90.0), 0.0, 0.0)
    bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam

    bpy.context.scene.render.filepath = os.path.join(OUT_DIR, "tex_barbed_wire.png")
    bpy.ops.render.render(write_still=True)
    print("Rendered Megascans barbed wire -> tex_barbed_wire.png")


def apply_front_normal_override():
    mat = bpy.data.materials.new("FrontNormalMat")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(geo.outputs["Normal"], sep.inputs["Vector"])
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


def render_wood_wall():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    glb = os.path.join(MS_DIR, "military_trenches_wall_wood_02_ydysdhy_mid.glb")
    bpy.ops.import_scene.gltf(filepath=glb)
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    min_v, max_v = get_bounds(meshes)
    w = max_v.x - min_v.x
    h = max_v.z - min_v.z
    cx = (min_v.x + max_v.x) * 0.5
    cz = (min_v.z + max_v.z) * 0.5

    # Tile left/right so 1024x1024 has zero side gaps
    for dx in [-w * 0.95, w * 0.95]:
        for src in meshes:
            dup = src.copy()
            dup.data = src.data
            bpy.context.collection.objects.link(dup)
            dup.matrix_world = src.matrix_world.copy()
            dup.matrix_world.translation += Vector((dx, 0.0, 0.0))

    setup_render(1024, 1024, transparent=False)
    cam_d = bpy.data.cameras.new("WoodCam")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = h * 0.90
    cam = bpy.data.objects.new("WoodCam", cam_d)
    cam.location = (cx, -4.0, cz)
    cam.rotation_euler = (math.radians(90.0), 0.0, 0.0)
    bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam

    bpy.context.scene.render.filepath = os.path.join(OUT_DIR, "tex_trench_wall_wood.png")
    bpy.ops.render.render(write_still=True)

    apply_front_normal_override()
    bpy.context.scene.render.filepath = os.path.join(OUT_DIR, "tex_trench_wall_wood_normal.png")
    bpy.ops.render.render(write_still=True)
    print("Rendered Megascans wood trench wall albedo + normal")


def render_crate():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    glb = os.path.join(MS_DIR, "military_trenches_storage_crate_wood_s_02_vlqjdg2_mid.glb")
    bpy.ops.import_scene.gltf(filepath=glb)
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    min_v, max_v = get_bounds(meshes)
    cx = (min_v.x + max_v.x) * 0.5
    cy = (min_v.y + max_v.y) * 0.5
    cz = (min_v.z + max_v.z) * 0.5

    setup_render(512, 512, transparent=True)
    cam_d = bpy.data.cameras.new("CrateCam")
    cam_d.lens = 50.0
    cam = bpy.data.objects.new("CrateCam", cam_d)
    cam.location = (cx + 0.55, cy - 0.72, cz + 0.36)
    direction = Vector((cx, cy, cz)) - cam.location
    cam.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam

    bpy.context.scene.render.filepath = os.path.join(OUT_DIR, "tex_trench_crate.png")
    bpy.ops.render.render(write_still=True)
    print("Rendered Megascans storage crate -> tex_trench_crate.png")


if __name__ == "__main__":
    render_barbed_wire()
    render_wood_wall()
    render_crate()
