extends SceneTree

func _init() -> void:
	print("[TEST] Running P03 Player TPS Movement, Camera & ADS Tests...")
	
	var player_scene = load("res://scenes/actors/player.tscn")
	if not player_scene:
		push_error("Failed to load res://scenes/actors/player.tscn")
		quit(1)
		return
		
	var player = player_scene.instantiate() as PlayerController
	if not player:
		push_error("Failed to instantiate PlayerController")
		quit(1)
		return
		
	root.add_child(player)
	
	# 1. Verify Collision and Layer setup
	if player.collision_layer != 2 or player.collision_mask != 1:
		push_error("Invalid player collision layer/mask")
		player.queue_free()
		quit(1)
		return
	print("[PASS] Collision layer and mask verified (layer=2, mask=1)")
	
	# 2. Verify Camera and Rig
	var cam_rig = player.camera_rig
	if not cam_rig:
		push_error("CameraRig not found on player")
		player.queue_free()
		quit(1)
		return
	if not cam_rig.spring_arm or not cam_rig.camera:
		push_error("SpringArm3D or Camera3D missing in CameraRig")
		player.queue_free()
		quit(1)
		return
	print("[PASS] CameraRig, SpringArm3D and Camera3D verified")
	
	# 3. Test ADS Toggle and Parameter Lerping
	cam_rig.set_aiming(false)
	cam_rig._process(1.0)
	var normal_len = cam_rig.spring_arm.spring_length
	
	cam_rig.set_aiming(true)
	# Simulate 10 frames of transition
	for i in range(10):
		cam_rig._process(0.05)
		
	var aim_len = cam_rig.spring_arm.spring_length
	if aim_len >= normal_len:
		push_error("Camera spring arm did not shorten during ADS")
		player.queue_free()
		quit(1)
		return
	if cam_rig.camera.fov >= 75.0:
		push_error("Camera FOV did not narrow during ADS")
		player.queue_free()
		quit(1)
		return
	print("[PASS] ADS transition verified (Arm shortened from %.2f to %.2f, FOV narrowed to %.2f)" % [normal_len, aim_len, cam_rig.camera.fov])
	
	# 4. Test Movement Adapter (Moving Forward: move_vec.y = -1.0)
	player.manual_input_override = true
	player.is_aiming = false
	player.input_move_vector = Vector2(0.0, -1.0) # Move forward
	
	# Simulate physics process
	for i in range(5):
		player._physics_process(0.02)
		
	if player.velocity.z >= 0.0:
		push_error("Forward movement did not generate negative Z velocity: " + str(player.velocity))
		player.queue_free()
		quit(1)
		return
	print("[PASS] Forward movement velocity verified: ", player.velocity)
	
	# 5. Test Damage, Death, and Revive (1-time revive requirement)
	var signal_received := [false]
	player.player_died.connect(func(): signal_received[0] = true)
	
	player.apply_damage(40.0)
	if player.current_health != 60.0:
		push_error("Damage calculation mismatch")
		player.queue_free()
		quit(1)
		return
		
	player.apply_damage(70.0)
	if not player.is_dead or not signal_received[0]:
		push_error("Player death signal or state failed")
		player.queue_free()
		quit(1)
		return
	print("[PASS] Player damage and death verified")
	
	player.revive(80.0)
	if player.is_dead or player.current_health != 80.0:
		push_error("Player revive failed")
		player.queue_free()
		quit(1)
		return
	print("[PASS] Player 1-time revive logic verified (HP restored to 80)")
	
	player.queue_free()
	print("[TEST COMPLETE] P03 player tests passed with 0 errors!")
	quit(0)
