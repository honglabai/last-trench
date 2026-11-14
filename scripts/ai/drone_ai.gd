class_name DroneAI
extends EnemyBase

@export var cruise_altitude: float = 9.0
@export var altitude_adjust_speed: float = 3.0

var fall_timer: float = 0.0
var hit_recovery_timer: float = 0.0

func _ready() -> void:
	max_health = 35.0
	current_health = max_health
	move_speed = 4.0
	attack_range = 18.0
	attack_damage = 6.0
	attack_cooldown = 1.8
	collision_layer = 4 # Enemy
	collision_mask = 1 # Environment
	
	var dmg_comp := get_node_or_null("DamageableComponent") as DamageableComponent
	if dmg_comp:
		dmg_comp.max_health = max_health
		dmg_comp.current_health = max_health

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		_process_falling_dead(delta)
		return
		
	# Drones fly: maintain cruise altitude instead of standard ground gravity
	var current_y := global_position.y if is_inside_tree() else position.y
	var alt_diff := cruise_altitude - current_y
	velocity.y = clampf(alt_diff * altitude_adjust_speed, -3.0, 3.0)
	
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
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(horiz_dir.x, horiz_dir.z), 8.0 * delta)
		
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
	
	if horizontal_dist > attack_range * 1.3:
		change_state(State.APPROACH)
		return
		
	# Face target
	var horiz_dir := Vector3(diff.x, 0.0, diff.z).normalized()
	if visual_mesh and horiz_dir.length_squared() > 0.001:
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(horiz_dir.x, horiz_dir.z), 10.0 * delta)
		
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
	hit_recovery_timer += delta
	if hit_recovery_timer >= 0.15:
		hit_recovery_timer = 0.0
		change_state(State.APPROACH)

func _process_falling_dead(delta: float) -> void:
	fall_timer += delta
	velocity.y -= gravity * 2.0 * delta
	velocity.x = lerpf(velocity.x, 0.0, 2.0 * delta)
	velocity.z = lerpf(velocity.z, 0.0, 2.0 * delta)
	
	if visual_mesh:
		visual_mesh.rotation.y += 12.0 * delta
		visual_mesh.rotation.x += 8.0 * delta
		
	if is_inside_tree() and get_world_3d() and get_world_3d().space.is_valid():
		move_and_slide()
		
	if fall_timer >= 1.5:
		queue_free()
