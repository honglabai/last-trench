class_name BossFinalAssaultAI
extends EnemyBase

signal boss_damaged(cur_hp: float, max_hp: float)
signal bullet_fired(start_pos: Vector3, target_pos: Vector3)
signal rocket_fired(start_pos: Vector3, target_pos: Vector3)
signal summon_escorts(escort_type: String, count: int)

@export var is_boss: bool = true
@export var boss_title: String = "최후의 결전 지휘병기"

var attack_phase: int = 1 # 1: normal, 2: frenzy barrage, 3: enraged
var attack_sub_timer: float = 0.0
var salvo_count: int = 0
var has_summoned_reinforcements: bool = false
var death_sink_timer: float = 0.0
var walk_cycle: float = 0.0

func _ready() -> void:
	super._ready()
	max_health = 2000.0
	current_health = max_health
	move_speed = 2.0
	attack_range = 24.0
	attack_damage = 45.0
	attack_cooldown = 2.2
	
	var dmg_comp := get_node_or_null("DamageableComponent") as DamageableComponent
	if dmg_comp:
		dmg_comp.max_health = max_health
		dmg_comp.current_health = max_health

func apply_damage(amount: float) -> void:
	super.apply_damage(amount)
	boss_damaged.emit(current_health, max_health)
	
	var ratio := current_health / max_health
	if ratio <= 0.65 and attack_phase == 1:
		attack_phase = 2
		attack_cooldown = 1.8
		if not has_summoned_reinforcements:
			has_summoned_reinforcements = true
			summon_escorts.emit("drone_attack", 3)
	elif ratio <= 0.3 and attack_phase == 2:
		attack_phase = 3
		attack_cooldown = 1.3
		summon_escorts.emit("combat_robot", 2)

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
			change_state(State.ATTACK) # Unstoppable super boss

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
	
	walk_cycle += delta * 5.0
	if visual_mesh:
		visual_mesh.position.y = abs(sin(walk_cycle)) * 0.14
		visual_mesh.rotation.z = sin(walk_cycle) * 0.03
		if horiz_dir.length_squared() > 0.001:
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(horiz_dir.x, horiz_dir.z), 5.0 * delta)
			
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
	
	if horizontal_dist > attack_range * 1.35:
		change_state(State.APPROACH)
		return
		
	var horiz_dir := Vector3(diff.x, 0.0, diff.z).normalized()
	if visual_mesh and horiz_dir.length_squared() > 0.001:
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(horiz_dir.x, horiz_dir.z), 7.0 * delta)
		
	attack_timer += delta
	if attack_timer >= attack_cooldown:
		attack_timer = 0.0
		_execute_apex_barrage()

func _execute_apex_barrage() -> void:
	if not target or not is_instance_valid(target):
		return
	var my_pos := global_position if is_inside_tree() else position
	var tgt_pos := target.global_position if target.is_inside_tree() else target.position
	
	# 1. Rotary Cannon salvo
	for side in [-1.5, 1.5]:
		var muzzle_pos := my_pos + Vector3(side, 1.8, 1.2)
		var target_pos := tgt_pos + Vector3(randf_range(-1.8, 1.8), randf_range(0.2, 1.2), 0.0)
		AudioManager.play_sound_at("enemy_shot", muzzle_pos, my_pos)
		bullet_fired.emit(muzzle_pos, target_pos)
		
	# 2. Quad Missile Barrage in Phase 2 & 3
	if attack_phase >= 2:
		for rx in [-0.8, 0.8]:
			var r_muzzle := my_pos + Vector3(rx, 3.2, 0.5)
			var r_target := tgt_pos + Vector3(randf_range(-2.0, 2.0), randf_range(0.2, 1.8), 0.0)
			AudioManager.play_sound_at("drone_rocket", r_muzzle, my_pos)
			rocket_fired.emit(r_muzzle, r_target)
			
	if target.has_method("apply_damage"):
		target.apply_damage(attack_damage)
	attack_performed.emit(target, attack_damage)

func _process_dead(delta: float) -> void:
	velocity = Vector3.ZERO
	death_sink_timer += delta
	if visual_mesh:
		visual_mesh.rotation.x = lerp_angle(visual_mesh.rotation.x, deg_to_rad(-60.0), 4.0 * delta)
		visual_mesh.position.y = -0.5 * death_sink_timer
	if death_sink_timer >= 2.5:
		queue_free()
