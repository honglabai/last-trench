class_name BaseObjective
extends StaticBody3D

signal base_damaged(current_hp: float, max_hp: float)
signal base_destroyed()

@export var max_health: float = 500.0
var current_health: float = 500.0
var is_destroyed: bool = false

func _ready() -> void:
	current_health = max_health

func apply_damage(amount: float) -> void:
	if is_destroyed:
		return
	current_health = maxf(0.0, current_health - amount)
	base_damaged.emit(current_health, max_health)
	if current_health <= 0.0:
		is_destroyed = true
		base_destroyed.emit()

func repair(amount: float) -> void:
	if is_destroyed:
		return
	current_health = minf(max_health, current_health + amount)
	base_damaged.emit(current_health, max_health)
