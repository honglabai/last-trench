class_name RPGInfantryAI
extends InfantryAI

signal rocket_fired(start_pos: Vector3, target_pos: Vector3)

func _ready() -> void:
	super._ready()
	max_health = 85.0
	current_health = max_health
	move_speed = 2.8
	attack_range = 22.0
	attack_damage = 25.0
	attack_cooldown = 3.2
	
	var dmg_comp := get_node_or_null("DamageableComponent") as DamageableComponent
	if dmg_comp:
		dmg_comp.max_health = max_health
		dmg_comp.current_health = max_health

func _execute_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	var my_pos := global_position if is_inside_tree() else position
	var tgt_pos := target.global_position if target.is_inside_tree() else target.position
	var muzzle_pos := my_pos + Vector3(0.26, 1.25, 0.4)
	var target_pos := tgt_pos + Vector3(randf_range(-1.2, 1.2), randf_range(0.2, 1.0), 0.0)
	
	rocket_fired.emit(muzzle_pos, target_pos)
	launch_projectile(EnemyProjectile.ProjectileType.ROCKET, muzzle_pos, target_pos, attack_damage, 34.0, 5.5, target)
