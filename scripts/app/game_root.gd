class_name GameRoot
extends Node3D

var _trench_map: TrenchMap
var trench_map: TrenchMap:
	get:
		if not _trench_map: _trench_map = get_node_or_null("TrenchMap")
		return _trench_map

var _player: PlayerController
var player: PlayerController:
	get:
		if not _player: _player = get_node_or_null("Player")
		return _player

var _wave_director: WaveDirector
var wave_director: WaveDirector:
	get:
		if not _wave_director: _wave_director = get_node_or_null("WaveDirector")
		return _wave_director

var _game_session: GameSession
var game_session: GameSession:
	get:
		if not _game_session: _game_session = get_node_or_null("GameSession")
		return _game_session

var _touch_controls: TouchControls
var touch_controls: TouchControls:
	get:
		if not _touch_controls: _touch_controls = get_node_or_null("TouchControls")
		return _touch_controls

var _battle_hud: BattleHUD
var battle_hud: BattleHUD:
	get:
		if not _battle_hud: _battle_hud = get_node_or_null("BattleHUD")
		return _battle_hud

var _enemy_container: Node3D
var enemy_container: Node3D:
	get:
		if not _enemy_container: _enemy_container = get_node_or_null("Enemies")
		return _enemy_container

var active_slot_nearby: DefenseSlot = null
var turret_scene: PackedScene = preload("res://scenes/defenses/mg_turret.tscn")
var _is_initialized: bool = false

func _ready() -> void:
	if _is_initialized:
		return
	_is_initialized = true
	# 1. Place player at trench map start transform
	if trench_map and player:
		player.global_transform = trench_map.get_player_start_transform()
		
	# 2. Wire Player to HUD
	if player and battle_hud:
		player.player_damaged.connect(func(cur, max_hp): battle_hud.update_player_health(cur, max_hp))
		player.aiming_changed.connect(func(is_aiming): battle_hud.set_crosshair_aim(is_aiming))
		battle_hud.update_player_health(player.current_health, player.max_health)
		
		if player.weapon:
			player.weapon.fired.connect(func(cur, _max):
				battle_hud.update_ammo(cur, player.weapon.reserve_ammo)
			)
			player.weapon.reload_started.connect(func():
				battle_hud.set_reload_indicator(true)
			)
			player.weapon.reload_completed.connect(func(cur, res):
				battle_hud.set_reload_indicator(false)
				battle_hud.update_ammo(cur, res)
			)
			battle_hud.update_ammo(player.weapon.current_ammo, player.weapon.reserve_ammo)
			
	# 3. Wire Base to HUD
	var base_obj := trench_map.get_base_objective() if trench_map else null
	if base_obj and battle_hud:
		base_obj.base_damaged.connect(func(cur, max_hp): battle_hud.update_base_health(cur, max_hp))
		battle_hud.update_base_health(base_obj.current_health, base_obj.max_health)
		
	# 4. Wire TouchControls to Player
	if touch_controls and player:
		touch_controls.move_vector_changed.connect(func(vec):
			player.manual_input_override = true
			player.input_move_vector = vec
		)
		touch_controls.look_delta_produced.connect(func(delta_look):
			if player.camera_rig:
				player.camera_rig.handle_look_input(delta_look)
		)
		touch_controls.fire_pressed.connect(func(pressed):
			player.is_firing_requested = pressed
		)
		touch_controls.aim_toggled.connect(func():
			player.is_aiming = touch_controls.is_aim_active
		)
		touch_controls.reload_requested.connect(func():
			if player.weapon:
				player.weapon.start_reload()
		)
		touch_controls.interact_requested.connect(_on_interact_requested)
		
	# 5. Wire DefenseSlots proximity
	if trench_map:
		for slot in trench_map.get_defense_slots():
			slot.interaction_available.connect(func(can_inst, can_rep):
				active_slot_nearby = slot
				var label := "포탑 설치 [E]" if can_inst else ("포탑 수리 [E]" if can_rep else "")
				if touch_controls:
					touch_controls.set_interact_available(can_inst or can_rep, label)
			)
			slot.interaction_unavailable.connect(func():
				if active_slot_nearby == slot:
					active_slot_nearby = null
					if touch_controls:
						touch_controls.set_interact_available(false)
			)
			
	# 6. Wire WaveDirector
	if wave_director:
		wave_director.set_battlefield_context(trench_map, base_obj, enemy_container)
		wave_director.wave_state_changed.connect(_on_wave_state_changed)
		wave_director.wave_started.connect(func(w_num, total):
			battle_hud.update_wave(w_num, wave_director.max_waves_in_run, "교전 시작! (적: %d)" % total)
		)
		wave_director.enemy_killed.connect(func(_e, remaining, _act):
			battle_hud.update_wave(wave_director.current_wave_number, wave_director.max_waves_in_run, "남은 적: %d" % remaining)
		)
		wave_director.wave_cleared.connect(func(w_num):
			battle_hud.update_wave(w_num, wave_director.max_waves_in_run, "웨이브 %d 클리어!" % w_num)
		)
		
	# 7. Wire GameSession
	if game_session:
		game_session.start_session(player, base_obj, wave_director)
		game_session.player_revived.connect(func(left, _hp):
			battle_hud.update_revives(left)
			battle_hud.update_player_health(player.current_health, player.max_health)
		)
		game_session.session_victory.connect(func():
			battle_hud.show_victory()
		)
		game_session.session_defeat.connect(func(reason):
			battle_hud.show_defeat(reason)
		)
		battle_hud.update_revives(game_session.revives_remaining)
		
	# 8. HUD Buttons
	if battle_hud:
		battle_hud.restart_requested.connect(func():
			get_tree().reload_current_scene()
		)
		battle_hud.menu_requested.connect(func():
			get_tree().change_scene_to_file("res://scenes/app/main_menu.tscn")
		)
		
	# 9. Start the run
	if wave_director:
		wave_director.start_run(3)

func _physics_process(_delta: float) -> void:
	# Update slots with player position for proximity detection
	if trench_map and player:
		for slot in trench_map.get_defense_slots():
			slot.update_player_proximity(player.global_position)

func _unhandled_input(event: InputEvent) -> void:
	# Keyboard shortcut for DefenseSlot interaction
	if event.is_action_pressed("interact"):
		_on_interact_requested()
	# Web/Desktop Mouse capture: click to lock, ESC to unlock
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_wave_state_changed(state: int) -> void:
	if not battle_hud or not wave_director:
		return
	if state == WaveDirector.WaveState.PREPARATION:
		battle_hud.update_wave(wave_director.current_wave_number, wave_director.max_waves_in_run, "정비 시간...")
	elif state == WaveDirector.WaveState.COMBAT:
		battle_hud.update_wave(wave_director.current_wave_number, wave_director.max_waves_in_run, "적 공세 방어 중!")

func _on_interact_requested() -> void:
	if not active_slot_nearby:
		return
	if active_slot_nearby.can_install():
		var turret = turret_scene.instantiate() as TurretController
		active_slot_nearby.install_turret(turret)
	elif active_slot_nearby.can_repair():
		active_slot_nearby.repair_turret(50.0)
