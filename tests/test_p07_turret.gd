extends SceneTree

func _init() -> void:
	print("[TEST] Running P07 MG Turret, Slot Anchors & Proximity Interaction Tests...")
	
	var slot_scene = load("res://scenes/defenses/defense_slot.tscn")
	var turret_scene = load("res://scenes/defenses/mg_turret.tscn")
	var infantry_scene = load("res://scenes/actors/enemy_infantry.tscn")
	var drone_scene = load("res://scenes/actors/enemy_drone.tscn")
	
	if not slot_scene or not turret_scene or not infantry_scene or not drone_scene:
		push_error("Failed to load required scenes for P07")
		quit(1)
		return
		
	var slot = slot_scene.instantiate() as DefenseSlot
	root.add_child(slot)
	slot._ready()
	
	# 1. Test Player Proximity & Interaction Visibility
	var interaction_events := []
	slot.interaction_available.connect(func(c_inst, c_rep): interaction_events.append(["avail", c_inst, c_rep]))
	slot.interaction_unavailable.connect(func(): interaction_events.append(["unavail"]))
	
	# Player far away (10m away)
	slot.update_player_proximity(Vector3(0.0, 0.0, 10.0))
	if slot.is_player_nearby:
		push_error("Slot incorrectly marked player nearby when far away")
		quit(1)
		return
	print("[PASS] Far player correctly does not trigger slot interaction")
	
	# Player moves close (1.2m away)
	slot.update_player_proximity(Vector3(0.0, 0.0, 1.2))
	if not slot.is_player_nearby or interaction_events.is_empty():
		push_error("Slot failed to detect nearby player")
		quit(1)
		return
	var last_event = interaction_events.back()
	if last_event[0] != "avail" or last_event[1] != true or last_event[2] != false:
		push_error("Proximity interaction flags incorrect: " + str(last_event))
		quit(1)
		return
	print("[PASS] Proximity detected: interaction available (can_install=true, can_repair=false)")
	
	# 2. Test Installation on Designated Slot & Duplicate Prevention
	var turret1 = turret_scene.instantiate() as TurretController
	turret1._ready()
	var installed1 = slot.install_turret(turret1)
	if not installed1 or not slot.is_occupied:
		push_error("First turret installation on slot failed")
		quit(1)
		return
	print("[PASS] Turret 1 successfully installed on designated slot")
	
	var turret2 = turret_scene.instantiate() as TurretController
	turret2._ready()
	var installed2 = slot.install_turret(turret2)
	if installed2:
		push_error("Duplicate turret installation allowed on already occupied slot!")
		quit(1)
		return
	turret2.free()
	print("[PASS] Rule Invariant Verified: Duplicate installation rejected on occupied slot")
	
	# 3. Test Automated Firing at Ground Infantry
	var infantry = infantry_scene.instantiate() as InfantryAI
	root.add_child(infantry)
	infantry.position = Vector3(0.0, 0.0, -10.0) # 10m away
	infantry._ready()
	
	turret1.manual_target_override = infantry
	turret1._physics_process(0.3) # Advance past fire_rate (0.25s)
	
	if infantry.current_health != 60.0 - turret1.damage:
		push_error("Turret failed to damage ground infantry: HP is " + str(infantry.current_health))
		quit(1)
		return
	print("[PASS] Automated firing at ground infantry verified: damage dealt = ", turret1.damage)
	
	# 4. Test Automated Firing at Aerial Drone
	var drone = drone_scene.instantiate() as DroneAI
	root.add_child(drone)
	drone.position = Vector3(0.0, 9.0, -12.0) # Aerial target, ~15m away
	drone._ready()
	
	turret1.manual_target_override = drone
	turret1.fire_timer = turret1.fire_rate # prime cooldown
	turret1._physics_process(0.05)
	
	if drone.current_health != 35.0 - turret1.damage:
		push_error("Turret failed to damage aerial drone: HP is " + str(drone.current_health))
		quit(1)
		return
	print("[PASS] Automated firing at aerial drone verified: damage dealt = ", turret1.damage)
	
	# 5. Test Turret Damage, Breakdown, and Repair
	var broken_flag := [false]
	var repaired_flag := [false]
	turret1.turret_broken.connect(func(): broken_flag[0] = true)
	turret1.turret_repaired.connect(func(): repaired_flag[0] = true)
	
	turret1.apply_damage(160.0)
	if not turret1.is_broken or turret1.current_health != 0.0 or not broken_flag[0]:
		push_error("Turret breakdown state failed")
		quit(1)
		return
	print("[PASS] Turret breakdown verified upon taking fatal damage")
	
	# Verify broken turret does not fire
	var hp_before = drone.current_health
	turret1.fire_timer = turret1.fire_rate
	turret1._physics_process(0.1)
	if drone.current_health != hp_before:
		push_error("Broken turret still fired at target!")
		quit(1)
		return
	print("[PASS] Broken turret correctly ceased firing")
	
	# Verify repair via slot
	var repaired = slot.repair_turret(80.0)
	if not repaired or turret1.is_broken or turret1.current_health != 80.0 or not repaired_flag[0]:
		push_error("Turret repair via DefenseSlot failed")
		quit(1)
		return
	print("[PASS] Turret repair via DefenseSlot verified: restored to HP ", turret1.current_health)
	
	# Clean up
	infantry.queue_free()
	drone.queue_free()
	slot.queue_free()
	
	print("[TEST COMPLETE] P07 turret tests passed with 0 errors!")
	quit(0)
