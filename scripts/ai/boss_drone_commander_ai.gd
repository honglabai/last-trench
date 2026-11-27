class_name BossDroneCommanderAI
extends DroneAI

signal boss_damaged(cur_hp: float, max_hp: float)
signal summon_escorts(escort_type: String, count: int)

@export var is_boss: bool = true
@export var boss_title: String = "드론 군집 지휘체"

var has_summoned_60: bool = false
var has_summoned_30: bool = false

func _ready() -> void:
	super._ready()
	max_health = 780.0
	current_health = max_health
	armor_rating = 0.40
	enemy_role = "boss_drone"
	cruise_altitude = 11.0
	move_speed = 3.0
	attack_range = 25.0
	attack_damage = 22.0
	attack_cooldown = 2.2
	
	var dmg_comp := get_node_or_null("DamageableComponent") as DamageableComponent
	if dmg_comp:
		dmg_comp.max_health = max_health
		dmg_comp.current_health = max_health

func apply_damage(amount: float, damage_type: String = "ballistic") -> void:
	super.apply_damage(amount, damage_type)
	boss_damaged.emit(current_health, max_health)
	
	# Reinforcement summoning threshold checks
	var ratio := current_health / max_health
	if ratio <= 0.6 and not has_summoned_60:
		has_summoned_60 = true
		summon_escorts.emit("drone_attack", 2)
	elif ratio <= 0.3 and not has_summoned_30:
		has_summoned_30 = true
		summon_escorts.emit("drone_attack", 2)

func _execute_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	var my_pos := global_position if is_inside_tree() else position
	var tgt_pos := target.global_position if target.is_inside_tree() else target.position
	
	# Twin heavy missile barrage from dual launch pods
	for side in [-0.9, 0.9]:
		var muzzle_pos := my_pos + Vector3(side, -0.4, 0.6)
		var target_pos := tgt_pos + Vector3(randf_range(-1.4, 1.4), randf_range(0.2, 1.2), 0.0)
		rocket_fired.emit(muzzle_pos, target_pos)
		launch_projectile(EnemyProjectile.ProjectileType.MISSILE_SALVO, muzzle_pos, target_pos, attack_damage * 0.5, 36.0, 4.0, target)
