extends SceneTree

func _init() -> void:
	print("[TEST] Running Buttons Visual Uniformity & Layout Tests...")
	
	# 1. Main Menu Buttons Test
	var main_menu_scene: PackedScene = load("res://scenes/app/main_menu.tscn")
	assert(main_menu_scene != null, "MainMenu scene should load successfully")
	var menu: Node = main_menu_scene.instantiate()
	
	var vbox: VBoxContainer = menu.get_node_or_null("CenterContainer/VBoxContainer")
	assert(vbox != null, "VBoxContainer must exist in MainMenu")
	
	var sep = vbox.get_theme_constant("separation")
	assert(sep == 2, "VBoxContainer separation must be exactly 2px, got %d" % sep)
	print("[PASS] MainMenu VBoxContainer vertical button separation is exactly 2px")
	
	var button_names = ["StartButton", "ShopButton", "GuideButton", "SettingsButton", "ExitButton"]
	var expected_size: Vector2 = Vector2.ZERO
	for i in range(button_names.size()):
		var btn: TextureButton = vbox.get_node_or_null(button_names[i])
		assert(btn != null, "Button %s must exist in MainMenu" % button_names[i])
		if i == 0:
			expected_size = btn.custom_minimum_size
			assert(expected_size.x > 0 and expected_size.y > 0, "Button size must be valid")
		else:
			assert(btn.custom_minimum_size == expected_size, 
				"Button %s size (%s) must match expected size (%s)" % [button_names[i], str(btn.custom_minimum_size), str(expected_size)])
		
		assert(btn.texture_normal != null, "Button %s normal texture must be assigned" % button_names[i])
		assert(btn.texture_pressed != null, "Button %s pressed texture must be assigned" % button_names[i])
		assert(btn.stretch_mode == TextureButton.STRETCH_KEEP_ASPECT_CENTERED, "Button %s must have keep_aspect_centered stretch_mode" % button_names[i])
	
	print("[PASS] All 5 MainMenu buttons verified with exact identical size: %s" % str(expected_size))
	menu.queue_free()
	
	# 2. Touch Controls HUD Buttons Test
	var touch_scene: PackedScene = load("res://scenes/ui/touch_controls.tscn")
	assert(touch_scene != null, "TouchControls scene should load successfully")
	var touch: Node = touch_scene.instantiate()
	
	var joy_base: TextureRect = touch.get_node_or_null("LeftZone/JoystickBase")
	assert(joy_base != null and joy_base.texture != null, "JoystickBase texture must exist")
	
	var aim_btn: Button = touch.get_node_or_null("LeftZone/AimButton")
	assert(aim_btn != null and aim_btn.icon != null, "AimButton icon must exist")
	
	var fire_btn: Button = touch.get_node_or_null("RightZone/ActionButtons/FireButton")
	assert(fire_btn != null and fire_btn.icon != null, "FireButton icon must exist")
	
	var grenade_btn: Button = touch.get_node_or_null("RightZone/ActionButtons/GrenadeButton")
	assert(grenade_btn != null and grenade_btn.icon != null, "GrenadeButton icon must exist")
	
	var reload_btn: Button = touch.get_node_or_null("RightZone/ActionButtons/ReloadButton")
	assert(reload_btn != null and reload_btn.icon != null, "ReloadButton icon must exist")
	
	var switch_btn: Button = touch.get_node_or_null("RightZone/ActionButtons/SwitchButton")
	assert(switch_btn != null and switch_btn.icon != null, "SwitchButton icon must exist")
	
	var interact_btn: Button = touch.get_node_or_null("RightZone/ActionButtons/InteractButton")
	assert(interact_btn != null and interact_btn.icon != null, "InteractButton icon must exist")
	
	print("[PASS] All 7 HUD action buttons and textures verified in touch_controls.tscn")
	touch.queue_free()
	
	print("[TEST COMPLETE] Buttons Visual Uniformity & Layout tests passed with 0 errors!")
	quit(0)
