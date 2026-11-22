extends SceneTree

func _init() -> void:
	print("[TEST] Running 15-Wave Expansion, Bosses & Tactical Events Tests...")
	
	var director := WaveDirector.new()
	root.add_child(director)
	
	# 1. Test 15-Wave Plan Data Loading
	var loaded := director.load_wave_plan()
	assert(loaded, "Failed to load wave_plan.json")
	assert(director.max_active_enemies == 12, "max_active_enemies must be 12 (cap rule)")
	
	var waves_list: Array = director.wave_plan_data.get("waves", [])
	assert(waves_list.size() >= 15, "wave_plan.json must define at least 15 waves (got: %d)" % waves_list.size())
	print("[PASS] Verified all waves defined in data/wave_plan.json")
	
	# 2. Verify 3 Boss Encounters exist in wave plan
	var has_drone_commander := false
	var has_armored_robot := false
	var has_final_assault := false
	for w in waves_list:
		var et: Dictionary = w.get("enemy_total", {})
		if et.has("drone_swarm_commander"): has_drone_commander = true
		if et.has("armored_robot_boss"): has_armored_robot = true
		if et.has("final_assault_boss"): has_final_assault = true
	assert(has_drone_commander, "Wave plan must feature drone_swarm_commander")
	assert(has_armored_robot, "Wave plan must feature armored_robot_boss")
	assert(has_final_assault, "Wave plan must feature final_assault_boss")
	print("[PASS] Verified all 3 Bosses configured across the regional stages")
	
	# 3. Verify Intermediate Specialty Threats
	var has_rpg := false
	var has_robot := false
	for w in waves_list:
		var et: Dictionary = w.get("enemy_total", {})
		if et.has("rpg_infantry"): has_rpg = true
		if et.has("combat_robot"): has_robot = true
	assert(has_rpg, "Wave plan must introduce rpg_infantry")
	assert(has_robot, "Wave plan must introduce combat_robot")
	print("[PASS] Verified intermediate threats (rpg_infantry, combat_robot)")
	
	# 4. Verify Instantiation of all 7 Enemy Types
	var dummy_obj := Node3D.new()
	root.add_child(dummy_obj)
	director.target_objective = dummy_obj
	
	var test_types := [
		"infantry_basic",
		"drone_attack",
		"rpg_infantry",
		"combat_robot",
		"drone_swarm_commander",
		"armored_robot_boss",
		"final_assault_boss"
	]
	
	for t_name in test_types:
		var enemy := director._spawn_enemy(t_name)
		assert(enemy != null, "Failed to spawn enemy type: %s" % t_name)
		assert(enemy is EnemyBase, "Spawned enemy must inherit EnemyBase")
		assert(enemy.max_health > 0.0, "Enemy must have positive health")
		if t_name == "drone_swarm_commander":
			assert(enemy.get("is_boss") == true, "drone_swarm_commander must be flagged as boss")
			assert(enemy.max_health == 650.0, "drone_swarm_commander max_health must be 650.0")
		elif t_name == "armored_robot_boss":
			assert(enemy.get("is_boss") == true, "armored_robot_boss must be flagged as boss")
			assert(enemy.max_health == 1200.0, "armored_robot_boss max_health must be 1200.0")
		elif t_name == "final_assault_boss":
			assert(enemy.get("is_boss") == true, "final_assault_boss must be flagged as boss")
			assert(enemy.max_health == 2000.0, "final_assault_boss max_health must be 2000.0")
		enemy.die()
		enemy.queue_free()
	director.active_enemies.clear()
	print("[PASS] Verified all 7 enemy & boss scenes instantiate with correct stats")
	
	# 5. Fast Simulation of Full 15 Waves Progression & Victory
	director.preparation_duration = 0.001
	director.default_spawn_interval = 0.001
	director.max_active_enemies = 12
	
	var waves_cleared_log := []
	var victory_fired := [false]
	var boss_spawn_log := []
	
	director.wave_cleared.connect(func(w): waves_cleared_log.append(w))
	director.run_victory.connect(func(): victory_fired[0] = true)
	director.boss_spawned.connect(func(_b, b_title, _hp): boss_spawn_log.append(b_title))
	
	var total_run_waves := waves_list.size()
	director.start_run(total_run_waves)
	assert(director.max_waves_in_run == total_run_waves, "max_waves_in_run must be %d" % total_run_waves)
	
	for wave_idx in range(1, total_run_waves + 1):
		# Transition to COMBAT
		director._process(0.01)
		# Flush queue and enemies
		while not director.pending_spawn_queue.is_empty():
			director._process(0.01)
			assert(director.active_enemies.size() <= 12, "Cap exceeded during wave %d!" % wave_idx)
			for e in director.active_enemies.duplicate():
				e.die()
				e.queue_free()
		# Clear remaining
		for e in director.active_enemies.duplicate():
			e.die()
			e.queue_free()
		director._process(0.01) # Wave clear step
		
	assert(waves_cleared_log.size() == total_run_waves, "Expected %d waves cleared, got: %d" % [total_run_waves, waves_cleared_log.size()])
	assert(victory_fired[0], "run_victory signal must be emitted on final wave completion")
	assert(boss_spawn_log.size() >= 3, "Expected at least 3 boss spawns, got: %d" % boss_spawn_log.size())
	print("[PASS] Full campaign run simulation completed successfully with Victory!")
	
	dummy_obj.queue_free()
	director.queue_free()
	print("[TEST COMPLETE] test_wave_expansion_15.gd PASSED ALL CHECKS (0 errors)!")
	quit()
