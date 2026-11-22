extends SceneTree

func _init() -> void:
	print("[TEST] Running Grenade Usage & Shop Purchase Lifecycle Tests...")
	
	# Reset/setup clean state
	GameSession.grenade_count = 3
	GameSession.credits = 1000
	GameSession.save_profile()
	
	# 1. Test GameSession use_grenade decrement
	assert(GameSession.get_grenade_count() == 3, "Initial grenade count should be 3")
	
	var used1 := GameSession.use_grenade()
	assert(used1 == true, "use_grenade should return true when count > 0")
	assert(GameSession.get_grenade_count() == 2, "Grenade count should decrement to 2")
	print("[PASS] 1st grenade used: count decremented from 3 to 2")
	
	var used2 := GameSession.use_grenade()
	assert(used2 == true and GameSession.get_grenade_count() == 1, "Count should decrement to 1")
	print("[PASS] 2nd grenade used: count decremented from 2 to 1")
	
	var used3 := GameSession.use_grenade()
	assert(used3 == true and GameSession.get_grenade_count() == 0, "Count should decrement to 0")
	print("[PASS] 3rd grenade used: count decremented from 1 to 0")
	
	# Test when empty (0 grenades)
	var used4 := GameSession.use_grenade()
	assert(used4 == false, "use_grenade should return false when count == 0")
	assert(GameSession.get_grenade_count() == 0, "Count should not go below 0")
	print("[PASS] Empty grenade depletion verified: returns false and stays at 0")
	
	# 2. Test ArmoryShop Purchase (+3 grenades for 250 P)
	var shop_scene: PackedScene = load("res://scenes/ui/armory_shop.tscn")
	assert(shop_scene != null, "ArmoryShop scene should load successfully")
	var shop: ArmoryShop = shop_scene.instantiate() as ArmoryShop
	root.add_child(shop)
	shop._ready()
	shop.open_shop()
	
	assert(GameSession.get_grenade_count() == 0, "Grenade count before purchase should be 0")
	var init_credits := GameSession.credits
	
	# Trigger quick action or purchase for k413_grenade
	shop._handle_quick_key_action("k413_grenade")
	assert(GameSession.get_grenade_count() == 3, "Purchasing in shop should increase grenade count from 0 to 3, got %d" % GameSession.get_grenade_count())
	assert(GameSession.credits == init_credits - 250, "Credits should decrease by 250 (from %d to %d)" % [init_credits, GameSession.credits])
	print("[PASS] Shop purchase (+3 grenades) verified: count increased from 0 to 3, 250 credits spent")
	
	# Purchase again
	shop._handle_quick_key_action("k413_grenade")
	assert(GameSession.get_grenade_count() == 6, "Purchasing in shop second time should increase grenade count to 6, got %d" % GameSession.get_grenade_count())
	print("[PASS] Second shop purchase verified: count increased from 3 to 6")
	
	shop.close_shop()
	shop.queue_free()
	
	# 3. Test TouchControls visual update (dimming at 0, badge update)
	var touch_scene: PackedScene = load("res://scenes/ui/touch_controls.tscn")
	var touch: TouchControls = touch_scene.instantiate() as TouchControls
	root.add_child(touch)
	touch._ready()
	
	touch.update_grenade_count(6)
	assert(touch.grenade_button.text == "6", "Grenade button text should be '6'")
	assert(touch.grenade_count_badge != null and touch.grenade_count_badge.text == "6", "Count badge should show '6'")
	assert(touch.grenade_button.modulate == Color(1, 1, 1, 1), "Button should be full brightness when count > 0")
	print("[PASS] TouchControls count badge and full brightness verified for count=6")
	
	touch.update_grenade_count(0)
	assert(touch.grenade_button.text == "0", "Grenade button text should be '0'")
	assert(touch.grenade_count_badge.text == "0", "Count badge should show '0'")
	assert(touch.grenade_button.modulate.a < 0.9, "Button should be dimmed when count == 0")
	print("[PASS] TouchControls count badge and dimming verified for count=0")
	
	touch.queue_free()
	
	# 4. Test BattleHUD grenade count label
	var hud_scene: PackedScene = load("res://scenes/ui/battle_hud.tscn")
	var hud: BattleHUD = hud_scene.instantiate() as BattleHUD
	root.add_child(hud)
	hud._ready()
	
	hud.update_grenade_count(3)
	assert(hud.grenade_label != null, "GrenadeLabel must exist in BattleHUD")
	assert("3" in hud.grenade_label.text, "Grenade label should contain '3'")
	print("[PASS] BattleHUD GrenadeLabel verified for count=3: '%s'" % hud.grenade_label.text)
	
	hud.update_grenade_count(0)
	assert("0" in hud.grenade_label.text, "Grenade label should contain '0'")
	print("[PASS] BattleHUD GrenadeLabel verified for count=0: '%s'" % hud.grenade_label.text)
	
	hud.queue_free()
	
	# 5. Full GameRoot Integration Test
	var root_scene: PackedScene = load("res://scenes/app/game_root.tscn")
	var game_root: GameRoot = root_scene.instantiate() as GameRoot
	root.add_child(game_root)
	game_root._ready()
	
	# Set 2 grenades for testing combat throw
	GameSession.grenade_count = 2
	GameSession.save_profile()
	game_root._on_grenade_count_changed(2)
	
	assert(GameSession.get_grenade_count() == 2, "Starting combat with 2 grenades")
	
	# Throw 1st grenade
	game_root._on_quick_grenade_requested()
	assert(GameSession.get_grenade_count() == 1, "Grenade count should decrement to 1 after throw")
	if game_root.touch_controls:
		assert(game_root.touch_controls.grenade_button.text == "1", "Touch grenade button should reflect 1")
	if game_root.battle_hud and game_root.battle_hud.grenade_label:
		assert("1" in game_root.battle_hud.grenade_label.text, "BattleHUD label should reflect 1")
	print("[PASS] GameRoot quick grenade throw successfully decremented count to 1 and synchronized HUD")
	
	# Throw 2nd grenade
	game_root._last_grenade_time = -1.0 # reset debounce
	game_root._on_quick_grenade_requested()
	assert(GameSession.get_grenade_count() == 0, "Grenade count should decrement to 0 after 2nd throw")
	print("[PASS] GameRoot quick grenade throw successfully decremented count to 0 and synchronized HUD")
	
	# Attempt throw when empty
	game_root._last_grenade_time = -1.0
	game_root._on_quick_grenade_requested()
	assert(GameSession.get_grenade_count() == 0, "Count should remain 0 when empty")
	print("[PASS] GameRoot empty grenade throw blocked and toast triggered")
	
	game_root.queue_free()
	
	print("[TEST COMPLETE] All grenade usage and shop purchase tests PASSED with 0 errors!")
	quit(0)
