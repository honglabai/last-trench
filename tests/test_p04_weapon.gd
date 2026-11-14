extends SceneTree

func _init() -> void:
	print("[TEST] Running P04 Weapon, Ammo, Reload & Hit Detection Tests...")
	
	# 1. Test DamageableComponent
	var target_node = Node.new()
	var dmg_comp = DamageableComponent.new()
	dmg_comp.name = "DamageableComponent"
	dmg_comp.max_health = 100.0
	target_node.add_child(dmg_comp)
	dmg_comp._ready()
	
	var destroyed_flag := [false]
	dmg_comp.destroyed.connect(func(): destroyed_flag[0] = true)
	
	dmg_comp.apply_damage(30.0)
	if dmg_comp.current_health != 70.0:
		push_error("DamageableComponent damage calculation failed")
		quit(1)
		return
	print("[PASS] DamageableComponent damage verified: HP is ", dmg_comp.current_health)
	
	dmg_comp.apply_damage(80.0)
	if dmg_comp.current_health != 0.0 or not destroyed_flag[0]:
		push_error("DamageableComponent destruction failed")
		quit(1)
		return
	print("[PASS] DamageableComponent destruction and signal verified")
	
	# 2. Test WeaponComponent data loading & ammo handling
	var weapon = WeaponComponent.new()
	weapon.weapon_id = "rifle_basic"
	weapon.load_weapon_data()
	
	if weapon.damage != 25.0 or weapon.magazine_size != 30 or weapon.fire_rate != 0.12:
		push_error("WeaponComponent failed to load JSON balance data correctly")
		quit(1)
		return
	print("[PASS] WeaponComponent successfully loaded rifle_basic data from weapons.json")
	
	# 3. Test Fire Rate Cooldown
	var shot1 = weapon.try_fire(Vector3.ZERO, Vector3.FORWARD)
	if not shot1 or weapon.current_ammo != 29:
		push_error("First shot failed or ammo not decremented")
		quit(1)
		return
		
	# Immediate next shot should be blocked by fire_rate cooldown
	var shot_immediate = weapon.try_fire(Vector3.ZERO, Vector3.FORWARD)
	if shot_immediate:
		push_error("Rapid fire failed to respect fire_rate cooldown")
		quit(1)
		return
	print("[PASS] Fire rate cooldown correctly prevented accidental multiple shots")
	
	# Advance time past fire_rate (0.15s > 0.12s)
	weapon._process(0.15)
	var shot2 = weapon.try_fire(Vector3.ZERO, Vector3.FORWARD)
	if not shot2 or weapon.current_ammo != 28:
		push_error("Second shot after cooldown failed")
		quit(1)
		return
	print("[PASS] Second shot succeeded after fire_rate cooldown elapsed")
	
	# 4. Test Ammo Depletion
	var depleted_flag := [false]
	weapon.ammo_depleted.connect(func(): depleted_flag[0] = true)
	
	# Deplete all remaining 28 rounds
	for i in range(28):
		weapon._process(0.15)
		weapon.try_fire(Vector3.ZERO, Vector3.FORWARD)
		
	if weapon.current_ammo != 0 or not depleted_flag[0]:
		push_error("Ammo depletion state or signal failed")
		quit(1)
		return
		
	var dry_fire = weapon.try_fire(Vector3.ZERO, Vector3.FORWARD)
	if dry_fire:
		push_error("Weapon allowed firing with 0 ammo")
		quit(1)
		return
	print("[PASS] Weapon correctly blocked firing when ammo reached 0")
	
	# 5. Test Reloading & Reload Lockout
	var reload_start_flag := [false]
	var reload_complete_flag := [false]
	weapon.reload_started.connect(func(): reload_start_flag[0] = true)
	weapon.reload_completed.connect(func(c, r): reload_complete_flag[0] = true)
	
	var initial_reserve = weapon.reserve_ammo
	var reload_started = weapon.start_reload()
	if not reload_started or not weapon.is_reloading or not reload_start_flag[0]:
		push_error("Reload start failed")
		quit(1)
		return
		
	# Firing during reload must be blocked
	var fire_during_reload = weapon.try_fire(Vector3.ZERO, Vector3.FORWARD)
	if fire_during_reload:
		push_error("Weapon allowed firing while reloading")
		quit(1)
		return
	print("[PASS] Firing blocked during reload state")
	
	# Advance reload time (1.0s of 1.8s) -> Still reloading
	weapon._process(1.0)
	if not weapon.is_reloading:
		push_error("Reload ended prematurely")
		quit(1)
		return
		
	# Finish reload (another 0.9s -> 1.9s total)
	weapon._process(0.9)
	if weapon.is_reloading or not reload_complete_flag[0] or weapon.current_ammo != 30:
		push_error("Reload completion failed")
		quit(1)
		return
	if weapon.reserve_ammo != initial_reserve - 30:
		push_error("Reserve ammo decrement mismatch")
		quit(1)
		return
	print("[PASS] Reload completed successfully: Ammo is 30, Reserve is ", weapon.reserve_ammo)
	
	# 6. Test Damage Application through Hit
	var fresh_target = Node.new()
	var fresh_dmg = DamageableComponent.new()
	fresh_dmg.name = "DamageableComponent"
	fresh_dmg.max_health = 100.0
	fresh_target.add_child(fresh_dmg)
	fresh_dmg._ready()
	
	weapon._apply_hit(fresh_target, Vector3.ZERO, Vector3.UP)
	if fresh_dmg.current_health != 75.0: # 100 - 25 = 75
		push_error("Hit damage application failed")
		quit(1)
		return
	print("[PASS] Hit detection correctly dealt 25 damage to DamageableComponent")
	
	target_node.free()
	fresh_target.free()
	weapon.free()
	
	print("[TEST COMPLETE] P04 weapon tests passed with 0 errors!")
	quit(0)
