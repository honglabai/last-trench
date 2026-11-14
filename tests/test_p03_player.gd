extends SceneTree

func _init() -> void:
	print("[TEST] Running P03 Player 1st-Person Stationary Defense & Camera Tests...")
	
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
	
	# 2. Verify 1st-Person Camera Rig & Hidden Body Mesh
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
		
	if not cam_rig.is_first_person:
		push_error("CameraRig is not configured for 1st-person mode (is_first_person != true)")
		player.queue_free()
		quit(1)
		return
		
	if cam_rig.spring_arm.spring_length != 0.0:
		push_error("1st-Person Camera spring_length must be 0.0, got: " + str(cam_rig.spring_arm.spring_length))
		player.queue_free()
		quit(1)
		return
		
	if player.visual_mesh and player.visual_mesh.visible:
		push_error("1st-Person mode must hide visual mesh to prevent camera clipping")
		player.queue_free()
		quit(1)
		return
	print("[PASS] 1st-Person CameraRig, zero arm length and hidden visual mesh verified")
	
	# 3. Test ADS Toggle and FOV Zoom in 1st-Person
	cam_rig.set_aiming(false)
	cam_rig._process(1.0)
	var normal_fov = cam_rig.camera.fov
	
	cam_rig.set_aiming(true)
	# Simulate 10 frames of transition
	for i in range(10):
		cam_rig._process(0.05)
		
	var aim_fov = cam_rig.camera.fov
	if aim_fov >= normal_fov or aim_fov > 55.0:
		push_error("Camera FOV did not zoom in during 1st-person ADS: " + str(aim_fov))
		player.queue_free()
		quit(1)
		return
	print("[PASS] 1st-Person ADS FOV zoom verified (Normal: %.1f -> Aim: %.1f)" % [normal_fov, aim_fov])
	
	# 4. Test Stationary Defense Mode (Movement clamped, aim rotation active)
	if not player.stationary_defense_mode:
		push_error("PlayerController must have stationary_defense_mode enabled by default")
		player.queue_free()
		quit(1)
		return
		
	player.manual_input_override = true
	player.is_aiming = false
	player.input_move_vector = Vector2(0.0, -1.0) # Attempt forward move
	
	for i in range(5):
		player._physics_process(0.02)
		
	if abs(player.velocity.x) > 0.001 or abs(player.velocity.z) > 0.001:
		push_error("Stationary defense failed: horizontal velocity must be 0.0, got: " + str(player.velocity))
		player.queue_free()
		quit(1)
		return
	print("[PASS] Stationary defense position anchoring verified: velocity = ", player.velocity)
	
	# Test Aim Rotation
	cam_rig.handle_look_input(Vector2(50.0, -20.0))
	if abs(cam_rig.yaw) < 0.001 or abs(cam_rig.pitch) < 0.001:
		push_error("Aim rotation failed to update yaw/pitch")
		player.queue_free()
		quit(1)
		return
	print("[PASS] Aim rotation verified: yaw = %.3f, pitch = %.3f" % [cam_rig.yaw, cam_rig.pitch])
	
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
