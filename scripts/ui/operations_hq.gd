class_name OperationsHQ
extends Control

@onready var credits_label: Label = $Header/HBox/CreditsLabel
@onready var progress_bar: ProgressBar = $Header/HBox/VBox/ProgressRow/ProgressBar
@onready var progress_label: Label = $Header/HBox/VBox/ProgressRow/ProgressLabel

@onready var stage_container: VBoxContainer = $MainSplit/StageListPanel/VBox/Scroll/StageList
@onready var briefing_panel: PanelContainer = $MainSplit/BriefingPanel
@onready var briefing_title: Label = $MainSplit/BriefingPanel/VBox/TitleLabel
@onready var briefing_diff_label: Label = $MainSplit/BriefingPanel/VBox/DiffLabel
@onready var briefing_waves_label: Label = $MainSplit/BriefingPanel/VBox/WavesLabel
@onready var briefing_desc_label: Label = $MainSplit/BriefingPanel/VBox/DescLabel
@onready var briefing_threats_label: Label = $MainSplit/BriefingPanel/VBox/ThreatsLabel
@onready var briefing_reward_label: Label = $MainSplit/BriefingPanel/VBox/RewardLabel
@onready var deploy_button: Button = $MainSplit/BriefingPanel/VBox/DeployButton

@onready var close_briefing_btn: Button = get_node_or_null("MainSplit/BriefingPanel/VBox/TopBar/CloseBriefingBtn") as Button
@onready var open_briefing_btn: Button = get_node_or_null("MainSplit/MapArea/OpenBriefingBtn") as Button
@onready var prev_sector_btn: Button = get_node_or_null("MainSplit/BriefingPanel/VBox/NavRow/PrevSectorBtn") as Button
@onready var next_sector_btn: Button = get_node_or_null("MainSplit/BriefingPanel/VBox/NavRow/NextSectorBtn") as Button
@onready var pins_container: Control = get_node_or_null("MainSplit/MapArea/PinsContainer") as Control

@onready var shop_button: Button = $Footer/HBox/ShopButton
@onready var guide_button: Button = $Footer/HBox/GuideButton
@onready var settings_button: Button = $Footer/HBox/SettingsButton
@onready var title_button: Button = $Footer/HBox/TitleButton

@onready var armory_shop: ArmoryShop = $ArmoryShop
var guide_dialog: Panel:
	get: return get_node_or_null("GuideDialog") as Panel
var settings_dialog: Panel:
	get: return get_node_or_null("SettingsDialog") as Panel

var wave_plan_data: Dictionary = {}
var stages_data: Array = []
var selected_stage_id: int = 1
var stage_card_buttons: Dictionary = {}
var map_pin_nodes: Dictionary = {}
var map_pin_arrows: Dictionary = {}
var map_pin_buttons: Dictionary = {}
var anim_time: float = 0.0

const SECTOR_NAMES: Dictionary = {
	1: "SECTOR 01: 전초 경계선 (Alpha)",
	2: "SECTOR 02: 험준 협곡 통로 (Bravo)",
	3: "SECTOR 03: 외곽 보급로 (Charlie)",
	4: "SECTOR 04: 공업 폐허 지구 (Delta)",
	5: "SECTOR 05: 포격 초토화 지대 (Echo)",
	6: "SECTOR 06: 강변 야간 침투로 (Foxtrot)",
	7: "SECTOR 07: 철갑 전차 돌파선 (Golf)",
	8: "SECTOR 08: 중장갑 기계화 요새 (Hotel)",
	9: "SECTOR 09: 사령부 외곽 방벽 (India)",
	10: "SECTOR 10: 사령부 중앙 결전지 (Omega)"
}

const SECTOR_LOCATION_DESCS: Dictionary = {
	1: "동부 전선 14호 구역 (외곽 참호 지대)",
	2: "남부 전선 28호 구역 (협준 협곡 협착로)",
	3: "서부 보급 축선 07호 (전방 탄약 보급로)",
	4: "시가전 폐허 구역 (공업 단지 인근)",
	5: "중부 포격 지대 (파괴된 교량 전선)",
	6: "하천 야간 침투 축선 (도하 저지선)",
	7: "기갑 돌파 평원 (적 전차 주력 진격로)",
	8: "기계화 요새 지대 (전투로봇 집결지)",
	9: "사령부 1차 방벽 (고위험 합동 공세선)",
	10: "사령부 최후 방어선 (최종 결전 참호)"
}

# Downward-pointing arrow pin coordinates on the theater satellite map
const SECTOR_COORDINATES: Dictionary = {
	1: Vector2(640, 150),
	2: Vector2(520, 210),
	3: Vector2(390, 260),
	4: Vector2(720, 280),
	5: Vector2(590, 340),
	6: Vector2(260, 390),
	7: Vector2(410, 400),
	8: Vector2(680, 420),
	9: Vector2(310, 175),
	10: Vector2(480, 145)
}

func _ready() -> void:
	AudioManager.ensure_instance(self)
	_load_wave_plan()
	GameSession._ensure_profile_loaded()
	
	selected_stage_id = clampi(GameSession.selected_stage, 1, 10)
	if not GameSession.is_stage_unlocked(selected_stage_id):
		selected_stage_id = 1
		
	if deploy_button and not deploy_button.pressed.is_connected(_on_deploy_pressed):
		deploy_button.pressed.connect(_on_deploy_pressed)
	if shop_button and not shop_button.pressed.is_connected(_on_shop_pressed):
		shop_button.pressed.connect(_on_shop_pressed)
	if guide_button and not guide_button.pressed.is_connected(_on_guide_pressed):
		guide_button.pressed.connect(_on_guide_pressed)
	if settings_button and not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)
	if title_button and not title_button.pressed.is_connected(_on_title_pressed):
		title_button.pressed.connect(_on_title_pressed)
		
	if close_briefing_btn and not close_briefing_btn.pressed.is_connected(_on_close_briefing_pressed):
		close_briefing_btn.pressed.connect(_on_close_briefing_pressed)
	if open_briefing_btn and not open_briefing_btn.pressed.is_connected(_on_open_briefing_pressed):
		open_briefing_btn.pressed.connect(_on_open_briefing_pressed)
	if prev_sector_btn and not prev_sector_btn.pressed.is_connected(_on_prev_sector_pressed):
		prev_sector_btn.pressed.connect(_on_prev_sector_pressed)
	if next_sector_btn and not next_sector_btn.pressed.is_connected(_on_next_sector_pressed):
		next_sector_btn.pressed.connect(_on_next_sector_pressed)
		
	var close_guide := get_node_or_null("GuideDialog/VBox/CloseButton") as BaseButton
	if close_guide and not close_guide.pressed.is_connected(_on_guide_close_pressed):
		close_guide.pressed.connect(_on_guide_close_pressed)
	var close_settings := get_node_or_null("SettingsDialog/VBox/CloseSettingsBtn") as BaseButton
	if close_settings and not close_settings.pressed.is_connected(_on_settings_close_pressed):
		close_settings.pressed.connect(_on_settings_close_pressed)
		
	if armory_shop and not armory_shop.closed.is_connected(refresh_hq_ui):
		armory_shop.closed.connect(refresh_hq_ui)
		
	_build_stage_cards()
	_build_map_pins()
	refresh_hq_ui()

func _process(delta: float) -> void:
	anim_time += delta
	for st_id in map_pin_arrows.keys():
		var arrow: TextureRect = map_pin_arrows[st_id]
		if arrow and is_instance_valid(arrow):
			if st_id == selected_stage_id:
				arrow.position.y = sin(anim_time * 6.0) * 4.0
			else:
				arrow.position.y = 0.0

func _load_wave_plan() -> void:
	var path := "res://data/wave_plan.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		wave_plan_data = parsed
		stages_data = wave_plan_data.get("stages", [])

func get_stage_info(st_id: int) -> Dictionary:
	for st in stages_data:
		if int(st.get("stage_id", 0)) == st_id:
			return st
	return {}

func _build_map_pins() -> void:
	if not pins_container:
		return
	for c in pins_container.get_children():
		c.queue_free()
	map_pin_nodes.clear()
	map_pin_arrows.clear()
	map_pin_buttons.clear()
	
	var arrow_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/ui/pin_arrow_down.png"):
		arrow_tex = load("res://assets/ui/pin_arrow_down.png") as Texture2D
	
	for i in range(1, 6):
		var st_id := i
		var pin_root := Control.new()
		pin_root.name = "SectorPin_%d" % st_id
		pin_root.custom_minimum_size = Vector2(160, 84)
		var coord: Vector2 = SECTOR_COORDINATES.get(st_id, Vector2(400, 250))
		pin_root.position = coord - Vector2(80, 84)
		
		var vbox := VBoxContainer.new()
		vbox.custom_minimum_size = Vector2(160, 84)
		vbox.add_theme_constant_override("separation", 2)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Badge Button
		var btn := Button.new()
		btn.name = "PinBtn"
		btn.custom_minimum_size = Vector2(150, 48)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.add_theme_font_size_override("font_size", 12)
		
		var on_pin_click = func():
			_on_pin_selected(st_id)
		btn.pressed.connect(on_pin_click)
		
		# Downward Arrow Box
		var arrow_box := Control.new()
		arrow_box.custom_minimum_size = Vector2(160, 32)
		var arrow_rect := TextureRect.new()
		arrow_rect.name = "Arrow"
		arrow_rect.texture = arrow_tex
		arrow_rect.custom_minimum_size = Vector2(30, 30)
		arrow_rect.size = Vector2(30, 30)
		arrow_rect.position = Vector2(65, 0)
		arrow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arrow_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		arrow_rect.mouse_filter = Control.MOUSE_FILTER_PASS
		arrow_box.add_child(arrow_rect)
		
		vbox.add_child(btn)
		vbox.add_child(arrow_box)
		pin_root.add_child(vbox)
		pins_container.add_child(pin_root)
		
		map_pin_nodes[st_id] = pin_root
		map_pin_arrows[st_id] = arrow_rect
		map_pin_buttons[st_id] = btn

func _on_pin_selected(st_id: int) -> void:
	if not GameSession.is_stage_unlocked(st_id):
		AudioManager.play_sound("click", 0.05, -4.0)
		return
	AudioManager.play_sound("click")
	selected_stage_id = st_id
	GameSession.select_stage(st_id)
	show_floating_briefing(true)
	refresh_hq_ui()

func show_floating_briefing(p_visible: bool) -> void:
	if briefing_panel:
		briefing_panel.visible = p_visible
	if open_briefing_btn:
		open_briefing_btn.visible = not p_visible

func _on_close_briefing_pressed() -> void:
	AudioManager.play_sound("click")
	show_floating_briefing(false)

func _on_open_briefing_pressed() -> void:
	AudioManager.play_sound("click")
	show_floating_briefing(true)

func _on_prev_sector_pressed() -> void:
	var prev_id := selected_stage_id - 1
	if prev_id < 1: prev_id = 10
	while prev_id != selected_stage_id:
		if GameSession.is_stage_unlocked(prev_id):
			_on_pin_selected(prev_id)
			break
		prev_id -= 1
		if prev_id < 1: prev_id = 10

func _on_next_sector_pressed() -> void:
	var next_id := selected_stage_id + 1
	if next_id > 10: next_id = 1
	while next_id != selected_stage_id:
		if GameSession.is_stage_unlocked(next_id):
			_on_pin_selected(next_id)
			break
		next_id += 1
		if next_id > 10: next_id = 1

func _build_stage_cards() -> void:
	if not stage_container:
		return
	for c in stage_container.get_children():
		c.queue_free()
	stage_card_buttons.clear()
	
	for i in range(1, 11):
		var st_id := i
		var st_info := get_stage_info(st_id)
		var st_name: String = st_info.get("stage_name", "제%d작전" % st_id)
		var st_diff: String = st_info.get("difficulty", "보통")
		
		var card := Button.new()
		card.custom_minimum_size = Vector2(0, 72)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.add_theme_font_size_override("font_size", 14)
		
		var do_select = func():
			if GameSession.is_stage_unlocked(st_id):
				AudioManager.play_sound("click")
				selected_stage_id = st_id
				GameSession.select_stage(st_id)
				show_floating_briefing(true)
				refresh_hq_ui()
			else:
				AudioManager.play_sound("click", 0.05, -4.0)
				
		card.pressed.connect(do_select)
		stage_card_buttons[st_id] = card
		stage_container.add_child(card)

func refresh_hq_ui() -> void:
	GameSession._ensure_profile_loaded()
	
	# Update Credits & Campaign Progress
	if credits_label:
		credits_label.text = "보유 전공 점수: %s P" % str(GameSession.credits)
		
	var cleared_count: int = 0
	for i in range(1, 11):
		if GameSession.is_stage_cleared(i):
			cleared_count += 1
			
	if progress_bar:
		progress_bar.max_value = 10
		progress_bar.value = cleared_count
	if progress_label:
		var pct := cleared_count * 10
		progress_label.text = "작전 총괄 진행도: %d / 10 개 구역 완수 (%d%%)" % [cleared_count, pct]
		
	# Refresh Stage Cards
	for st_id in range(1, 11):
		if not stage_card_buttons.has(st_id):
			continue
		var card: Button = stage_card_buttons[st_id]
		var st_info := get_stage_info(st_id)
		var st_name: String = st_info.get("stage_name", "제%d작전" % st_id)
		var st_diff: String = st_info.get("difficulty", "보통")
		
		var is_unlocked := GameSession.is_stage_unlocked(st_id)
		var is_cleared := GameSession.is_stage_cleared(st_id)
		var is_selected := (st_id == selected_stage_id)
		
		var status_str := "[잠김]"
		if is_cleared:
			status_str = "[작전 완수]"
		elif is_unlocked:
			status_str = "[작전 가능]"
			
		var select_marker := " >> 선택됨 <<" if is_selected else ""
		var sector_short: String = SECTOR_NAMES.get(st_id, "SECTOR %02d" % st_id)
		card.text = " [%d] %s%s\n  %s | %s | 상태: %s" % [
			st_id, st_name, select_marker, sector_short, st_diff, status_str
		]
		
		card.disabled = not is_unlocked
		if is_selected:
			card.modulate = Color(0.3, 1.0, 0.7)
		elif is_cleared:
			card.modulate = Color(0.4, 0.9, 1.0)
		elif is_unlocked:
			card.modulate = Color(1.0, 0.9, 0.4)
		else:
			card.modulate = Color(0.5, 0.5, 0.5)
			
	# Refresh Map Pins (Downward Arrow Markers on Satellite Map)
	for st_id in range(1, 11):
		if not map_pin_buttons.has(st_id):
			continue
		var p_btn: Button = map_pin_buttons[st_id]
		var arrow: TextureRect = map_pin_arrows.get(st_id)
		var is_unlocked := GameSession.is_stage_unlocked(st_id)
		var is_cleared := GameSession.is_stage_cleared(st_id)
		var is_selected := (st_id == selected_stage_id)
		
		var status_str := "[잠김]"
		if is_cleared:
			status_str = "[완수]"
		elif is_unlocked:
			status_str = "[출격 가능]"
			
		var sector_full: String = SECTOR_NAMES.get(st_id, "SECTOR %02d" % st_id)
		var sector_parts := sector_full.split(":")
		var sector_name_part := sector_parts[1].strip_edges() if sector_parts.size() > 1 else sector_full
		p_btn.text = "SECTOR %02d %s\n%s" % [st_id, status_str, sector_name_part]
		p_btn.disabled = not is_unlocked
		
		var pin_col := Color(0.5, 0.5, 0.5)
		if is_selected:
			pin_col = Color(0.2, 1.0, 0.6)
		elif is_cleared:
			pin_col = Color(0.4, 0.9, 1.0)
		elif is_unlocked:
			pin_col = Color(1.0, 0.88, 0.3)
			
		p_btn.modulate = pin_col
		if arrow:
			arrow.modulate = pin_col
			
	# Refresh Selected Stage Briefing in Floating Box
	var cur_st := get_stage_info(selected_stage_id)
	var sector_tag: String = SECTOR_NAMES.get(selected_stage_id, "SECTOR %02d" % selected_stage_id)
	var sector_loc: String = SECTOR_LOCATION_DESCS.get(selected_stage_id, "러우전 최전방 작전 구역")
	if briefing_title:
		briefing_title.text = "[전투상황 브리핑] %s" % cur_st.get("stage_name", "제%d작전" % selected_stage_id)
	if briefing_diff_label:
		briefing_diff_label.text = "위험 등급: %s  |  %s" % [cur_st.get("difficulty", "보통"), sector_tag]
	if briefing_waves_label:
		briefing_waves_label.text = "위성 작전 좌표: %s (10 웨이브)" % sector_loc
	if briefing_desc_label:
		briefing_desc_label.text = "작전 목표:\n%s" % cur_st.get("briefing", "적 침투를 저지하고 최후의 참호를 사수하십시오.")
	if briefing_threats_label:
		briefing_threats_label.text = "식별 적 병력: %s" % cur_st.get("expected_enemies", "적 보병 및 무인 드론 편대")
	if briefing_reward_label:
		briefing_reward_label.text = "완수 보상: 전공 점수 +%d P 지급" % int(cur_st.get("reward_credits", 1500))
		
	if deploy_button:
		deploy_button.text = "[%s 출격 (START OPERATION)]" % sector_tag
		deploy_button.disabled = not GameSession.is_stage_unlocked(selected_stage_id)

func _on_deploy_pressed() -> void:
	if not GameSession.is_stage_unlocked(selected_stage_id):
		return
	AudioManager.play_sound("click")
	GameSession.select_stage(selected_stage_id)
	get_tree().change_scene_to_file("res://scenes/app/game_root.tscn")

func _on_shop_pressed() -> void:
	AudioManager.play_sound("click")
	if guide_dialog: guide_dialog.visible = false
	if settings_dialog: settings_dialog.visible = false
	if armory_shop: armory_shop.open_shop()

func _on_guide_pressed() -> void:
	AudioManager.play_sound("click")
	if guide_dialog: guide_dialog.visible = true
	if settings_dialog: settings_dialog.visible = false
	if armory_shop: armory_shop.close_shop()

func _on_guide_close_pressed() -> void:
	AudioManager.play_sound("click")
	if guide_dialog: guide_dialog.visible = false

func _on_settings_pressed() -> void:
	AudioManager.play_sound("click")
	if settings_dialog: settings_dialog.visible = true
	if guide_dialog: guide_dialog.visible = false
	if armory_shop: armory_shop.close_shop()

func _on_settings_close_pressed() -> void:
	AudioManager.play_sound("click")
	if settings_dialog: settings_dialog.visible = false

func _on_title_pressed() -> void:
	AudioManager.play_sound("click")
	get_tree().change_scene_to_file("res://scenes/app/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if armory_shop and armory_shop.visible:
			return
		if guide_dialog and guide_dialog.visible:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_G:
				_on_guide_close_pressed()
				_consume_input()
			return
		if settings_dialog and settings_dialog.visible:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_I:
				_on_settings_close_pressed()
				_consume_input()
			return
			
		if event.keycode >= KEY_1 and event.keycode <= KEY_5:
			var target_id: int = int(event.keycode - KEY_1 + 1)
			if GameSession.is_stage_unlocked(target_id):
				AudioManager.play_sound("click")
				selected_stage_id = target_id
				GameSession.select_stage(target_id)
				show_floating_briefing(true)
				refresh_hq_ui()
				_consume_input()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_on_deploy_pressed()
			_consume_input()
		elif event.keycode == KEY_S or event.keycode == KEY_B:
			_on_shop_pressed()
			_consume_input()
		elif event.keycode == KEY_G or event.keycode == KEY_C:
			_on_guide_pressed()
			_consume_input()
		elif event.keycode == KEY_I or event.keycode == KEY_O:
			_on_settings_pressed()
			_consume_input()
		elif event.keycode == KEY_ESCAPE or event.keycode == KEY_X:
			if briefing_panel and briefing_panel.visible:
				_on_close_briefing_pressed()
				_consume_input()
			else:
				_on_title_pressed()
				_consume_input()

func _consume_input() -> void:
	var vp := get_viewport()
	if vp:
		vp.set_input_as_handled()
