class_name InfantryAI
extends EnemyBase

signal bullet_fired(start_pos: Vector3, target_pos: Vector3)

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

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		_process_dead(delta)
		return
		
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

func _process_spawn(delta: float) -> void:
	change_state(State.APPROACH)
	_process_approach(delta)

func _process_approach(delta: float) -> void:
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
	if attack_timer >= attack_cooldown:
		attack_timer = 0.0
		_execute_attack()

func _execute_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	var my_pos := global_position if is_inside_tree() else position
	var tgt_pos := target.global_position if (target.is_inside_tree()) else target.position
	var muzzle_pos := my_pos + Vector3(0.0, 0.9, 0.5)
	var target_pos := tgt_pos + Vector3(randf_range(-1.0, 1.0), randf_range(0.2, 0.8), 0.0)
	bullet_fired.emit(muzzle_pos, target_pos)
	if target.has_method("apply_damage"):
		target.apply_damage(attack_damage)
	attack_performed.emit(target, attack_damage)

func _process_hit(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	hit_recovery_timer += delta
	if hit_recovery_timer >= 0.2:
		hit_recovery_timer = 0.0
		change_state(State.APPROACH)

func _process_dead(delta: float) -> void:
	velocity = Vector3.ZERO
	death_sink_timer += delta
	if visual_mesh:
		visual_mesh.rotation.x = lerp_angle(visual_mesh.rotation.x, deg_to_rad(-75.0), 8.0 * delta)
		visual_mesh.position.y = -0.4 * death_sink_timer
	if death_sink_timer >= 1.5:
		queue_free()
