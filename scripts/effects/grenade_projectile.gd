class_name GrenadeProjectile
extends Node3D

@export var blast_radius: float = 6.5
@export var damage: float = 250.0

var velocity: Vector3 = Vector3.ZERO
var gravity: float = 16.0
var max_fuse_time: float = 1.8
var timer: float = 0.0
var has_exploded: bool = false

var explosion_scene: PackedScene = preload("res://scenes/effects/explosion_effect.tscn")
var grenade_mesh: MeshInstance3D

func setup(origin: Vector3, throw_dir: Vector3, throw_power: float = 30.0, radius: float = 6.5, dmg: float = 250.0) -> void:
	if is_inside_tree():
		global_position = origin
	else:
		position = origin
	blast_radius = radius
	damage = dmg
	# Parabolic throw: forward + slight upward arc
	var forward_dir := Vector3(throw_dir.x, 0.0, throw_dir.z).normalized()
	velocity = forward_dir * throw_power + Vector3(0.0, 4.5, 0.0)

func _ready() -> void:
	_create_visual_mesh()
	AudioManager.play_sound("click", 0.04, 1.0) # Pin release click

func _create_visual_mesh() -> void:
	grenade_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.26
	grenade_mesh.mesh = sphere
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.24, 0.32, 0.20)
	mat.metallic = 0.3
	mat.roughness = 0.6
	grenade_mesh.material_override = mat
	add_child(grenade_mesh)
	
	# Metal fuze top
	var fuze := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.035
	cyl.bottom_radius = 0.035
	cyl.height = 0.08
	fuze.mesh = cyl
	fuze.position.y = 0.14
	
	var mat_fuze := StandardMaterial3D.new()
	mat_fuze.albedo_color = Color(0.6, 0.65, 0.7)
	mat_fuze.metallic = 0.9
	fuze.material_override = mat_fuze
	add_child(fuze)

func _process(delta: float) -> void:
	if has_exploded:
		return
		
	timer += delta
	velocity.y -= gravity * delta
	global_position += velocity * delta
	
	# Tumbling rotation
	rotate_x(delta * 9.0)
	rotate_z(delta * 7.0)
	
	# Detonate if reaches ground level (Y <= 0.2) or fuse timer expires
	if global_position.y <= 0.2 or timer >= max_fuse_time:
		explode(Vector3(global_position.x, maxf(0.1, global_position.y), global_position.z))

func explode(hit_pos: Vector3) -> void:
	if has_exploded:
		return
	has_exploded = true
	
	# Splash damage to enemies
	var space := get_world_3d().direct_space_state if is_inside_tree() and get_world_3d() else null
	if space:
		var sphere := SphereShape3D.new()
		sphere.radius = blast_radius
		var shape_q := PhysicsShapeQueryParameters3D.new()
		shape_q.shape = sphere
		shape_q.transform = Transform3D(Basis(), hit_pos)
		shape_q.collision_mask = 4 | 8 # Enemies and destructibles
		shape_q.collide_with_areas = true
		shape_q.collide_with_bodies = true
		var hits := space.intersect_shape(shape_q, 16)
		for h in hits:
			var col = h.get("collider")
			if col and col.has_method("apply_damage"):
				if col is EnemyBase:
					col.apply_damage(damage, "explosive")
				else:
					col.apply_damage(damage)
			elif col and col.get_parent() and col.get_parent().has_method("apply_damage"):
				var p_node: Node = col.get_parent()
				if p_node is EnemyBase:
					p_node.apply_damage(damage, "explosive")
				else:
					p_node.apply_damage(damage)
				
	if explosion_scene:
		var exp_node = explosion_scene.instantiate()
		if get_parent():
			get_parent().add_child(exp_node)
		if exp_node.has_method("setup"):
			exp_node.setup(hit_pos, blast_radius)
		
	queue_free()
