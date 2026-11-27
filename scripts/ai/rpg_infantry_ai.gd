class_name RPGInfantryAI
extends InfantryAI

signal rocket_fired(start_pos: Vector3, target_pos: Vector3)

const PATH_RPG_RUN := "res://assets/textures/tex_enemy_rpg_soldier.png"
const PATH_RPG_AIM := "res://assets/textures/tex_enemy_rpg_aim.png"
const PATH_RPG_FIRE := "res://assets/textures/tex_enemy_rpg_fire.png"

var _tex_rpg_run: Texture2D = null
var _tex_rpg_aim: Texture2D = null
var _tex_rpg_fire: Texture2D = null

func _ready() -> void:
	super._ready()
	max_health = 75.0
	current_health = max_health
	armor_rating = 0.10
	enemy_role = "rpg_infantry"
	move_speed = 3.0
	attack_range = 32.0
	attack_damage = 28.0
	attack_cooldown = 3.2
	
	if ResourceLoader.exists(PATH_RPG_RUN):
		_tex_rpg_run = load(PATH_RPG_RUN) as Texture2D
	if ResourceLoader.exists(PATH_RPG_AIM):
		_tex_rpg_aim = load(PATH_RPG_AIM) as Texture2D
	if ResourceLoader.exists(PATH_RPG_FIRE):
		_tex_rpg_fire = load(PATH_RPG_FIRE) as Texture2D
	
	var dmg_comp := get_node_or_null("DamageableComponent") as DamageableComponent
	if dmg_comp:
		dmg_comp.max_health = max_health
		dmg_comp.current_health = max_health

func _update_soldier_pose(_delta: float = 0.0) -> void:
	if not soldier_sprite:
		return
	if fire_pose_timer > 0.0 and _tex_rpg_fire:
		if soldier_sprite.texture != _tex_rpg_fire:
			soldier_sprite.texture = _tex_rpg_fire
	elif current_state == State.ATTACK and _tex_rpg_aim:
		if soldier_sprite.texture != _tex_rpg_aim:
			soldier_sprite.texture = _tex_rpg_aim
	elif _tex_rpg_run:
		if soldier_sprite.texture != _tex_rpg_run:
			soldier_sprite.texture = _tex_rpg_run

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
		
	var horiz_dir := Vector3(diff.x, 0.0, diff.z).normalized()
	if visual_mesh and horiz_dir.length_squared() > 0.001:
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(horiz_dir.x, horiz_dir.z), 12.0 * delta)
		# Kneel/brace while aiming RPG-7
		visual_mesh.position.y = lerpf(visual_mesh.position.y, -0.10, 8.0 * delta)
		
	attack_timer += delta
	var is_telegraphing := attack_timer >= (attack_cooldown * 0.40) and fire_pose_timer <= 0.0
	_update_aim_laser(is_telegraphing)
	
	if attack_timer >= attack_cooldown:
		attack_timer = 0.0
		_execute_attack()

func _execute_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	var my_pos := global_position if is_inside_tree() else position
	var tgt_pos := target.global_position if target.is_inside_tree() else target.position
	var muzzle_pos := my_pos + Vector3(0.24, 1.30, 0.45)
	var target_pos := tgt_pos + Vector3(randf_range(-1.2, 1.2), randf_range(0.2, 1.0), 0.0)
	
	fire_pose_timer = 0.22
	muzzle_light_timer = 0.14
	recoil_kick = 0.22
	if muzzle_light:
		muzzle_light.visible = true
	_update_aim_laser(false)
	
	rocket_fired.emit(muzzle_pos, target_pos)
	launch_projectile(EnemyProjectile.ProjectileType.ROCKET, muzzle_pos, target_pos, attack_damage, 34.0, 5.5, target)
