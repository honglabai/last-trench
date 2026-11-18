class_name RocketProjectile
extends Node3D

@export var speed: float = 68.0

var target_position: Vector3 = Vector3.ZERO
var travel_direction: Vector3 = Vector3.FORWARD
var total_distance: float = 0.0
var distance_traveled: float = 0.0
var blast_radius: float = 7.0
var damage: float = 220.0
var has_exploded: bool = false
var is_guided: bool = false
var target_node: Node3D = null
var homing_turn_rate: float = 7.5

var explosion_scene: PackedScene = preload("res://scenes/effects/explosion_effect.tscn")
var smoke_timer: float = 0.0

var rocket_root: Node3D
var exhaust_flame: MeshInstance3D

func setup(origin: Vector3, destination: Vector3, flight_speed: float = 68.0, radius: float = 7.0, dmg_amount: float = 220.0, guided: bool = false, locked_target: Node3D = null) -> void:
	if is_inside_tree():
		global_position = origin
	else:
		position = origin
	target_position = destination
	speed = flight_speed
	blast_radius = radius
	damage = dmg_amount
	is_guided = guided
	target_node = locked_target
	
	var diff := destination - origin
	total_distance = diff.length()
	if total_distance > 0.001:
		travel_direction = diff.normalized()
		var up_vec := Vector3.UP
		if abs(travel_direction.dot(Vector3.UP)) > 0.95:
			up_vec = Vector3.RIGHT
		if is_inside_tree():
			look_at(global_position + travel_direction, up_vec)
		else:
			var fwd := travel_direction
			var right := up_vec.cross(fwd).normalized()
			var up := fwd.cross(right).normalized()
			transform.basis = Basis(right, up, fwd)

func _ready() -> void:
	_create_visual_mesh()
	AudioManager.play_sound("drone_rocket", 0.04, 1.8)

func _create_visual_mesh() -> void:
	rocket_root = Node3D.new()
	add_child(rocket_root)
	
	# 1. Warhead Ogive (Military Olive Drab)
	var warhead := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.02
	cone.bottom_radius = 0.12
	cone.height = 0.35
	warhead.mesh = cone
	warhead.position.z = -0.3
	warhead.rotation.x = deg_to_rad(90.0)
	
	var mat_warhead := StandardMaterial3D.new()
	mat_warhead.albedo_color = Color(0.28, 0.36, 0.22)
	mat_warhead.roughness = 0.5
	warhead.material_override = mat_warhead
	rocket_root.add_child(warhead)
	
	# 2. Rocket Motor Body (Dark Steel)
	var motor := MeshInstance3D.new()
	var body_cyl := CylinderMesh.new()
	body_cyl.top_radius = 0.08
	body_cyl.bottom_radius = 0.08
	body_cyl.height = 0.55
	motor.mesh = body_cyl
	motor.position.z = 0.05
	motor.rotation.x = deg_to_rad(90.0)
	
	var mat_motor := StandardMaterial3D.new()
	mat_motor.albedo_color = Color(0.2, 0.22, 0.25)
	mat_motor.metallic = 0.8
	mat_motor.roughness = 0.35
	motor.material_override = mat_motor
	rocket_root.add_child(motor)
	
	# 3. Stabilizing Tail Fins (4 fins)
	for i in range(4):
		var fin := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(0.02, 0.18, 0.22)
		fin.mesh = prism
		fin.position.z = 0.28
		fin.rotation.z = deg_to_rad(i * 90.0)
		fin.material_override = mat_motor
		rocket_root.add_child(fin)
		
	# 4. Exhaust Thruster Flame
	exhaust_flame = MeshInstance3D.new()
	var flame_cone := CylinderMesh.new()
	flame_cone.top_radius = 0.07
	flame_cone.bottom_radius = 0.01
	flame_cone.height = 0.45
	exhaust_flame.mesh = flame_cone
	exhaust_flame.position.z = 0.52
	exhaust_flame.rotation.x = deg_to_rad(90.0)
	
	var mat_flame := StandardMaterial3D.new()
	mat_flame.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_flame.albedo_color = Color(1.0, 0.7, 0.1, 0.95)
	mat_flame.emission_enabled = true
	mat_flame.emission = Color(1.0, 0.55, 0.1)
	mat_flame.emission_energy_multiplier = 4.0
	exhaust_flame.material_override = mat_flame
	rocket_root.add_child(exhaust_flame)
	
	var thruster_light := OmniLight3D.new()
	thruster_light.light_color = Color(1.0, 0.6, 0.1)
	thruster_light.light_energy = 3.5
	thruster_light.omni_range = 4.0
	exhaust_flame.add_child(thruster_light)

func _process(delta: float) -> void:
	if has_exploded:
		return
		
	# 1. Guided Missile Target Tracking (Hyungung K-ATGM)
	if is_guided:
		if not is_instance_valid(target_node) or (target_node.has_method("is_alive") and not target_node.is_alive()):
			target_node = _find_nearest_enemy_in_cone()
			
		if is_instance_valid(target_node):
			var cur_pos := global_position if is_inside_tree() else position
			var tgt_pos: Vector3 = target_node.global_position if target_node.is_inside_tree() else target_node.position
			tgt_pos += Vector3(0.0, 0.25, 0.0) # Center of enemy mass / drone core
			target_position = tgt_pos
			
			var to_target := (tgt_pos - cur_pos).normalized()
			var steer_amount := clampf(homing_turn_rate * delta, 0.0, 1.0)
			travel_direction = travel_direction.slerp(to_target, steer_amount).normalized()
			
			var up_vec := Vector3.UP
			if abs(travel_direction.dot(Vector3.UP)) > 0.95:
				up_vec = Vector3.RIGHT
			if is_inside_tree():
				look_at(global_position + travel_direction, up_vec)
			else:
				var fwd := travel_direction
				var right := up_vec.cross(fwd).normalized()
				var up := fwd.cross(right).normalized()
				transform.basis = Basis(right, up, fwd)
			
			# Proximity detonation on direct missile impact
			if cur_pos.distance_to(tgt_pos) <= 2.2:
				explode(tgt_pos)
				return
		
	var step := speed * delta
	distance_traveled += step
	if is_inside_tree():
		global_position += travel_direction * step
	else:
		position += travel_direction * step
	
	# Exhaust flame flicker
	if exhaust_flame:
		exhaust_flame.scale = Vector3(
			randf_range(0.85, 1.2),
			randf_range(0.85, 1.2),
			randf_range(0.9, 1.4)
		)
		
	# Spawn smoke puff periodically
	smoke_timer += delta
	if smoke_timer >= 0.035:
		smoke_timer = 0.0
		_spawn_smoke_puff()
		
	# Check arrival at target or beyond
	if distance_traveled >= total_distance:
		explode(target_position)

func _find_nearest_enemy_in_cone() -> Node3D:
	if not is_inside_tree():
		return null
	var enemies := get_tree().get_nodes_in_group("enemies")
	var best_target: Node3D = null
	var best_score: float = -9999.0
	for node in enemies:
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		var n3d := node as Node3D
		if n3d.has_method("is_alive") and not n3d.is_alive():
			continue
		var to_node := (n3d.global_position - global_position).normalized()
		var dot_prod := travel_direction.dot(to_node)
		if dot_prod < 0.15: # Must be generally in front of missile
			continue
		var dist := global_position.distance_to(n3d.global_position)
		if dist > 140.0:
			continue
		# High priority for Drones and heavy robots/walkers
		var is_drone_or_robot: bool = n3d is DroneAI or n3d.name.to_lower().contains("drone") or n3d.name.to_lower().contains("robot")
		var priority: float = 40.0 if is_drone_or_robot else 12.0
		var score := (dot_prod * 45.0) + priority - (dist * 0.35)
		if score > best_score:
			best_score = score
			best_target = n3d
	return best_target

func _spawn_smoke_puff() -> void:
	if not is_inside_tree() or not get_parent():
		return
	var puff := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	puff.mesh = sphere
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.7, 0.7, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff.material_override = mat
	
	get_parent().add_child(puff)
	puff.global_position = global_position + travel_direction * -0.5
	
	var tw := puff.create_tween()
	tw.tween_property(puff, "scale", Vector3.ONE * 2.8, 0.35)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tw.tween_callback(puff.queue_free)

func explode(hit_pos: Vector3) -> void:
	if has_exploded:
		return
	has_exploded = true
	
	# Apply radial explosive splash damage upon rocket impact
	var space := get_world_3d().direct_space_state if is_inside_tree() and get_world_3d() else null
	if space:
		var sphere := SphereShape3D.new()
		sphere.radius = blast_radius
		var shape_q := PhysicsShapeQueryParameters3D.new()
		shape_q.shape = sphere
		shape_q.transform = Transform3D(Basis(), hit_pos)
		shape_q.collision_mask = 4 | 8 # Enemies (layer 4) and destructible cover (layer 8)
		shape_q.collide_with_areas = true
		shape_q.collide_with_bodies = true
		var hits := space.intersect_shape(shape_q, 16)
		for h in hits:
			var col = h.get("collider")
			if col and col.has_method("apply_damage"):
				col.apply_damage(damage)
			elif col and col.get_parent() and col.get_parent().has_method("apply_damage"):
				col.get_parent().apply_damage(damage)
	
	if explosion_scene:
		var exp_node = explosion_scene.instantiate()
		if get_parent():
			get_parent().add_child(exp_node)
		if exp_node.has_method("setup"):
			exp_node.setup(hit_pos, blast_radius)
		
	queue_free()
