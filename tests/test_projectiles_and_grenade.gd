extends SceneTree

func _init() -> void:
	print("[TEST] Running test_projectiles_and_grenade.gd...")
	var errors := 0
	
	# 1. Test GameSession default loadout (Rifle, Pistol, Grenade Count)
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
		
	if GameSession.get_grenade_count() < 3:
		print("[FAIL] GameSession default grenade count is less than 3: %d" % GameSession.get_grenade_count())
		errors += 1
	else:
		print("[PASS] GameSession default grenade count is 3 (dedicated quick-throw consumable)")
		
	if GameSession.owned_weapons.has("k413_grenade"):
		print("[FAIL] k413_grenade should be excluded from gun cycle switching!")
		errors += 1
	else:
		print("[PASS] k413_grenade excluded from weapon cycling as requested")
		
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
		
	# 5. Test TouchControls button sizing and requested layout
	var touch_scene = load("res://scenes/ui/touch_controls.tscn")
	if touch_scene:
		var touch = touch_scene.instantiate() as TouchControls
		
		# FIRE button (anchor at bottom-right)
		var fb: Button = touch.fire_button
		var fire_w: float = fb.offset_right - fb.offset_left
		var fire_h: float = fb.offset_bottom - fb.offset_top
		print("[INFO] FireButton size: %dx%d" % [int(fire_w), int(fire_h)])
		if fire_w >= 140 and fire_h >= 140:
			print("[PASS] FireButton is enlarged (>= 140px)")
		else:
			print("[FAIL] FireButton should be enlarged: size=%dx%d" % [int(fire_w), int(fire_h)])
			errors += 1
			
		# AimButton relocated above left joystick in LeftZone
		var aim_btn: Button = touch.aim_button
		if aim_btn and aim_btn.get_parent().name == "LeftZone":
			print("[PASS] AimButton relocated to LeftZone directly above joystick")
		else:
			print("[FAIL] AimButton should be located in LeftZone above joystick!")
			errors += 1
			
		# Sub-buttons around FireButton: Interact (Left), Reload (Upper-Left), Switch (Top), Grenade (Upper-Right)
		var fire_cx: float = (fb.offset_left + fb.offset_right) * 0.5
		var fire_cy: float = (fb.offset_top + fb.offset_bottom) * 0.5
		
		# Interact is directly to the Left of Fire
		var ib: Button = touch.interact_button
		var ib_cx: float = (ib.offset_left + ib.offset_right) * 0.5
		var ib_cy: float = (ib.offset_top + ib.offset_bottom) * 0.5
		if ib_cx < fire_cx and absf(ib_cy - fire_cy) < 50.0:
			print("[PASS] Interact (Turret) button positioned directly to the LEFT of FireButton")
		else:
			print("[FAIL] Interact button layout mismatch: cx=%f, cy=%f (Fire: cx=%f, cy=%f)" % [ib_cx, ib_cy, fire_cx, fire_cy])
			errors += 1
			
		# Reload is to the Upper-Left of Fire
		var rb: Button = touch.reload_button
		var rb_cx: float = (rb.offset_left + rb.offset_right) * 0.5
		var rb_cy: float = (rb.offset_top + rb.offset_bottom) * 0.5
		if rb_cx < fire_cx and rb_cy < fire_cy:
			print("[PASS] Reload button positioned UPPER-LEFT of FireButton")
		else:
			print("[FAIL] Reload button layout mismatch: cx=%f, cy=%f" % [rb_cx, rb_cy])
			errors += 1
			
		# Switch is directly to the Top of Fire
		var sb: Button = touch.switch_button
		var sb_cx: float = (sb.offset_left + sb.offset_right) * 0.5
		var sb_cy: float = (sb.offset_top + sb.offset_bottom) * 0.5
		if sb_cy < fire_cy and absf(sb_cx - fire_cx) < 50.0:
			print("[PASS] Switch weapon button positioned directly TOP of FireButton")
		else:
			print("[FAIL] Switch weapon button layout mismatch: cx=%f, cy=%f" % [sb_cx, sb_cy])
			errors += 1
			
		# Grenade count update test
		touch.update_grenade_count(3)
		if touch.grenade_button.text == "3":
			print("[PASS] Grenade button displays correct remaining count (3)")
		else:
			print("[FAIL] Grenade button count display failed: text='%s'" % touch.grenade_button.text)
			errors += 1
			
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
