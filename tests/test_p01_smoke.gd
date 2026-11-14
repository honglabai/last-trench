extends SceneTree

func _init() -> void:
	print("[TEST] Running P01 Smoke Tests...")
	
	# 1. Check main_menu scene load
	var main_menu_res = load("res://scenes/app/main_menu.tscn")
	if not main_menu_res:
		push_error("Failed to load res://scenes/app/main_menu.tscn")
		quit(1)
		return
	var main_menu_node = main_menu_res.instantiate()
	if not main_menu_node:
		push_error("Failed to instantiate main_menu.tscn")
		quit(1)
		return
	print("[PASS] main_menu.tscn instantiated successfully")
	main_menu_node.free()
	
	# 2. Check game_root scene load
	var game_root_res = load("res://scenes/app/game_root.tscn")
	if not game_root_res:
		push_error("Failed to load res://scenes/app/game_root.tscn")
		quit(1)
		return
	var game_root_node = game_root_res.instantiate()
	if not game_root_node:
		push_error("Failed to instantiate game_root.tscn")
		quit(1)
		return
	print("[PASS] game_root.tscn instantiated successfully")
	game_root_node.free()
	
	# 3. Check InputMap actions
	var required_actions = ["move_forward", "move_backward", "move_left", "move_right", "fire", "aim", "reload", "interact"]
	for action in required_actions:
		if not InputMap.has_action(action):
			push_error("Missing required InputMap action: " + action)
			quit(1)
			return
		print("[PASS] InputMap action verified: " + action)
		
	print("[TEST COMPLETE] P01 smoke tests passed with 0 errors!")
	quit(0)
