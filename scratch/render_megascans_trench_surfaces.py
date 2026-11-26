import bpy
import math
import mathutils
import os

MEGASCANS_DIR = "/Users/kobujang/Desktop/cording/LAST_TRENCH/scratch/megascans"
OUT_DIR = "/Users/kobujang/Desktop/cording/LAST_TRENCH/assets/textures"


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 48
    scene.cycles.use_denoising = True
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    return scene


def setup_world(scene, strength=0.6):
    world = bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.35, 0.34, 0.32, 1.0)
        bg.inputs[1].default_value = strength


def add_sun(location, rotation_deg, energy=3.5, color=(1.0, 0.96, 0.90)):
    light_data = bpy.data.lights.new(name="Sun", type="SUN")
    light_data.energy = energy
    light_data.color = color
    light_data.angle = math.radians(18.0)
    light_obj = bpy.data.objects.new(name="Sun", object_data=light_data)
    bpy.context.collection.objects.link(light_obj)
    light_obj.location = location
    light_obj.rotation_euler = [math.radians(a) for a in rotation_deg]
    return light_obj


def add_ortho_camera(location, rotation_deg, ortho_scale):
    cam_data = bpy.data.cameras.new(name="OrthoCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = ortho_scale
    cam_data.clip_start = 0.05
    cam_data.clip_end = 50.0
    cam_obj = bpy.data.objects.new(name="OrthoCam", object_data=cam_data)
    bpy.context.collection.objects.link(cam_obj)
    cam_obj.location = location
    cam_obj.rotation_euler = [math.radians(a) for a in rotation_deg]
    bpy.context.scene.camera = cam_obj
    return cam_obj


def make_normal_override_mat(axis_mode="top"):
    mat = bpy.data.materials.new("NormalOverride")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    out = nodes.new("ShaderNodeOutputMaterial")
    emit = nodes.new("ShaderNodeEmission")
    geom = nodes.new("ShaderNodeNewGeometry")
    sep = nodes.new("ShaderNodeSeparateXYZ")
    comb = nodes.new("ShaderNodeCombineXYZ")
    mul = nodes.new("ShaderNodeVectorMath")
    mul.operation = "SCALE"
    mul.inputs["Scale"].default_value = 0.5
    add = nodes.new("ShaderNodeVectorMath")
    add.operation = "ADD"
    add.inputs[1].default_value = (0.5, 0.5, 0.5)

    links.new(geom.outputs["Normal"], sep.inputs["Vector"])
    if axis_mode == "top":
        links.new(sep.outputs["X"], comb.inputs["X"])
        links.new(sep.outputs["Y"], comb.inputs["Y"])
        links.new(sep.outputs["Z"], comb.inputs["Z"])
    else:
        # Front-facing (-Y toward camera): tangent X=X, Y=Z, Z=-Y
        inv_y = nodes.new("ShaderNodeMath")
        inv_y.operation = "MULTIPLY"
        inv_y.inputs[1].default_value = -1.0
        links.new(sep.outputs["Y"], inv_y.inputs[0])
        links.new(sep.outputs["X"], comb.inputs["X"])
        links.new(sep.outputs["Z"], comb.inputs["Y"])
        links.new(inv_y.outputs["Value"], comb.inputs["Z"])

    links.new(comb.outputs["Vector"], mul.inputs[0])
    links.new(mul.outputs["Vector"], add.inputs[0])
    links.new(add.outputs["Vector"], emit.inputs["Color"])
    links.new(emit.outputs["Emission"], out.inputs["Surface"])
    return mat


def render_color_and_normal(scene, color_path, normal_path, res_x, res_y, axis_mode="top"):
    scene.render.resolution_x = res_x
    scene.render.resolution_y = res_y
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.film_transparent = False

    # Color pass
    scene.view_layers[0].material_override = None
    scene.render.filepath = color_path
    bpy.ops.render.render(write_still=True)

    # Normal pass via material override (tangent-space RGB)
    prev_samples = scene.cycles.samples
    scene.cycles.samples = 16
    scene.view_layers[0].material_override = make_normal_override_mat(axis_mode)
    scene.render.filepath = normal_path
    bpy.ops.render.render(write_still=True)
    scene.view_layers[0].material_override = None
    scene.cycles.samples = prev_samples


def render_duckboard_floor():
    scene = reset_scene()
    setup_world(scene, strength=0.55)
    add_sun((0, 0, 5), (25, 15, 0), energy=3.8)
    add_sun((0, 0, 5), (-20, -15, 0), energy=1.6, color=(0.85, 0.90, 1.0))

    # Muddy trench ground plane underneath
    bpy.ops.mesh.primitive_plane_add(size=8.0, location=(0, 0, -0.01))
    mud = bpy.context.active_object
    mat = bpy.data.materials.new("WetMud")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 14.0
    noise.inputs["Detail"].default_value = 8.0
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (0.045, 0.036, 0.028, 1.0)
    ramp.color_ramp.elements[1].color = (0.095, 0.075, 0.056, 1.0)
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.72
    mud.data.materials.append(mat)

    # Import duckboard GLB 3 times so hierarchy/transforms are preserved cleanly
    glb_path = os.path.join(MEGASCANS_DIR, "military_trenches_equipment_duckboard_wood_l_yd0kcdxga_mid.glb")
    for y_off in [-0.72, 0.0, 0.72]:
        before = set(bpy.context.scene.objects)
        bpy.ops.import_scene.gltf(filepath=glb_path)
        new_objs = [o for o in bpy.context.scene.objects if o not in before and o.parent is None]
        for o in new_objs:
            o.location = (0.0, y_off, 0.0)

    add_ortho_camera((0.0, 0.0, 4.0), (0.0, 0.0, 0.0), ortho_scale=2.2)
    render_color_and_normal(
        scene,
        os.path.join(OUT_DIR, "tex_trench_duckboard.png"),
        os.path.join(OUT_DIR, "tex_trench_duckboard_normal.png"),
        1024,
        1024,
        axis_mode="top",
    )


def render_wall_mixed():
    scene = reset_scene()
    setup_world(scene, strength=0.65)
    add_sun((0, -5, 3), (65, 0, 15), energy=3.8)
    add_sun((0, -5, 3), (50, 0, -25), energy=1.5, color=(0.85, 0.90, 1.0))

    glb_path = os.path.join(MEGASCANS_DIR, "military_trenches_wall_mixed_ydxlegi_mid.glb")
    bpy.ops.import_scene.gltf(filepath=glb_path)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    pts = [o.matrix_world @ mathutils.Vector(c) for o in meshes for c in o.bound_box]
    cx = (min(p.x for p in pts) + max(p.x for p in pts)) * 0.5
    cz = (min(p.z for p in pts) + max(p.z for p in pts)) * 0.5
    w = max(p.x for p in pts) - min(p.x for p in pts)

    # Dark earth backing behind any gaps
    bpy.ops.mesh.primitive_plane_add(size=6.0, location=(cx, 0.35, cz), rotation=(math.radians(90), 0, 0))
    back = bpy.context.active_object
    bmat = bpy.data.materials.new("BackEarth")
    bmat.use_nodes = True
    bmat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.05, 0.04, 0.03, 1.0)
    back.data.materials.append(bmat)

    add_ortho_camera((cx, -4.0, cz), (90.0, 0.0, 0.0), ortho_scale=w * 0.88)
    render_color_and_normal(
        scene,
        os.path.join(OUT_DIR, "tex_trench_wall_mixed.png"),
        os.path.join(OUT_DIR, "tex_trench_wall_mixed_normal.png"),
        1024,
        512,
        axis_mode="front",
    )


def render_sandbag_barrier():
    scene = reset_scene()
    setup_world(scene, strength=0.65)
    add_sun((0, -5, 4), (55, 0, 20), energy=3.8)
    add_sun((0, -5, 4), (45, 0, -25), energy=1.6, color=(0.85, 0.90, 1.0))

    glb_path = os.path.join(MEGASCANS_DIR, "military_trenches_barrier_sandbag_canvas_03_ydymfdzga_mid.glb")
    bpy.ops.import_scene.gltf(filepath=glb_path)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    pts = [o.matrix_world @ mathutils.Vector(c) for o in meshes for c in o.bound_box]
    cx = (min(p.x for p in pts) + max(p.x for p in pts)) * 0.5
    cz = (min(p.z for p in pts) + max(p.z for p in pts)) * 0.5
    w = max(p.x for p in pts) - min(p.x for p in pts)

    bpy.ops.mesh.primitive_plane_add(size=8.0, location=(cx, 0.48, cz), rotation=(math.radians(90), 0, 0))
    back = bpy.context.active_object
    bmat = bpy.data.materials.new("BackBag")
    bmat.use_nodes = True
    bmat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.14, 0.12, 0.09, 1.0)
    back.data.materials.append(bmat)

    add_ortho_camera((cx, -4.0, cz), (90.0, 0.0, 0.0), ortho_scale=w * 0.85)
    render_color_and_normal(
        scene,
        os.path.join(OUT_DIR, "tex_sandbag_stacked.png"),
        os.path.join(OUT_DIR, "tex_sandbag_stacked_normal.png"),
        1024,
        256,
        axis_mode="front",
    )


if __name__ == "__main__":
    render_duckboard_floor()
    print("MEGASCANS_DUCKBOARD_DONE")
