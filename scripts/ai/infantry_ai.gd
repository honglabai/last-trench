class_name InfantryAI
extends EnemyBase

signal bullet_fired(start_pos: Vector3, target_pos: Vector3)

const PATH_SOLDIER_ADVANCE: String = "res://assets/textures/tex_enemy_soldier_realistic.png"
const PATH_SOLDIER_AIM: String = "res://assets/textures/tex_enemy_soldier_aim.png"
const PATH_SOLDIER_FIRE: String = "res://assets/textures/tex_enemy_soldier_fire.png"

var _tex_advance: Texture2D = null
var _tex_aim: Texture2D = null
var _tex_fire: Texture2D = null

enum MovementPattern {
	DIRECT,
	ZIGZAG,
	SPRINT_COVER,
	FLANK
}

@export var pattern: MovementPattern = MovementPattern.DIRECT

var hit_recovery_timer: float = 0.0
var death_sink_timer: float = 0.0
var walk_cycle: float = 0.0
var pattern_timer: float = 0.0
var lateral_phase: float = 0.0
var is_sprint_pausing: bool = false
var sprint_pause_timer: float = 0.0
var initial_speed: float = 3.2
var fire_pose_timer: float = 0.0
var muzzle_light_timer: float = 0.0
var recoil_kick: float = 0.0

var _soldier_sprite: Sprite3D
var soldier_sprite: Sprite3D:
	get:
		if not _soldier_sprite:
			_soldier_sprite = get_node_or_null("VisualMesh/SoldierSprite") as Sprite3D
		return _soldier_sprite

var _muzzle_light: OmniLight3D
var muzzle_light: OmniLight3D:
	get:
		if not _muzzle_light:
			_muzzle_light = get_node_or_null("VisualMesh/MuzzleLight") as OmniLight3D
		return _muzzle_light

var _aim_laser: MeshInstance3D = null

func _ready() -> void:
	max_health = 60.0
	current_health = max_health
	move_speed = 3.2
	attack_range = 14.0
	attack_damage = 8.0
	attack_cooldown = 1.6
	collision_layer = 4 # Enemy
	collision_mask = 1 # Environment
	
	lateral_phase = randf() * TAU
	pattern = (randi() % 4) as MovementPattern
	initial_speed = randf_range(2.9, 3.8)
	move_speed = initial_speed
	_load_pose_textures()
	_setup_aim_laser()

func _load_pose_textures() -> void:
	if self is RPGInfantryAI:
		return
	if ResourceLoader.exists(PATH_SOLDIER_ADVANCE):
		_tex_advance = load(PATH_SOLDIER_ADVANCE) as Texture2D
	if ResourceLoader.exists(PATH_SOLDIER_AIM):
		_tex_aim = load(PATH_SOLDIER_AIM) as Texture2D
	if ResourceLoader.exists(PATH_SOLDIER_FIRE):
		_tex_fire = load(PATH_SOLDIER_FIRE) as Texture2D

func _setup_aim_laser() -> void:
	if _aim_laser or not visual_mesh:
		return
	_aim_laser = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.008
	cyl.bottom_radius = 0.008
	cyl.height = 1.0
	_aim_laser.mesh = cyl
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.12, 0.12, 0.75)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.1, 0.08, 1.0)
	mat.emission_energy_multiplier = 3.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_aim_laser.material_override = mat
	_aim_laser.visible = false
	add_child(_aim_laser)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		_process_dead(delta)
		return
		
	_update_attack_feedback(delta)
	
	# Apply gravity
	if is_inside_tree() and is_on_floor():
		velocity.y = -0.1
	else:
		velocity.y -= gravity * delta
		
	match current_state:
		State.SPAWN:
			_process_spawn(delta)
		State.APPROACH:
			_process_approach(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HIT:
			_process_hit(delta)
			
	_update_soldier_pose()

func _update_attack_feedback(delta: float) -> void:
	if fire_pose_timer > 0.0:
		fire_pose_timer = maxf(0.0, fire_pose_timer - delta)
	if muzzle_light_timer > 0.0:
		muzzle_light_timer = maxf(0.0, muzzle_light_timer - delta)
		if muzzle_light and muzzle_light_timer <= 0.0:
			muzzle_light.visible = false
	if recoil_kick > 0.0:
		recoil_kick = lerpf(recoil_kick, 0.0, 14.0 * delta)
		if visual_mesh and current_state == State.ATTACK:
			visual_mesh.rotation.x = -recoil_kick

func _update_soldier_pose() -> void:
	if self is RPGInfantryAI or not soldier_sprite:
		return
	if fire_pose_timer > 0.0 and _tex_fire:
		if soldier_sprite.texture != _tex_fire:
			soldier_sprite.texture = _tex_fire
	elif (current_state == State.ATTACK or is_sprint_pausing) and _tex_aim:
		if soldier_sprite.texture != _tex_aim:
			soldier_sprite.texture = _tex_aim
	elif _tex_advance:
		if soldier_sprite.texture != _tex_advance:
			soldier_sprite.texture = _tex_advance

func _update_aim_laser(active: bool) -> void:
	if not _aim_laser:
		return
	if not active or not target or not is_instance_valid(target):
		_aim_laser.visible = false
		return
	var my_pos := global_position if is_inside_tree() else position
	var tgt_pos := target.global_position if target.is_inside_tree() else target.position
	var muzzle := my_pos + Vector3(0.18, 1.15, 0.35)
	var aim_end := tgt_pos + Vector3(0.0, 0.6, 0.0)
	var diff := aim_end - muzzle
	var dist := diff.length()
	if dist < 0.2:
		_aim_laser.visible = false
		return
	_aim_laser.visible = true
	var mid := (muzzle + aim_end) * 0.5
	if is_inside_tree():
		_aim_laser.global_position = mid
		_aim_laser.look_at(aim_end, Vector3.UP)
		_aim_laser.rotate_object_local(Vector3.RIGHT, deg_to_rad(90.0))
	_aim_laser.scale = Vector3(1.0, dist, 1.0)

func _process_spawn(delta: float) -> void:
	change_state(State.APPROACH)
	_process_approach(delta)

func _process_approach(delta: float) -> void:
	_update_aim_laser(false)
	if not target or not is_instance_valid(target):
		velocity.x = 0.0
		velocity.z = 0.0
		return
		
	var my_pos := global_position if is_inside_tree() else position
	var tgt_pos := target.global_position if (target.is_inside_tree()) else target.position
	var diff := tgt_pos - my_pos
	var horizontal_dist := Vector2(diff.x, diff.z).length()
	
	if horizontal_dist <= attack_range:
		velocity.x = 0.0
		velocity.z = 0.0
		attack_timer = attack_cooldown # Ready to fire on arrival
		change_state(State.ATTACK)
		return
		
	pattern_timer += delta
	var horiz_dir := Vector3(diff.x, 0.0, diff.z).normalized()
	var forward_speed := move_speed
	var lateral_speed := 0.0
	
	match pattern:
		MovementPattern.ZIGZAG:
			var lateral_factor := sin(pattern_timer * 3.0 + lateral_phase)
			lateral_speed = lateral_factor * move_speed * 1.1
		MovementPattern.SPRINT_COVER:
			if is_sprint_pausing:
				sprint_pause_timer -= delta
				forward_speed = 0.0
				lateral_speed = 0.0
				if sprint_pause_timer <= 0.0:
					is_sprint_pausing = false
			else:
				forward_speed = move_speed * 1.35
				if fmod(pattern_timer, 3.2) < delta:
					is_sprint_pausing = true
					sprint_pause_timer = 0.9
					if horizontal_dist < 26.0:
						_execute_attack()
		MovementPattern.FLANK:
			if horizontal_dist > 18.0:
				var flank_dir := 1.0 if (my_pos.x > 0.0 or lateral_phase > PI) else -1.0
				lateral_speed = flank_dir * move_speed * 0.75
		MovementPattern.DIRECT:
			forward_speed = move_speed
			
	var perp := Vector3(-horiz_dir.z, 0.0, horiz_dir.x)
	velocity.x = horiz_dir.x * forward_speed + perp.x * lateral_speed
	velocity.z = horiz_dir.z * forward_speed + perp.z * lateral_speed
	
	# Guarantee invariant: advancing towards target
	if diff.z > 0.0 and velocity.z <= 0.0:
		velocity.z = move_speed * 0.5
	
	walk_cycle += delta * (10.0 if forward_speed > 0.0 else 0.0)
	if visual_mesh:
		visual_mesh.position.y = abs(sin(walk_cycle)) * 0.08
		visual_mesh.rotation.z = sin(walk_cycle) * 0.04
		var move_heading := Vector3(velocity.x, 0.0, velocity.z)
		if move_heading.length_squared() > 0.01:
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(move_heading.x, move_heading.z), 10.0 * delta)
		else:
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(horiz_dir.x, horiz_dir.z), 10.0 * delta)
		
	if is_inside_tree() and get_world_3d() and get_world_3d().space.is_valid():
		move_and_slide()

func _process_attack(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	
	if not target or not is_instance_valid(target):
		change_state(State.APPROACH)
		return
		
	var my_pos := global_position if is_inside_tree() else position
	var tgt_pos := target.global_position if (target.is_inside_tree()) else target.position
	var diff := tgt_pos - my_pos
	var horizontal_dist := Vector2(diff.x, diff.z).length()
	
	if horizontal_dist > attack_range * 1.25:
		change_state(State.APPROACH)
		return
		
	# Face target
	var horiz_dir := Vector3(diff.x, 0.0, diff.z).normalized()
	if visual_mesh and horiz_dir.length_squared() > 0.001:
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(horiz_dir.x, horiz_dir.z), 12.0 * delta)
		
	attack_timer += delta
	# Telegraph aiming laser right before firing
	var is_telegraphing := attack_timer >= (attack_cooldown * 0.45) and fire_pose_timer <= 0.0
	_update_aim_laser(is_telegraphing)
	
	if attack_timer >= attack_cooldown:
		attack_timer = 0.0
		_execute_attack()

func _execute_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	var my_pos := global_position if is_inside_tree() else position
	var tgt_pos := target.global_position if (target.is_inside_tree()) else target.position
	var muzzle_pos := my_pos + Vector3(0.18, 1.15, 0.45)
	var target_pos := tgt_pos + Vector3(randf_range(-1.0, 1.0), randf_range(0.2, 0.8), 0.0)
	
	fire_pose_timer = 0.16
	muzzle_light_timer = 0.10
	recoil_kick = 0.12
	if muzzle_light:
		muzzle_light.visible = true
	_update_aim_laser(false)
	
	bullet_fired.emit(muzzle_pos, target_pos)
	launch_projectile(EnemyProjectile.ProjectileType.BULLET, muzzle_pos, target_pos, attack_damage, 58.0, 0.0, target)

func _process_hit(delta: float) -> void:
	_update_aim_laser(false)
	velocity.x = 0.0
	velocity.z = 0.0
	hit_recovery_timer += delta
	if hit_recovery_timer >= 0.2:
		hit_recovery_timer = 0.0
		change_state(State.APPROACH)

func _process_dead(delta: float) -> void:
	_update_aim_laser(false)
	if muzzle_light:
		muzzle_light.visible = false
	velocity = Vector3.ZERO
	death_sink_timer += delta
	if visual_mesh:
		visual_mesh.rotation.x = lerp_angle(visual_mesh.rotation.x, deg_to_rad(-75.0), 8.0 * delta)
		visual_mesh.position.y = -0.4 * death_sink_timer
	if death_sink_timer >= 1.5:
		queue_free()
