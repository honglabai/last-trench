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
const WEAPON_IDS: Array[String] = [
	"k2c1_rifle",
	"k5_pistol",
	"k413_grenade",
	"m4a1_carbine",
	"hk416_elite",
	"scar_h_battle",
	"k14_sniper",
	"rpg7_launcher",
	"hyungung_atgm"
]

func _ready() -> void:
	layer = 30 # Topmost layer above touch controls and HUD
	_load_weapons_data()
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
	if grant_btn:
		grant_btn.text = "+2,000 P 보급금 지원 [G]"
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

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_S or event.keycode == KEY_B:
			_on_close_pressed()
			var vp := get_viewport()
			if vp: vp.set_input_as_handled()
			return
		elif event.keycode == KEY_G:
			AudioManager.play_sound("click")
			GameSession.add_credits(2000)
			refresh_shop_ui()
			var vp := get_viewport()
			if vp: vp.set_input_as_handled()
			return
		elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var slot_idx: int = event.keycode - KEY_1
			if slot_idx >= 0 and slot_idx < WEAPON_IDS.size():
				var target_w_id: String = WEAPON_IDS[slot_idx]
				_handle_quick_key_action(target_w_id)
				get_viewport().set_input_as_handled()
				return

func _handle_quick_key_action(w_id: String) -> void:
	if not weapons_data.has(w_id):
		return
	if w_id == "k413_grenade":
		var grn_price: int = 250
		if GameSession.grenade_count < GameSession.max_grenades and GameSession.spend_credits(grn_price):
			GameSession.add_grenades(3)
			AudioManager.play_sound("reload")
			refresh_shop_ui()
		else:
			AudioManager.play_sound("click", 0.05, -3.0)
		return
	var info: Dictionary = weapons_data[w_id]
	var is_owned: bool = GameSession.owned_weapons.has(w_id)
	if not is_owned:
		var price: int = int(info.get("price", 500))
		if GameSession.credits >= price and GameSession.buy_weapon(w_id, price):
			AudioManager.play_sound("reload")
			GameSession.equip_weapon(w_id)
			weapon_equipped.emit(w_id)
			refresh_shop_ui()
		else:
			AudioManager.play_sound("click", 0.05, -3.0)
	else:
		AudioManager.play_sound("click")
		GameSession.equip_weapon(w_id)
		weapon_equipped.emit(w_id)
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
		
	for i in range(WEAPON_IDS.size()):
		var w_id: String = WEAPON_IDS[i]
		if not weapons_data.has(w_id):
			continue
		var w_info: Dictionary = weapons_data[w_id]
		var card = _create_weapon_card(w_id, w_info, i + 1)
		weapon_container.add_child(card)

func _create_weapon_card(w_id: String, info: Dictionary, key_num: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 112)
	
	var is_owned: bool = GameSession.owned_weapons.has(w_id)
	var cur_lvl: int = GameSession.get_weapon_level(w_id)
	var is_equipped: bool = (GameSession.equipped_weapon_id == w_id)
	var is_explosive: bool = bool(info.get("is_explosive", false))
	
	# Tactical card border
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.13, 0.92)
	if w_id == "k413_grenade":
		style.border_color = Color(0.2, 0.75, 0.95, 0.85) # High-tech cyan for consumable ordnance
	elif is_equipped:
		style.border_color = Color(0.2, 0.95, 0.6, 0.9) # Glowing green for equipped
	elif is_owned:
		style.border_color = Color(0.2, 0.75, 0.95, 0.6) # Cyan for owned
	else:
		style.border_color = Color(0.4, 0.5, 0.6, 0.4) # Subdued gray for locked
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	panel.add_child(hbox)
	
	# 1. Weapon Picture Thumbnail Box
	var thumb_box := PanelContainer.new()
	thumb_box.custom_minimum_size = Vector2(136, 92)
	var thumb_style := StyleBoxFlat.new()
	thumb_style.bg_color = Color(0.02, 0.04, 0.07, 0.95)
	thumb_style.border_color = Color(0.25, 0.55, 0.75, 0.4)
	thumb_style.border_width_left = 1
	thumb_style.border_width_top = 1
	thumb_style.border_width_right = 1
	thumb_style.border_width_bottom = 1
	thumb_style.corner_radius_top_left = 4
	thumb_style.corner_radius_top_right = 4
	thumb_style.corner_radius_bottom_right = 4
	thumb_style.corner_radius_bottom_left = 4
	thumb_box.add_theme_stylebox_override("panel", thumb_style)
	hbox.add_child(thumb_box)
	
	var thumb_inner := VBoxContainer.new()
	thumb_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	thumb_box.add_child(thumb_inner)
	
	var thumb_img := TextureRect.new()
	thumb_img.custom_minimum_size = Vector2(128, 70)
	thumb_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var thumb_path: String = info.get("thumbnail", "")
	if thumb_path.is_empty() or not ResourceLoader.exists(thumb_path):
		thumb_path = info.get("texture", "res://assets/textures/tex_fps_iron_sights.png")
	if ResourceLoader.exists(thumb_path):
		thumb_img.texture = load(thumb_path)
	thumb_inner.add_child(thumb_img)
	
	var key_badge := Label.new()
	key_badge.text = "[키보드 %d]" % key_num
	key_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_badge.add_theme_font_size_override("font_size", 13)
	key_badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 0.9))
	thumb_inner.add_child(key_badge)
	
	# 2. Weapon Identity & Status Box
	var info_box := VBoxContainer.new()
	info_box.custom_minimum_size = Vector2(200, 0)
	info_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(info_box)
	
	var name_lbl := Label.new()
	var country_name = info.get("country", "")
	name_lbl.text = "[%s] %s" % [country_name, info.get("name", w_id)]
	name_lbl.add_theme_font_size_override("font_size", 19)
	if w_id == "k413_grenade":
		name_lbl.modulate = Color(0.3, 0.85, 1.0)
	elif is_equipped:
		name_lbl.modulate = Color(0.2, 0.95, 0.6)
	elif is_owned:
		name_lbl.modulate = Color(0.3, 0.85, 1.0)
	info_box.add_child(name_lbl)
	
	var type_lbl := Label.new()
	type_lbl.text = "구분: %s" % info.get("type", "화기")
	type_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 0.95, 0.8))
	type_lbl.add_theme_font_size_override("font_size", 14)
	info_box.add_child(type_lbl)
	
	var lvl_lbl := Label.new()
	if w_id == "k413_grenade":
		lvl_lbl.text = "보유 수량: %d발 / 최대 %d발 (기본 3발 지급)" % [GameSession.get_grenade_count(), GameSession.max_grenades]
		lvl_lbl.add_theme_color_override("font_color", Color(0.2, 0.95, 0.6))
	elif is_owned:
		lvl_lbl.text = "숙련도: Lv. %d / 5" % cur_lvl
		lvl_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	else:
		lvl_lbl.text = "구매가: %d P (미보유)" % int(info.get("price", 500))
		lvl_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
	lvl_lbl.add_theme_font_size_override("font_size", 15)
	info_box.add_child(lvl_lbl)
	
	# 3. Performance Stats Box
	var stats_box := VBoxContainer.new()
	stats_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(stats_box)
	
	var up_dict: Dictionary = info.get("upgrade_per_level", {})
	var lvl_step: int = maxi(0, cur_lvl - 1)
	var cur_dmg: float = float(info.get("damage", 25.0)) + float(up_dict.get("damage", 5.0)) * lvl_step
	var cur_mag: int = int(info.get("magazine_size", 30)) + int(up_dict.get("magazine_size", 5)) * lvl_step
	var cur_fr: float = maxf(0.05, float(info.get("fire_rate", 0.12)) + float(up_dict.get("fire_rate", -0.005)) * lvl_step)
	var cur_rel: float = maxf(0.8, float(info.get("reload_time", 1.8)) + float(up_dict.get("reload_time", -0.12)) * lvl_step)
	var cur_rng: float = float(info.get("range", 80.0))
	
	var stats_lbl1 := Label.new()
	if w_id == "k413_grenade":
		var splash: float = float(info.get("splash_radius", 6.5))
		stats_lbl1.text = "화력: %.0f (광역 파편 폭발 피해) | 폭발 반경: %.1fm | 사거리: 50m" % [cur_dmg, splash]
	elif is_explosive:
		var splash: float = float(info.get("splash_radius", 7.0))
		stats_lbl1.text = "화력: %.0f (광역 폭발 피해) | 폭발 반경: %.1fm | 사거리: %.0fm" % [cur_dmg, splash, cur_rng]
	else:
		stats_lbl1.text = "화력: %.0f (관통 탄환 피해) | 사거리: %.0fm" % [cur_dmg, cur_rng]
	stats_lbl1.add_theme_font_size_override("font_size", 15)
	stats_lbl1.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35) if is_explosive else Color(0.9, 0.95, 1.0))
	stats_box.add_child(stats_lbl1)
	
	var stats_lbl2 := Label.new()
	if w_id == "k413_grenade":
		stats_lbl2.text = "작전 투입 기본: 3발 지급 | 투척 쿨타임: %.1fs | 상점 추가 보급 가능" % cur_fr
	else:
		stats_lbl2.text = "장탄수: %d발 | 연사속도: %.2fs | 재장전: %.1fs" % [cur_mag, cur_fr, cur_rel]
	stats_lbl2.add_theme_font_size_override("font_size", 14)
	stats_lbl2.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95, 0.85))
	stats_box.add_child(stats_lbl2)
	
	var desc_lbl := Label.new()
	desc_lbl.text = info.get("description", "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8, 0.75))
	stats_box.add_child(desc_lbl)
	
	# 4. Action Buttons Box (Buy, Upgrade, Equip)
	var action_box := VBoxContainer.new()
	action_box.custom_minimum_size = Vector2(185, 0)
	action_box.alignment = BoxContainer.ALIGNMENT_CENTER
	action_box.add_theme_constant_override("separation", 6)
	hbox.add_child(action_box)
	
	if w_id == "k413_grenade":
		var grn_price: int = int(info.get("price", 250))
		var grn_btn := Button.new()
		grn_btn.custom_minimum_size = Vector2(0, 52)
		grn_btn.add_theme_font_size_override("font_size", 16)
		var is_max := (GameSession.grenade_count >= GameSession.max_grenades)
		if is_max:
			grn_btn.text = "보급 완료\n(최대 %d발)" % GameSession.max_grenades
			grn_btn.disabled = true
			grn_btn.modulate = Color(0.6, 0.6, 0.6)
		else:
			grn_btn.text = "수류탄 보급 (+3발) [%d]\n(%d P)" % [key_num, grn_price]
			grn_btn.disabled = (GameSession.credits < grn_price)
			grn_btn.modulate = Color(0.4, 0.9, 1.0)
			var do_buy_grn = func():
				if not grn_btn.disabled and GameSession.spend_credits(grn_price):
					GameSession.add_grenades(3)
					AudioManager.play_sound("reload")
					refresh_shop_ui()
			grn_btn.pressed.connect(do_buy_grn)
			grn_btn.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventScreenTouch and ev.pressed:
					do_buy_grn.call()
			)
		action_box.add_child(grn_btn)
		return panel

	if not is_owned:
		var buy_btn := Button.new()
		var price: int = int(info.get("price", 500))
		buy_btn.text = "무기 구매 [%d]\n(%d P)" % [key_num, price]
		buy_btn.custom_minimum_size = Vector2(0, 52)
		buy_btn.add_theme_font_size_override("font_size", 16)
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
		equip_btn.custom_minimum_size = Vector2(0, 44)
		equip_btn.add_theme_font_size_override("font_size", 16)
		if is_equipped:
			equip_btn.text = "장착 완료 (EQUIPPED)"
			equip_btn.disabled = true
			equip_btn.modulate = Color(0.3, 1.0, 0.6)
		else:
			equip_btn.text = "전투 장착 [%d]" % key_num
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
			up_btn.custom_minimum_size = Vector2(0, 36)
			up_btn.add_theme_font_size_override("font_size", 15)
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
			max_lbl.text = "최고 레벨 (MAX)"
			max_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			max_lbl.add_theme_font_size_override("font_size", 15)
			max_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			action_box.add_child(max_lbl)
			
	return panel
