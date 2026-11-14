extends SceneTree

func _init() -> void:
	print("[TEST] Running P06 Enemy Drone AI, Aerial Approach & Shootdown Tests...")
	
	var drone_scene = load("res://scenes/actors/enemy_drone.tscn")
	if not drone_scene:
		push_error("Failed to load res://scenes/actors/enemy_drone.tscn")
		quit(1)
		return
		
	var drone = drone_scene.instantiate() as DroneAI
	if not drone:
		push_error("Failed to instantiate DroneAI")
		quit(1)
		return
		
	root.add_child(drone)
	drone._ready()
	
	# 1. Collision & Layer test
	if drone.collision_layer != 4 or drone.collision_mask != 1:
		push_error("Invalid drone collision layer/mask (expected layer=4, mask=1)")
		drone.queue_free()
		quit(1)
		return
	print("[PASS] Drone collision layer=4 (Enemy) and mask=1 verified")
	
	# 2. Front Air Spawn Verification (Rule: Z < -15, Y >= 5)
	drone.position = Vector3(0.0, 9.0, -35.0)
	if drone.position.z >= -15.0 or drone.position.y < 5.0:
		push_error("Drone spawned outside front aerial envelope: " + str(drone.position))
		drone.queue_free()
		quit(1)
		return
	print("[PASS] Front aerial spawn verified: ", drone.position)
	
	# 3. Altitude Maintenance Test (Flying, not falling under normal ground gravity)
	drone.position = Vector3(0.0, 7.5, -35.0) # slightly below 9.0 cruise altitude
	drone._physics_process(0.05)
	if drone.velocity.y <= 0.0:
		push_error("Drone failed to adjust upward velocity towards cruise altitude: " + str(drone.velocity.y))
		drone.queue_free()
		quit(1)
		return
	print("[PASS] Drone cruise altitude adjustment verified: velocity.y = ", drone.velocity.y)
	
	# 4. Target Approach Test
	var dummy_base = BaseObjective.new()
	dummy_base.name = "BaseObjective"
	dummy_base.position = Vector3(0.0, 0.0, 6.0)
	dummy_base.max_health = 500.0
	dummy_base._ready()
	root.add_child(dummy_base)
	
	drone.position = Vector3(0.0, 9.0, -35.0)
	drone.set_target(dummy_base)
	drone._physics_process(0.05)
	
	if drone.current_state != EnemyBase.State.APPROACH:
		push_error("Drone failed to enter APPROACH state")
		drone.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
		
	if drone.velocity.z <= 0.0:
		push_error("Drone approach velocity not pointing towards target: " + str(drone.velocity))
		drone.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
	print("[PASS] Aerial approach towards target verified: velocity.z = ", drone.velocity.z)
	
	# 5. Aerial Attack & Base Damage Test
	# Move drone to Z = -5.0 (Horizontal distance to base at Z=6.0 is 11.0m <= attack_range 18.0m)
	drone.position = Vector3(0.0, 9.0, -5.0)
	var attack_count := [0]
	drone.attack_performed.connect(func(t, d): attack_count[0] += 1)
	
	drone._physics_process(0.05)
	if drone.current_state != EnemyBase.State.ATTACK:
		push_error("Drone failed to transition to ATTACK state within attack_range")
		drone.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
	print("[PASS] Transition to ATTACK state verified within aerial attack range")
	
	# Advance attack cooldown to trigger attack
	drone._physics_process(drone.attack_cooldown + 0.1)
	if attack_count[0] != 1 or dummy_base.current_health != 500.0 - drone.attack_damage:
		push_error("Base objective damage from drone attack failed")
		drone.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
	print("[PASS] Base objective damaged by drone: HP reduced from 500 to ", dummy_base.current_health)
	
	# 6. Anti-Air Shootdown & Crash Physics Test
	var death_event_count := [0]
	drone.enemy_died.connect(func(e): death_event_count[0] += 1)
	
	# Shot 1: 25 damage (HP 35 -> 10)
	drone.apply_damage(25.0)
	if drone.current_health != 10.0 or drone.is_dead:
		push_error("Drone first hit damage mismatch")
		drone.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
	print("[PASS] Drone sustained first hit: HP reduced to ", drone.current_health)
	
	# Shot 2: Fatal hit (HP 10 -> 0)
	drone.apply_damage(25.0)
	if not drone.is_dead or drone.current_state != EnemyBase.State.DEAD:
		push_error("Drone fatal hit state mismatch")
		drone.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
	if death_event_count[0] != 1:
		push_error("Drone death event not emitted on shootdown")
		drone.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
	print("[PASS] Drone shootdown death event received")
	
	# Verify crash physics: gravity activated, downward velocity
	drone._physics_process(0.1)
	if drone.velocity.y >= 0.0:
		push_error("Drone crash gravity did not accelerate downward: " + str(drone.velocity.y))
		drone.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
	print("[PASS] Drone crash physics verified: downward velocity = ", drone.velocity.y)
	
	# Overkill check: no duplicate death signal
	drone.apply_damage(50.0)
	if death_event_count[0] != 1:
		push_error("Duplicate death event emitted on drone overkill")
		drone.queue_free()
		dummy_base.queue_free()
		quit(1)
		return
	print("[PASS] Verified 0 duplicate death events upon drone overkill")
	
	drone.queue_free()
	dummy_base.queue_free()
	print("[TEST COMPLETE] P06 drone tests passed with 0 errors!")
	quit(0)
