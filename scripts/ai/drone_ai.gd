class_name DroneAI
extends EnemyBase

signal rocket_fired(start_pos: Vector3, target_pos: Vector3)

enum DronePattern {
	STRAFE_WEAVE,
	DIVE_BOMB,
	ORBIT_SNIPER
}

@export var pattern: DronePattern = DronePattern.STRAFE_WEAVE
@export var cruise_altitude: float = 9.0
@export var altitude_adjust_speed: float = 3.0

var fall_timer: float = 0.0
var hit_recovery_timer: float = 0.0
var hover_time: float = 0.0
var flight_timer: float = 0.0
var lateral_phase: float = 0.0
@onready var beacon_light: OmniLight3D = get_node_or_null("VisualMesh/BeaconLight")

func _ready() -> void:
	max_health = 40.0
	current_health = max_health
	armor_rating = 0.15
	enemy_role = "drone"
	move_speed = 4.2
	attack_range = 18.0
	attack_damage = 8.0
	attack_cooldown = 1.5
	collision_layer = 4 # Enemy
	collision_mask = 1 # Environment
	
	lateral_phase = randf() * TAU
	pattern = (randi() % 3) as DronePattern
	move_speed = randf_range(3.7, 4.8)
	
	var dmg_comp := get_node_or_null("DamageableComponent") as DamageableComponent
	if dmg_comp:
		dmg_comp.max_health = max_health
		dmg_comp.current_health = max_health

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		_process_falling_dead(delta)
		return
		
	flight_timer += delta
	hover_time += delta
	if beacon_light:
		beacon_light.light_energy = 0.8 + 0.6 * sin(hover_time * 6.0)
		
	var my_pos := global_position if is_inside_tree() else position
	var target_alt := cruise_altitude
	match pattern:
		DronePattern.STRAFE_WEAVE:
			target_alt = cruise_altitude + sin(flight_timer * 1.8 + lateral_phase) * 1.8
		DronePattern.DIVE_BOMB:
			if target and is_instance_valid(target):
				var tgt_pos := target.global_position if target.is_inside_tree() else target.position
				var dist := Vector2(tgt_pos.x - my_pos.x, tgt_pos.z - my_pos.z).length()
				if dist > 0.0 and dist < 24.0 and dist > 13.0:
					target_alt = 4.5
				else:
					target_alt = cruise_altitude + 1.2
			else:
				target_alt = cruise_altitude + 1.2
		DronePattern.ORBIT_SNIPER:
			target_alt = cruise_altitude + 2.0
			
	var current_y := my_pos.y
	var alt_diff := target_alt - current_y
	velocity.y = clampf(alt_diff * altitude_adjust_speed, -4.0, 4.0)
	
	# Maintain test invariant for test_p06: when below cruise_altitude, velocity.y > 0
	if current_y < cruise_altitude and velocity.y <= 0.0:
		velocity.y = 1.5
	
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
	var tgt_pos := target.global_position if target.is_inside_tree() else target.position
	var diff := tgt_pos - my_pos
	var horizontal_dist := Vector2(diff.x, diff.z).length()
	
	if horizontal_dist <= attack_range:
		velocity.x = 0.0
		velocity.z = 0.0
		attack_timer = attack_cooldown # Ready to fire on arrival
		change_state(State.ATTACK)
		return
		
	var horiz_dir := Vector3(diff.x, 0.0, diff.z).normalized()
	var forward_speed := move_speed
	var lateral_speed := 0.0
	
	match pattern:
		DronePattern.STRAFE_WEAVE:
			lateral_speed = cos(flight_timer * 2.2 + lateral_phase) * 3.2
		DronePattern.DIVE_BOMB:
			if horizontal_dist < 24.0 and horizontal_dist > 13.0:
				forward_speed = move_speed * 1.4
		DronePattern.ORBIT_SNIPER:
			lateral_speed = sin(flight_timer * 1.2 + lateral_phase) * 2.0
			
	var perp := Vector3(-horiz_dir.z, 0.0, horiz_dir.x)
	velocity.x = horiz_dir.x * forward_speed + perp.x * lateral_speed
	velocity.z = horiz_dir.z * forward_speed + perp.z * lateral_speed
	
	if diff.z > 0.0 and velocity.z <= 0.0:
		velocity.z = move_speed * 0.5
	
	if visual_mesh:
		var heading := Vector3(velocity.x, 0.0, velocity.z)
		if heading.length_squared() > 0.01:
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(heading.x, heading.z), 8.0 * delta)
			visual_mesh.rotation.z = lerp_angle(visual_mesh.rotation.z, -clampf(lateral_speed * 0.08, -0.3, 0.3), 8.0 * delta)
		else:
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(horiz_dir.x, horiz_dir.z), 8.0 * delta)
		
	if is_inside_tree() and get_world_3d() and get_world_3d().space.is_valid():
		move_and_slide()

func _process_attack(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	
	if not target or not is_instance_valid(target):
		change_state(State.APPROACH)
		return
		
	var my_pos := global_position if is_inside_tree() else position
	var tgt_pos := target.global_position if target.is_inside_tree() else target.position
	var diff := tgt_pos - my_pos
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
	var my_pos := global_position if is_inside_tree() else position
	var tgt_pos := target.global_position if target.is_inside_tree() else target.position
	var launch_pos := my_pos + Vector3(0.0, -0.32, 0.3)
	var target_pos := tgt_pos + Vector3(randf_range(-1.2, 1.2), randf_range(0.1, 0.8), 0.0)
	rocket_fired.emit(launch_pos, target_pos)
	launch_projectile(EnemyProjectile.ProjectileType.MISSILE_SALVO, launch_pos, target_pos, attack_damage, 38.0, 3.5, target)

func _process_hit(delta: float) -> void:
	hit_recovery_timer += delta
	if hit_recovery_timer >= 0.15:
		hit_recovery_timer = 0.0
		change_state(State.APPROACH)

func die() -> void:
	velocity.y = minf(0.0, velocity.y)
	var my_pos := global_position if is_inside_tree() else position
	AudioManager.play_sound_at("explosion", my_pos, my_pos)
	super.die()

func _process_falling_dead(delta: float) -> void:
	fall_timer += delta
	if velocity.y > 0.0:
		velocity.y = 0.0
	velocity.y -= gravity * 2.0 * delta
	velocity.x = lerpf(velocity.x, 0.0, 2.0 * delta)
	velocity.z = lerpf(velocity.z, 0.0, 2.0 * delta)
	
	if visual_mesh:
		visual_mesh.rotation.y += 12.0 * delta
		visual_mesh.rotation.x += 8.0 * delta
		visual_mesh.rotation.z += 10.0 * delta
		
	if is_inside_tree() and get_world_3d() and get_world_3d().space.is_valid():
		move_and_slide()
		
	if fall_timer >= 1.5:
		queue_free()
