class_name TurretController
extends StaticBody3D

signal turret_fired(target: Node3D, damage: float)
signal turret_damaged(current_hp: float, max_hp: float)
signal turret_broken()
signal turret_repaired()
signal bullet_fired(origin: Vector3, target_point: Vector3)

@export var max_health: float = 150.0
@export var attack_range: float = 22.0
@export var fire_rate: float = 0.25 # Seconds between shots
@export var damage: float = 12.0

var current_health: float = 150.0
var is_broken: bool = false
var fire_timer: float = 0.0
var current_target: Node3D = null

var manual_target_override: Node3D = null

var _swivel: Node3D
var swivel: Node3D:
	get:
		if not _swivel:
			_swivel = get_node_or_null("Swivel")
		return _swivel

var _barrel: Node3D
var barrel: Node3D:
	get:
		if not _barrel:
			_barrel = get_node_or_null("Swivel/Barrel")
		return _barrel

var _range_area: Area3D
var range_area: Area3D:
	get:
		if not _range_area:
			_range_area = get_node_or_null("RangeArea")
		return _range_area

func _ready() -> void:
	current_health = max_health
	collision_layer = 8 # Defense layer
	collision_mask = 0

func _physics_process(delta: float) -> void:
	if is_broken:
		return
		
	# 1. Update target
	_update_target()
	
	if not current_target or not is_instance_valid(current_target):
		return
		
	# 2. Aim at target
	_aim_at_target(delta)
	
	# 3. Fire at target
	fire_timer += delta
	if fire_timer >= fire_rate:
		fire_timer = 0.0
		_fire_at_target(current_target)

func _update_target() -> void:
	if manual_target_override and is_instance_valid(manual_target_override):
		if not _is_target_dead(manual_target_override):
			var dist := _get_distance_to(manual_target_override)
			if dist <= attack_range:
				current_target = manual_target_override
				return
				
	# Search overlapping bodies in RangeArea or scene tree
	var best_target: Node3D = null
	var closest_dist := attack_range
	
	if range_area:
		for body in range_area.get_overlapping_bodies():
			if body is EnemyBase and not body.is_dead:
				var dist := _get_distance_to(body)
				if dist < closest_dist:
					closest_dist = dist
					best_target = body
					
	current_target = best_target

func _get_distance_to(node: Node3D) -> float:
	var my_pos := global_position if is_inside_tree() else position
	var target_pos := node.global_position if node.is_inside_tree() else node.position
	return my_pos.distance_to(target_pos)

func _is_target_dead(node: Node3D) -> bool:
	if node is EnemyBase:
		return node.is_dead
	return false

func _aim_at_target(delta: float) -> void:
	if not current_target:
		return
	var my_pos := global_position if is_inside_tree() else position
	var target_pos := current_target.global_position if current_target.is_inside_tree() else current_target.position
	var aim_diff := target_pos - my_pos
	
	if swivel:
		var horiz_angle := atan2(aim_diff.x, -aim_diff.z) # Godot forward is -Z
		swivel.rotation.y = lerp_angle(swivel.rotation.y, horiz_angle, 15.0 * delta)
		
	if barrel:
		var horiz_dist := Vector2(aim_diff.x, aim_diff.z).length()
		var vert_angle := atan2(aim_diff.y, horiz_dist)
		barrel.rotation.x = lerp_angle(barrel.rotation.x, vert_angle, 15.0 * delta)

func _fire_at_target(target_node: Node3D) -> void:
	if not target_node or not is_instance_valid(target_node):
		return
	if target_node.has_method("apply_damage"):
		target_node.apply_damage(damage)
	turret_fired.emit(target_node, damage)
	var origin := (barrel.global_position if (barrel and barrel.is_inside_tree()) else global_position) if is_inside_tree() else (position + Vector3(0.0, 1.2, 0.0))
	var target_pos := (target_node.global_position if target_node.is_inside_tree() else target_node.position) + Vector3(0.0, 0.8, 0.0)
	bullet_fired.emit(origin, target_pos)

func apply_damage(amount: float) -> void:
	if is_broken:
		return
	current_health = maxf(0.0, current_health - amount)
	turret_damaged.emit(current_health, max_health)
	
	if current_health <= 0.0:
		is_broken = true
		turret_broken.emit()

func repair(amount: float) -> void:
	current_health = minf(max_health, current_health + amount)
	turret_damaged.emit(current_health, max_health)
	if is_broken and current_health > 0.0:
		is_broken = false
		turret_repaired.emit()
