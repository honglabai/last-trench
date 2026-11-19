extends SceneTree

func _init() -> void:
	print("--- Running Test Suite: Character Movement Controller & LOD System ---")
	
	# 1. Setup Mock CharacterBody3D
	var body = CharacterBody3D.new()
	var move_ctrl = CharacterMovementController.new()
	var lod_ctrl = CharacterLODController.new()
	
	root.add_child(body)
	body.add_child(move_ctrl)
	body.add_child(lod_ctrl)
	
	move_ctrl.setup(body, 4.0, 10.0, 20.0, 8.0)
	lod_ctrl.setup(body, 20.0, 40.0)
	
	# Test 1: Initial state
	assert(move_ctrl.current_horizontal_speed == 0.0, "Initial speed must be 0")
	assert(move_ctrl.movement_ratio == 0.0, "Initial movement ratio must be 0")
	assert(not move_ctrl.is_moving, "Should not be moving initially")
	print("[PASS] Test 1: Initial state verified.")
	
	# Test 2: Acceleration curve
	# Target speed 4.0, accel = 10.0, delta = 0.1s -> speed should increase by 1.0
	var step1 = move_ctrl.calculate_step(Vector3(0, 0, 1), 4.0, 0.1)
	assert(is_equal_approx(step1.z, 1.0), "After 0.1s at accel=10, velocity.z should be approx 1.0, got: %f" % step1.z)
	assert(move_ctrl.is_moving, "Should be marked as moving")
	assert(move_ctrl.movement_ratio > 0.0, "Movement ratio should increase")
	
	# Accelerate to max speed (0.4s more)
	for _i in range(4):
		move_ctrl.calculate_step(Vector3(0, 0, 1), 4.0, 0.1)
	assert(is_equal_approx(move_ctrl.current_horizontal_speed, 4.0), "Speed should reach max 4.0, got: %f" % move_ctrl.current_horizontal_speed)
	assert(is_equal_approx(move_ctrl.movement_ratio, 1.0), "Movement ratio should be 1.0 at max speed")
	print("[PASS] Test 2: Acceleration curve to max speed verified.")
	
	# Test 3: Stride playback scale
	var stride_scale = move_ctrl.get_stride_playback_scale(4.0)
	assert(is_equal_approx(stride_scale, 1.0), "Stride scale should be 1.0 when speed == base_walk_speed")
	var half_stride = move_ctrl.get_stride_playback_scale(2.0)
	assert(half_stride > 1.0, "When base speed is half, playback speed should scale up")
	print("[PASS] Test 3: Stride playback speed scaling verified.")
	
	# Test 4: Deceleration / Braking curve
	# decel = 20.0, delta = 0.1s -> speed drops by 2.0 (from 4.0 to 2.0)
	var brake_step1 = move_ctrl.apply_braking(0.1)
	assert(is_equal_approx(brake_step1.z, 2.0), "After 0.1s braking at decel=20, velocity.z should be 2.0, got: %f" % brake_step1.z)
	
	# Next 0.1s braking -> speed drops from 2.0 to 0.0
	var brake_step2 = move_ctrl.apply_braking(0.1)
	assert(is_equal_approx(brake_step2.z, 0.0), "Speed should be 0 after full brake")
	assert(not move_ctrl.is_moving, "Should not be moving after full stop")
	print("[PASS] Test 4: Deceleration and braking curve verified.")
	
	# Test 5: Smooth visual rotation interpolation
	var visual_node = Node3D.new()
	body.add_child(visual_node)
	visual_node.rotation.y = 0.0
	# Target forward pointing east (Vector3.RIGHT = +X, angle = PI/2)
	move_ctrl.smooth_rotate_visual(visual_node, Vector3.RIGHT, 0.1, 5.0)
	assert(visual_node.rotation.y > 0.0 and visual_node.rotation.y < PI / 2.0, "Visual rotation.y should smoothly interpolate towards target")
	print("[PASS] Test 5: Visual rotation interpolation verified.")
	
	# Test 6: LOD Distance & Update Frequency
	body.position = Vector3(0, 0, 0)
	# At distance 10m -> LOD_NEAR
	var lod_near = lod_ctrl.update_lod_distance(Vector3(0, 0, 10))
	assert(lod_near == CharacterLODController.LODLevel.LOD_NEAR, "LOD at 10m should be LOD_NEAR")
	assert(lod_ctrl.should_update_animation(), "LOD_NEAR should update animation every frame")
	
	# At distance 30m -> LOD_MID
	var lod_mid = lod_ctrl.update_lod_distance(Vector3(0, 0, 30))
	assert(lod_mid == CharacterLODController.LODLevel.LOD_MID, "LOD at 30m should be LOD_MID")
	
	# At distance 60m -> LOD_FAR
	var lod_far = lod_ctrl.update_lod_distance(Vector3(0, 0, 60))
	assert(lod_far == CharacterLODController.LODLevel.LOD_FAR, "LOD at 60m should be LOD_FAR")
	print("[PASS] Test 6: LOD distance thresholds and levels verified.")
	
	# Cleanup
	body.queue_free()
	print("=== ALL CHARACTER MOVEMENT & LOD TESTS PASSED SUCCESSFULLY! ===")
	quit(0)
