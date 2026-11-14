class_name DefenseSlot
extends Node3D

signal turret_installed(turret: Node3D)
signal turret_removed()

@export var slot_id: String = "slot_1"
@export var allowed_types: Array[String] = ["mg_turret"]

var is_occupied: bool = false
var installed_turret: Node3D = null

@onready var visual_marker: MeshInstance3D = $VisualMarker
@onready var interaction_area: Area3D = $InteractionArea

func can_install() -> bool:
	return not is_occupied

func install_turret(turret: Node3D) -> bool:
	if is_occupied:
		return false
	is_occupied = true
	installed_turret = turret
	add_child(turret)
	turret.position = Vector3.ZERO
	if visual_marker:
		visual_marker.visible = false
	turret_installed.emit(turret)
	return true

func remove_turret() -> void:
	if not is_occupied:
		return
	if installed_turret and is_instance_valid(installed_turret):
		installed_turret.queue_free()
	installed_turret = null
	is_occupied = false
	if visual_marker:
		visual_marker.visible = true
	turret_removed.emit()
