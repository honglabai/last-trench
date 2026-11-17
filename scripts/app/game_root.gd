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
var tracer_scene: PackedScene = preload("res://scenes/effects/bullet_tracer.tscn")
var _is_initialized: bool = false

func _ready() -> void:
	if _is_initialized:
		return
	_is_initialized = true
	AudioManager.ensure_instance(self)
	# 1. Place player at trench map start transform
	if trench_map and player:
		player.global_transform = trench_map.get_player_start_transform()
		
	# 2. Wire Player to HUD
	if player and battle_hud:
		player.player_damaged.connect(func(cur, max_hp): battle_hud.update_player_health(cur, max_hp))
		player.aiming_changed.connect(func(is_aiming): battle_hud.set_crosshair_aim(is_aiming))
		battle_hud.update_player_health(player.current_health, player.max_health)
		
		if player.weapon:
			player.weapon.bullet_fired.connect(_on_bullet_fired)
			player.weapon.fired.connect(func(cur, _max):
				battle_hud.update_ammo(cur, player.weapon.reserve_ammo)
				battle_hud.trigger_weapon_fire()
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
		touch_controls.touch_detected.connect(func():
			player.manual_input_override = true
		)
		touch_controls.move_vector_changed.connect(func(vec):
			player.manual_input_override = true
			player.input_move_vector = vec
		)
		touch_controls.look_delta_produced.connect(func(delta_look):
			if player.camera_rig:
				player.camera_rig.handle_look_input(delta_look)
		)
		touch_controls.fire_pressed.connect(func(pressed):
			player.manual_input_override = true
			player.is_firing_requested = pressed
		)
		touch_controls.aim_toggled.connect(func():
			player.manual_input_override = true
			player.is_aiming = touch_controls.is_aim_active
		)
		touch_controls.reload_requested.connect(func():
			player.manual_input_override = true
			if player.weapon:
				player.weapon.start_reload()
		)
		touch_controls.interact_requested.connect(_on_interact_requested)
		touch_controls.weapon_switch_requested.connect(func():
			if battle_hud:
				battle_hud.open_armory_shop()
		)
		
	# 5. Wire DefenseSlots proximity
	if trench_map:
		for slot in trench_map.get_defense_slots():
			slot.turret_installed.connect(func(t):
				if t and t.has_signal("bullet_fired"):
					t.bullet_fired.connect(func(start_p, target_p):
						_spawn_tracer(start_p, target_p, 200.0, Color(1.0, 0.45, 0.1))
					)
				if touch_controls and active_slot_nearby == slot:
					touch_controls.set_interact_available(slot.can_repair(), "포탑 수리 [E]")
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
		wave_director.enemy_spawned.connect(func(enemy, _count):
			if enemy and enemy.has_signal("bullet_fired"):
				enemy.bullet_fired.connect(func(start_p, target_p):
					_spawn_tracer(start_p, target_p, 140.0, Color(1.0, 0.22, 0.12), 0.045, 0.85)
				)
			if enemy and enemy.has_signal("rocket_fired"):
				enemy.rocket_fired.connect(func(start_p, target_p):
					_spawn_tracer(start_p, target_p, 68.0, Color(1.0, 0.18, 0.35), 0.09, 1.4)
				)
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
		game_session.credits_changed.connect(func(credits):
			battle_hud.update_credits(credits)
		)
		battle_hud.update_revives(game_session.revives_remaining)
		battle_hud.update_credits(GameSession.credits)
		
	# 8. HUD Buttons & Modals
	if battle_hud:
		battle_hud.restart_requested.connect(func():
			get_tree().reload_current_scene()
		)
		battle_hud.menu_requested.connect(func():
			get_tree().change_scene_to_file("res://scenes/app/main_menu.tscn")
		)
		battle_hud.modal_visibility_changed.connect(func(is_open):
			if touch_controls:
				touch_controls.set_input_locked(is_open)
			if is_open:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			elif not OS.has_feature("mobile"):
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		)
		battle_hud.weapon_changed.connect(func(w_id):
			if player and player.weapon:
				player.weapon.load_weapon_data(w_id, GameSession.get_weapon_level(w_id))
				battle_hud.update_ammo(player.weapon.current_ammo, player.weapon.reserve_ammo)
		)
		
	# 9. Start the run
	if wave_director:
		wave_director.start_run(3)

func _physics_process(_delta: float) -> void:
	if trench_map and player:
		var slots = trench_map.get_defense_slots()
		for slot in slots:
			slot.update_player_proximity(player.global_position)
			
		# Look-targeted slot selection for stationary bunker defense
		var best_slot: DefenseSlot = null
		var best_dot: float = 0.25 # Require facing toward the slot sector
		var cam_forward := Vector3.FORWARD
		if player.camera_rig:
			cam_forward = player.camera_rig.get_camera_forward()
			
		for slot in slots:
			if slot.is_player_nearby and (slot.can_install() or slot.can_repair()):
				var to_slot = (slot.global_position - player.global_position).normalized()
				var dot = cam_forward.dot(to_slot)
				if dot > best_dot:
					best_dot = dot
					best_slot = slot
					
		if best_slot != active_slot_nearby:
			active_slot_nearby = best_slot
			if active_slot_nearby:
				var slot_name = "좌측 포탑" if active_slot_nearby.slot_id.contains("left") else ("우측 포탑" if active_slot_nearby.slot_id.contains("right") else "포탑")
				var action_str = "설치" if active_slot_nearby.can_install() else "수리"
				var label_text = "%s %s [E]" % [slot_name, action_str]
				if touch_controls:
					touch_controls.set_interact_available(true, label_text)
			else:
				if touch_controls:
					touch_controls.set_interact_available(false)

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
	if active_slot_nearby:
		if active_slot_nearby.can_install():
			var turret = turret_scene.instantiate() as TurretController
			active_slot_nearby.install_turret(turret)
			AudioManager.play_sound("turret_shot", 0.05, -2.0)
			return
		elif active_slot_nearby.can_repair():
			active_slot_nearby.repair_turret(50.0)
			AudioManager.play_sound("reload", 0.05)
			return
			
	# If player taps Turret button when not directly colliding with a slot, auto-target nearest slot
	if trench_map:
		var slots = [trench_map.defense_slot_left, trench_map.defense_slot_right]
		var best_slot: DefenseSlot = null
		var min_dist: float = 999.0
		var p_pos: Vector3 = player.global_position if (player and player.is_inside_tree()) else Vector3.ZERO
		for slot in slots:
			if slot and is_instance_valid(slot):
				var s_pos: Vector3 = slot.global_position if slot.is_inside_tree() else slot.position
				var d: float = (s_pos - p_pos).length()
				if d < min_dist:
					min_dist = d
					best_slot = slot
		if best_slot:
			if best_slot.can_install():
				var turret = turret_scene.instantiate() as TurretController
				best_slot.install_turret(turret)
				AudioManager.play_sound("turret_shot", 0.05, -2.0)
			elif best_slot.can_repair():
				best_slot.repair_turret(50.0)
				AudioManager.play_sound("reload", 0.05)

func _on_bullet_fired(start_pos: Vector3, target_pos: Vector3) -> void:
	var muzzle_start := start_pos
	if player and player.camera_rig and player.camera_rig.camera:
		var cam: Camera3D = player.camera_rig.camera
		var basis_cam := cam.global_transform.basis
		# Originating from authentic gun barrel point below eye level directly toward aim target
		muzzle_start = cam.global_position - basis_cam.y * 0.12 - basis_cam.z * 0.25
	_spawn_tracer(muzzle_start, target_pos, 220.0, Color(1.0, 0.88, 0.25))

func _spawn_tracer(start_pos: Vector3, target_pos: Vector3, speed: float, color: Color, custom_radius: float = 0.035, custom_len: float = 0.9) -> void:
	if not tracer_scene:
		return
	var tracer := tracer_scene.instantiate() as BulletTracer
	add_child(tracer)
	tracer.setup(start_pos, target_pos, speed, color, custom_radius, custom_len)
