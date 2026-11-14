class_name ProceduralAssets
extends RefCounted

## Utility helper to create standard prototype materials and meshes with collisions
static func create_prototype_material(albedo_color: Color, roughness: float = 0.8) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo_color
	mat.roughness = roughness
	return mat

static func create_box_static_body(size: Vector3, color: Color, collision_layer: int = 1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = collision_layer
	body.collision_mask = 0
	
	var mi := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	box_mesh.material = create_prototype_material(color)
	mi.mesh = box_mesh
	body.add_child(mi)
	
	var cs := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	cs.shape = box_shape
	body.add_child(cs)
	
	return body
