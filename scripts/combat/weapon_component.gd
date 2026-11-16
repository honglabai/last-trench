class_name WeaponComponent
extends Node3D

signal fired(current_ammo: int, max_ammo: int)
signal reload_started()
signal reload_completed(current_ammo: int, reserve_ammo: int)
signal ammo_depleted()
signal hit_target(target: Object, point: Vector3, normal: Vector3, damage: float)
signal bullet_fired(origin: Vector3, target_point: Vector3)

@export var weapon_id: String = "rifle_basic"
@export var damage: float = 25.0
@export var fire_rate: float = 0.12 # Time between shots
@export var magazine_size: int = 30
@export var max_reserve_ammo: int = 180
@export var reload_time: float = 1.8
@export var range_distance: float = 80.0

var current_ammo: int = 30
var reserve_ammo: int = 120
var is_reloading: bool = false
var time_since_last_shot: float = 999.0
var reload_timer: float = 0.0

@onready var muzzle: Marker3D = $Muzzle

func _ready() -> void:
	load_weapon_data()

func load_weapon_data() -> void:
	var path := "res://data/weapons.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var json_str := file.get_as_text()
	var test_json = JSON.new()
	var parse_err = test_json.parse(json_str)
	if parse_err != OK:
		return
	var data: Dictionary = test_json.data
	if data.has(weapon_id):
		var w: Dictionary = data[weapon_id]
		damage = float(w.get("damage", damage))
		fire_rate = float(w.get("fire_rate", fire_rate))
		magazine_size = int(w.get("magazine_size", magazine_size))
		max_reserve_ammo = int(w.get("max_reserve_ammo", max_reserve_ammo))
		reload_time = float(w.get("reload_time", reload_time))
		range_distance = float(w.get("range", range_distance))
		current_ammo = magazine_size
		reserve_ammo = max_reserve_ammo

func _process(delta: float) -> void:
	time_since_last_shot += delta
	
	if is_reloading:
		reload_timer += delta
		if reload_timer >= reload_time:
			finish_reload()

func can_fire() -> bool:
	if is_reloading:
		return false
	if time_since_last_shot < fire_rate:
		return false
	if current_ammo <= 0:
		return false
	return true

func try_fire(origin: Vector3, direction: Vector3, space_state: PhysicsDirectSpaceState3D = null, exclude: Array[RID] = []) -> bool:
	if not can_fire():
		if current_ammo <= 0 and not is_reloading:
			ammo_depleted.emit()
		return false
		
	time_since_last_shot = 0.0
	current_ammo -= 1
	fired.emit(current_ammo, magazine_size)
	
	if space_state:
		var end_pos := origin + direction.normalized() * range_distance
		# Priority 1: Check Enemies (Layer 4) and Destructible units (Layer 8) so obstacles NEVER block hits on enemies
		var enemy_query := PhysicsRayQueryParameters3D.create(origin, end_pos, 4 | 8, exclude)
		enemy_query.collide_with_areas = true
		enemy_query.collide_with_bodies = true
		var result := space_state.intersect_ray(enemy_query)
		
		# Priority 2: If no enemy in line of fire, check environment/covers (Layer 1 | 16) for impact
		if result.is_empty():
			var env_query := PhysicsRayQueryParameters3D.create(origin, end_pos, 1 | 16, exclude)
			env_query.collide_with_areas = true
			env_query.collide_with_bodies = true
			result = space_state.intersect_ray(env_query)
		
		var target_pos := end_pos
		if not result.is_empty():
			var collider: Object = result.collider
			var hit_point: Vector3 = result.position
			var hit_normal: Vector3 = result.normal
			target_pos = hit_point
			
			_apply_hit(collider, hit_point, hit_normal)
			hit_target.emit(collider, hit_point, hit_normal, damage)
			
		bullet_fired.emit(origin, target_pos)
	else:
		bullet_fired.emit(origin, origin + direction.normalized() * range_distance)
			
	if current_ammo == 0:
		ammo_depleted.emit()
		
	return true

func _apply_hit(collider: Object, point: Vector3, normal: Vector3) -> void:
	if not collider:
		return
	if collider.has_method("apply_damage"):
		collider.apply_damage(damage)
	elif collider is Node:
		var dmg_comp := (collider as Node).get_node_or_null("DamageableComponent") as DamageableComponent
		if dmg_comp:
			dmg_comp.apply_damage(damage)

func start_reload() -> bool:
	if is_reloading or current_ammo >= magazine_size or reserve_ammo <= 0:
		return false
	is_reloading = true
	reload_timer = 0.0
	reload_started.emit()
	return true

func finish_reload() -> void:
	var needed := magazine_size - current_ammo
	var reload_amount := mini(needed, reserve_ammo)
	current_ammo += reload_amount
	reserve_ammo -= reload_amount
	is_reloading = false
	reload_timer = 0.0
	reload_completed.emit(current_ammo, reserve_ammo)
