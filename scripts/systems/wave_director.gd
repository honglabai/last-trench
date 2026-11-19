class_name WaveDirector
extends Node

signal wave_state_changed(new_state: int)
signal wave_started(wave_number: int, total_enemies: int)
signal enemy_spawned(enemy: EnemyBase, active_count: int)
signal enemy_killed(enemy: EnemyBase, remaining_in_wave: int, active_count: int)
signal wave_cleared(wave_number: int)
signal run_victory()
signal boss_spawned(boss_enemy: EnemyBase, boss_title: String, max_hp: float)
signal boss_damaged(cur_hp: float, max_hp: float)
signal boss_defeated(boss_enemy: EnemyBase, boss_title: String)
signal wave_event_triggered(event_name: String, wave_number: int)

enum WaveState { IDLE, PREPARATION, COMBAT, WAVE_CLEARED, VICTORY, GAME_OVER }

@export var max_active_enemies: int = 12
@export var default_spawn_interval: float = 1.0
@export var preparation_duration: float = 3.0
@export var max_waves_in_run: int = 15 # Full 15 waves

var current_state: WaveState = WaveState.IDLE
var current_wave_number: int = 0
var wave_plan_data: Dictionary = {}

var pending_spawn_queue: Array = []
var active_enemies: Array[EnemyBase] = []
var total_enemies_in_wave: int = 0
var killed_enemies_in_wave: int = 0

var spawn_timer: float = 0.0
var state_timer: float = 0.0
var victory_emitted: bool = false

# External references
var map_node: TrenchMap = null
var target_objective: Node3D = null
var enemy_parent: Node = null

var infantry_scene: PackedScene = preload("res://scenes/actors/enemy_infantry.tscn")
var drone_scene: PackedScene = preload("res://scenes/actors/enemy_drone.tscn")
var rpg_scene: PackedScene = preload("res://scenes/actors/enemy_rpg.tscn")
var robot_scene: PackedScene = preload("res://scenes/actors/enemy_robot.tscn")
var boss_drone_scene: PackedScene = preload("res://scenes/actors/boss_drone_commander.tscn")
var boss_robot_scene: PackedScene = preload("res://scenes/actors/boss_armored_robot.tscn")
var boss_final_scene: PackedScene = preload("res://scenes/actors/boss_final_assault.tscn")

func _ready() -> void:
	load_wave_plan()

func load_wave_plan(path: String = "res://data/wave_plan.json") -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return false
	wave_plan_data = json.data
	if wave_plan_data.has("max_active_enemies"):
		max_active_enemies = int(wave_plan_data["max_active_enemies"])
	return true

func set_battlefield_context(map: TrenchMap, objective: Node3D, parent: Node) -> void:
	map_node = map
	target_objective = objective
	enemy_parent = parent

func start_run(target_max_waves: int = 15) -> void:
	max_waves_in_run = target_max_waves
	current_wave_number = 0
	active_enemies.clear()
	pending_spawn_queue.clear()
	victory_emitted = false
	start_next_wave()

func start_next_wave() -> void:
	if current_wave_number >= max_waves_in_run:
		_trigger_victory()
		return
		
	current_wave_number += 1
	_change_state(WaveState.PREPARATION)
	state_timer = preparation_duration

func _change_state(new_state: WaveState) -> void:
	current_state = new_state
	wave_state_changed.emit(current_state)

func _process(delta: float) -> void:
	match current_state:
		WaveState.PREPARATION:
			state_timer -= delta
			if state_timer <= 0.0:
				_begin_combat()
		WaveState.COMBAT:
			_process_combat(delta)

func _begin_combat() -> void:
	_change_state(WaveState.COMBAT)
	_build_wave_queue(current_wave_number)
	total_enemies_in_wave = pending_spawn_queue.size()
	killed_enemies_in_wave = 0
	spawn_timer = 0.0
	wave_started.emit(current_wave_number, total_enemies_in_wave)

func _build_wave_queue(wave_num: int) -> void:
	pending_spawn_queue.clear()
	var waves_list: Array = wave_plan_data.get("waves", [])
	var wave_info: Dictionary = {}
	for w in waves_list:
		if int(w.get("id", 0)) == wave_num:
			wave_info = w
			break
			
	if wave_info.is_empty():
		# Fallback defaults if json missing
		if wave_num == 1:
			for i in range(4): pending_spawn_queue.append("infantry_basic")
		elif wave_num == 2:
			for i in range(5): pending_spawn_queue.append("infantry_basic")
			for i in range(2): pending_spawn_queue.append("drone_attack")
		elif wave_num == 3:
			for i in range(6): pending_spawn_queue.append("infantry_basic")
			for i in range(4): pending_spawn_queue.append("drone_attack")
		return
		
	# Trigger wave events and boss warnings
	var events: Array = wave_info.get("events", [])
	for ev in events:
		wave_event_triggered.emit(str(ev), wave_num)
	if wave_info.get("boss", false):
		wave_event_triggered.emit("boss_wave", wave_num)
		
	var enemy_dict: Dictionary = wave_info.get("enemy_total", {})
	for enemy_type in enemy_dict:
		var count := int(enemy_dict[enemy_type])
		for i in range(count):
			pending_spawn_queue.append(enemy_type)

func _process_combat(delta: float) -> void:
	# 1. Pacing & Cap check
	if not pending_spawn_queue.is_empty():
		spawn_timer += delta
		if spawn_timer >= default_spawn_interval:
			# Strict cap enforcement: active_enemies < max_active_enemies
			if active_enemies.size() < max_active_enemies:
				spawn_timer = 0.0
				var enemy_type: String = pending_spawn_queue.pop_front()
				_spawn_enemy(enemy_type)
				
	# 2. Check wave completion
	if pending_spawn_queue.is_empty() and active_enemies.is_empty():
		_on_wave_completed()

func _spawn_enemy(type_name: String) -> EnemyBase:
	var enemy_instance: EnemyBase = null
	var is_air: bool = (type_name == "drone_attack" or type_name == "drone_swarm_commander")
	
	match type_name:
		"drone_attack":
			enemy_instance = drone_scene.instantiate() as EnemyBase
		"rpg_infantry":
			enemy_instance = rpg_scene.instantiate() as EnemyBase
		"combat_robot":
			enemy_instance = robot_scene.instantiate() as EnemyBase
		"drone_swarm_commander":
			enemy_instance = boss_drone_scene.instantiate() as EnemyBase
		"armored_robot_boss":
			enemy_instance = boss_robot_scene.instantiate() as EnemyBase
		"final_assault_boss":
			enemy_instance = boss_final_scene.instantiate() as EnemyBase
		_:
			enemy_instance = infantry_scene.instantiate() as EnemyBase
		
	if not enemy_instance:
		return null
		
	# Wire boss specific events and health reporting
	if enemy_instance.get("is_boss") == true:
		var b_title: String = str(enemy_instance.get("boss_title"))
		if enemy_instance.has_signal("boss_damaged"):
			enemy_instance.connect("boss_damaged", func(c, m): boss_damaged.emit(c, m))
		if enemy_instance.has_signal("summon_escorts"):
			enemy_instance.connect("summon_escorts", func(escort_type: String, count: int):
				for i in range(count):
					pending_spawn_queue.push_front(escort_type)
				total_enemies_in_wave += count
			)
		boss_spawned.emit(enemy_instance, b_title, enemy_instance.max_health)
		
	# Select spawn position strictly in front
	var spawn_pos := Vector3(0, 0, -35.0)
	if map_node:
		if is_air:
			var pts := map_node.get_air_spawn_positions()
			if not pts.is_empty():
				spawn_pos = pts[randi() % pts.size()]
		else:
			var pts := map_node.get_ground_spawn_positions()
			if not pts.is_empty():
				spawn_pos = pts[randi() % pts.size()]
	elif is_air:
		spawn_pos = Vector3(0, 9.0, -35.0)
		
	enemy_instance.position = spawn_pos
	if target_objective:
		enemy_instance.set_target(target_objective)
		
	enemy_instance.enemy_died.connect(_on_enemy_died)
	
	if enemy_parent:
		enemy_parent.add_child(enemy_instance)
	else:
		add_child(enemy_instance)
		
	active_enemies.append(enemy_instance)
	enemy_spawned.emit(enemy_instance, active_enemies.size())
	return enemy_instance

func _on_enemy_died(enemy: EnemyBase) -> void:
	if active_enemies.has(enemy):
		active_enemies.erase(enemy)
	killed_enemies_in_wave += 1
	var remaining := total_enemies_in_wave - killed_enemies_in_wave
	enemy_killed.emit(enemy, remaining, active_enemies.size())
	if enemy.get("is_boss") == true:
		boss_defeated.emit(enemy, str(enemy.get("boss_title")))

func _on_wave_completed() -> void:
	_change_state(WaveState.WAVE_CLEARED)
	wave_cleared.emit(current_wave_number)
	if current_wave_number >= max_waves_in_run:
		_trigger_victory()
	else:
		start_next_wave()

func _trigger_victory() -> void:
	if victory_emitted:
		return
	victory_emitted = true
	_change_state(WaveState.VICTORY)
	run_victory.emit()
