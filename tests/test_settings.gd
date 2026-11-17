extends SceneTree

func _init() -> void:
	print("[TEST] Running GameSettings & AudioManager Tests...")
	
	# 1. Test Aim Sensitivity
	GameSettings.set_aim_sensitivity(0.45)
	if absf(GameSettings.get_aim_sensitivity() - 0.45) > 0.001:
		push_error("GameSettings aim sensitivity set/get failed")
		quit(1)
		return
	print("[PASS] GameSettings aim sensitivity verified: ", GameSettings.get_aim_sensitivity())
	
	# Clamp check
	GameSettings.set_aim_sensitivity(10.0)
	if GameSettings.get_aim_sensitivity() > 2.01:
		push_error("GameSettings aim sensitivity max clamp failed")
		quit(1)
		return
	GameSettings.set_aim_sensitivity(0.60) # Restore default
	
	# 2. Test Audio Volumes
	GameSettings.set_master_volume(0.80)
	if absf(GameSettings.get_master_volume() - 0.80) > 0.001:
		push_error("GameSettings master volume failed")
		quit(1)
		return
		
	GameSettings.set_bgm_volume(0.65)
	if absf(GameSettings.get_bgm_volume() - 0.65) > 0.001:
		push_error("GameSettings BGM volume failed")
		quit(1)
		return
		
	GameSettings.set_sfx_volume(0.90)
	if absf(GameSettings.get_sfx_volume() - 0.90) > 0.001:
		push_error("GameSettings SFX volume failed")
		quit(1)
		return
	print("[PASS] GameSettings Master/BGM/SFX volumes verified")
	
	# 3. Test AudioManager
	var am := AudioManager.ensure_instance(root)
	if not am:
		push_error("Failed to instantiate AudioManager")
		quit(1)
		return
	am.set_master_volume(0.5)
	am.set_bgm_volume(0.5)
	am.set_sfx_volume(0.5)
	if am.master_vol_scale != 0.5 or am.bgm_vol_scale != 0.5 or am.sfx_vol_scale != 0.5:
		push_error("AudioManager volume scale mismatch")
		quit(1)
		return
	print("[PASS] AudioManager real-time volume adjustment verified")
	
	# 4. Test TouchControls input locking
	var tc_scene = load("res://scenes/ui/touch_controls.tscn")
	var tc = tc_scene.instantiate() as TouchControls
	root.add_child(tc)
	tc.set_input_locked(true)
	if not tc.is_input_locked or tc._is_firing or tc.current_move_vector != Vector2.ZERO:
		push_error("TouchControls input lock failed to reset state")
		quit(1)
		return
	tc.set_input_locked(false)
	if tc.is_input_locked:
		push_error("TouchControls input unlock failed")
		quit(1)
		return
	print("[PASS] TouchControls input lock and unlock verified")
	tc.queue_free()
	am.queue_free()
	
	print("[TEST COMPLETE] GameSettings & AudioManager tests passed with 0 errors!")
	quit(0)
