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
var rocket_scene: PackedScene = preload("res://scenes/effects/rocket_projectile.tscn")
var grenade_scene: PackedScene = preload("res://scenes/effects/grenade_projectile.tscn")
var enemy_projectile_scene: PackedScene = preload("res://scenes/effects/enemy_projectile.tscn")
var _is_initialized: bool = false

# Timed Turret Construction System
var is_building_turret: bool = false
var building_slot: DefenseSlot = null
var build_progress: float = 0.0
const TURRET_BUILD_TIME: float = 2.5
var build_tick_timer: float = 0.0

var _g_key_was_pressed: bool = false
var _last_grenade_time: float = -1.0


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
			player.set_aiming(touch_controls.is_aim_active)
			if battle_hud:
				battle_hud.set_aiming(touch_controls.is_aim_active)
		)
		touch_controls.reload_requested.connect(func():
			player.manual_input_override = true
			if player.weapon:
				player.weapon.start_reload()
		)
		touch_controls.interact_requested.connect(_on_interact_requested)
		touch_controls.weapon_switch_requested.connect(func():
			switch_to_next_weapon()
		)
		touch_controls.grenade_requested.connect(_on_quick_grenade_requested)
		if game_session and not game_session.grenade_count_changed.is_connected(_on_grenade_count_changed):
			game_session.grenade_count_changed.connect(_on_grenade_count_changed)
		_on_grenade_count_changed(GameSession.get_grenade_count())
		
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
		wave_director.stage_started.connect(func(st_id, st_name, diff, total_w):
			if battle_hud:
				battle_hud.show_tactical_alert("[작전 개시] STAGE %d/5: %s (난이도: %s)" % [st_id, st_name, diff], 3.5)
				battle_hud.update_stage_and_wave(st_id, wave_director.max_stages_in_region, 1, total_w, diff, "작전 개시")
		)
		wave_director.stage_cleared.connect(func(cleared_st, st_name, reward, next_st):
			GameSession.on_stage_completed(cleared_st, reward)
			if battle_hud:
				battle_hud.update_credits(GameSession.credits)
				battle_hud.show_toast("[STAGE %d 클리어] 보너스 +%d P 획득!" % [cleared_st, reward], 4.0)
				if next_st <= wave_director.max_stages_in_region:
					battle_hud.show_tactical_alert("[STAGE %d 완수] 다음 작전 구역(STAGE %d) 해금!" % [cleared_st, next_st], 4.0)
		)
		wave_director.wave_started.connect(func(w_num, total):
			if battle_hud:
				battle_hud.update_stage_and_wave(
					wave_director.current_stage_id,
					wave_director.max_stages_in_region,
					wave_director.current_stage_wave,
					wave_director.total_waves_in_stage,
					wave_director.stage_difficulty,
					"교전 시작! (적: %d)" % total
				)
		)
		wave_director.enemy_killed.connect(func(_e, remaining, _act):
			if battle_hud:
				battle_hud.update_stage_and_wave(
					wave_director.current_stage_id,
					wave_director.max_stages_in_region,
					wave_director.current_stage_wave,
					wave_director.total_waves_in_stage,
					wave_director.stage_difficulty,
					"남은 적: %d" % remaining
				)
		)
		wave_director.wave_cleared.connect(func(w_num):
			if battle_hud:
				battle_hud.update_stage_and_wave(
					wave_director.current_stage_id,
					wave_director.max_stages_in_region,
					wave_director.current_stage_wave,
					wave_director.total_waves_in_stage,
					wave_director.stage_difficulty,
					"웨이브 %d 클리어!" % wave_director.current_stage_wave
				)
				battle_hud.show_toast("웨이브 %d 클리어! 전공 점수 지급" % wave_director.current_stage_wave, 2.5)
		)
		wave_director.boss_spawned.connect(func(_boss, b_title, max_hp):
			if battle_hud:
				battle_hud.show_boss_bar(b_title, max_hp)
				battle_hud.show_tactical_alert("[BOSS 경보] %s 출현! 화력을 집중하십시오!" % b_title, 4.0)
			AudioManager.play_sound("alarm", 0.0, 1.0)
		)
		wave_director.boss_damaged.connect(func(cur, max_hp):
			if battle_hud:
				battle_hud.update_boss_hp(cur, max_hp)
		)
		wave_director.boss_defeated.connect(func(_boss, b_title):
			if battle_hud:
				battle_hud.hide_boss_bar()
				battle_hud.show_toast("[BOSS 격퇴] %s 격파 성공!" % b_title, 3.5)
				battle_hud.show_tactical_alert("[BOSS 격퇴] %s 섬멸 완료!" % b_title, 3.5)
			GameSession.add_credits(1500)
			if battle_hud:
				battle_hud.update_credits(GameSession.credits)
		)
		wave_director.wave_event_triggered.connect(_handle_wave_event)
		wave_director.enemy_spawned.connect(func(enemy, _count):
			if enemy and enemy.has_signal("projectile_launched"):
				enemy.projectile_launched.connect(func(p_type, start_p, target_p, dmg, spd, rad, recv):
					_spawn_enemy_projectile(p_type, start_p, target_p, dmg, spd, rad, recv)
				)
			elif enemy and enemy.has_signal("rocket_fired"):
				enemy.rocket_fired.connect(func(start_p, target_p):
					_spawn_enemy_projectile(EnemyProjectile.ProjectileType.ROCKET, start_p, target_p, 25.0, 34.0, 5.0, player)
				)
			elif enemy and enemy.has_signal("bullet_fired"):
				enemy.bullet_fired.connect(func(start_p, target_p):
					_spawn_enemy_projectile(EnemyProjectile.ProjectileType.BULLET, start_p, target_p, 8.0, 58.0, 0.0, player)
				)
		)
		
	# 7. Wire GameSession
	if game_session:
		game_session.start_session(player, base_obj, wave_director)
		if not game_session.grenade_count_changed.is_connected(_on_grenade_count_changed):
			game_session.grenade_count_changed.connect(_on_grenade_count_changed)
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
		_on_grenade_count_changed(GameSession.get_grenade_count())
		
	# 8. HUD Buttons & Modals
	if battle_hud:
		battle_hud.restart_requested.connect(func():
			get_tree().reload_current_scene()
		)
		battle_hud.menu_requested.connect(func():
			get_tree().change_scene_to_file("res://scenes/ui/operations_hq.tscn")
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
		wave_director.start_stage(GameSession.selected_stage)

func _physics_process(delta: float) -> void:
	if trench_map and player:
		var slots = trench_map.get_defense_slots()
		for slot in slots:
			var p_pos := player.global_position if player.is_inside_tree() else player.position
			slot.update_player_proximity(p_pos)
			
		# Timed Turret Construction Update
		if is_building_turret:
			if not building_slot or not is_instance_valid(building_slot) or building_slot.is_occupied:
				_cancel_turret_build()
			else:
				var b_pos := building_slot.global_position if building_slot.is_inside_tree() else building_slot.position
				var p_pos := player.global_position if player.is_inside_tree() else player.position
				if player and (b_pos.distance_to(p_pos) > 8.0):
					_cancel_turret_build()
					if battle_hud:
						battle_hud.show_toast("거리 이탈로 포탑 구축이 취소되었습니다")
				else:
					build_progress += delta / TURRET_BUILD_TIME
					build_tick_timer += delta
					if build_tick_timer >= 0.45:
						build_tick_timer = 0.0
						AudioManager.play_sound("click", 0.04, 2.5)
					var pct := mini(99, int(build_progress * 100.0))
					if touch_controls:
						touch_controls.set_interact_available(true, "포탑 조립 중... %d%% [E]" % pct)
					if build_progress >= 1.0:
						_complete_turret_build()
		else:
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

func _is_grenade_key(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_G or event.keycode == KEY_G:
			return true
		# Strict exact match only - NEVER use .contains("G") as keys like 'Right' contain 'g'
		var t := event.as_text().strip_edges().to_upper()
		if t == "G":
			return true
		if event.unicode == 103 or event.unicode == 71 or event.unicode == 12622: # 'g', 'G', 'ㅎ'
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	# 1. DefenseSlot interaction / Turret Build
	if event.is_action_pressed("interact"):
		_on_interact_requested()
	# 2. Cycle weapon
	elif event.is_action_pressed("switch_weapon") or (event is InputEventKey and event.pressed and event.keycode == KEY_Q):
		switch_to_next_weapon()
	# 3. Open Armory Shop
	elif event.is_action_pressed("open_shop") or (event is InputEventKey and event.pressed and (event.keycode == KEY_S or event.keycode == KEY_B)):
		if battle_hud:
			battle_hud.open_armory_shop()
	# 4. Open Settings
	elif event.is_action_pressed("open_settings") or (event is InputEventKey and event.pressed and (event.keycode == KEY_I or event.keycode == KEY_O)):
		if battle_hud:
			battle_hud.open_settings()
	# 5. Reload
	elif event.is_action_pressed("reload") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
		if player and player.weapon:
			player.weapon.start_reload()
	# 6. Quick Grenade throw ('G')
	elif _is_grenade_key(event) or event.is_action_pressed("throw_grenade"):
		if not battle_hud or not battle_hud.armory_shop or not battle_hud.armory_shop.visible:
			_on_quick_grenade_requested()
			if get_viewport():
				get_viewport().set_input_as_handled()
	# 7. Direct numeric weapon select (1 to 9)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode >= KEY_1 and event.keycode <= KEY_9:
		var slot_idx: int = event.keycode - KEY_1
		_select_weapon_by_slot(slot_idx)
	# 8. Web/Desktop Mouse capture: click to lock, ESC to unlock
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _select_weapon_by_slot(slot_idx: int) -> void:
	var weapon_catalog: Array[String] = [
		"k2c1_rifle",
		"k5_pistol",
		"k413_grenade",
		"m4a1_carbine",
		"hk416_elite",
		"scar_h_battle",
		"k14_sniper",
		"rpg7_launcher",
		"hyungung_atgm"
	]
	if slot_idx < 0 or slot_idx >= weapon_catalog.size():
		return
	var target_w_id := weapon_catalog[slot_idx]
	if GameSession.owned_weapons.has(target_w_id):
		GameSession.equip_weapon(target_w_id)
		var lvl := GameSession.get_weapon_level(target_w_id)
		if player and player.weapon:
			player.weapon.load_weapon_data(target_w_id, lvl)
		if battle_hud:
			battle_hud._update_viewmodel_texture(target_w_id)
			if player and player.weapon:
				battle_hud.update_ammo(player.weapon.current_ammo, player.weapon.reserve_ammo)
			battle_hud.show_weapon_toast(target_w_id)
		if player and player.camera_rig:
			player.camera_rig.set_sniper_mode(target_w_id == "k14_sniper")
		AudioManager.play_sound("reload")
	else:
		if battle_hud:
			battle_hud.show_toast("[미보유 무기] B키(무기 상점)에서 구매할 수 있습니다")

func switch_to_next_weapon() -> void:
	var next_id := GameSession.get_next_owned_weapon()
	if next_id == GameSession.equipped_weapon_id and GameSession.owned_weapons.size() <= 1:
		if battle_hud:
			battle_hud.open_armory_shop()
		return
		
	GameSession.equip_weapon(next_id)
	var lvl := GameSession.get_weapon_level(next_id)
	if player and player.weapon:
		player.weapon.load_weapon_data(next_id, lvl)
	if battle_hud:
		battle_hud._update_viewmodel_texture(next_id)
		if player and player.weapon:
			battle_hud.update_ammo(player.weapon.current_ammo, player.weapon.reserve_ammo)
		battle_hud.show_weapon_toast(next_id)
	if player and player.camera_rig:
		player.camera_rig.set_sniper_mode(next_id == "k14_sniper")
	AudioManager.play_sound("reload")

func _on_wave_state_changed(state: int) -> void:
	if not battle_hud or not wave_director:
		return
	if state == WaveDirector.WaveState.PREPARATION:
		battle_hud.update_wave(wave_director.current_wave_number, wave_director.max_waves_in_run, "작전 정비 시간...")
	elif state == WaveDirector.WaveState.COMBAT:
		battle_hud.update_wave(wave_director.current_wave_number, wave_director.max_waves_in_run, "적 공세 방어 중!")

func _handle_wave_event(event_name: String, _wave_num: int) -> void:
	if not battle_hud:
		return
	match event_name:
		"boss_air", "boss_ground", "final_combined_assault":
			battle_hud.show_tactical_alert("[긴급 경보] 강력한 지휘체 신호 감지! 대공/대전차 화기 준비!", 4.0)
		"partial_cover_damage":
			battle_hud.show_tactical_alert("[위험 경보] 적 집중 포화로 전방 엄폐물 파손 발생!", 3.5)
		"jamming":
			battle_hud.show_tactical_alert("[전자전 경보] 적 통신 재밍 발생! 조준선 교란 주의!", 3.5)
		"night", "dust":
			battle_hud.show_tactical_alert("[야간 작전] 야간/먼지 폭풍 작전: 열화상 탐지 모드 가동!", 3.5)
		"artillery_warning":
			battle_hud.show_tactical_alert("[포격 경보] 적 야포 포격 경보: 참호 엄폐를 유지하십시오!", 4.0)
		"rocket_artillery":
			battle_hud.show_tactical_alert("[방사포 경보] 방사포 일제 사격 경보: 전 구역 충격 대비!", 4.0)
		"helicopter_event":
			battle_hud.show_tactical_alert("[적기 접근] 적 항공 지원 접근: 대공 사격 준비!", 3.5)

func _start_turret_build(slot: DefenseSlot) -> void:
	if is_building_turret and building_slot == slot:
		return
	is_building_turret = true
	building_slot = slot
	build_progress = 0.0
	build_tick_timer = 0.0
	AudioManager.play_sound("reload", 0.05)
	if battle_hud:
		var slot_name = "좌측" if slot.slot_id.contains("left") else ("우측" if slot.slot_id.contains("right") else "")
		battle_hud.show_toast("%s 포탑 긴급 조립 공사 시작! (2.5초 소요)" % slot_name)
	if touch_controls:
		touch_controls.set_interact_available(true, "포탑 조립 중... 0% [E]")

func _cancel_turret_build() -> void:
	is_building_turret = false
	building_slot = null
	build_progress = 0.0
	if touch_controls:
		touch_controls.set_interact_available(active_slot_nearby != null)

func _complete_turret_build() -> void:
	if building_slot and is_instance_valid(building_slot) and building_slot.can_install():
		var turret = turret_scene.instantiate() as TurretController
		building_slot.install_turret(turret)
		AudioManager.play_sound("turret_shot", 0.05, -1.0)
		AudioManager.play_sound("click", 0.05, 3.0)
		if battle_hud:
			var slot_name = "좌측" if building_slot.slot_id.contains("left") else ("우측" if building_slot.slot_id.contains("right") else "")
			battle_hud.show_toast("%s 방어 포탑 조립 완료! 자동 사격 개시" % slot_name)
	_cancel_turret_build()

func _on_interact_requested() -> void:
	var target_slot: DefenseSlot = active_slot_nearby
	if not target_slot and trench_map:
		var slots = [trench_map.defense_slot_left, trench_map.defense_slot_right]
		var min_dist: float = 999.0
		var p_pos: Vector3 = player.global_position if (player and player.is_inside_tree()) else Vector3.ZERO
		for slot in slots:
			if slot and is_instance_valid(slot):
				var s_pos: Vector3 = slot.global_position if slot.is_inside_tree() else slot.position
				var d: float = (s_pos - p_pos).length()
				if d < min_dist:
					min_dist = d
					target_slot = slot
					
	if not target_slot:
		return
		
	if target_slot.can_install():
		_start_turret_build(target_slot)
	elif target_slot.can_repair():
		target_slot.repair_turret(50.0)
		AudioManager.play_sound("reload", 0.05)

func _on_bullet_fired(start_pos: Vector3, target_pos: Vector3) -> void:
	var muzzle_start := start_pos
	if player and player.camera_rig and player.camera_rig.camera:
		var cam: Camera3D = player.camera_rig.camera
		var basis_cam := cam.global_transform.basis
		# Originating from authentic gun barrel point below eye level directly toward aim target
		muzzle_start = cam.global_position - basis_cam.y * 0.12 - basis_cam.z * 0.25
		
	if player and player.weapon:
		if player.weapon.current_weapon_id == "k413_grenade":
			var grn = grenade_scene.instantiate()
			add_child(grn)
			var throw_dir := (target_pos - muzzle_start).normalized()
			if grn.has_method("setup"):
				grn.setup(muzzle_start, throw_dir, 30.0, player.weapon.splash_radius, player.weapon.damage)
			return
		elif player.weapon.is_explosive:
			var rkt = rocket_scene.instantiate()
			add_child(rkt)
			var is_guided: bool = (player.weapon.current_weapon_id == "hyungung_atgm")
			var best_target: Node3D = null
			if is_guided:
				best_target = _find_guided_missile_target(muzzle_start, (target_pos - muzzle_start).normalized())
				if battle_hud:
					battle_hud.show_toast("[현궁 K-ATGM] 드론/로봇 자동 추적 유도탄 발사!")
			if rkt.has_method("setup"):
				rkt.setup(muzzle_start, target_pos, 75.0 if is_guided else 68.0, player.weapon.splash_radius, player.weapon.damage, is_guided, best_target)
			return
			
	_spawn_tracer(muzzle_start, target_pos, 220.0, Color(1.0, 0.88, 0.25))

func _find_guided_missile_target(aim_origin: Vector3, aim_dir: Vector3) -> Node3D:
	var best_candidate: Node3D = null
	var best_score: float = -9999.0
	if wave_director and not wave_director.active_enemies.is_empty():
		for e in wave_director.active_enemies:
			if not is_instance_valid(e) or e.is_dead:
				continue
			var to_enemy := (e.global_position - aim_origin).normalized()
			var dot_prod := aim_dir.dot(to_enemy)
			if dot_prod < 0.2: # Must be generally in front of player
				continue
			var dist := aim_origin.distance_to(e.global_position)
			var is_drone_or_robot: bool = (e is DroneAI or e.name.to_lower().contains("drone") or e.name.to_lower().contains("robot"))
			var priority: float = 40.0 if is_drone_or_robot else 15.0
			var score: float = (dot_prod * 50.0) + priority - (dist * 0.4)
			if score > best_score:
				best_score = score
				best_candidate = e
	return best_candidate

func _on_grenade_count_changed(cnt: int) -> void:
	if touch_controls:
		touch_controls.update_grenade_count(cnt)
	if battle_hud:
		battle_hud.update_grenade_count(cnt)

func _on_quick_grenade_requested() -> void:
	if not player or player.is_dead:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_grenade_time < 0.25:
		return
	_last_grenade_time = now
	if not GameSession.use_grenade():
		AudioManager.play_sound("click", 0.04, 0.5)
		if battle_hud:
			battle_hud.show_toast("[수류탄 소진] S키(상점)에서 추가 구매할 수 있습니다")
		_on_grenade_count_changed(GameSession.get_grenade_count())
		return
		
	var origin: Vector3 = player.global_position + Vector3(0.0, 1.5, 0.0) if player.is_inside_tree() else player.position + Vector3(0.0, 1.5, 0.0)
	var throw_dir: Vector3 = Vector3.FORWARD
	if player.camera_rig:
		throw_dir = player.camera_rig.get_camera_forward()
		if player.camera_rig.camera and player.camera_rig.camera.is_inside_tree():
			origin = player.camera_rig.camera.global_position
	var grn = grenade_scene.instantiate()
	add_child(grn)
	if grn.has_method("setup"):
		grn.setup(origin, throw_dir, 30.0, 6.5, 250.0)
	AudioManager.play_sound("click", 0.05, 0.8)
	_on_grenade_count_changed(GameSession.get_grenade_count())
	if battle_hud:
		battle_hud.show_toast("수류탄 투척! (잔여: %d발)" % GameSession.get_grenade_count())

func _spawn_tracer(start_pos: Vector3, target_pos: Vector3, speed: float, color: Color, custom_radius: float = 0.035, custom_len: float = 0.9) -> void:
	if not tracer_scene:
		return
	var tracer := tracer_scene.instantiate() as BulletTracer
	add_child(tracer)
	tracer.setup(start_pos, target_pos, speed, color, custom_radius, custom_len)

func _spawn_enemy_projectile(p_type: int, start_pos: Vector3, target_pos: Vector3, damage: float, speed: float, blast_rad: float, receiver: Node) -> void:
	if not enemy_projectile_scene:
		return
	var proj := enemy_projectile_scene.instantiate() as EnemyProjectile
	add_child(proj)
	proj.setup(start_pos, target_pos, p_type as EnemyProjectile.ProjectileType, damage, speed, blast_rad, receiver)
