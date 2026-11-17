extends SceneTree

func _init() -> void:
	print("[TEST] Running Weapons Arsenal, Scaling & Armory Shop Tests...")
	
	# 1. Test weapons.json loading and 7 weapons (including Rocket Launcher & ATGM)
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
	var expected_weapons = [
		"k2c1_rifle",
		"m4a1_carbine",
		"hk416_elite",
		"scar_h_battle",
		"k14_sniper",
		"rpg7_launcher",
		"hyungung_atgm"
	]
	for w_id in expected_weapons:
		if not w_data.has(w_id):
			push_error("Missing weapon in catalog: " + w_id)
			quit(1)
			return
		var entry: Dictionary = w_data[w_id]
		if not entry.has("thumbnail") or entry["thumbnail"].is_empty():
			push_error("Missing thumbnail picture for weapon: " + w_id)
			quit(1)
			return
	print("[PASS] Verified all 7 weapons and thumbnails in weapons.json catalog")
	
	# 2. Test WeaponComponent level scaling & Explosive Weapons
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
	
	# RPG-7 Rocket Launcher
	wc.load_weapon_data("rpg7_launcher", 1)
	if not wc.is_explosive or wc.splash_radius < 5.0 or wc.damage < 200.0:
		push_error("RPG-7 explosive properties incorrect: is_explosive=%s, radius=%.1f, dmg=%.1f" % [wc.is_explosive, wc.splash_radius, wc.damage])
		quit(1)
		return
	print("[PASS] RPG-7 anti-tank rocket launcher explosive verified: dmg=%.1f, radius=%.1fm" % [wc.damage, wc.splash_radius])
	
	# Hyungung ATGM Missile
	wc.load_weapon_data("hyungung_atgm", 1)
	if not wc.is_explosive or wc.splash_radius < 7.0 or wc.damage < 300.0:
		push_error("Hyungung ATGM properties incorrect: is_explosive=%s, radius=%.1f, dmg=%.1f" % [wc.is_explosive, wc.splash_radius, wc.damage])
		quit(1)
		return
	print("[PASS] Hyungung K-ATGM anti-tank missile verified: dmg=%.1f, radius=%.1fm" % [wc.damage, wc.splash_radius])
	wc.queue_free()
	
	# 3. Test GameSession Credits & Weapon Purchase/Upgrade
	GameSession.add_credits(5000)
	GameSession.owned_weapons.erase("rpg7_launcher")
	GameSession.save_profile()
	var pre_credits = GameSession.credits
	
	# Buy RPG-7 (2,800 P)
	var buy_ok = GameSession.buy_weapon("rpg7_launcher", 2800)
	if not buy_ok or not GameSession.owned_weapons.has("rpg7_launcher"):
		push_error("GameSession RPG-7 purchase failed")
		quit(1)
		return
	if GameSession.credits != pre_credits - 2800:
		push_error("GameSession credits deduction failed")
		quit(1)
		return
	print("[PASS] RPG-7 purchase and credit deduction verified")
	
	# Equip RPG-7
	GameSession.equip_weapon("rpg7_launcher")
	if GameSession.equipped_weapon_id != "rpg7_launcher":
		push_error("GameSession equip weapon failed")
		quit(1)
		return
	print("[PASS] Weapon equip verified: ", GameSession.equipped_weapon_id)
	
	# 4. Test ArmoryShop UI instantiation and 7 Cards
	var shop_scene = load("res://scenes/ui/armory_shop.tscn")
	var shop = shop_scene.instantiate() as ArmoryShop
	root.add_child(shop)
	await process_frame
	if not shop.weapon_container or shop.weapon_container.get_child_count() < 7:
		push_error("ArmoryShop failed to populate 7 weapon cards, count is: " + str(shop.weapon_container.get_child_count() if shop.weapon_container else 0))
		quit(1)
		return
	print("[PASS] ArmoryShop UI populated 7 weapon cards with photos and stats successfully")
	
	if not shop.grant_btn:
		push_error("ArmoryShop missing grant_btn")
		quit(1)
		return
	var pre_grant := GameSession.credits
	shop.grant_btn.pressed.emit()
	if GameSession.credits != pre_grant + 2000:
		push_error("ArmoryShop grant_btn failed to add 2000 credits")
		quit(1)
		return
	print("[PASS] ArmoryShop supply grant (+2,000 P [G]) verified")
	shop.queue_free()
	
	# 5. Test Weapon Cycling with 7 weapons
	GameSession.owned_weapons["k2c1_rifle"] = 1
	var next_w := GameSession.get_next_owned_weapon("k2c1_rifle")
	if next_w != "rpg7_launcher" and next_w != "m4a1_carbine":
		push_error("get_next_owned_weapon expected owned weapon but got: " + next_w)
		quit(1)
		return
	print("[PASS] Weapon cycling between owned weapons verified")
	
	print("[TEST COMPLETE] Weapons Arsenal & Armory Shop tests passed with 0 errors!")
	quit(0)
