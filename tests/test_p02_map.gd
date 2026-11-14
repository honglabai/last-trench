extends SceneTree

func _init() -> void:
	print("[TEST] Running P02 Trench Map & Spawns & Anchors Tests...")
	
	var map_scene = load("res://scenes/maps/trench_map.tscn")
	if not map_scene:
		push_error("Failed to load res://scenes/maps/trench_map.tscn")
		quit(1)
		return
		
	var map_node = map_scene.instantiate() as TrenchMap
	if not map_node:
		push_error("Failed to instantiate TrenchMap")
		quit(1)
		return
		
	root.add_child(map_node)
	
	# 1. Player Start check
	var p_start = map_node.get_player_start_transform()
	print("[PASS] Player start transform origin: ", p_start.origin)
	
	# 2. Base Objective check
	var base = map_node.get_base_objective()
	if not base:
		push_error("BaseObjective node missing in map")
		map_node.queue_free()
		quit(1)
		return
	if base.max_health <= 0 or base.current_health != base.max_health:
		push_error("Invalid base health configuration")
		map_node.queue_free()
		quit(1)
		return
	print("[PASS] BaseObjective verified with HP: ", base.max_health)
	
	# 3. Front Spawns validation (Rule: strictly front facing, no 360-degree spawns)
	var spawn_val = map_node.validate_front_spawns()
	if not spawn_val.valid:
		push_error("Front spawn validation failed: " + str(spawn_val.errors))
		map_node.queue_free()
		quit(1)
		return
	print("[PASS] Front-facing spawns verified: Ground=%d, Air=%d" % [spawn_val.ground_count, spawn_val.air_count])
	
	# 4. Defense Slots check (Rule: designated fixed slots only)
	var slots = map_node.get_defense_slots()
	if slots.size() != 2:
		push_error("Expected 2 designated defense slots, got: " + str(slots.size()))
		map_node.queue_free()
		quit(1)
		return
	for s in slots:
		if not s.can_install():
			push_error("Defense slot should initially be empty: " + s.slot_id)
			map_node.queue_free()
			quit(1)
			return
		print("[PASS] Verified fixed defense slot: ", s.slot_id)
		
	# 5. Destructible Cover test
	var cover = map_node.get_node_or_null("Covers/SandbagCenter") as DestructibleCover
	if not cover:
		push_error("SandbagCenter cover not found")
		map_node.queue_free()
		quit(1)
		return
	var initial_hp = cover.current_health
	cover.apply_damage(30.0)
	if cover.current_health != initial_hp - 30.0:
		push_error("DestructibleCover damage mismatch")
		map_node.queue_free()
		quit(1)
		return
	cover.repair(20.0)
	if cover.current_health != initial_hp - 10.0:
		push_error("DestructibleCover repair mismatch")
		map_node.queue_free()
		quit(1)
		return
	print("[PASS] DestructibleCover damage/repair logic verified")
	
	map_node.queue_free()
	print("[TEST COMPLETE] P02 map tests passed with 0 errors!")
	quit(0)
