extends SceneTree

func _init() -> void:
	print("[TEST] Running Weapons Arsenal, Scaling & Armory Shop Tests...")
	
	# 1. Test weapons.json loading and 5 national firearms
	var path := "res://data/weapons.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open data/weapons.json")
		quit(1)
		return
	var test_json := JSON.new()
	if test_json.parse(file.get_as_text()) != OK:
		push_error("Failed to parse data/weapons.json")
		quit(1)
		return
	var w_data: Dictionary = test_json.data
	var expected_weapons = ["k2c1_rifle", "m4a1_carbine", "hk416_elite", "scar_h_battle", "k14_sniper"]
	for w_id in expected_weapons:
		if not w_data.has(w_id):
			push_error("Missing national firearm in catalog: " + w_id)
			quit(1)
			return
	print("[PASS] Verified all 5 national firearms in weapons.json catalog")
	
	# 2. Test WeaponComponent level scaling
	var wc := WeaponComponent.new()
	root.add_child(wc)
	
	# Level 1 K2C1
	wc.load_weapon_data("k2c1_rifle", 1)
	var base_dmg := wc.damage
	var base_mag := wc.magazine_size
	if base_dmg != 25.0 or base_mag != 30:
		push_error("K2C1 Level 1 base stats incorrect")
		quit(1)
		return
		
	# Level 3 K2C1
	wc.load_weapon_data("k2c1_rifle", 3)
	if wc.damage <= base_dmg or wc.magazine_size <= base_mag:
		push_error("K2C1 Level 3 upgrade scaling failed to increase stats")
		quit(1)
		return
	print("[PASS] WeaponComponent level upgrade stat scaling verified (Lv.1: %.1f dmg -> Lv.3: %.1f dmg)" % [base_dmg, wc.damage])
	
	# SCAR-H heavy damage check
	wc.load_weapon_data("scar_h_battle", 1)
	if wc.damage < 50.0:
		push_error("SCAR-H heavy damage expected >= 50.0")
		quit(1)
		return
	print("[PASS] FN SCAR-H 7.62mm heavy battle rifle damage verified: %.1f" % wc.damage)
	
	# K14 sniper damage check
	wc.load_weapon_data("k14_sniper", 1)
	if wc.damage < 120.0:
		push_error("K14 sniper rifle damage expected >= 120.0")
		quit(1)
		return
	print("[PASS] K14 sniper rifle high damage verified: %.1f" % wc.damage)
	wc.queue_free()
	
	# 3. Test GameSession Credits & Weapon Purchase/Upgrade
	GameSession.add_credits(2000)
	GameSession.owned_weapons.erase("m4a1_carbine")
	GameSession.save_profile()
	var pre_credits = GameSession.credits
	# Buy M4A1 (500 P)
	var buy_ok = GameSession.buy_weapon("m4a1_carbine", 500)
	if not buy_ok or not GameSession.owned_weapons.has("m4a1_carbine"):
		push_error("GameSession weapon purchase failed")
		quit(1)
		return
	if GameSession.credits != pre_credits - 500:
		push_error("GameSession credits deduction failed")
		quit(1)
		return
	print("[PASS] Weapon purchase and credit deduction verified")
	
	# Equip M4A1
	GameSession.equip_weapon("m4a1_carbine")
	if GameSession.equipped_weapon_id != "m4a1_carbine":
		push_error("GameSession equip weapon failed")
		quit(1)
		return
	print("[PASS] Weapon equip verified: ", GameSession.equipped_weapon_id)
	
	# Upgrade M4A1 to Lv. 2
	var up_ok = GameSession.upgrade_weapon("m4a1_carbine", 350)
	if not up_ok or GameSession.get_weapon_level("m4a1_carbine") != 2:
		push_error("GameSession weapon upgrade failed")
		quit(1)
		return
	print("[PASS] Weapon upgrade to Level 2 verified")
	
	# 4. Test ArmoryShop UI instantiation
	var shop_scene = load("res://scenes/ui/armory_shop.tscn")
	var shop = shop_scene.instantiate() as ArmoryShop
	root.add_child(shop)
	await process_frame
	if not shop.weapon_container or shop.weapon_container.get_child_count() < 5:
		push_error("ArmoryShop failed to populate 5 weapon cards")
		quit(1)
		return
	print("[PASS] ArmoryShop UI populated 5 weapon cards successfully")
	shop.queue_free()
	
	print("[TEST COMPLETE] Weapons Arsenal & Armory Shop tests passed with 0 errors!")
	quit(0)
