class_name EnemyProjectile
extends Node3D

enum ProjectileType {
	BULLET,
	ROCKET,
	SIEGE_SHELL,
	MISSILE_SALVO
}

@export var projectile_type: ProjectileType = ProjectileType.BULLET
@export var speed: float = 55.0
@export var damage: float = 10.0
@export var blast_radius: float = 0.0

var start_pos: Vector3 = Vector3.ZERO
var target_pos: Vector3 = Vector3.ZERO
var travel_direction: Vector3 = Vector3.FORWARD
var total_distance: float = 0.0
var distance_traveled: float = 0.0
var has_impacted: bool = false
var smoke_timer: float = 0.0
var target_receiver: Node = null # Player or Base object

var visual_root: Node3D = null
var projectile_mesh: MeshInstance3D = null
var point_light: OmniLight3D = null

var explosion_scene: PackedScene = preload("res://scenes/effects/explosion_effect.tscn")

func setup(
	origin: Vector3,
	destination: Vector3,
	p_type: ProjectileType,
	dmg_amount: float,
	flight_speed: float = 55.0,
	splash_rad: float = 0.0,
	receiver: Node = null
) -> void:
	start_pos = origin
	target_pos = destination
	projectile_type = p_type
	damage = dmg_amount
	speed = flight_speed
	blast_radius = splash_rad
	target_receiver = receiver
	
	if is_inside_tree():
		global_position = origin
	else:
		position = origin
		
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
	_play_launch_audio()

func _play_launch_audio() -> void:
	var p := global_position if is_inside_tree() else position
	match projectile_type:
		ProjectileType.ROCKET, ProjectileType.MISSILE_SALVO:
			AudioManager.play_sound_at("drone_rocket", p, p)
		ProjectileType.SIEGE_SHELL:
			AudioManager.play_sound_at("heavy_cannon", p, p)
		ProjectileType.BULLET:
			AudioManager.play_sound_at("enemy_shot", p, p)

func _create_visual_mesh() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	
	match projectile_type:
		ProjectileType.BULLET:
			_build_bullet_visual()
		ProjectileType.ROCKET:
			_build_rocket_visual()
		ProjectileType.SIEGE_SHELL:
			_build_siege_shell_visual()
		ProjectileType.MISSILE_SALVO:
			_build_missile_salvo_visual()

func _build_bullet_visual() -> void:
	projectile_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.045
	cyl.bottom_radius = 0.045
	cyl.height = 0.85
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.35, 0.1, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.45, 0.1, 1.0)
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	projectile_mesh.mesh = cyl
	projectile_mesh.material_override = mat
	projectile_mesh.rotation.x = deg_to_rad(90.0)
	visual_root.add_child(projectile_mesh)
	
	point_light = OmniLight3D.new()
	point_light.light_color = Color(1.0, 0.4, 0.1)
	point_light.light_energy = 1.2
	point_light.omni_range = 3.5
	visual_root.add_child(point_light)

func _build_rocket_visual() -> void:
	# Detailed RPG-7 Warhead and motor
	var warhead := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.01
	cone.bottom_radius = 0.12
	cone.height = 0.35
	var w_mat := StandardMaterial3D.new()
	w_mat.albedo_color = Color(0.28, 0.35, 0.22) # Olive Drab
	w_mat.metallic = 0.4
	w_mat.roughness = 0.5
	warhead.mesh = cone
	warhead.material_override = w_mat
	warhead.rotation.x = deg_to_rad(90.0)
	warhead.position.z = 0.2
	visual_root.add_child(warhead)
	
	# Rocket body tube
	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.06
	cyl.height = 0.55
	var b_mat := StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.2, 0.22, 0.25)
	b_mat.metallic = 0.7
	body.mesh = cyl
	body.material_override = b_mat
	body.rotation.x = deg_to_rad(90.0)
	body.position.z = -0.22
	visual_root.add_child(body)
	
	# Stabilizing Fins
	for rot in [0.0, 90.0]:
		var fin := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.32, 0.015, 0.16)
		var f_mat := StandardMaterial3D.new()
		f_mat.albedo_color = Color(0.15, 0.16, 0.18)
		fin.mesh = box
		fin.material_override = f_mat
		fin.rotation.z = deg_to_rad(rot)
		fin.position.z = -0.42
		visual_root.add_child(fin)
		
	# Fiery Exhaust Flame
	var flame := MeshInstance3D.new()
	var f_cone := CylinderMesh.new()
	f_cone.top_radius = 0.045
	f_cone.bottom_radius = 0.0
	f_cone.height = 0.3
	var fl_mat := StandardMaterial3D.new()
	fl_mat.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	fl_mat.emission_enabled = true
	fl_mat.emission = Color(1.0, 0.6, 0.1, 1.0)
	fl_mat.emission_energy_multiplier = 5.0
	fl_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame.mesh = f_cone
	flame.material_override = fl_mat
	flame.rotation.x = deg_to_rad(-90.0)
	flame.position.z = -0.6
	visual_root.add_child(flame)
	
	point_light = OmniLight3D.new()
	point_light.light_color = Color(1.0, 0.5, 0.1)
	point_light.light_energy = 3.0
	point_light.omni_range = 6.0
	point_light.position.z = -0.5
	visual_root.add_child(point_light)

func _build_siege_shell_visual() -> void:
	# Heavy 120mm Plasma Railgun projectile
	projectile_mesh = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.16
	cap.height = 1.1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.85, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.9, 1.0, 1.0)
	mat.emission_energy_multiplier = 6.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	projectile_mesh.mesh = cap
	projectile_mesh.material_override = mat
	projectile_mesh.rotation.x = deg_to_rad(90.0)
	visual_root.add_child(projectile_mesh)
	
	# Plasma Energy Corona Ring
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.22
	torus.outer_radius = 0.32
	var r_mat := StandardMaterial3D.new()
	r_mat.albedo_color = Color(0.8, 0.95, 1.0, 0.8)
	r_mat.emission_enabled = true
	r_mat.emission = Color(0.3, 0.9, 1.0, 1.0)
	r_mat.emission_energy_multiplier = 4.0
	ring.mesh = torus
	ring.material_override = r_mat
	ring.rotation.x = deg_to_rad(90.0)
	visual_root.add_child(ring)
	
	point_light = OmniLight3D.new()
	point_light.light_color = Color(0.2, 0.85, 1.0)
	point_light.light_energy = 4.5
	point_light.omni_range = 8.0
	visual_root.add_child(point_light)

func _build_missile_salvo_visual() -> void:
	# Micro-cruise missile
	projectile_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.05
	cyl.height = 0.6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.28, 0.32)
	mat.metallic = 0.6
	projectile_mesh.mesh = cyl
	projectile_mesh.material_override = mat
	projectile_mesh.rotation.x = deg_to_rad(90.0)
	visual_root.add_child(projectile_mesh)
	
	point_light = OmniLight3D.new()
	point_light.light_color = Color(1.0, 0.3, 0.2)
	point_light.light_energy = 2.0
	point_light.omni_range = 4.5
	visual_root.add_child(point_light)

func _process(delta: float) -> void:
	if has_impacted:
		return
		
	var step := speed * delta
	distance_traveled += step
	if is_inside_tree():
		global_position += travel_direction * step
	else:
		position += travel_direction * step
	
	# Smoke puff trail for rockets and missiles
	if projectile_type == ProjectileType.ROCKET or projectile_type == ProjectileType.MISSILE_SALVO or projectile_type == ProjectileType.SIEGE_SHELL:
		smoke_timer += delta
		if smoke_timer >= 0.04:
			smoke_timer = 0.0
			_spawn_smoke_trail()
			
	# Check arrival at destination
	if distance_traveled >= total_distance:
		impact(target_pos)

func _spawn_smoke_trail() -> void:
	if not is_inside_tree() or not get_parent():
		return
	var puff := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.09 if projectile_type != ProjectileType.SIEGE_SHELL else 0.18
	sphere.height = sphere.radius * 2.0
	puff.mesh = sphere
	
	var mat := StandardMaterial3D.new()
	if projectile_type == ProjectileType.SIEGE_SHELL:
		mat.albedo_color = Color(0.2, 0.8, 1.0, 0.5)
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.8, 1.0)
		mat.emission_energy_multiplier = 2.0
	else:
		mat.albedo_color = Color(0.7, 0.7, 0.7, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material_override = mat
	
	get_parent().add_child(puff)
	puff.global_position = global_position - travel_direction * 0.4
	
	var tw := puff.create_tween()
	tw.tween_property(puff, "scale", Vector3.ONE * 2.5, 0.35)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tw.tween_callback(puff.queue_free)

func impact(hit_pos: Vector3) -> void:
	if has_impacted:
		return
	has_impacted = true
	
	match projectile_type:
		ProjectileType.ROCKET, ProjectileType.MISSILE_SALVO, ProjectileType.SIEGE_SHELL:
			_explode_at(hit_pos)
		ProjectileType.BULLET:
			_bullet_hit_at(hit_pos)
			
	queue_free()

func _explode_at(hit_pos: Vector3) -> void:
	AudioManager.play_sound_at("explosion", hit_pos, hit_pos)
	
	# Spawn Explosion Visual Effect
	if explosion_scene and get_parent():
		var exp_node = explosion_scene.instantiate()
		get_parent().add_child(exp_node)
		if exp_node.has_method("setup"):
			var radius := blast_radius if blast_radius > 0.0 else 5.0
			exp_node.setup(hit_pos, radius)
			
	# Apply damage to target receiver or radial splash
	if target_receiver and is_instance_valid(target_receiver) and target_receiver.has_method("apply_damage"):
		target_receiver.apply_damage(damage)
	elif blast_radius > 0.0:
		_apply_splash_damage(hit_pos, blast_radius, damage)
		
	# Trigger tactile mobile vibration on hit
	if Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(150)

func _bullet_hit_at(hit_pos: Vector3) -> void:
	# Spawns spark/dirt puff
	_spawn_spark_puff(hit_pos)
	AudioManager.play_sound_at("ricochet", hit_pos, hit_pos)
	
	if target_receiver and is_instance_valid(target_receiver) and target_receiver.has_method("apply_damage"):
		target_receiver.apply_damage(damage)
		
	# Subtle hit vibration
	if Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(70)

func _spawn_spark_puff(pos: Vector3) -> void:
	if not is_inside_tree() or not get_parent():
		return
	var spark := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.12
	sph.height = 0.24
	spark.mesh = sph
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.7, 0.2, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.3)
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark.material_override = mat
	
	get_parent().add_child(spark)
	spark.global_position = pos
	
	var tw := spark.create_tween()
	tw.tween_property(spark, "scale", Vector3.ONE * 2.0, 0.15)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.15)
	tw.tween_callback(spark.queue_free)

func _apply_splash_damage(center: Vector3, rad: float, dmg: float) -> void:
	var space := get_world_3d().direct_space_state if is_inside_tree() and get_world_3d() else null
	if not space:
		return
	var sphere := SphereShape3D.new()
	sphere.radius = rad
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = sphere
	q.transform = Transform3D(Basis(), center)
	q.collision_mask = 1 | 2 # Player/Base layers
	q.collide_with_areas = true
	q.collide_with_bodies = true
	var hits := space.intersect_shape(q, 8)
	for h in hits:
		var col = h.get("collider")
		if col and col.has_method("apply_damage"):
			col.apply_damage(dmg)
		elif col and col.get_parent() and col.get_parent().has_method("apply_damage"):
			col.get_parent().apply_damage(dmg)
