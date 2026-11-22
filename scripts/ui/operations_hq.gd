class_name OperationsHQ
extends Control

@onready var credits_label: Label = $Header/HBox/CreditsLabel
@onready var progress_bar: ProgressBar = $Header/HBox/VBox/ProgressRow/ProgressBar
@onready var progress_label: Label = $Header/HBox/VBox/ProgressRow/ProgressLabel

@onready var stage_container: VBoxContainer = $MainSplit/StageListPanel/VBox/Scroll/StageList
@onready var briefing_title: Label = $MainSplit/BriefingPanel/VBox/TitleLabel
@onready var briefing_diff_label: Label = $MainSplit/BriefingPanel/VBox/DiffLabel
@onready var briefing_waves_label: Label = $MainSplit/BriefingPanel/VBox/WavesLabel
@onready var briefing_desc_label: Label = $MainSplit/BriefingPanel/VBox/DescLabel
@onready var briefing_threats_label: Label = $MainSplit/BriefingPanel/VBox/ThreatsLabel
@onready var briefing_reward_label: Label = $MainSplit/BriefingPanel/VBox/RewardLabel
@onready var deploy_button: Button = $MainSplit/BriefingPanel/VBox/DeployButton

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

func _ready() -> void:
	AudioManager.ensure_instance(self)
	_load_wave_plan()
	GameSession._ensure_profile_loaded()
	
	selected_stage_id = clampi(GameSession.selected_stage, 1, 5)
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
		
	var close_guide := get_node_or_null("GuideDialog/VBox/CloseButton") as BaseButton
	if close_guide and not close_guide.pressed.is_connected(_on_guide_close_pressed):
		close_guide.pressed.connect(_on_guide_close_pressed)
	var close_settings := get_node_or_null("SettingsDialog/VBox/CloseSettingsBtn") as BaseButton
	if close_settings and not close_settings.pressed.is_connected(_on_settings_close_pressed):
		close_settings.pressed.connect(_on_settings_close_pressed)
		
	if armory_shop and not armory_shop.closed.is_connected(refresh_hq_ui):
		armory_shop.closed.connect(refresh_hq_ui)
		
	_build_stage_cards()
	refresh_hq_ui()

const SECTOR_NAMES: Dictionary = {
	1: "SECTOR 01: 전초 경계선 (Alpha)",
	2: "SECTOR 02: 험준 협곡 통로 (Bravo)",
	3: "SECTOR 03: 도심 폐허 지구 (Charlie)",
	4: "SECTOR 04: 야간 기습 구역 (Delta)",
	5: "SECTOR 05: 사령부 중앙 결전지 (Omega)"
}

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

func _build_stage_cards() -> void:
	if not stage_container:
		return
	for c in stage_container.get_children():
		c.queue_free()
	stage_card_buttons.clear()
	
	for i in range(1, 6):
		var st_id := i
		var st_info := get_stage_info(st_id)
		var st_name: String = st_info.get("stage_name", "제%d작전" % st_id)
		var st_diff: String = st_info.get("difficulty", "보통")
		
		var card := Button.new()
		card.custom_minimum_size = Vector2(0, 88)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.add_theme_font_size_override("font_size", 15)
		
		var do_select = func():
			if GameSession.is_stage_unlocked(st_id):
				AudioManager.play_sound("click")
				selected_stage_id = st_id
				GameSession.select_stage(st_id)
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
	for i in range(1, 6):
		if GameSession.is_stage_cleared(i):
			cleared_count += 1
			
	if progress_bar:
		progress_bar.max_value = 5
		progress_bar.value = cleared_count
	if progress_label:
		var pct := cleared_count * 20
		progress_label.text = "작전 총괄 진행도: %d / 5 개 구역 완수 (%d%%)" % [cleared_count, pct]
		
	# Refresh Stage Cards
	for st_id in range(1, 6):
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
		card.text = " [%d] %s%s\n  난이도: %s | 10웨이브 | 상태: %s" % [
			st_id, st_name, select_marker, st_diff, status_str
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
			
	# Refresh Selected Stage Briefing
	var cur_st := get_stage_info(selected_stage_id)
	var sector_tag: String = SECTOR_NAMES.get(selected_stage_id, "SECTOR %02d" % selected_stage_id)
	if briefing_title:
		briefing_title.text = "[작전 브리핑] %s" % cur_st.get("stage_name", "제%d작전" % selected_stage_id)
	if briefing_diff_label:
		briefing_diff_label.text = "위험 등급: %s  |  %s" % [cur_st.get("difficulty", "보통"), sector_tag]
	if briefing_waves_label:
		briefing_waves_label.text = "작전 규모: 10개 연속 제파 웨이브 (Wave 1 ~ 10)"
	if briefing_desc_label:
		briefing_desc_label.text = "작전 요도 목표:\n%s" % cur_st.get("briefing", "적 침투를 저지하고 최후의 참호를 사수하십시오.")
	if briefing_threats_label:
		briefing_threats_label.text = "예상 적 병력: %s" % cur_st.get("expected_enemies", "적 보병 및 무인 드론 편대")
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
			_on_title_pressed()
			_consume_input()

func _consume_input() -> void:
	var vp := get_viewport()
	if vp:
		vp.set_input_as_handled()
