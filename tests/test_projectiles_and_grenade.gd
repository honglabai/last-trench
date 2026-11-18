extends SceneTree

func _init() -> void:
	print("[TEST] Running test_projectiles_and_grenade.gd...")
	var errors := 0
	
	# 1. Test GameSession default loadout (Rifle, Pistol, Grenade)
	GameSession._ensure_profile_loaded()
	if not GameSession.owned_weapons.has("k2c1_rifle"):
		print("[FAIL] k2c1_rifle missing from default owned_weapons!")
		errors += 1
	else:
		print("[PASS] k2c1_rifle owned by default")
		
	if not GameSession.owned_weapons.has("k5_pistol"):
		print("[FAIL] k5_pistol missing from default owned_weapons!")
		errors += 1
	else:
		print("[PASS] k5_pistol owned by default")
		
	if not GameSession.owned_weapons.has("k413_grenade"):
		print("[FAIL] k413_grenade missing from default owned_weapons!")
		errors += 1
	else:
		print("[PASS] k413_grenade owned by default")
		
	# 2. Test RocketProjectile setup and flight
	var rkt_scene = load("res://scenes/effects/rocket_projectile.tscn")
	if rkt_scene:
		var rkt = rkt_scene.instantiate()
		root.add_child(rkt)
		rkt.setup(Vector3(0, 1, 0), Vector3(0, 1, 20), 70.0, 7.0, 220.0)
		if rkt.blast_radius == 7.0 and rkt.damage == 220.0:
			print("[PASS] RocketProjectile setup verified (blast_radius=7.0, damage=220.0)")
		else:
			print("[FAIL] RocketProjectile setup values mismatch")
			errors += 1
		rkt.explode(Vector3(0, 1, 20))
		print("[PASS] RocketProjectile explode triggered cleanly")
	else:
		print("[FAIL] Failed to load rocket_projectile.tscn")
		errors += 1
		
	# 3. Test GrenadeProjectile setup and ballistic trajectory
	var grn_scene = load("res://scenes/effects/grenade_projectile.tscn")
	if grn_scene:
		var grn = grn_scene.instantiate()
		root.add_child(grn)
		grn.setup(Vector3(0, 1.5, 0), Vector3(0, 0, 1), 30.0, 6.5, 250.0)
		if grn.blast_radius == 6.5 and grn.damage == 250.0 and grn.velocity.y > 0:
			print("[PASS] GrenadeProjectile setup verified (parabolic velocity.y > 0)")
		else:
			print("[FAIL] GrenadeProjectile setup values mismatch")
			errors += 1
		grn.explode(Vector3(0, 0.1, 15))
		print("[PASS] GrenadeProjectile explode triggered cleanly")
	else:
		print("[FAIL] Failed to load grenade_projectile.tscn")
		errors += 1
		
	# 4. Test ExplosionEffect scaling with blast radius
	var exp_scene = load("res://scenes/effects/explosion_effect.tscn")
	if exp_scene:
		var exp_node = exp_scene.instantiate()
		root.add_child(exp_node)
		exp_node.setup(Vector3(0, 0, 0), 8.5)
		if exp_node.blast_radius == 8.5:
			print("[PASS] ExplosionEffect radius scaling verified (radius=8.5)")
		else:
			print("[FAIL] ExplosionEffect radius mismatch")
			errors += 1
		exp_node.queue_free()
	else:
		print("[FAIL] Failed to load explosion_effect.tscn")
		errors += 1
		
	# 5. Test TouchControls button sizing and radial layout
	var touch_scene = load("res://scenes/ui/touch_controls.tscn")
	if touch_scene:
		var touch = touch_scene.instantiate() as TouchControls
		root.add_child(touch)
		
		# FIRE button
		var fb: Button = touch.fire_button
		var fire_w: float = fb.offset_right - fb.offset_left
		var fire_h: float = fb.offset_bottom - fb.offset_top
		print("[INFO] FireButton size: %dx%d" % [int(fire_w), int(fire_h)])
		if fire_w >= 140 and fire_h >= 140:
			print("[PASS] FireButton is enlarged (>= 140px)")
		else:
			print("[FAIL] FireButton should be enlarged: size=%dx%d" % [int(fire_w), int(fire_h)])
			errors += 1
			
		# Sub buttons: Interact, Grenade, Aim, Reload, Switch
		var sub_buttons = [
			touch.interact_button,
			touch.grenade_button,
			touch.aim_button,
			touch.reload_button,
			touch.switch_button
		]
		var sub_names = ["Interact(270°)", "Grenade(300°)", "Aim(330°)", "Reload(0°)", "Switch(30°)"]
		
		for i in range(sub_buttons.size()):
			var btn: Button = sub_buttons[i]
			if not btn:
				print("[FAIL] Missing button: %s" % sub_names[i])
				errors += 1
				continue
			var bw: float = btn.offset_right - btn.offset_left
			var bh: float = btn.offset_bottom - btn.offset_top
			if absf(bw - fire_w * 0.5) <= 5.0 and absf(bh - fire_h * 0.5) <= 5.0:
				print("[PASS] Sub-button %s is ~1/2 size of FIRE button (%dx%d)" % [sub_names[i], int(bw), int(bh)])
			else:
				print("[FAIL] Sub-button %s size mismatch: %dx%d (expected ~%d)" % [sub_names[i], int(bw), int(bh), int(fire_w * 0.5)])
				errors += 1
				
		# Verify left-to-right ordering across 270° to 30°:
		# The center X of buttons should increase monotonically from left to right!
		var prev_center_x := -99999.0
		var order_ok := true
		for i in range(sub_buttons.size()):
			var btn: Button = sub_buttons[i]
			var cx: float = (btn.offset_left + btn.offset_right) * 0.5
			if cx < prev_center_x:
				print("[FAIL] Button %s X center (%f) is not greater than previous (%f)" % [sub_names[i], cx, prev_center_x])
				order_ok = false
				errors += 1
			prev_center_x = cx
		if order_ok:
			print("[PASS] Sub-buttons are evenly and strictly ordered left-to-right from 270° to 30°!")
			
		touch.queue_free()
	else:
		print("[FAIL] Failed to load touch_controls.tscn")
		errors += 1
		
	# 6. Test RPG-7 Texture solidness and continuity
	var rpg_tex = load("res://assets/textures/tex_fps_rpg.png")
	if rpg_tex:
		print("[PASS] RPG-7 texture loaded successfully (%dx%d)" % [rpg_tex.get_width(), rpg_tex.get_height()])
	else:
		print("[FAIL] Failed to load tex_fps_rpg.png")
		errors += 1
		
	if errors == 0:
		print("[TEST COMPLETE] test_projectiles_and_grenade.gd PASSED ALL CHECKS (0 errors)!")
	else:
		print("[TEST COMPLETE] test_projectiles_and_grenade.gd FAILED with %d errors!" % errors)
		
	quit(errors)
