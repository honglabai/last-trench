import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix

OUT_DIR = "/Users/kobujang/Desktop/cording/LAST_TRENCH/assets/textures"
MODEL_DIR = "/Users/kobujang/Desktop/cording/LAST_TRENCH/assets/models"
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(MODEL_DIR, exist_ok=True)


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def set_hide_recursive(obj, hide):
    obj.hide_render = hide
    obj.hide_viewport = hide
    for ch in obj.children:
        set_hide_recursive(ch, hide)


def make_camo_material(name):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()

    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.85

    tex_coord = nt.nodes.new("ShaderNodeTexCoord")
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 11.0
    noise.inputs["Detail"].default_value = 6.0
    noise.inputs["Roughness"].default_value = 0.65

    ramp = nt.nodes.new("ShaderNodeValToRGB")
    elems = ramp.color_ramp.elements
    elems[0].position = 0.34
    elems[0].color = (0.06, 0.08, 0.05, 1.0)
    elems[1].position = 0.68
    elems[1].color = (0.18, 0.21, 0.14, 1.0)
    e2 = ramp.color_ramp.elements.new(0.50)
    e2.color = (0.11, 0.13, 0.09, 1.0)

    nt.links.new(tex_coord.outputs["Object"], noise.inputs["Vector"])
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat


def make_pbr_material(name, color, roughness=0.6, metallic=0.0, emission=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission is not None and emission_strength > 0.0:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat


def create_empty(name, loc=(0, 0, 0), parent=None):
    empty = bpy.data.objects.new(name, None)
    empty.location = loc
    bpy.context.collection.objects.link(empty)
    if parent:
        empty.parent = parent
    return empty


def add_box(name, size, loc=(0, 0, 0), rot=(0, 0, 0), mat=None, parent=None, bevel=0.01):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    if bevel > 0.0:
        bmesh.ops.bevel(bm, geom=bm.edges[:], offset=bevel, segments=2, affect='EDGES')
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    obj.location = loc
    obj.rotation_euler = rot
    if mat:
        obj.data.materials.append(mat)
    bpy.context.collection.objects.link(obj)
    if parent:
        obj.parent = parent
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def add_tapered_limb(name, r_top, r_bot, depth, segments=16, loc=(0, 0, 0), rot=(0, 0, 0), mat=None, parent=None):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cone(
        bm,
        cap_ends=True,
        cap_tris=False,
        segments=segments,
        radius1=r_bot,
        radius2=r_top,
        depth=depth,
    )
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    obj.location = loc
    obj.rotation_euler = rot
    if mat:
        obj.data.materials.append(mat)
    bpy.context.collection.objects.link(obj)
    if parent:
        obj.parent = parent
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def add_sphere(name, radius, scale=(1, 1, 1), loc=(0, 0, 0), rot=(0, 0, 0), mat=None, parent=None):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=20, v_segments=14, radius=radius)
    bmesh.ops.scale(bm, vec=scale, verts=bm.verts)
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    obj.location = loc
    obj.rotation_euler = rot
    if mat:
        obj.data.materials.append(mat)
    bpy.context.collection.objects.link(obj)
    if parent:
        obj.parent = parent
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def aim_limb_segment(segment_obj, start_world, end_world):
    """Positions and orients a limb segment (local -Z axis) from start_world to end_world."""
    vec = end_world - start_world
    length = vec.length
    if length < 0.001:
        return
    # Compute rotation so local -Z points along vec
    quat = vec.normalized().to_track_quat('-Z', 'Y')
    segment_obj.matrix_world = Matrix.Translation(start_world) @ quat.to_matrix().to_4x4()


def solve_two_bone_ik(shoulder_pos, hand_target, upper_len, lower_len, elbow_hint_dir):
    """Returns elbow world position for a 2-bone arm chain."""
    to_hand = hand_target - shoulder_pos
    dist = to_hand.length
    max_reach = upper_len + lower_len - 0.01
    if dist > max_reach:
        to_hand = to_hand.normalized() * max_reach
        dist = max_reach
    if dist < 0.05:
        dist = 0.05

    cos_a = (upper_len**2 + dist**2 - lower_len**2) / (2.0 * upper_len * dist)
    cos_a = max(-1.0, min(1.0, cos_a))
    sin_a = math.sqrt(max(0.0, 1.0 - cos_a**2))

    fwd = to_hand.normalized()
    # Orthogonalize hint direction
    ortho_hint = (elbow_hint_dir - fwd * elbow_hint_dir.dot(fwd))
    if ortho_hint.length < 0.001:
        ortho_hint = Vector((0, 0, -1))
    else:
        ortho_hint.normalize()

    elbow_pos = shoulder_pos + fwd * (upper_len * cos_a) + ortho_hint * (upper_len * sin_a)
    return elbow_pos


def build_soldier():
    clear_scene()

    mat_camo = make_camo_material("Mat_Camo")
    mat_vest = make_pbr_material("Mat_Vest", (0.10, 0.11, 0.09), roughness=0.78)
    mat_pouch = make_pbr_material("Mat_Pouch", (0.14, 0.15, 0.11), roughness=0.72)
    mat_helmet = make_pbr_material("Mat_Helmet", (0.15, 0.17, 0.14), roughness=0.48, metallic=0.12)
    mat_goggles = make_pbr_material("Mat_Goggles", (0.04, 0.03, 0.02), roughness=0.06, metallic=0.55)
    mat_balaclava = make_pbr_material("Mat_Balaclava", (0.05, 0.05, 0.055), roughness=0.88)
    mat_gear = make_pbr_material("Mat_Gear", (0.04, 0.04, 0.045), roughness=0.58)
    mat_gun_metal = make_pbr_material("Mat_GunMetal", (0.05, 0.055, 0.06), roughness=0.32, metallic=0.88)
    mat_gun_poly = make_pbr_material("Mat_GunPoly", (0.035, 0.035, 0.04), roughness=0.65)
    mat_flash_outer = make_pbr_material(
        "Mat_MuzzleFlashOuter",
        (1.0, 0.42, 0.05),
        roughness=0.2,
        emission=(1.0, 0.38, 0.04),
        emission_strength=14.0,
    )
    mat_flash_core = make_pbr_material(
        "Mat_MuzzleFlashCore",
        (1.0, 0.88, 0.35),
        roughness=0.1,
        emission=(1.0, 0.86, 0.30),
        emission_strength=26.0,
    )
    mat_laser = make_pbr_material(
        "Mat_Laser",
        (1.0, 0.05, 0.05),
        roughness=0.1,
        emission=(1.0, 0.06, 0.04),
        emission_strength=16.0,
    )

    root = create_empty("SoldierRoot", (0, 0, 0))

    # Pelvis
    pelvis = create_empty("Pelvis", (0, 0, 0.93), root)
    add_box("PelvisBase", (0.33, 0.21, 0.17), (0, 0, 0), mat=mat_camo, parent=pelvis, bevel=0.03)
    add_box("TacticalBelt", (0.35, 0.23, 0.065), (0, 0, 0.045), mat=mat_gear, parent=pelvis, bevel=0.01)
    add_box("BeltBuckle", (0.07, 0.04, 0.065), (0, -0.115, 0.045), mat=mat_gun_metal, parent=pelvis, bevel=0.005)
    add_box("DropHolster", (0.06, 0.12, 0.18), (0.185, -0.02, -0.11), mat=mat_gear, parent=pelvis, bevel=0.01)

    # Legs
    def build_leg(side_name, x_sign):
        hip = create_empty(f"{side_name}Hip", (x_sign * 0.105, 0, -0.04), pelvis)
        add_tapered_limb(f"{side_name}Thigh", 0.095, 0.078, 0.44, 16, (0, 0, -0.22), mat=mat_camo, parent=hip)
        knee = create_empty(f"{side_name}Knee", (0, 0, -0.44), hip)
        add_box(f"{side_name}KneePad", (0.115, 0.11, 0.11), (0, -0.055, 0), mat=mat_gear, parent=knee, bevel=0.022)
        add_tapered_limb(f"{side_name}Shin", 0.082, 0.064, 0.40, 16, (0, 0, -0.20), mat=mat_camo, parent=knee)
        add_box(f"{side_name}Boot", (0.11, 0.24, 0.125), (0, -0.045, -0.40), mat=mat_gear, parent=knee, bevel=0.025)
        return hip, knee

    l_hip, l_knee = build_leg("Left", -1.0)
    r_hip, r_knee = build_leg("Right", 1.0)

    # Torso
    torso = create_empty("Torso", (0, 0, 0.08), pelvis)
    add_box("TorsoBase", (0.35, 0.21, 0.48), (0, 0, 0.24), mat=mat_camo, parent=torso, bevel=0.04)
    add_box("PlateCarrier", (0.33, 0.25, 0.39), (0, -0.01, 0.25), mat=mat_vest, parent=torso, bevel=0.025)
    add_box("VestCollar", (0.20, 0.18, 0.07), (0, 0, 0.46), mat=mat_vest, parent=torso, bevel=0.015)
    for i, px in enumerate([-0.095, 0.0, 0.095]):
        add_box(f"MagPouch_{i}", (0.072, 0.06, 0.14), (px, -0.145, 0.16), mat=mat_pouch, parent=torso, bevel=0.01)
    add_box("AdminPouch", (0.16, 0.045, 0.085), (0, -0.14, 0.31), mat=mat_pouch, parent=torso, bevel=0.008)
    add_box("LeftShoulderPad", (0.085, 0.16, 0.13), (-0.205, 0, 0.40), (0, 0.22, 0), mat=mat_vest, parent=torso, bevel=0.02)
    add_box("RightShoulderPad", (0.085, 0.16, 0.13), (0.205, 0, 0.40), (0, -0.22, 0), mat=mat_vest, parent=torso, bevel=0.02)
    add_box("Backpack", (0.26, 0.14, 0.34), (0, 0.16, 0.26), mat=mat_pouch, parent=torso, bevel=0.02)
    add_tapered_limb("RadioAntenna", 0.004, 0.007, 0.38, 8, (-0.11, 0.18, 0.56), (0.08, -0.05, 0), mat=mat_gun_metal, parent=torso)

    # Head & Helmet (lowered cleanly into collar)
    head = create_empty("HeadGroup", (0, 0, 0.46), torso)
    add_tapered_limb("Neck", 0.064, 0.074, 0.12, 14, (0, 0, 0.04), mat=mat_balaclava, parent=head)
    add_sphere("HeadBalaclava", 0.102, (0.92, 1.02, 1.12), (0, -0.01, 0.13), mat=mat_balaclava, parent=head)
    add_sphere("HelmetShell", 0.126, (1.03, 1.10, 0.92), (0, 0.0, 0.175), mat=mat_helmet, parent=head)
    add_box("HelmetRim", (0.235, 0.255, 0.032), (0, -0.005, 0.14), mat=mat_helmet, parent=head, bevel=0.01)
    add_box("NVGMount", (0.048, 0.03, 0.052), (0, -0.132, 0.185), mat=mat_gun_metal, parent=head, bevel=0.005)
    add_box("GogglesFrame", (0.162, 0.058, 0.062), (0, -0.102, 0.13), mat=mat_gear, parent=head, bevel=0.01)
    add_box("GogglesLens", (0.148, 0.02, 0.046), (0, -0.128, 0.13), mat=mat_goggles, parent=head, bevel=0.006)
    add_tapered_limb("EarCupL", 0.042, 0.042, 0.035, 12, (-0.115, 0.0, 0.11), (0, math.pi / 2, 0), mat=mat_gear, parent=head)
    add_tapered_limb("EarCupR", 0.042, 0.042, 0.035, 12, (0.115, 0.0, 0.11), (0, math.pi / 2, 0), mat=mat_gear, parent=head)

    # Shoulder socket markers (parented to torso so we know exact world coords)
    l_sh_socket = create_empty("L_Sh_Socket", (-0.21, 0.0, 0.41), torso)
    r_sh_socket = create_empty("R_Sh_Socket", (0.21, 0.0, 0.41), torso)

    # Arms as world-space IK segments (upper + lower + glove)
    def make_arm_meshes(side_name):
        upper = create_empty(f"{side_name}_UpperRoot", (0, 0, 0), root)
        add_sphere(f"{side_name}_Deltoid", 0.068, (1, 1, 1), (0, 0, 0), mat=mat_camo, parent=upper)
        add_tapered_limb(f"{side_name}_UpperMesh", 0.066, 0.056, 0.29, 14, (0, 0, -0.145), mat=mat_camo, parent=upper)

        lower = create_empty(f"{side_name}_LowerRoot", (0, 0, 0), root)
        add_sphere(f"{side_name}_ElbowPad", 0.058, (1, 1, 1), (0, 0, 0), mat=mat_gear, parent=lower)
        add_tapered_limb(f"{side_name}_LowerMesh", 0.056, 0.046, 0.27, 14, (0, 0, -0.135), mat=mat_camo, parent=lower)
        add_box(f"{side_name}_Glove", (0.072, 0.090, 0.085), (0, 0, -0.275), mat=mat_gear, parent=lower, bevel=0.015)
        return upper, lower

    l_upper, l_lower = make_arm_meshes("Left")
    r_upper, r_lower = make_arm_meshes("Right")

    # Weapon (AK-12 Tactical Assault Rifle)
    wpn = create_empty("Weapon_AK12", (0.12, -0.24, 0.34), torso)
    add_box("AK_Receiver", (0.048, 0.30, 0.085), (0, -0.06, 0.0), mat=mat_gun_metal, parent=wpn, bevel=0.005)
    add_box("AK_TopRail", (0.036, 0.28, 0.022), (0, -0.06, 0.05), mat=mat_gun_metal, parent=wpn, bevel=0.003)
    add_box("AK_OpticBase", (0.036, 0.07, 0.035), (0, -0.03, 0.072), mat=mat_gun_metal, parent=wpn, bevel=0.003)
    add_tapered_limb("AK_OpticTube", 0.022, 0.022, 0.08, 14, (0, -0.03, 0.098), (math.pi / 2, 0, 0), mat=mat_gun_metal, parent=wpn)
    add_box("AK_Handguard", (0.050, 0.24, 0.070), (0, -0.32, 0.005), mat=mat_gun_poly, parent=wpn, bevel=0.006)
    add_tapered_limb("AK_Barrel", 0.012, 0.012, 0.32, 12, (0, -0.52, 0.01), (math.pi / 2, 0, 0), mat=mat_gun_metal, parent=wpn)
    add_tapered_limb("AK_GasTube", 0.010, 0.010, 0.16, 10, (0, -0.44, 0.035), (math.pi / 2, 0, 0), mat=mat_gun_metal, parent=wpn)
    add_tapered_limb("AK_MuzzleBrake", 0.018, 0.018, 0.065, 12, (0, -0.68, 0.01), (math.pi / 2, 0, 0), mat=mat_gun_metal, parent=wpn)
    add_box("AK_Stock", (0.038, 0.24, 0.10), (0, 0.20, -0.01), mat=mat_gun_poly, parent=wpn, bevel=0.006)
    add_box("AK_Grip", (0.036, 0.055, 0.12), (0, 0.04, -0.08), (-0.28, 0, 0), mat=mat_gun_poly, parent=wpn, bevel=0.005)
    add_box("AK_MagTop", (0.034, 0.072, 0.12), (0, -0.14, -0.09), (0.18, 0, 0), mat=mat_gun_poly, parent=wpn, bevel=0.004)
    add_box("AK_MagBot", (0.034, 0.070, 0.11), (0, -0.17, -0.19), (0.36, 0, 0), mat=mat_gun_poly, parent=wpn, bevel=0.004)

    # Hand grip targets parented to weapon!
    r_grip_target = create_empty("R_Grip_Target", (0.0, 0.04, -0.06), wpn)
    l_grip_target = create_empty("L_Grip_Target", (0.0, -0.32, -0.02), wpn)

    # Tactical Laser Box & Dot
    add_box("AK_LaserBox", (0.028, 0.075, 0.030), (0.038, -0.35, 0.015), mat=mat_gear, parent=wpn, bevel=0.003)
    laser_dot = add_sphere("AK_LaserEmitter", 0.012, (1, 1, 1), (0.038, -0.39, 0.015), mat=mat_laser, parent=wpn)
    # Thin glowing red laser beam for aim pose
    laser_beam = add_tapered_limb("AK_LaserBeam", 0.003, 0.003, 1.4, 8, (0.038, -1.09, 0.015), (math.pi / 2, 0, 0), mat=mat_laser, parent=wpn)

    # Crisp Starburst Muzzle Flash Group at muzzle tip
    flash_grp = create_empty("MuzzleFlashGroup", (0, -0.72, 0.01), wpn)
    add_tapered_limb("FlashCoreJet", 0.055, 0.008, 0.24, 12, (0, -0.12, 0), (math.pi / 2, 0, 0), mat=mat_flash_core, parent=flash_grp)
    for angle in [0, 45, 90, 135]:
        rad = math.radians(angle)
        add_tapered_limb(
            f"FlashStarA_{angle}",
            0.003,
            0.035,
            0.22,
            8,
            (0, -0.02, 0),
            (0, rad, 0),
            mat=mat_flash_outer,
            parent=flash_grp,
        )

    flash_light_data = bpy.data.lights.new(name="MuzzleLight", type='POINT')
    flash_light_data.energy = 140.0
    flash_light_data.color = (1.0, 0.52, 0.12)
    flash_light_data.shadow_soft_size = 0.2
    flash_light = bpy.data.objects.new(name="MuzzleLight", object_data=flash_light_data)
    flash_light.location = (0, -0.16, 0.04)
    bpy.context.collection.objects.link(flash_light)
    flash_light.parent = flash_grp

    # Camera framed cleanly around 1.8m tall soldier
    cam_data = bpy.data.cameras.new(name="RenderCam")
    cam_data.lens = 58.0
    cam_obj = bpy.data.objects.new("RenderCam", cam_data)
    cam_obj.location = (0.0, -3.55, 0.94)
    cam_obj.rotation_euler = (math.radians(90.0), 0.0, 0.0)
    bpy.context.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj

    # Lighting
    key_data = bpy.data.lights.new("KeyLight", type='AREA')
    key_data.energy = 280.0
    key_data.size = 2.5
    key_data.color = (0.95, 0.98, 1.0)
    key_obj = bpy.data.objects.new("KeyLight", key_data)
    key_obj.location = (-2.2, -3.2, 2.8)
    key_obj.rotation_euler = (math.radians(52), 0, math.radians(-35))
    bpy.context.collection.objects.link(key_obj)

    rim_data = bpy.data.lights.new("RimLight", type='AREA')
    rim_data.energy = 240.0
    rim_data.size = 2.0
    rim_data.color = (1.0, 0.85, 0.65)
    rim_obj = bpy.data.objects.new("RimLight", rim_data)
    rim_obj.location = (2.0, 2.2, 2.4)
    rim_obj.rotation_euler = (math.radians(125), 0, math.radians(38))
    bpy.context.collection.objects.link(rim_obj)

    fill_data = bpy.data.lights.new("FillLight", type='AREA')
    fill_data.energy = 100.0
    fill_data.size = 3.0
    fill_data.color = (0.78, 0.86, 1.0)
    fill_obj = bpy.data.objects.new("FillLight", fill_data)
    fill_obj.location = (2.4, -2.6, 1.1)
    fill_obj.rotation_euler = (math.radians(82), 0, math.radians(40))
    bpy.context.collection.objects.link(fill_obj)

    world = bpy.data.worlds.new("StudioWorld")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (0.14, 0.16, 0.18, 1.0)
    bg.inputs["Strength"].default_value = 0.45
    bpy.context.scene.world = world

    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'

    return {
        "pelvis": pelvis,
        "torso": torso,
        "head": head,
        "l_hip": l_hip,
        "l_knee": l_knee,
        "r_hip": r_hip,
        "r_knee": r_knee,
        "l_sh_socket": l_sh_socket,
        "r_sh_socket": r_sh_socket,
        "l_upper": l_upper,
        "l_lower": l_lower,
        "r_upper": r_upper,
        "r_lower": r_lower,
        "wpn": wpn,
        "r_grip_target": r_grip_target,
        "l_grip_target": l_grip_target,
        "flash_grp": flash_grp,
        "laser_dot": laser_dot,
        "laser_beam": laser_beam,
    }


def apply_arm_ik(parts):
    bpy.context.view_layer.update()

    # Right arm (pistol grip)
    r_sh = parts["r_sh_socket"].matrix_world.translation
    r_hand = parts["r_grip_target"].matrix_world.translation
    r_elbow = solve_two_bone_ik(r_sh, r_hand, 0.29, 0.27, Vector((0.35, 0.2, -0.8)))
    aim_limb_segment(parts["r_upper"], r_sh, r_elbow)
    aim_limb_segment(parts["r_lower"], r_elbow, r_hand)

    # Left arm (handguard)
    l_sh = parts["l_sh_socket"].matrix_world.translation
    l_hand = parts["l_grip_target"].matrix_world.translation
    l_elbow = solve_two_bone_ik(l_sh, l_hand, 0.29, 0.27, Vector((-0.35, 0.2, -0.8)))
    aim_limb_segment(parts["l_upper"], l_sh, l_elbow)
    aim_limb_segment(parts["l_lower"], l_elbow, l_hand)


def set_pose(parts, pose_name):
    parts["pelvis"].location = (0, 0, 0.93)
    parts["torso"].rotation_euler = (0, 0, 0)
    parts["head"].rotation_euler = (0, 0, 0)
    parts["l_hip"].rotation_euler = (0, 0, 0)
    parts["l_knee"].rotation_euler = (0, 0, 0)
    parts["r_hip"].rotation_euler = (0, 0, 0)
    parts["r_knee"].rotation_euler = (0, 0, 0)

    if pose_name == "advance":
        # Patrol / Advancing stride, rifle diagonally across chest
        parts["torso"].rotation_euler = (math.radians(6), 0, math.radians(-10))
        parts["head"].rotation_euler = (math.radians(-4), 0, math.radians(10))
        parts["l_hip"].rotation_euler = (math.radians(-18), 0, math.radians(-4))
        parts["l_knee"].rotation_euler = (math.radians(22), 0, 0)
        parts["r_hip"].rotation_euler = (math.radians(14), 0, math.radians(4))
        parts["r_knee"].rotation_euler = (math.radians(10), 0, 0)

        parts["wpn"].location = (-0.01, -0.22, 0.24)
        parts["wpn"].rotation_euler = (math.radians(-14), math.radians(-8), math.radians(46))

        set_hide_recursive(parts["flash_grp"], True)
        set_hide_recursive(parts["laser_dot"], True)
        set_hide_recursive(parts["laser_beam"], True)

    elif pose_name == "aim":
        # Braced combat crouch aiming straight at player with red laser sight
        parts["pelvis"].location = (0, 0, 0.83)
        parts["torso"].rotation_euler = (math.radians(14), 0, math.radians(18))
        parts["head"].rotation_euler = (math.radians(-10), 0, math.radians(-18))
        parts["l_hip"].rotation_euler = (math.radians(-30), 0, math.radians(-8))
        parts["l_knee"].rotation_euler = (math.radians(46), 0, 0)
        parts["r_hip"].rotation_euler = (math.radians(22), 0, math.radians(10))
        parts["r_knee"].rotation_euler = (math.radians(24), 0, 0)

        parts["wpn"].location = (0.11, -0.23, 0.36)
        parts["wpn"].rotation_euler = (math.radians(-2), 0, math.radians(-18))

        set_hide_recursive(parts["flash_grp"], True)
        set_hide_recursive(parts["laser_dot"], False)
        set_hide_recursive(parts["laser_beam"], False)

    elif pose_name == "fire":
        # Firing pose with recoil kick & crisp starburst muzzle flash
        parts["pelvis"].location = (0, 0, 0.84)
        parts["torso"].rotation_euler = (math.radians(8), 0, math.radians(16))
        parts["head"].rotation_euler = (math.radians(-6), 0, math.radians(-16))
        parts["l_hip"].rotation_euler = (math.radians(-28), 0, math.radians(-8))
        parts["l_knee"].rotation_euler = (math.radians(42), 0, 0)
        parts["r_hip"].rotation_euler = (math.radians(20), 0, math.radians(10))
        parts["r_knee"].rotation_euler = (math.radians(22), 0, 0)

        parts["wpn"].location = (0.11, -0.21, 0.38)
        parts["wpn"].rotation_euler = (math.radians(4), 0, math.radians(-16))

        set_hide_recursive(parts["flash_grp"], False)
        set_hide_recursive(parts["laser_dot"], False)
        set_hide_recursive(parts["laser_beam"], True)

    apply_arm_ik(parts)


def main():
    parts = build_soldier()

    blend_path = os.path.join(MODEL_DIR, "enemy_soldier.blend")
    set_pose(parts, "aim")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"Saved Blender model: {blend_path}")

    poses = [
        ("advance", os.path.join(OUT_DIR, "tex_enemy_soldier_realistic.png")),
        ("aim", os.path.join(OUT_DIR, "tex_enemy_soldier_aim.png")),
        ("fire", os.path.join(OUT_DIR, "tex_enemy_soldier_fire.png")),
    ]

    for pose_name, out_path in poses:
        set_pose(parts, pose_name)
        bpy.context.scene.render.filepath = out_path
        bpy.ops.render.render(write_still=True)
        print(f"Rendered {pose_name} -> {out_path}")


if __name__ == "__main__":
    main()
