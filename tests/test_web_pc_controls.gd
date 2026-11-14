extends SceneTree

func _init() -> void:
	print("[TEST] Running Web & PC Controls Tests...")
	
	# 1. Test PlayerController keyboard input integration
	var player_scene = load("res://scenes/actors/player.tscn")
	if not player_scene:
		push_error("Failed to load player.tscn")
		quit(1)
		return
		
	var player = player_scene.instantiate() as PlayerController
	root.add_child(player)
	
	# Test mouse motion input
	var mouse_event = InputEventMouseMotion.new()
	mouse_event.relative = Vector2(50.0, -25.0)
	player._unhandled_input(mouse_event)
	
	if not player.camera_rig or is_equal_approx(player.camera_rig.yaw, 0.0):
		push_error("Mouse motion failed to rotate camera yaw")
		quit(1)
		return
	print("[PASS] Mouse motion camera aiming verified: yaw = ", player.camera_rig.yaw)
	
	# 2. Test GameRoot Keyboard Interact & DefenseSlot E shortcut
	var root_scene = load("res://scenes/app/game_root.tscn")
	var game_root = root_scene.instantiate() as GameRoot
	root.add_child(game_root)
	
	# Move player close to slot_left
	var slots = game_root.trench_map.get_defense_slots()
	if slots.is_empty():
		push_error("No defense slots found in map")
		quit(1)
		return
		
	var target_slot = slots[0]
	game_root.player.position = target_slot.position + Vector3(0.0, 0.0, 1.0)
	target_slot.update_player_proximity(game_root.player.position)
	game_root.active_slot_nearby = target_slot
	
	if not target_slot.can_install():
		push_error("Target slot not available for installation")
		quit(1)
		return
		
	# Trigger E key interact
	var interact_event = InputEventAction.new()
	interact_event.action = "interact"
	interact_event.pressed = true
	game_root._unhandled_input(interact_event)
	
	if not target_slot.is_occupied:
		push_error("Pressing E failed to install turret on slot")
		quit(1)
		return
	print("[PASS] PC [E] key turret installation on DefenseSlot verified")
	
	# 3. Test BattleHUD Help Label
	if not game_root.battle_hud or not game_root.battle_hud.help_label:
		push_error("BattleHUD help_label missing")
		quit(1)
		return
	if not game_root.battle_hud.help_label.text.contains("[마우스]"):
		push_error("BattleHUD help text missing mouse aim guide")
		quit(1)
		return
	print("[PASS] BattleHUD PC controls guide text verified: ", game_root.battle_hud.help_label.text)
	
	player.queue_free()
	game_root.queue_free()
	
	print("[TEST COMPLETE] Web & PC controls tests passed with 0 errors!")
	quit(0)
