class_name DefenseSlot
extends Node3D

signal turret_installed(turret: Node3D)
signal turret_removed()
signal interaction_available(can_install: bool, can_repair: bool)
signal interaction_unavailable()

@export var slot_id: String = "slot_1"
@export var allowed_types: Array[String] = ["mg_turret"]
@export var interaction_radius: float = 5.0

var is_occupied: bool = false
var installed_turret: TurretController = null
var is_player_nearby: bool = false

var _visual_marker: MeshInstance3D
var visual_marker: MeshInstance3D:
	get:
		if not _visual_marker:
			_visual_marker = get_node_or_null("VisualMarker")
		return _visual_marker

var _interaction_area: Area3D
var interaction_area: Area3D:
	get:
		if not _interaction_area:
			_interaction_area = get_node_or_null("InteractionArea")
		return _interaction_area

func _ready() -> void:
	if interaction_area:
		if not interaction_area.body_entered.is_connected(_on_body_entered):
			interaction_area.body_entered.connect(_on_body_entered)
		if not interaction_area.body_exited.is_connected(_on_body_exited):
			interaction_area.body_exited.connect(_on_body_exited)

func can_install() -> bool:
	return not is_occupied

func can_repair() -> bool:
	if is_occupied and installed_turret and is_instance_valid(installed_turret):
		return installed_turret.current_health < installed_turret.max_health
	return false

## Strict installation rule: Installs ONLY on this designated anchor slot
func install_turret(turret: TurretController) -> bool:
	if is_occupied:
		push_warning("Cannot install on occupied DefenseSlot: " + slot_id)
		return false
	if not turret:
		return false
		
	is_occupied = true
	installed_turret = turret
	add_child(turret)
	turret.position = Vector3.ZERO
	if visual_marker:
		visual_marker.visible = false
		
	turret_installed.emit(turret)
	_update_interaction_state()
	return true

func repair_turret(amount: float = 50.0) -> bool:
	if not is_occupied or not installed_turret or not is_instance_valid(installed_turret):
		return false
	installed_turret.repair(amount)
	_update_interaction_state()
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
	_update_interaction_state()

func _on_body_entered(body: Node) -> void:
	if body is PlayerController or body.name == "Player":
		is_player_nearby = true
		_update_interaction_state()

func _on_body_exited(body: Node) -> void:
	if body is PlayerController or body.name == "Player":
		is_player_nearby = false
		interaction_unavailable.emit()

func update_player_proximity(player_pos: Vector3) -> void:
	var my_pos := global_position if is_inside_tree() else position
	var dist := my_pos.distance_to(player_pos)
	var nearby := dist <= interaction_radius
	if nearby != is_player_nearby:
		is_player_nearby = nearby
		if is_player_nearby:
			_update_interaction_state()
		else:
			interaction_unavailable.emit()

func _update_interaction_state() -> void:
	if is_player_nearby:
		interaction_available.emit(can_install(), can_repair())
