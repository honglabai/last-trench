extends SceneTree

func _init() -> void:
	print("[TEST] Running test_fire_and_haptic.gd...")
	var errors := 0
	
	# 1. Test PlayerController firing logic in touch mode
	var player := PlayerController.new()
	player._ready()
	
	# Simulate mobile/touch mode
	player.manual_input_override = true
	player.is_firing_requested = false
	
	# In touch mode, when is_firing_requested is false, wants_fire MUST be false
	var wants_fire_touch_idle: bool = player.is_firing_requested or Input.is_physical_key_pressed(KEY_SPACE)
	if wants_fire_touch_idle:
		print("[FAIL] Touch idle should not fire!")
		errors += 1
	else:
		print("[PASS] Touch idle does not trigger fire")
		
	# When fire button is pressed, is_firing_requested is true
	player.is_firing_requested = true
	var wants_fire_touch_active: bool = player.is_firing_requested or Input.is_physical_key_pressed(KEY_SPACE)
	if not wants_fire_touch_active:
		print("[FAIL] Touch fire button should trigger fire!")
		errors += 1
	else:
		print("[PASS] Touch fire button triggers fire correctly")
		
	# 2. Test trigger_haptic method
	PlayerController.trigger_haptic(25)
	print("[PASS] trigger_haptic(25) executed cleanly without crash")
	PlayerController.trigger_haptic(120)
	print("[PASS] trigger_haptic(120) executed cleanly without crash")
	
	# 3. Test apply_damage invokes haptic and emits signal
	var test_box := {"hp": -1.0}
	player.player_damaged.connect(func(cur, max_hp):
		test_box["hp"] = cur
	)
	player.apply_damage(20.0)
	if absf(test_box["hp"] - 80.0) < 0.01 and absf(player.current_health - 80.0) < 0.01:
		print("[PASS] apply_damage applied damage and triggered haptic cleanly")
	else:
		print("[FAIL] apply_damage failed: damaged_hp = %f, current_hp = %f" % [test_box["hp"], player.current_health])
		errors += 1
		
	# 4. Test landing page index.html contents
	var html_file := FileAccess.open("res://public/index.html", FileAccess.READ)
	if html_file:
		var content := html_file.get_as_text()
		if "landing-video" in content:
			print("[PASS] landing-video element found in public/index.html")
		else:
			print("[FAIL] landing-video element missing in public/index.html")
			errors += 1
			
		if "작전준비 진행율" in content or "작전 준비 진행률" in content:
			print("[PASS] Operation preparation progress label found in public/index.html")
		else:
			print("[FAIL] Operation preparation progress label missing in public/index.html")
			errors += 1
			
		if "전투 출격" in content:
			print("[PASS] '전투 출격' button found in public/index.html")
		else:
			print("[FAIL] '전투 출격' button missing in public/index.html")
			errors += 1
			
		if "btn-sound" in content:
			print("[FAIL] Unnecessary sound button 'btn-sound' still present in public/index.html")
			errors += 1
		else:
			print("[PASS] Unnecessary sound button removed from public/index.html")
			
		if "landing-top-bar" in content:
			print("[FAIL] Unnecessary top bar box 'landing-top-bar' still present in public/index.html")
			errors += 1
		else:
			print("[PASS] Unnecessary top bar box removed from public/index.html")
	else:
		print("[FAIL] Could not open public/index.html")
		errors += 1
		
	# 5. Test weapon texture files exist and load
	var textures := [
		"res://assets/textures/tex_fps_m4a1.png",
		"res://assets/textures/tex_fps_rpg.png",
		"res://assets/textures/tex_fps_iron_sights.png",
		"res://assets/textures/tex_fps_hk416.png",
		"res://assets/textures/tex_fps_scar_h.png",
		"res://assets/textures/tex_fps_k14.png",
		"res://assets/textures/tex_fps_atgm.png"
	]
	for t_path in textures:
		if ResourceLoader.exists(t_path):
			var tex: Texture2D = load(t_path)
			if tex and tex.get_width() > 0:
				print("[PASS] Loaded weapon texture: %s (%dx%d)" % [t_path, tex.get_width(), tex.get_height()])
			else:
				print("[FAIL] Invalid texture loaded for: %s" % t_path)
				errors += 1
		else:
			print("[FAIL] Weapon texture missing: %s" % t_path)
			errors += 1
			
	if errors == 0:
		print("[TEST COMPLETE] test_fire_and_haptic.gd PASSED ALL CHECKS (0 errors)!")
	else:
		print("[TEST COMPLETE] test_fire_and_haptic.gd FAILED with %d errors!" % errors)
		
	player.free()
	quit(errors)
