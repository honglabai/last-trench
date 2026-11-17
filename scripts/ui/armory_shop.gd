class_name ArmoryShop
extends CanvasLayer

signal weapon_equipped(weapon_id: String)
signal closed()

var _credits_label: Label
var credits_label: Label:
	get:
		if not _credits_label: _credits_label = get_node_or_null("Panel/VBox/Header/CreditsLabel")
		return _credits_label

var _grant_btn: Button
var grant_btn: Button:
	get:
		if not _grant_btn: _grant_btn = get_node_or_null("Panel/VBox/Header/GrantBtn")
		return _grant_btn

var _close_btn: BaseButton
var close_btn: BaseButton:
	get:
		if not _close_btn: _close_btn = get_node_or_null("Panel/VBox/Footer/CloseBtn")
		return _close_btn

var _weapon_container: VBoxContainer
var weapon_container: VBoxContainer:
	get:
		if not _weapon_container: _weapon_container = get_node_or_null("Panel/VBox/Scroll/WeaponList")
		return _weapon_container

var weapons_data: Dictionary = {}

func _ready() -> void:
	layer = 30 # Topmost layer above touch controls and HUD
	_load_weapons_data()
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
	if grant_btn:
		var do_grant = func():
			AudioManager.play_sound("click")
			GameSession.add_credits(2000)
			refresh_shop_ui()
		grant_btn.pressed.connect(do_grant)
		grant_btn.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventScreenTouch and ev.pressed:
				do_grant.call()
		)
	refresh_shop_ui()

func open_shop() -> void:
	visible = true
	refresh_shop_ui()

func close_shop() -> void:
	visible = false
	closed.emit()

func _on_close_pressed() -> void:
	AudioManager.play_sound("click")
	close_shop()

func _load_weapons_data() -> void:
	var path := "res://data/weapons.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		weapons_data = parsed

func refresh_shop_ui() -> void:
	if credits_label:
		credits_label.text = "보유 전공 점수: %d P" % GameSession.credits
		
	if not weapon_container:
		return
		
	# Clear existing card nodes
	for child in weapon_container.get_children():
		child.queue_free()
		
	var weapon_ids = ["k2c1_rifle", "m4a1_carbine", "hk416_elite", "scar_h_battle", "k14_sniper"]
	for w_id in weapon_ids:
		if not weapons_data.has(w_id):
			continue
		var w_info: Dictionary = weapons_data[w_id]
		var card = _create_weapon_card(w_id, w_info)
		weapon_container.add_child(card)

func _create_weapon_card(w_id: String, info: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 100)
	
	var is_owned: bool = GameSession.owned_weapons.has(w_id)
	var cur_lvl: int = GameSession.get_weapon_level(w_id)
	var is_equipped: bool = (GameSession.equipped_weapon_id == w_id)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)
	
	# 1. Weapon Icon / Flag
	var info_box := VBoxContainer.new()
	info_box.custom_minimum_size = Vector2(240, 0)
	hbox.add_child(info_box)
	
	var name_lbl := Label.new()
	var country_name = info.get("country", "")
	name_lbl.text = "[%s] %s" % [country_name, info.get("name", w_id)]
	name_lbl.add_theme_font_size_override("font_size", 18)
	if is_equipped:
		name_lbl.modulate = Color(0.2, 0.9, 1.0)
	info_box.add_child(name_lbl)
	
	var type_lbl := Label.new()
	type_lbl.text = "구분: %s" % info.get("type", "화기")
	type_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 0.95, 0.8))
	type_lbl.add_theme_font_size_override("font_size", 13)
	info_box.add_child(type_lbl)
	
	var lvl_lbl := Label.new()
	lvl_lbl.text = "숙련도: Lv. %d / 5" % cur_lvl if is_owned else "상태: 미보유 (구매 필요)"
	lvl_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if is_owned else Color(0.9, 0.4, 0.4))
	lvl_lbl.add_theme_font_size_override("font_size", 13)
	info_box.add_child(lvl_lbl)
	
	# 2. Stats Summary
	var stats_box := VBoxContainer.new()
	stats_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(stats_box)
	
	var up_dict: Dictionary = info.get("upgrade_per_level", {})
	var lvl_step: int = maxi(0, cur_lvl - 1)
	var cur_dmg: float = float(info.get("damage", 25.0)) + float(up_dict.get("damage", 5.0)) * lvl_step
	var cur_mag: int = int(info.get("magazine_size", 30)) + int(up_dict.get("magazine_size", 5)) * lvl_step
	var cur_fr: float = maxf(0.05, float(info.get("fire_rate", 0.12)) + float(up_dict.get("fire_rate", -0.005)) * lvl_step)
	var cur_rel: float = maxf(0.8, float(info.get("reload_time", 1.8)) + float(up_dict.get("reload_time", -0.12)) * lvl_step)
	
	var stats_lbl := Label.new()
	stats_lbl.text = "화력(파괴력): %.1f | 장탄수: %d발 | 연사속도: %.2fs | 재장전: %.1fs" % [cur_dmg, cur_mag, cur_fr, cur_rel]
	stats_lbl.add_theme_font_size_override("font_size", 14)
	stats_box.add_child(stats_lbl)
	
	var desc_lbl := Label.new()
	desc_lbl.text = info.get("description", "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.75))
	stats_box.add_child(desc_lbl)
	
	# 3. Action Buttons (Buy, Upgrade, Equip)
	var action_box := VBoxContainer.new()
	action_box.custom_minimum_size = Vector2(180, 0)
	action_box.add_theme_constant_override("separation", 6)
	hbox.add_child(action_box)
	
	if not is_owned:
		var buy_btn := Button.new()
		var price: int = int(info.get("price", 500))
		buy_btn.text = "무기 구매 (%d P)" % price
		buy_btn.custom_minimum_size = Vector2(0, 42)
		buy_btn.disabled = (GameSession.credits < price)
		var do_buy = func():
			if not buy_btn.disabled and GameSession.buy_weapon(w_id, price):
				AudioManager.play_sound("reload")
				GameSession.equip_weapon(w_id)
				weapon_equipped.emit(w_id)
				refresh_shop_ui()
		buy_btn.pressed.connect(do_buy)
		buy_btn.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventScreenTouch and ev.pressed:
				do_buy.call()
		)
		action_box.add_child(buy_btn)
	else:
		# Equip / Status button
		var equip_btn := Button.new()
		equip_btn.custom_minimum_size = Vector2(0, 40)
		if is_equipped:
			equip_btn.text = "장착 완료 (EQUIPPED)"
			equip_btn.disabled = true
			equip_btn.modulate = Color(0.3, 1.0, 0.6)
		else:
			equip_btn.text = "전투 장착 (EQUIP)"
			var do_equip = func():
				AudioManager.play_sound("click")
				GameSession.equip_weapon(w_id)
				weapon_equipped.emit(w_id)
				refresh_shop_ui()
			equip_btn.pressed.connect(do_equip)
			equip_btn.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventScreenTouch and ev.pressed:
					do_equip.call()
			)
		action_box.add_child(equip_btn)
		
		# Upgrade Level button
		if cur_lvl < 5:
			var up_cost: int = int(up_dict.get("cost_multiplier", 300)) * cur_lvl
			var up_btn := Button.new()
			up_btn.custom_minimum_size = Vector2(0, 34)
			up_btn.text = "Lv.%d 강화 (%d P)" % [cur_lvl + 1, up_cost]
			up_btn.disabled = (GameSession.credits < up_cost)
			var do_up = func():
				if not up_btn.disabled and GameSession.upgrade_weapon(w_id, up_cost):
					AudioManager.play_sound("reload")
					weapon_equipped.emit(w_id)
					refresh_shop_ui()
			up_btn.pressed.connect(do_up)
			up_btn.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventScreenTouch and ev.pressed:
					do_up.call()
			)
			action_box.add_child(up_btn)
		else:
			var max_lbl := Label.new()
			max_lbl.text = "최고 레벨 도달 (MAX)"
			max_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			max_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			action_box.add_child(max_lbl)
			
	return panel
