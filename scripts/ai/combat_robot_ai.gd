class_name CombatRobotAI
extends EnemyBase

signal bullet_fired(start_pos: Vector3, target_pos: Vector3)

var hit_recovery_timer: float = 0.0
var walk_cycle: float = 0.0
var burst_count: int = 0
var burst_timer: float = 0.0
var is_bursting: bool = false
var death_sink_timer: float = 0.0

func _ready() -> void:
	super._ready()
	max_health = 180.0
	current_health = max_health
	armor_rating = 0.35
	enemy_role = "combat_robot"
	move_speed = 3.2
	attack_range = 16.0
	attack_damage = 11.0
	attack_cooldown = 1.4
	
	var dmg_comp := get_node_or_null("DamageableComponent") as DamageableComponent
	if dmg_comp:
		dmg_comp.max_health = max_health
		dmg_comp.current_health = max_health

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		_process_dead(delta)
		return
		
	if is_inside_tree() and is_on_floor():
		velocity.y = -0.1
	else:
		velocity.y -= gravity * delta
		
	match current_state:
		State.SPAWN:
			change_state(State.APPROACH)
		State.APPROACH:
			_process_approach(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HIT:
			_process_hit(delta)

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
		attack_timer = attack_cooldown
		change_state(State.ATTACK)
		return
		
	var horiz_dir := Vector3(diff.x, 0.0, diff.z).normalized()
	velocity.x = horiz_dir.x * move_speed
	velocity.z = horiz_dir.z * move_speed
	
	walk_cycle += delta * 12.0
	if visual_mesh:
		visual_mesh.position.y = abs(sin(walk_cycle)) * 0.06
		visual_mesh.rotation.z = sin(walk_cycle) * 0.03
		if horiz_dir.length_squared() > 0.001:
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
	var tgt_pos := target.global_position if target.is_inside_tree() else target.position
	var diff := tgt_pos - my_pos
	var horizontal_dist := Vector2(diff.x, diff.z).length()
	
	if horizontal_dist > attack_range * 1.3:
		change_state(State.APPROACH)
		return
		
	var horiz_dir := Vector3(diff.x, 0.0, diff.z).normalized()
	if visual_mesh and horiz_dir.length_squared() > 0.001:
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(horiz_dir.x, horiz_dir.z), 12.0 * delta)
		
	if is_bursting:
		burst_timer += delta
		if burst_timer >= 0.12:
			burst_timer = 0.0
			_fire_single_shot()
			burst_count += 1
			if burst_count >= 2: # Double tap
				is_bursting = false
				burst_count = 0
		return
		
	attack_timer += delta
	if attack_timer >= attack_cooldown:
		attack_timer = 0.0
		is_bursting = true
		burst_count = 0
		burst_timer = 0.0
		_fire_single_shot()
		burst_count += 1

func _fire_single_shot() -> void:
	if not target or not is_instance_valid(target):
		return
	var my_pos := global_position if is_inside_tree() else position
	var tgt_pos := target.global_position if target.is_inside_tree() else target.position
	var side := 0.65 if (burst_count % 2 == 0) else -0.65
	var muzzle_pos := my_pos + Vector3(side, 0.85, 0.4)
	var target_pos := tgt_pos + Vector3(randf_range(-0.8, 0.8), randf_range(0.2, 0.8), 0.0)
	
	bullet_fired.emit(muzzle_pos, target_pos)
	launch_projectile(EnemyProjectile.ProjectileType.BULLET, muzzle_pos, target_pos, attack_damage, 70.0, 0.0, target)

func _process_hit(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	hit_recovery_timer += delta
	if hit_recovery_timer >= 0.15:
		hit_recovery_timer = 0.0
		change_state(State.APPROACH)

func _process_dead(delta: float) -> void:
	velocity = Vector3.ZERO
	death_sink_timer += delta
	if visual_mesh:
		visual_mesh.rotation.x = lerp_angle(visual_mesh.rotation.x, deg_to_rad(-80.0), 8.0 * delta)
		visual_mesh.position.y = -0.3 * death_sink_timer
	if death_sink_timer >= 1.5:
		queue_free()
