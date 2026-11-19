extends SceneTree

func _init() -> void:
	print("[TEST] Running P10 Touch Controls, Battle HUD & GameRoot Integration Tests...")
	
	# 1. Test TouchControls
	var touch_scene = load("res://scenes/ui/touch_controls.tscn")
	if not touch_scene:
		push_error("Failed to load touch_controls.tscn")
		quit(1)
		return
		
	var touch = touch_scene.instantiate() as TouchControls
	root.add_child(touch)
	
	var move_vectors := []
	touch.move_vector_changed.connect(func(v): move_vectors.append(v))
	
	# Simulate joystick drag
	touch.joystick_center = Vector2(80, 80)
	touch.joystick_base.global_position = Vector2(50, 450)
	touch._update_joystick(Vector2(50 + 80, 450 + 80 - 70)) # Drag forward (UP)
	
	if move_vectors.is_empty():
		push_error("Joystick failed to emit move_vector_changed")
		quit(1)
		return
	var last_vec = move_vectors.back()
	if last_vec.y >= 0.0 or not is_equal_approx(last_vec.y, -1.0):
		push_error("Joystick forward drag mismatch: " + str(last_vec))
		quit(1)
		return
	print("[PASS] TouchControls joystick drag verified: move vector = ", last_vec)
	
	# Test Aim Toggle
	var aim_toggled_flag := [false]
	touch.aim_toggled.connect(func(): aim_toggled_flag[0] = true)
	touch._on_aim_pressed()
	if not touch.is_aim_active or not aim_toggled_flag[0]:
		push_error("Aim toggle failed")
		quit(1)
		return
	print("[PASS] TouchControls aim toggle verified: is_aim_active = true")
	
	# Test Interact Button Always-Visible on HUD
	touch.set_interact_available(true, "포탑 설치")
	if not touch.interact_button.visible:
		push_error("Interact button display failed")
		quit(1)
		return
	touch.set_interact_available(false)
	if not touch.interact_button.visible:
		push_error("Interact button must remain displayed on HUD at all times")
		quit(1)
		return
	print("[PASS] TouchControls interact button always displayed on HUD verified")
	
	# 2. Test BattleHUD
	var hud_scene = load("res://scenes/ui/battle_hud.tscn")
	if not hud_scene:
		push_error("Failed to load battle_hud.tscn")
		quit(1)
		return
		
	var hud = hud_scene.instantiate() as BattleHUD
	root.add_child(hud)
	
	hud.update_player_health(65.0, 100.0)
	if hud.player_hp_bar.value != 65.0 or hud.player_hp_label.text != "병사 HP: 65 / 100":
		push_error("Player HP HUD sync failed")
		quit(1)
		return
		
	hud.update_revives(0)
	if hud.revives_label.text != "즉시 부활: 0 / 1":
		push_error("Revives HUD sync failed")
		quit(1)
		return
		
	hud.update_base_health(320.0, 500.0)
	if hud.base_hp_bar.value != 320.0 or hud.base_hp_label.text != "참호 거점: 320 / 500":
		push_error("Base HP HUD sync failed")
		quit(1)
		return
		
	hud.update_ammo(21, 150)
	if hud.ammo_label.text != "21 / 150":
		push_error("Ammo HUD sync failed")
		quit(1)
		return
		
	hud.set_crosshair_aim(true)
	if hud.crosshair_ring.scale.x >= 1.0:
		push_error("Crosshair aim scale failed to tighten")
		quit(1)
		return
		
	hud.show_victory()
	if not hud.victory_panel.visible:
		push_error("Victory overlay panel failed to display")
		quit(1)
		return
		
	hud.show_defeat("BASE_DESTROYED")
	if not hud.defeat_panel.visible:
		push_error("Defeat overlay panel failed to display")
		quit(1)
		return
	print("[PASS] BattleHUD data sync, crosshair scaling, and victory/defeat panels verified")
	
	# 3. Test Full GameRoot Integration
	var root_scene = load("res://scenes/app/game_root.tscn")
	if not root_scene:
		push_error("Failed to load game_root.tscn")
		quit(1)
		return
		
	var game_root = root_scene.instantiate() as GameRoot
	if not game_root:
		push_error("Failed to instantiate GameRoot")
		quit(1)
		return
		
	root.add_child(game_root)
	game_root._ready()
	
	if not game_root.trench_map or not game_root.player or not game_root.wave_director or not game_root.game_session or not game_root.touch_controls or not game_root.battle_hud:
		push_error("GameRoot components failed to wire properly")
		quit(1)
		return
	print("[PASS] GameRoot full integration (Map, Player, WaveDirector, Session, Touch, HUD) verified with 0 errors")
	
	# 4. Verify Independent Joystick Direction and Fire Button Separation
	# Joystick drag must ONLY affect move/direction, NOT fire
	game_root.touch_controls._update_joystick(Vector2(50 + 80 + 50, 450 + 80))
	if game_root.player.is_firing_requested:
		push_error("Left joystick movement incorrectly triggered firing!")
		quit(1)
		return
	print("[PASS] Left joystick direction movement verified (0 firing triggered)")
	
	# Only right fire button triggers firing
	game_root.touch_controls._on_fire_down()
	if not game_root.player.is_firing_requested:
		push_error("Right fire button failed to set is_firing_requested")
		quit(1)
		return
	game_root.touch_controls._on_fire_up()
	if game_root.player.is_firing_requested:
		push_error("Releasing right fire button failed to reset is_firing_requested")
		quit(1)
		return
	print("[PASS] Right fire button exclusive firing trigger verified")
	
	touch.queue_free()
	hud.queue_free()
	game_root.queue_free()
	
	print("[TEST COMPLETE] P10 UI & integration tests passed with 0 errors!")
	quit(0)
