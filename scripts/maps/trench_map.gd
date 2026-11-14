class_name TrenchMap
extends Node3D

@onready var player_start: Marker3D = $PlayerStart
@onready var base_objective: BaseObjective = $BaseObjective
@onready var ground_spawns_container: Node3D = $Spawns/GroundSpawns
@onready var air_spawns_container: Node3D = $Spawns/AirSpawns
@onready var defense_slots_container: Node3D = $DefenseSlots

func _ready() -> void:
	_resolve_references()

func _resolve_references() -> void:
	if not player_start:
		player_start = get_node_or_null("PlayerStart")
	if not base_objective:
		base_objective = get_node_or_null("BaseObjective")
	if not ground_spawns_container:
		ground_spawns_container = get_node_or_null("Spawns/GroundSpawns")
	if not air_spawns_container:
		air_spawns_container = get_node_or_null("Spawns/AirSpawns")
	if not defense_slots_container:
		defense_slots_container = get_node_or_null("DefenseSlots")

func get_player_start_transform() -> Transform3D:
	_resolve_references()
	if player_start:
		return player_start.global_transform if player_start.is_inside_tree() else player_start.transform
	return Transform3D.IDENTITY

func get_base_objective() -> BaseObjective:
	_resolve_references()
	return base_objective

func get_ground_spawn_positions() -> Array[Vector3]:
	_resolve_references()
	var positions: Array[Vector3] = []
	if ground_spawns_container:
		for child in ground_spawns_container.get_children():
			if child is Marker3D:
				var pos: Vector3 = child.global_position if child.is_inside_tree() else child.position
				positions.append(pos)
	return positions

func get_air_spawn_positions() -> Array[Vector3]:
	_resolve_references()
	var positions: Array[Vector3] = []
	if air_spawns_container:
		for child in air_spawns_container.get_children():
			if child is Marker3D:
				var pos: Vector3 = child.global_position if child.is_inside_tree() else child.position
				positions.append(pos)
	return positions

func get_defense_slots() -> Array[DefenseSlot]:
	_resolve_references()
	var slots: Array[DefenseSlot] = []
	if defense_slots_container:
		for child in defense_slots_container.get_children():
			if child is DefenseSlot:
				slots.append(child)
	return slots

## Validates strict front-facing spawn constraints according to project invariant rules
func validate_front_spawns() -> Dictionary:
	var errors: Array[String] = []
	var ground_pts := get_ground_spawn_positions()
	var air_pts := get_air_spawn_positions()
	
	if ground_pts.is_empty():
		errors.append("No ground spawn points found")
	if air_pts.is_empty():
		errors.append("No air spawn points found")
		
	# Rule: Enemies must spawn strictly in FRONT of the trench defense line (Z < -15.0)
	for pt in ground_pts:
		if pt.z >= -15.0:
			errors.append("Ground spawn point out of front hemisphere: " + str(pt))
			
	for pt in air_pts:
		if pt.z >= -15.0:
			errors.append("Air spawn point out of front hemisphere: " + str(pt))
		if pt.y < 5.0:
			errors.append("Air spawn point altitude too low: " + str(pt))
			
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"ground_count": ground_pts.size(),
		"air_count": air_pts.size()
	}
