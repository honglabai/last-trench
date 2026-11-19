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
	assert(waves_list.size() == 15, "wave_plan.json must define exactly 15 waves (got: %d)" % waves_list.size())
	print("[PASS] Verified all 15 waves defined in data/wave_plan.json")
	
	# 2. Verify Boss Waves 5, 10, 15
	var boss_waves: Array = director.wave_plan_data.get("boss_waves", [])
	var boss_wave_ints: Array[int] = []
	for bw in boss_waves:
		boss_wave_ints.append(int(bw))
	assert(boss_wave_ints == [5, 10, 15], "boss_waves must be [5, 10, 15] (got: %s)" % str(boss_wave_ints))
	
	var w5: Dictionary = waves_list[4]
	assert(w5.get("boss") == true, "Wave 5 must be a boss wave")
	assert(w5.get("enemy_total", {}).has("drone_swarm_commander"), "Wave 5 must feature drone_swarm_commander")
	
	var w10: Dictionary = waves_list[9]
	assert(w10.get("boss") == true, "Wave 10 must be a boss wave")
	assert(w10.get("enemy_total", {}).has("armored_robot_boss"), "Wave 10 must feature armored_robot_boss")
	
	var w15: Dictionary = waves_list[14]
	assert(w15.get("boss") == true, "Wave 15 must be a boss wave")
	assert(w15.get("enemy_total", {}).has("final_assault_boss"), "Wave 15 must feature final_assault_boss")
	print("[PASS] Verified Bosses strictly configured at Waves 5, 10, 15")
	
	# 3. Verify Intermediate Specialty Threats
	var w4: Dictionary = waves_list[3]
	assert(w4.get("enemy_total", {}).has("rpg_infantry"), "Wave 4 must introduce rpg_infantry")
	
	var w7: Dictionary = waves_list[6]
	assert(w7.get("enemy_total", {}).has("combat_robot"), "Wave 7 must introduce combat_robot")
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
	
	director.start_run(15)
	assert(director.max_waves_in_run == 15, "max_waves_in_run must be 15")
	
	for wave_idx in range(1, 16):
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
		
	assert(waves_cleared_log.size() == 15, "Expected 15 waves cleared, got: %d" % waves_cleared_log.size())
	assert(victory_fired[0], "run_victory signal must be emitted on Wave 15 completion")
	assert(boss_spawn_log.size() == 3, "Expected exactly 3 boss spawns (Waves 5, 10, 15), got: %d" % boss_spawn_log.size())
	print("[PASS] Full 15-Wave run simulation completed successfully with Victory!")
	
	dummy_obj.queue_free()
	director.queue_free()
	print("[TEST COMPLETE] test_wave_expansion_15.gd PASSED ALL CHECKS (0 errors)!")
	quit()
