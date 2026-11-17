extends SceneTree

func _init() -> void:
	print("[TEST] Running Comprehensive Settings Live Adjustment Tests...")
	
	# 1. Test BattleHUD Settings Stepper Buttons and Slider Sync
	var hud_scene = load("res://scenes/ui/battle_hud.tscn")
	var hud = hud_scene.instantiate() as BattleHUD
	root.add_child(hud)
	hud._ready()
	
	# Initial sensitivity check
	GameSettings.set_aim_sensitivity(0.60)
	hud._on_settings_pressed()
	
	if absf(hud.sensitivity_slider.value - 0.60) > 0.001:
		push_error("BattleHUD sensitivity_slider did not sync initial GameSettings value")
		quit(1)
		return
	print("[PASS] BattleHUD sensitivity_slider initial sync verified: ", hud.sensitivity_slider.value)
	
	# Test Sensitivity Stepper [+] button
	if not hud.sensitivity_inc_btn:
		push_error("BattleHUD sensitivity_inc_btn not found")
		quit(1)
		return
	hud.sensitivity_inc_btn.pressed.emit()
	if absf(hud.sensitivity_slider.value - 0.65) > 0.001 or absf(GameSettings.get_aim_sensitivity() - 0.65) > 0.001:
		push_error("BattleHUD sensitivity increment failed. Slider: " + str(hud.sensitivity_slider.value) + ", Settings: " + str(GameSettings.get_aim_sensitivity()))
		quit(1)
		return
	print("[PASS] BattleHUD sensitivity increment verified (0.60 -> 0.65)")
	
	# Test Sensitivity Stepper [-] button
	if not hud.sensitivity_dec_btn:
		push_error("BattleHUD sensitivity_dec_btn not found")
		quit(1)
		return
	hud.sensitivity_dec_btn.emit_signal("pressed")
	hud.sensitivity_dec_btn.emit_signal("pressed")
	if absf(hud.sensitivity_slider.value - 0.55) > 0.001:
		push_error("BattleHUD sensitivity decrement failed: " + str(hud.sensitivity_slider.value))
		quit(1)
		return
	print("[PASS] BattleHUD sensitivity decrement verified (0.65 -> 0.55)")
	
	# 2. Test Audio Volume Stepper Buttons
	GameSettings.set_master_volume(0.80)
	GameSettings.set_bgm_volume(0.70)
	GameSettings.set_sfx_volume(0.85)
	hud._sync_settings_from_game_settings()
	
	hud.master_vol_inc_btn.emit_signal("pressed")
	if absf(GameSettings.get_master_volume() - 0.85) > 0.001:
		push_error("Master volume increment failed: " + str(GameSettings.get_master_volume()))
		quit(1)
		return
	print("[PASS] Master volume increment verified (0.80 -> 0.85)")
	
	hud.bgm_vol_dec_btn.emit_signal("pressed")
	if absf(GameSettings.get_bgm_volume() - 0.65) > 0.001:
		push_error("BGM volume decrement failed: " + str(GameSettings.get_bgm_volume()))
		quit(1)
		return
	print("[PASS] BGM volume decrement verified (0.70 -> 0.65)")
	
	hud.sfx_vol_inc_btn.emit_signal("pressed")
	if absf(GameSettings.get_sfx_volume() - 0.90) > 0.001:
		push_error("SFX volume increment failed: " + str(GameSettings.get_sfx_volume()))
		quit(1)
		return
	print("[PASS] SFX volume increment verified (0.85 -> 0.90)")
	
	# 3. Test Camera Aim Sensitivity Linear Response
	var cam_rig = ThirdPersonCamera.new()
	root.add_child(cam_rig)
	cam_rig.yaw = 0.0
	
	# At 0.50 sensitivity:
	GameSettings.set_aim_sensitivity(0.50)
	cam_rig.handle_look_input(Vector2(20.0, 0.0))
	var yaw_low: float = absf(cam_rig.yaw)
	
	# At 1.00 sensitivity (double):
	cam_rig.yaw = 0.0
	GameSettings.set_aim_sensitivity(1.00)
	cam_rig.handle_look_input(Vector2(20.0, 0.0))
	var yaw_high: float = absf(cam_rig.yaw)
	
	# Ratio should be exactly 2.0 (linear, NOT 4.0 squared)
	var ratio := yaw_high / yaw_low
	if absf(ratio - 2.0) > 0.05:
		push_error("Camera sensitivity scaling is not linear! Ratio: " + str(ratio))
		quit(1)
		return
	print("[PASS] Camera sensitivity linear response verified: 2x sensitivity produces %.2fx rotation" % ratio)
	
	# 4. Test AudioManager Persistence and AudioServer bus volume
	var am := AudioManager.ensure_instance()
	if not am or not is_instance_valid(am):
		push_error("AudioManager instance missing")
		quit(1)
		return
	am.set_master_volume(0.50)
	var bus_db := AudioServer.get_bus_volume_db(0)
	if absf(bus_db - linear_to_db(0.50)) > 0.1:
		push_error("AudioServer master bus volume mismatch: " + str(bus_db))
		quit(1)
		return
	print("[PASS] AudioServer master bus volume real-time synchronization verified: %.2f dB" % bus_db)
	
	# 5. Test MainMenu Settings Dialog and Stepper Buttons
	var menu_scene = load("res://scenes/app/main_menu.tscn")
	var menu = menu_scene.instantiate() as MainMenu
	root.add_child(menu)
	menu._ready()
	menu._on_settings_pressed()
	
	if not menu.sensitivity_inc_btn or not menu.sensitivity_dec_btn:
		push_error("MainMenu sensitivity stepper buttons missing")
		quit(1)
		return
		
	var sens_before = GameSettings.get_aim_sensitivity()
	menu.sensitivity_inc_btn.emit_signal("pressed")
	if absf(GameSettings.get_aim_sensitivity() - (sens_before + 0.05)) > 0.001:
		push_error("MainMenu sensitivity step failed")
		quit(1)
		return
	print("[PASS] MainMenu sensitivity stepper button verified")
	menu.queue_free()
	
	hud.queue_free()
	cam_rig.queue_free()
	print("[TEST COMPLETE] All settings live adjustment tests passed with 0 errors!")
	quit(0)
