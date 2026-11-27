import bpy
import math
import mathutils
import os

MODELS_DIR = "/Users/kobujang/Desktop/cording/LAST_TRENCH/scratch/enemy_models"
OUT_DIR = "/Users/kobujang/Desktop/cording/LAST_TRENCH/assets/textures"


def render_glb(glb_name, out_name, res_x, res_y, cam_az_deg=20.0, cam_el_deg=12.0, fit_margin=1.18):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 48
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.render.resolution_x = res_x
    scene.render.resolution_y = res_y
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"

    world = bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.38, 0.35, 0.32, 1.0)
        bg.inputs[1].default_value = 0.85

    path = os.path.join(MODELS_DIR, glb_name)
    bpy.ops.import_scene.gltf(filepath=path)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    pts = [o.matrix_world @ mathutils.Vector(c) for o in meshes for c in o.bound_box]
    min_v = mathutils.Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    max_v = mathutils.Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    center = (min_v + max_v) * 0.5
    size = max_v - min_v
    radius = max(size.x, size.y, size.z) * 0.5

    # Lighting: warm battlefield key, cool sky fill, crisp rim
    for name, rot, energy, col in [
        ("Key", (50, 0, -35), 4.2, (1.0, 0.93, 0.84)),
        ("Fill", (35, 0, 130), 2.0, (0.78, 0.86, 1.0)),
        ("Rim", (70, 0, 175), 3.0, (1.0, 0.88, 0.72)),
    ]:
        ld = bpy.data.lights.new(name=name, type="SUN")
        ld.energy = energy
        ld.color = col
        ld.angle = math.radians(14.0)
        lo = bpy.data.objects.new(name=name, object_data=ld)
        bpy.context.collection.objects.link(lo)
        lo.rotation_euler = [math.radians(a) for a in rot]

    # Perspective camera framing the normalized bounding sphere
    cam_data = bpy.data.cameras.new(name="Cam")
    cam_data.lens = 55.0
    cam_data.clip_start = 0.01
    cam_data.clip_end = max(100.0, radius * 40.0)
    cam_obj = bpy.data.objects.new(name="Cam", object_data=cam_data)
    bpy.context.collection.objects.link(cam_obj)

    az = math.radians(cam_az_deg)
    el = math.radians(cam_el_deg)
    dist = radius * fit_margin * 3.1
    cam_pos = center + mathutils.Vector((
        dist * math.cos(el) * math.sin(az),
        -dist * math.cos(el) * math.cos(az),
        dist * math.sin(el),
    ))
    cam_obj.location = cam_pos
    direction = (center - cam_pos).normalized()
    cam_obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam_obj

    scene.render.filepath = os.path.join(OUT_DIR, out_name)
    bpy.ops.render.render(write_still=True)
    print("RENDERED:", out_name)


if __name__ == "__main__":
    render_glb("kn0_w3r.glb", "tex_enemy_combat_robot.png", 512, 512, cam_az_deg=18.0, cam_el_deg=8.0, fit_margin=1.15)
    render_glb("mecha.glb", "tex_boss_armored_robot.png", 640, 640, cam_az_deg=20.0, cam_el_deg=10.0, fit_margin=1.18)
    render_glb("autopilot_aircraft_drone.glb", "tex_boss_drone_commander.png", 640, 512, cam_az_deg=24.0, cam_el_deg=22.0, fit_margin=1.10)
    render_glb("tank_challenger.glb", "tex_enemy_tank.png", 768, 512, cam_az_deg=28.0, cam_el_deg=14.0, fit_margin=1.12)
    print("ALL_ENEMY_MODELS_RENDERED")
