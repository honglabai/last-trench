class_name TankAI
extends EnemyBase

signal cannon_fired(start_pos: Vector3, target_pos: Vector3)

var track_cycle: float = 0.0
var death_sink_timer: float = 0.0

func _ready() -> void:
	super._ready()
	max_health = 520.0
	current_health = max_health
	armor_rating = 0.60
	enemy_role = "heavy_tank"
	move_speed = 1.6
	attack_range = 26.0
	attack_damage = 55.0
	attack_cooldown = 3.6

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
			_process_attack(delta)

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
		attack_timer = attack_cooldown * 0.6
		change_state(State.ATTACK)
		return

	var horiz_dir := Vector3(diff.x, 0.0, diff.z).normalized()
	velocity.x = horiz_dir.x * move_speed
	velocity.z = horiz_dir.z * move_speed

	track_cycle += delta * 8.0
	if visual_mesh:
		visual_mesh.position.y = abs(sin(track_cycle)) * 0.03
		if horiz_dir.length_squared() > 0.001:
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(horiz_dir.x, horiz_dir.z), 4.0 * delta)

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

	if horizontal_dist > attack_range * 1.25:
		change_state(State.APPROACH)
		return

	var horiz_dir := Vector3(diff.x, 0.0, diff.z).normalized()
	if visual_mesh and horiz_dir.length_squared() > 0.001:
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(horiz_dir.x, horiz_dir.z), 5.0 * delta)

	attack_timer -= delta
	if attack_timer <= 0.0:
		attack_timer = attack_cooldown
		var start_p := my_pos + Vector3(0.0, 1.4, 0.0)
		var end_p := tgt_pos + Vector3(0.0, 0.8, 0.0)
		cannon_fired.emit(start_p, end_p)
		launch_projectile(1, start_p, end_p, attack_damage, 30.0, 4.2, target)

func _process_dead(delta: float) -> void:
	death_sink_timer += delta
	if visual_mesh:
		visual_mesh.position.y -= 0.7 * delta
	if death_sink_timer >= 1.2:
		queue_free()
