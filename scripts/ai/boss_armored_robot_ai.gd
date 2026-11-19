class_name BossArmoredRobotAI
extends EnemyBase

signal boss_damaged(cur_hp: float, max_hp: float)
signal rocket_fired(start_pos: Vector3, target_pos: Vector3)

@export var is_boss: bool = true
@export var boss_title: String = "중장갑 전투로봇"

var hit_recovery_timer: float = 0.0
var walk_cycle: float = 0.0
var death_sink_timer: float = 0.0

func _ready() -> void:
	super._ready()
	max_health = 1200.0
	current_health = max_health
	move_speed = 2.2
	attack_range = 20.0
	attack_damage = 38.0
	attack_cooldown = 2.8
	
	var dmg_comp := get_node_or_null("DamageableComponent") as DamageableComponent
	if dmg_comp:
		dmg_comp.max_health = max_health
		dmg_comp.current_health = max_health

func apply_damage(amount: float) -> void:
	super.apply_damage(amount)
	boss_damaged.emit(current_health, max_health)

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
	
	walk_cycle += delta * 6.0
	if visual_mesh:
		visual_mesh.position.y = abs(sin(walk_cycle)) * 0.12
		visual_mesh.rotation.z = sin(walk_cycle) * 0.04
		if horiz_dir.length_squared() > 0.001:
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(horiz_dir.x, horiz_dir.z), 6.0 * delta)
			
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
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(horiz_dir.x, horiz_dir.z), 8.0 * delta)
		
	attack_timer += delta
	if attack_timer >= attack_cooldown:
		attack_timer = 0.0
		_execute_attack()

func _execute_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	var my_pos := global_position if is_inside_tree() else position
	var tgt_pos := target.global_position if target.is_inside_tree() else target.position
	
	# Massive siege cannon blast
	for side in [-1.5, 1.5]:
		var muzzle_pos := my_pos + Vector3(side, 2.5, 0.8)
		var target_pos := tgt_pos + Vector3(randf_range(-1.5, 1.5), randf_range(0.2, 1.5), 0.0)
		rocket_fired.emit(muzzle_pos, target_pos)
		launch_projectile(EnemyProjectile.ProjectileType.SIEGE_SHELL, muzzle_pos, target_pos, attack_damage * 0.5, 42.0, 6.0, target)

func _process_hit(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	hit_recovery_timer += delta
	if hit_recovery_timer >= 0.1:
		hit_recovery_timer = 0.0
		change_state(State.APPROACH)

func _process_dead(delta: float) -> void:
	velocity = Vector3.ZERO
	death_sink_timer += delta
	if visual_mesh:
		visual_mesh.rotation.x = lerp_angle(visual_mesh.rotation.x, deg_to_rad(-70.0), 6.0 * delta)
		visual_mesh.position.y = -0.4 * death_sink_timer
	if death_sink_timer >= 2.0:
		queue_free()
