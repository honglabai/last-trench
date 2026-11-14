class_name DestructibleCover
extends StaticBody3D

signal cover_damaged(current_hp: float, max_hp: float)
signal cover_destroyed()

@export var max_health: float = 120.0
var current_health: float = 120.0
var is_broken: bool = false

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	current_health = max_health

func apply_damage(amount: float) -> void:
	if is_broken:
		return
	current_health = maxf(0.0, current_health - amount)
	cover_damaged.emit(current_health, max_health)
	
	if current_health <= 0.0:
		break_cover()
	else:
		_update_damage_visual()

func repair(amount: float) -> void:
	current_health = minf(max_health, current_health + amount)
	if is_broken and current_health > 0.0:
		is_broken = false
		collision_shape.set_deferred("disabled", false)
	_update_damage_visual()
	cover_damaged.emit(current_health, max_health)

func break_cover() -> void:
	is_broken = true
	collision_shape.set_deferred("disabled", true)
	if mesh_instance:
		mesh_instance.visible = false
	cover_destroyed.emit()

func _update_damage_visual() -> void:
	if not mesh_instance or is_broken:
		return
	var ratio := current_health / max_health
	# Slight darkening/tinting on damage
	if mesh_instance.get_surface_override_material(0):
		var mat: StandardMaterial3D = mesh_instance.get_surface_override_material(0)
		mat.albedo_color = Color(0.6 * ratio + 0.2, 0.5 * ratio + 0.1, 0.3 * ratio)
