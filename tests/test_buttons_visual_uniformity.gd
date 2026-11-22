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
		assert(btn.stretch_mode == TextureButton.STRETCH_SCALE or btn.stretch_mode == TextureButton.STRETCH_KEEP_ASPECT_CENTERED, "Button %s must have valid stretch_mode" % button_names[i])
	
	assert(expected_size == Vector2(265, 76), "MainMenu buttons must be 90%% of previous width (265x76), got %s" % str(expected_size))
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
	var g_width = grenade_btn.offset_right - grenade_btn.offset_left
	var g_height = grenade_btn.offset_bottom - grenade_btn.offset_top
	assert(g_width == 148.0 and g_height == 148.0, "GrenadeButton must be 2x size (148x148), got %fx%f" % [g_width, g_height])
	print("[PASS] GrenadeButton 2x size verified: 148x148")
	
	var reload_btn: Button = touch.get_node_or_null("RightZone/ActionButtons/ReloadButton")
	assert(reload_btn != null and reload_btn.icon != null, "ReloadButton icon must exist")
	
	var switch_btn: Button = touch.get_node_or_null("RightZone/ActionButtons/SwitchButton")
	assert(switch_btn != null and switch_btn.icon != null, "SwitchButton icon must exist")
	
	var interact_btn: Button = touch.get_node_or_null("RightZone/ActionButtons/InteractButton")
	assert(interact_btn != null and interact_btn.icon != null, "InteractButton icon must exist")
	
	# Verify no overlap among right zone action buttons
	var rect_map: Dictionary = {
		"Fire": Rect2(fire_btn.offset_left, fire_btn.offset_top, fire_btn.offset_right - fire_btn.offset_left, fire_btn.offset_bottom - fire_btn.offset_top),
		"Grenade": Rect2(grenade_btn.offset_left, grenade_btn.offset_top, g_width, g_height),
		"Reload": Rect2(reload_btn.offset_left, reload_btn.offset_top, reload_btn.offset_right - reload_btn.offset_left, reload_btn.offset_bottom - reload_btn.offset_top),
		"Switch": Rect2(switch_btn.offset_left, switch_btn.offset_top, switch_btn.offset_right - switch_btn.offset_left, switch_btn.offset_bottom - switch_btn.offset_top),
		"Interact": Rect2(interact_btn.offset_left, interact_btn.offset_top, interact_btn.offset_right - interact_btn.offset_left, interact_btn.offset_bottom - interact_btn.offset_top)
	}
	for k1 in rect_map.keys():
		for k2 in rect_map.keys():
			if k1 >= k2: continue
			var r1: Rect2 = rect_map[k1]
			var r2: Rect2 = rect_map[k2]
			assert(not r1.intersects(r2), "Button %s and %s must not overlap! r1=%s, r2=%s" % [k1, k2, str(r1), str(r2)])
	print("[PASS] Action buttons zero-overlap layout verified")
	
	print("[PASS] All 7 HUD action buttons and textures verified in touch_controls.tscn")
	touch.queue_free()
	
	# 3. Test Shortcuts S (Shop) and I (Settings)
	var menu2: MainMenu = main_menu_scene.instantiate() as MainMenu
	root.add_child(menu2)
	menu2._ready()
	
	# Test S key for Shop
	var event_s := InputEventKey.new()
	event_s.pressed = true
	event_s.keycode = KEY_S
	menu2._unhandled_input(event_s)
	assert(menu2.armory_shop != null and menu2.armory_shop.visible == true, "S key must open ArmoryShop in MainMenu")
	print("[PASS] Shortcut S successfully opens ArmoryShop")
	
	# Test S key closes Shop
	var event_s_close := InputEventKey.new()
	event_s_close.pressed = true
	event_s_close.keycode = KEY_S
	menu2.armory_shop._unhandled_input(event_s_close)
	assert(menu2.armory_shop.visible == false, "S key must close ArmoryShop when open")
	print("[PASS] Shortcut S successfully closes ArmoryShop")
	
	# Test I key for Settings
	var event_i := InputEventKey.new()
	event_i.pressed = true
	event_i.keycode = KEY_I
	menu2._unhandled_input(event_i)
	assert(menu2.settings_dialog != null and menu2.settings_dialog.visible == true, "I key must open Settings in MainMenu")
	print("[PASS] Shortcut I successfully opens Settings")
	
	# Test I key closes Settings
	var event_i_close := InputEventKey.new()
	event_i_close.pressed = true
	event_i_close.keycode = KEY_I
	menu2._unhandled_input(event_i_close)
	assert(menu2.settings_dialog.visible == false, "I key must close Settings when open")
	print("[PASS] Shortcut I successfully closes Settings")
	
	menu2.queue_free()
	
	print("[TEST COMPLETE] Buttons Visual Uniformity & Layout tests passed with 0 errors!")
	quit(0)
