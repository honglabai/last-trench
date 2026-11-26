import bpy
import bmesh
import math
import os
from mathutils import Vector

OUT_DIR = "/Users/kobujang/Desktop/cording/LAST_TRENCH/assets/textures"
GLB_PATH = "/Users/kobujang/Desktop/cording/LAST_TRENCH/scratch/megascans/swat_operator_remastered.glb"
os.makedirs(OUT_DIR, exist_ok=True)


def set_hide_recursive(obj, hide):
    obj.hide_render = hide
    obj.hide_viewport = hide
    for ch in obj.children:
        set_hide_recursive(ch, hide)


def make_pbr_mat(name, color, roughness=0.5, metallic=0.0, emission=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission is not None and emission_strength > 0.0:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat


def add_cylinder_mesh(name, r1, r2, depth, loc, rot, mat, parent):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=14, radius1=r2, radius2=r1, depth=depth)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    obj.location = loc
    obj.rotation_euler = rot
    obj.data.materials.append(mat)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def build_rpg7_prop(parent_root):
    mat_metal = make_pbr_mat("RPG_Metal", (0.07, 0.075, 0.08), roughness=0.35, metallic=0.85)
    mat_wood = make_pbr_mat("RPG_Wood", (0.30, 0.15, 0.06), roughness=0.55)
    mat_warhead = make_pbr_mat("RPG_Warhead", (0.14, 0.20, 0.10), roughness=0.45, metallic=0.25)

    rpg = bpy.data.objects.new("RPG7_Prop", None)
    bpy.context.collection.objects.link(rpg)
    rpg.parent = parent_root

    add_cylinder_mesh("RPG_Tube", 0.028, 0.028, 0.95, (0, 0.08, 0), (math.pi / 2, 0, 0), mat_metal, rpg)
    add_cylinder_mesh("RPG_WoodShield", 0.036, 0.036, 0.34, (0, 0.06, 0), (math.pi / 2, 0, 0), mat_wood, rpg)
    add_cylinder_mesh("RPG_Exhaust", 0.048, 0.028, 0.16, (0, 0.62, 0), (math.pi / 2, 0, 0), mat_metal, rpg)
    add_cylinder_mesh("RPG_WarRear", 0.052, 0.024, 0.16, (0, -0.46, 0), (math.pi / 2, 0, 0), mat_warhead, rpg)
    add_cylinder_mesh("RPG_WarTip", 0.006, 0.052, 0.18, (0, -0.63, 0), (math.pi / 2, 0, 0), mat_warhead, rpg)
    return rpg


def build_fx_props():
    mat_flash_core = make_pbr_mat("FX_FlashCore", (1.0, 0.90, 0.40), 0.1, emission=(1.0, 0.88, 0.35), emission_strength=30.0)
    mat_flash_outer = make_pbr_mat("FX_FlashOuter", (1.0, 0.45, 0.06), 0.2, emission=(1.0, 0.40, 0.05), emission_strength=16.0)
    mat_laser = make_pbr_mat("FX_Laser", (1.0, 0.04, 0.04), 0.1, emission=(1.0, 0.05, 0.04), emission_strength=18.0)

    flash_grp = bpy.data.objects.new("MuzzleFlashFX", None)
    bpy.context.collection.objects.link(flash_grp)
    add_cylinder_mesh("FlashJet", 0.065, 0.008, 0.28, (0, -0.14, 0), (math.pi / 2, 0, 0), mat_flash_core, flash_grp)
    for ang in [0, 45, 90, 135]:
        add_cylinder_mesh(f"FlashSpike_{ang}", 0.004, 0.038, 0.24, (0, -0.02, 0), (0, math.radians(ang), 0), mat_flash_outer, flash_grp)

    light_d = bpy.data.lights.new("MuzzleLight", type='POINT')
    light_d.energy = 15000.0
    light_d.color = (1.0, 0.52, 0.12)
    light_d.shadow_soft_size = 2.0
    light_o = bpy.data.objects.new("MuzzleLight", light_d)
    light_o.location = (0, -0.22, 0.05)
    bpy.context.collection.objects.link(light_o)
    light_o.parent = flash_grp

    laser_grp = bpy.data.objects.new("LaserFX", None)
    bpy.context.collection.objects.link(laser_grp)
    add_cylinder_mesh("LaserBeam", 0.004, 0.004, 1.5, (0, -0.75, 0), (math.pi / 2, 0, 0), mat_laser, laser_grp)
    add_cylinder_mesh("LaserDot", 0.015, 0.015, 0.02, (0, 0, 0), (math.pi / 2, 0, 0), mat_laser, laser_grp)

    return flash_grp, laser_grp


def setup_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=GLB_PATH)
    ico = bpy.data.objects.get("Icosphere")
    if ico:
        bpy.data.objects.remove(ico, do_unlink=True)

    arm = bpy.data.objects.get("Object_4")
    for pb in arm.pose.bones:
        pb.rotation_mode = 'XYZ'
        pb.location = (0, 0, 0)
        pb.rotation_euler = (0, 0, 0)
        pb.scale = (1, 1, 1)

    # Stand character upright at ~1.8m real-world scale
    arm.scale = (18.0, 18.0, 18.0)
    arm.rotation_mode = 'XYZ'
    arm.rotation_euler = (math.radians(90.0), 0, 0)
    arm.location = (0, 0, 0.0)

    gun = bpy.data.objects.get("topGun_low")
    if gun:
        gun.rotation_mode = 'XYZ'
        gun.scale = (1400.0, 1400.0, 1400.0)

    rpg_root = bpy.data.objects.new("RPG_Anchor", None)
    bpy.context.collection.objects.link(rpg_root)
    rpg = build_rpg7_prop(rpg_root)
    flash_grp, laser_grp = build_fx_props()

    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = 768
    scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'

    cam_data = bpy.data.cameras.new("RenderCam")
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = 2.4
    cam = bpy.data.objects.new("RenderCam", cam_data)
    cam.location = (0.0, -5.0, 0.0)
    cam.rotation_euler = (math.radians(90.0), 0.0, 0.0)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam

    # Strong tactical 3-point lighting so dark tactical gear reads with rich detail
    key_d = bpy.data.lights.new("KeyLight", type='SUN')
    key_d.energy = 4.2
    key_d.color = (1.0, 0.97, 0.92)
    key = bpy.data.objects.new("KeyLight", key_d)
    key.rotation_euler = (math.radians(44), 0, math.radians(-30))
    bpy.context.collection.objects.link(key)

    fill_d = bpy.data.lights.new("FillLight", type='AREA')
    fill_d.energy = 240.0
    fill_d.size = 3.5
    fill_d.color = (0.82, 0.90, 1.0)
    fill = bpy.data.objects.new("FillLight", fill_d)
    fill.location = (2.2, -2.6, 0.8)
    fill.rotation_euler = (math.radians(82), 0, math.radians(38))
    bpy.context.collection.objects.link(fill)

    rim_d = bpy.data.lights.new("RimLight", type='AREA')
    rim_d.energy = 320.0
    rim_d.size = 2.5
    rim_d.color = (1.0, 0.86, 0.68)
    rim = bpy.data.objects.new("RimLight", rim_d)
    rim.location = (-2.0, 2.2, 1.8)
    rim.rotation_euler = (math.radians(122), 0, math.radians(-35))
    bpy.context.collection.objects.link(rim)

    world = bpy.data.worlds.new("StudioWorld")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (0.22, 0.24, 0.27, 1.0)
    bg.inputs["Strength"].default_value = 0.95
    scene.world = world

    return arm, gun, rpg, flash_grp, laser_grp


def reset_bones(arm):
    for pb in arm.pose.bones:
        pb.location = (0, 0, 0)
        pb.rotation_euler = (0, 0, 0)
        pb.scale = (1, 1, 1)


def set_pose(arm, gun, rpg, flash_grp, laser_grp, pose_name):
    reset_bones(arm)
    arm.location = (0, 0, 34.0)
    arm.rotation_euler = (math.radians(90.0), 0, 0)

    is_rpg = pose_name.startswith("rpg_")
    if gun:
        set_hide_recursive(gun, is_rpg)
    set_hide_recursive(rpg, not is_rpg)
    set_hide_recursive(flash_grp, True)
    set_hide_recursive(laser_grp, True)

    b = arm.pose.bones

    if pose_name.startswith("run_"):
        idx = int(pose_name.split("_")[1])
        configs = [
            (-48, 62, 32, 24, -12, -2.0, -1.0),
            (-12, 24, -18, 52, -4, 3.0, 2.0),
            (32, 24, -48, 62, 12, -2.0, -1.0),
            (-18, 52, -12, 24, 4, 3.0, 2.0),
        ]
        lh, lk, rh, rk, twist, bob, gz = configs[idx]

        arm.location = (0, 0, 34.0 + bob)
        b["mixamorig:Spine_02"].rotation_euler = (math.radians(15), math.radians(twist), 0)
        b["mixamorig:Spine1_03"].rotation_euler = (math.radians(8), 0, 0)
        b["mixamorig:Head_05"].rotation_euler = (math.radians(-18), math.radians(-twist * 0.7), 0)

        b["mixamorig:LeftUpLeg_054"].rotation_euler = (math.radians(lh), 0, math.radians(-4))
        b["mixamorig:LeftLeg_055"].rotation_euler = (math.radians(lk), 0, 0)
        b["mixamorig:RightUpLeg_059"].rotation_euler = (math.radians(rh), 0, math.radians(4))
        b["mixamorig:RightLeg_060"].rotation_euler = (math.radians(rk), 0, 0)

        # Arms DOWN (+Z on LeftArm, -Z on RightArm) and FORWARD (+X) to cradle rifle in front of chest!
        b["mixamorig:LeftArm_08"].rotation_euler = (math.radians(48), math.radians(20), math.radians(52))
        b["mixamorig:LeftForeArm_09"].rotation_euler = (math.radians(35), 0, math.radians(78))
        b["mixamorig:RightArm_031"].rotation_euler = (math.radians(42), math.radians(-20), math.radians(-52))
        b["mixamorig:RightForeArm_032"].rotation_euler = (math.radians(35), 0, math.radians(-78))

        if gun:
            gun.location = (-2.0, -24.0, 44.0 + gz * 0.4)
            gun.rotation_euler = (math.radians(8), math.radians(-12), math.radians(-42 + twist * 0.5))

    elif pose_name in ("aim", "fire"):
        recoil = 4.0 if pose_name == "fire" else 0.0
        arm.location = (0, 0, 30.0)
        b["mixamorig:Spine_02"].rotation_euler = (math.radians(14 - recoil), math.radians(18), 0)
        b["mixamorig:Head_05"].rotation_euler = (math.radians(-12 + recoil * 0.5), math.radians(-18), 0)

        b["mixamorig:LeftUpLeg_054"].rotation_euler = (math.radians(-28), 0, math.radians(-6))
        b["mixamorig:LeftLeg_055"].rotation_euler = (math.radians(44), 0, 0)
        b["mixamorig:RightUpLeg_059"].rotation_euler = (math.radians(22), 0, math.radians(8))
        b["mixamorig:RightLeg_060"].rotation_euler = (math.radians(24), 0, 0)

        b["mixamorig:RightArm_031"].rotation_euler = (math.radians(62), math.radians(-25), math.radians(-42))
        b["mixamorig:RightForeArm_032"].rotation_euler = (math.radians(30), 0, math.radians(-85))
        b["mixamorig:LeftArm_08"].rotation_euler = (math.radians(66), math.radians(25), math.radians(38))
        b["mixamorig:LeftForeArm_09"].rotation_euler = (math.radians(35), 0, math.radians(72))

        if gun:
            gun.location = (6.0, -26.0, 52.0 + recoil * 0.3)
            gun.rotation_euler = (math.radians(recoil), 0, math.radians(-175))

        if pose_name == "aim":
            set_hide_recursive(laser_grp, False)
            laser_grp.location = (0.06, -0.52, 0.52)
        else:
            set_hide_recursive(flash_grp, False)
            flash_grp.location = (0.06, -0.54, 0.54)

    elif pose_name in ("rpg_run", "rpg_aim", "rpg_fire"):
        crouch = 0.0 if pose_name == "rpg_run" else -4.0
        arm.location = (0, 0, 32.0 + crouch)
        b["mixamorig:Spine_02"].rotation_euler = (math.radians(12), math.radians(14), 0)
        b["mixamorig:Head_05"].rotation_euler = (math.radians(-10), math.radians(-14), 0)

        if pose_name == "rpg_run":
            b["mixamorig:LeftUpLeg_054"].rotation_euler = (math.radians(-34), 0, math.radians(-4))
            b["mixamorig:LeftLeg_055"].rotation_euler = (math.radians(48), 0, 0)
            b["mixamorig:RightUpLeg_059"].rotation_euler = (math.radians(24), 0, math.radians(4))
            b["mixamorig:RightLeg_060"].rotation_euler = (math.radians(22), 0, 0)
        else:
            b["mixamorig:LeftUpLeg_054"].rotation_euler = (math.radians(-38), 0, math.radians(-8))
            b["mixamorig:LeftLeg_055"].rotation_euler = (math.radians(58), 0, 0)
            b["mixamorig:RightUpLeg_059"].rotation_euler = (math.radians(24), 0, math.radians(10))
            b["mixamorig:RightLeg_060"].rotation_euler = (math.radians(32), 0, 0)

        b["mixamorig:RightArm_031"].rotation_euler = (math.radians(72), math.radians(-15), math.radians(-28))
        b["mixamorig:RightForeArm_032"].rotation_euler = (math.radians(25), 0, math.radians(-82))
        b["mixamorig:LeftArm_08"].rotation_euler = (math.radians(75), math.radians(20), math.radians(34))
        b["mixamorig:LeftForeArm_09"].rotation_euler = (math.radians(28), 0, math.radians(68))

        rpg.parent.location = (0.16, -0.06, 0.68 + crouch * 0.01)
        rpg.parent.rotation_euler = (math.radians(2), 0, math.radians(-6))

        if pose_name == "rpg_aim":
            set_hide_recursive(laser_grp, False)
            laser_grp.location = (0.18, -0.52, 0.64)
        elif pose_name == "rpg_fire":
            set_hide_recursive(flash_grp, False)
            flash_grp.location = (0.18, -0.68, 0.66)


def frame_camera_to_soldier():
    deps = bpy.context.evaluated_depsgraph_get()
    min_v = Vector((1e9, 1e9, 1e9))
    max_v = Vector((-1e9, -1e9, -1e9))
    for name in ["Object_83", "Object_84"]:
        obj = bpy.data.objects.get(name)
        if not obj:
            continue
        eval_obj = obj.evaluated_get(deps)
        for v in eval_obj.data.vertices:
            wc = eval_obj.matrix_world @ v.co
            min_v.x = min(min_v.x, wc.x); min_v.y = min(min_v.y, wc.y); min_v.z = min(min_v.z, wc.z)
            max_v.x = max(max_v.x, wc.x); max_v.y = max(max_v.y, wc.y); max_v.z = max(max_v.z, wc.z)
    h = max_v.z - min_v.z
    w = max_v.x - min_v.x
    cx = (min_v.x + max_v.x) * 0.5
    cz = (min_v.z + max_v.z) * 0.5
    cam = bpy.context.scene.camera
    cam.location = (cx, min_v.y - h * 2.2, cz)
    cam.data.clip_end = 500.0
    cam.data.ortho_scale = max(h, w) * 1.15
    return min_v, max_v, h


def main():
    arm, gun, rpg, flash_grp, laser_grp = setup_scene()

    renders = [
        ("run_0", "tex_enemy_soldier_run_0.png"),
        ("run_1", "tex_enemy_soldier_run_1.png"),
        ("run_2", "tex_enemy_soldier_run_2.png"),
        ("run_3", "tex_enemy_soldier_run_3.png"),
        ("run_0", "tex_enemy_soldier_realistic.png"),
        ("aim", "tex_enemy_soldier_aim.png"),
        ("fire", "tex_enemy_soldier_fire.png"),
        ("rpg_run", "tex_enemy_rpg_soldier.png"),
        ("rpg_aim", "tex_enemy_rpg_aim.png"),
        ("rpg_fire", "tex_enemy_rpg_fire.png"),
    ]

    for pose_name, fname in renders:
        set_pose(arm, gun, rpg, flash_grp, laser_grp, pose_name)
        bpy.context.view_layer.update()
        min_v, max_v, h = frame_camera_to_soldier()
        # Reposition gun/rpg/fx cleanly relative to soldier bounds (in world space, gun parent has 0.01 scale)
        if gun and not gun.hide_render:
            if pose_name.startswith("run_"):
                gun.location = (-0.02 * h * 100.0, (min_v.y - 0.06 * h) * 100.0, (min_v.z + h * 0.55) * 100.0)
                gun.rotation_euler = (math.radians(8), math.radians(-16), math.radians(-22))
            else:
                gun.location = (0.05 * h * 100.0, (min_v.y - 0.14 * h) * 100.0, (min_v.z + h * 0.65) * 100.0)
                gun.rotation_euler = (0, 0, math.radians(-92))
        if not rpg.hide_render:
            rpg.parent.location = (0.14 * h, min_v.y - 0.04 * h, min_v.z + h * 0.78)
            rpg.parent.scale = (h * 0.65, h * 0.65, h * 0.65)
        if not laser_grp.hide_render:
            laser_grp.scale = (h * 0.55, h * 0.55, h * 0.55)
            z_fx = h * (0.76 if pose_name.startswith("rpg_") else 0.65)
            laser_grp.location = (0.08 * h, min_v.y - 0.25 * h, min_v.z + z_fx)
        if not flash_grp.hide_render:
            flash_grp.scale = (h * 0.75, h * 0.75, h * 0.75)
            z_fx = h * (0.78 if pose_name.startswith("rpg_") else 0.65)
            flash_grp.location = (0.08 * h, min_v.y - 0.28 * h, min_v.z + z_fx)

        out_path = os.path.join(OUT_DIR, fname)
        bpy.context.scene.render.filepath = out_path
        bpy.ops.render.render(write_still=True)
        print(f"Rendered {pose_name} (h={h:.2f}) -> {fname}")


if __name__ == "__main__":
    main()
