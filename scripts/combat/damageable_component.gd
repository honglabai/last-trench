class_name DamageableComponent
extends Node

signal damaged(amount: float, current_hp: float, max_hp: float)
signal destroyed()

@export var max_health: float = 100.0
var current_health: float = 100.0
var is_alive: bool = true

func _ready() -> void:
	current_health = max_health
	is_alive = current_health > 0.0

func apply_damage(amount: float) -> void:
	if not is_alive:
		return
	current_health = maxf(0.0, current_health - amount)
	damaged.emit(amount, current_health, max_health)
	if current_health <= 0.0:
		is_alive = false
		destroyed.emit()

func heal(amount: float) -> void:
	if not is_alive:
		return
	current_health = minf(max_health, current_health + amount)
	damaged.emit(-amount, current_health, max_health)
