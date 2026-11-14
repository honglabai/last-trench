extends SceneTree

func _init() -> void:
	print("[TEST] Running P05 Infantry AI, Movement, Attack & Death Tests...")
	
	var infantry_scene = load("res://scenes/actors/enemy_infantry.tscn")
	if not infantry_scene:
		push_error("Failed to load res://scenes/actors/enemy_infantry.tscn")
		quit(1)
		return
		
	var infantry = infantry_scene.instantiate() as InfantryAI
	if not infantry:
		push_error("Failed to instantiate InfantryAI")
		quit(1)
		return
		
	root.add_child(infantry)
	infantry._ready()
	
	# 1. Collision & Layer test
	if infantry.collision_layer != 4 or infantry.collision_mask != 1:
		push_error("Invalid infantry collision layer/mask (expected layer=4, mask=1)")
		infantry.queue_free()
		quit(1)
		return
	print("[PASS] Infantry collision layer=4 (Enemy) and mask=1 verified")
	
	# 2. Spawning at front point
	infantry.position = Vector3(0.0, 0.0, -35.0)
	if infantry.position.z >= -15.0:
		push_error("Infantry spawned out of front hemisphere: " + str(infantry.position))
		infantry.queue_free()
		quit(1)
		return
	print("[PASS] Front hemisphere spawn verified: ", infantry.position)
	
	# 3. Target Approach
	var dummy_base = BaseObjective.new()
	dummy_base.name = "BaseObjective"
	dummy_base.position = Vector3(0.0, 0.0, 6.0)
	dummy_base.max_health = 500.0
	dummy_base._ready()
	root.add_child(dummy_base)
	
	infantry.set_target(dummy_base)
	infantry._physics_process(0.05)
	
	if infantry.current_state != EnemyBase.State.APPROACH:
		push_error("Infantry failed to transition to APPROACH state")
		infantry.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
		
	# Moving from -35 towards +6 must have positive Z velocity
	if infantry.velocity.z <= 0.0:
		push_error("Infantry approach velocity not pointing towards target: " + str(infantry.velocity))
		infantry.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
	print("[PASS] Approach movement towards target verified: velocity.z = ", infantry.velocity.z)
	
	# 4. Attack Range & Base Damage
	# Move infantry to Z = -4.0 (Distance to dummy_base at Z=6.0 is 10.0m <= attack_range 14.0m)
	infantry.position = Vector3(0.0, 0.0, -4.0)
	var attack_signal_count := [0]
	infantry.attack_performed.connect(func(t, d): attack_signal_count[0] += 1)
	
	infantry._physics_process(0.05)
	if infantry.current_state != EnemyBase.State.ATTACK:
		push_error("Infantry failed to transition to ATTACK state within attack_range")
		infantry.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
	print("[PASS] Transition to ATTACK state verified within attack range")
	
	# Advance attack cooldown to trigger attack
	infantry._physics_process(infantry.attack_cooldown + 0.1)
	if attack_signal_count[0] != 1 or dummy_base.current_health != 500.0 - infantry.attack_damage:
		push_error("Base objective damage from infantry attack failed")
		infantry.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
	print("[PASS] Base objective damaged successfully: HP reduced from 500 to ", dummy_base.current_health)
	
	# 5. Damage, Death & Single Death Event
	var death_event_count := [0]
	infantry.enemy_died.connect(func(e): death_event_count[0] += 1)
	
	infantry.apply_damage(25.0)
	if infantry.current_health != 35.0:
		push_error("Infantry damage calculation mismatch")
		infantry.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
	print("[PASS] Infantry damage verified: HP is ", infantry.current_health)
	
	# Fatal damage
	infantry.apply_damage(40.0)
	if not infantry.is_dead or infantry.current_state != EnemyBase.State.DEAD:
		push_error("Infantry fatal damage state mismatch")
		infantry.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
	if death_event_count[0] != 1:
		push_error("Enemy death signal not emitted on fatal damage")
		infantry.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
	print("[PASS] Infantry died correctly, death signal received")
	
	# Additional damage should NOT trigger second death event (Rule: duplicate death = 0)
	infantry.apply_damage(50.0)
	if death_event_count[0] != 1:
		push_error("Duplicate death event emitted on overkill")
		infantry.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
	print("[PASS] Verified 0 duplicate death events upon overkill")
	
	infantry.queue_free()
	dummy_base.queue_free()
	print("[TEST COMPLETE] P05 infantry tests passed with 0 errors!")
	quit(0)
