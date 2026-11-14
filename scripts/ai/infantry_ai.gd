class_name InfantryAI
extends EnemyBase

var hit_recovery_timer: float = 0.0
var death_sink_timer: float = 0.0

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
		
	var diff := target.global_position - global_position if is_inside_tree() else target.position - position
	var horizontal_dist := Vector2(diff.x, diff.z).length()
	
	if horizontal_dist <= attack_range:
		velocity.x = 0.0
		velocity.z = 0.0
		attack_timer = attack_cooldown # Ready to fire on arrival
		change_state(State.ATTACK)
		return
		
	var horiz_dir := Vector3(diff.x, 0.0, diff.z).normalized()
	velocity.x = horiz_dir.x * move_speed
	velocity.z = horiz_dir.z * move_speed
	
	if visual_mesh:
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(horiz_dir.x, horiz_dir.z), 10.0 * delta)
		
	if is_inside_tree() and get_world_3d() and get_world_3d().space.is_valid():
		move_and_slide()

func _process_attack(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	
	if not target or not is_instance_valid(target):
		change_state(State.APPROACH)
		return
		
	var diff := target.global_position - global_position if is_inside_tree() else target.position - position
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
	# Slight fall/sink visual
	if visual_mesh:
		visual_mesh.position.y = -0.3 * death_sink_timer
	if death_sink_timer >= 1.5:
		queue_free()
