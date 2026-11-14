extends SceneTree

func _init() -> void:
	print("[TEST] Running P08 Wave Director, Cap Enforcement & Victory Tests...")
	
	var director = WaveDirector.new()
	root.add_child(director)
	
	# 1. Test Data Loading
	var loaded = director.load_wave_plan()
	if not loaded or director.max_active_enemies != 12:
		push_error("WaveDirector failed to load wave_plan.json properly")
		quit(1)
		return
	print("[PASS] Wave plan JSON loaded successfully: max_active_enemies = ", director.max_active_enemies)
	
	# Fast-forward timer durations for automated unit testing
	director.preparation_duration = 0.01
	director.default_spawn_interval = 0.01
	
	# 2. Test Strict Active Enemy Cap (Rule: Never exceed max_active_enemies)
	director.max_active_enemies = 3 # Constrain cap to 3 for strict verification
	director._change_state(WaveDirector.WaveState.COMBAT)
	director.pending_spawn_queue = ["infantry_basic", "infantry_basic", "infantry_basic", "infantry_basic", "infantry_basic"]
	director.total_enemies_in_wave = 5
	director.killed_enemies_in_wave = 0
	
	# Attempt to spawn 5 enemies rapidly
	for i in range(10):
		director._process(0.02)
		if director.active_enemies.size() > 3:
			push_error("Active enemies exceeded cap! Count: " + str(director.active_enemies.size()))
			quit(1)
			return
			
	if director.active_enemies.size() != 3 or director.pending_spawn_queue.size() != 2:
		push_error("Cap enforcement failed to throttle spawn queue")
		quit(1)
		return
	print("[PASS] Strict active enemy cap verified: clamped at 3, pending 2")
	
	# Kill one enemy and verify queue resumes spawn
	var first_enemy = director.active_enemies[0]
	first_enemy.die()
	director._process(0.02)
	
	if director.active_enemies.size() > 3:
		push_error("Cap exceeded after kill refill")
		quit(1)
		return
	print("[PASS] Spawn queue resumed upon enemy kill, remaining capped")
	
	# Clean up temporary test enemies
	for enemy in director.active_enemies.duplicate():
		enemy.die()
		enemy.queue_free()
	director.active_enemies.clear()
	director.pending_spawn_queue.clear()
	
	# 3. Test Full 3-Wave Sequence & Single Victory Event
	director.max_active_enemies = 12
	var waves_cleared_log := []
	var victory_event_count := [0]
	
	director.wave_cleared.connect(func(w): waves_cleared_log.append(w))
	director.run_victory.connect(func(): victory_event_count[0] += 1)
	
	director.start_run(3)
	print("[PASS] Started 3-Wave MVP1 run")
	
	# Execute Wave 1
	director._process(0.02) # Finish prep -> COMBAT
	while not director.pending_spawn_queue.is_empty():
		director._process(0.02)
	for e in director.active_enemies.duplicate():
		e.die()
		e.queue_free()
	director._process(0.02) # Wave 1 complete
	
	if waves_cleared_log != [1]:
		push_error("Wave 1 clear event failed: " + str(waves_cleared_log))
		quit(1)
		return
	print("[PASS] Wave 1 cleared successfully")
	
	# Execute Wave 2
	director._process(0.02) # Finish prep -> COMBAT
	while not director.pending_spawn_queue.is_empty():
		director._process(0.02)
	for e in director.active_enemies.duplicate():
		e.die()
		e.queue_free()
	director._process(0.02) # Wave 2 complete
	
	if waves_cleared_log != [1, 2]:
		push_error("Wave 2 clear event failed: " + str(waves_cleared_log))
		quit(1)
		return
	print("[PASS] Wave 2 cleared successfully")
	
	# Execute Wave 3 (MVP1 Final Wave)
	director._process(0.02) # Finish prep -> COMBAT
	while not director.pending_spawn_queue.is_empty():
		director._process(0.02)
	for e in director.active_enemies.duplicate():
		e.die()
		e.queue_free()
	director._process(0.02) # Wave 3 complete -> VICTORY
	
	if waves_cleared_log != [1, 2, 3]:
		push_error("Wave 3 clear event failed: " + str(waves_cleared_log))
		quit(1)
		return
	if victory_event_count[0] != 1 or director.current_state != WaveDirector.WaveState.VICTORY:
		push_error("Run victory signal failed or not in VICTORY state")
		quit(1)
		return
	print("[PASS] Wave 3 cleared and single run_victory signal emitted successfully!")
	
	# Verify duplicate victory is strictly blocked
	director._trigger_victory()
	if victory_event_count[0] != 1:
		push_error("Duplicate run_victory signal emitted!")
		quit(1)
		return
	print("[PASS] Duplicate victory emission rejected (emitted exactly once)")
	
	director.queue_free()
	print("[TEST COMPLETE] P08 wave director tests passed with 0 errors!")
	quit(0)
