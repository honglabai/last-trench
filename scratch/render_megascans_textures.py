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


def render_sandbag_texture():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    glb_path = os.path.join(MS_DIR, "sandbag_barrier_udtvegsfa_mid.glb")
    bpy.ops.import_scene.gltf(filepath=glb_path)

    base_meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    min_v, max_v = get_bounds(base_meshes)
    h = max_v.z - min_v.z
    w = max_v.x - min_v.x

    # Duplicate into a 2x3 wall grid using world-space parent empties
    all_objs = list(base_meshes)
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
                all_objs.append(dup)

    # Frame tightly inside the middle of the stacked sandbags
    center_z = min_v.z + h * 1.25
    setup_ortho_studio(ortho_scale=h * 1.45, center_x=0.0, center_z=center_z)
    out_path = os.path.join(OUT_DIR, "tex_sandbag_stacked.png")
    bpy.context.scene.render.filepath = out_path
    bpy.ops.render.render(write_still=True)
    print("Rendered Megascans sandbag texture ->", out_path)


def render_concrete_barrier_texture():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    glb_path = os.path.join(MS_DIR, "concrete_barrier_sdsbo_mid.glb")
    bpy.ops.import_scene.gltf(filepath=glb_path)

    base_meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    min_v, max_v = get_bounds(base_meshes)
    h = max_v.z - min_v.z
    w = max_v.x - min_v.x

    # Stack 3 concrete tiers vertically so the full 1024x1024 wall texture has beveled seams & weathering
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
    out_path = os.path.join(OUT_DIR, "tex_trench_wall_gabion.png")
    bpy.context.scene.render.filepath = out_path
    bpy.ops.render.render(write_still=True)
    print("Rendered Megascans concrete barrier texture ->", out_path)


if __name__ == "__main__":
    render_sandbag_texture()
    render_concrete_barrier_texture()
