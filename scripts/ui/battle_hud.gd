class_name BattleHUD
extends CanvasLayer

signal restart_requested()
signal menu_requested()
signal modal_visibility_changed(is_open: bool)
signal weapon_changed(weapon_id: String)

var _player_hp_bar: Range
var player_hp_bar: Range:
	get:
		if not _player_hp_bar: _player_hp_bar = get_node_or_null("TopLeft/VBox/PlayerHPBar")
		return _player_hp_bar

var _player_hp_label: Label
var player_hp_label: Label:
	get:
		if not _player_hp_label: _player_hp_label = get_node_or_null("TopLeft/VBox/PlayerHPBar/Label")
		return _player_hp_label

var _revives_label: Label
var revives_label: Label:
	get:
		if not _revives_label: _revives_label = get_node_or_null("TopLeft/VBox/RevivesLabel")
		return _revives_label

var _base_hp_bar: Range
var base_hp_bar: Range:
	get:
		if not _base_hp_bar: _base_hp_bar = get_node_or_null("TopLeft/VBox/BaseHPBar")
		return _base_hp_bar

var _base_hp_label: Label
var base_hp_label: Label:
	get:
		if not _base_hp_label: _base_hp_label = get_node_or_null("TopLeft/VBox/BaseHPBar/Label")
		return _base_hp_label

var _wave_title_label: Label
var wave_title_label: Label:
	get:
		if not _wave_title_label:
			_wave_title_label = get_node_or_null("TopRightTactical/VBox/WaveTitleLabel")
			if not _wave_title_label: _wave_title_label = get_node_or_null("TopCenter/VBox/WaveTitleLabel")
		return _wave_title_label

var _wave_info_label: Label
var wave_info_label: Label:
	get:
		if not _wave_info_label:
			_wave_info_label = get_node_or_null("TopRightTactical/VBox/WaveInfoLabel")
			if not _wave_info_label: _wave_info_label = get_node_or_null("TopCenter/VBox/WaveInfoLabel")
		return _wave_info_label

var _credits_label: Label
var credits_label: Label:
	get:
		if not _credits_label: _credits_label = get_node_or_null("TopRightTactical/VBox/CreditsLabel")
		return _credits_label

var _level_title_label: Label
var level_title_label: Label:
	get:
		if not _level_title_label: _level_title_label = get_node_or_null("TopRightTactical/VBox/LevelTitle")
		return _level_title_label

var _ammo_label: Label
var ammo_label: Label:
	get:
		if not _ammo_label: _ammo_label = get_node_or_null("BottomRight/VBox/AmmoLabel")
		return _ammo_label

var _ammo_bar: Range
var ammo_bar: Range:
	get:
		if not _ammo_bar: _ammo_bar = get_node_or_null("BottomRight/VBox/AmmoBar")
		return _ammo_bar

var _defense_bar: Range
var defense_bar: Range:
	get:
		if not _defense_bar: _defense_bar = get_node_or_null("TopRightTactical/VBox/ProgressRow/DefenseBar")
		return _defense_bar

var _reload_label: Label
var reload_label: Label:
	get:
		if not _reload_label: _reload_label = get_node_or_null("BottomRight/VBox/ReloadLabel")
		return _reload_label

var _help_label: Label
var help_label: Label:
	get:
		if not _help_label: _help_label = get_node_or_null("BottomCenter/HelpLabel")
		return _help_label

var _crosshair_dot: Control
var crosshair_dot: Control:
	get:
		if not _crosshair_dot: _crosshair_dot = get_node_or_null("Center/Crosshair/Dot")
		return _crosshair_dot

var _crosshair_ring: Control
var crosshair_ring: Control:
	get:
		if not _crosshair_ring: _crosshair_ring = get_node_or_null("Center/Crosshair/Ring")
		return _crosshair_ring

var _boss_container: Control
var boss_container: Control:
	get:
		if not _boss_container: _boss_container = get_node_or_null("TopCenter/BossContainer")
		return _boss_container

var _boss_name_label: Label
var boss_name_label: Label:
	get:
		if not _boss_name_label: _boss_name_label = get_node_or_null("TopCenter/BossContainer/BossNameLabel")
		return _boss_name_label

var _boss_hp_bar: Range
var boss_hp_bar: Range:
	get:
		if not _boss_hp_bar: _boss_hp_bar = get_node_or_null("TopCenter/BossContainer/BossHPBar")
		return _boss_hp_bar

var _boss_hp_label: Label
var boss_hp_label: Label:
	get:
		if not _boss_hp_label: _boss_hp_label = get_node_or_null("TopCenter/BossContainer/BossHPLabel")
		return _boss_hp_label

var _tactical_alert_banner: Control
var tactical_alert_banner: Control:
	get:
		if not _tactical_alert_banner: _tactical_alert_banner = get_node_or_null("TopCenter/TacticalAlertBanner")
		return _tactical_alert_banner

var _tactical_alert_label: Label
var tactical_alert_label: Label:
	get:
		if not _tactical_alert_label: _tactical_alert_label = get_node_or_null("TopCenter/TacticalAlertBanner/AlertLabel")
		return _tactical_alert_label

var _victory_panel: Control
var victory_panel: Control:
	get:
		if not _victory_panel: _victory_panel = get_node_or_null("Overlay/VictoryPanel")
		return _victory_panel

var _defeat_panel: Control
var defeat_panel: Control:
	get:
		if not _defeat_panel: _defeat_panel = get_node_or_null("Overlay/DefeatPanel")
		return _defeat_panel

var _defeat_reason_label: Label
var defeat_reason_label: Label:
	get:
		if not _defeat_reason_label: _defeat_reason_label = get_node_or_null("Overlay/DefeatPanel/VBox/Reason")
		return _defeat_reason_label

var _victory_restart_btn: BaseButton
var victory_restart_btn: BaseButton:
	get:
		if not _victory_restart_btn: _victory_restart_btn = get_node_or_null("Overlay/VictoryPanel/VBox/HBox/RestartBtn")
		return _victory_restart_btn

var _victory_menu_btn: BaseButton
var victory_menu_btn: BaseButton:
	get:
		if not _victory_menu_btn: _victory_menu_btn = get_node_or_null("Overlay/VictoryPanel/VBox/HBox/MenuBtn")
		return _victory_menu_btn

var _defeat_restart_btn: BaseButton
var defeat_restart_btn: BaseButton:
	get:
		if not _defeat_restart_btn: _defeat_restart_btn = get_node_or_null("Overlay/DefeatPanel/VBox/HBox/RestartBtn")
		return _defeat_restart_btn

var _defeat_menu_btn: BaseButton
var defeat_menu_btn: BaseButton:
	get:
		if not _defeat_menu_btn: _defeat_menu_btn = get_node_or_null("Overlay/DefeatPanel/VBox/HBox/MenuBtn")
		return _defeat_menu_btn

var _shop_btn: BaseButton
var shop_btn: BaseButton:
	get:
		if not _shop_btn:
			_shop_btn = get_node_or_null("TopRightTactical/VBox/ActionRow/ShopBtn")
			if not _shop_btn: _shop_btn = get_node_or_null("TopButtons/ShopBtn")
		return _shop_btn

var _settings_btn: BaseButton
var settings_btn: BaseButton:
	get:
		if not _settings_btn:
			_settings_btn = get_node_or_null("TopRightTactical/VBox/ActionRow/SettingsBtn")
			if not _settings_btn: _settings_btn = get_node_or_null("TopButtons/SettingsBtn")
			if not _settings_btn: _settings_btn = get_node_or_null("SettingsBtn")
		return _settings_btn

var _settings_layer: CanvasLayer
var settings_layer: CanvasLayer:
	get:
		if not _settings_layer: _settings_layer = get_node_or_null("SettingsLayer")
		return _settings_layer

var _settings_dialog: Control
var settings_dialog: Control:
	get:
		if not _settings_dialog:
			_settings_dialog = get_node_or_null("SettingsLayer/SettingsDialog")
			if not _settings_dialog: _settings_dialog = get_node_or_null("Overlay/SettingsDialog")
		return _settings_dialog

var _armory_shop: ArmoryShop
var armory_shop: ArmoryShop:
	get:
		if not _armory_shop: _armory_shop = get_node_or_null("ArmoryShop")
		return _armory_shop

var _sensitivity_slider: Slider
var sensitivity_slider: Slider:
	get:
		if not _sensitivity_slider:
			_sensitivity_slider = get_node_or_null("SettingsLayer/SettingsDialog/VBox/SensitivityRow/SensitivitySlider")
			if not _sensitivity_slider: _sensitivity_slider = get_node_or_null("SettingsLayer/SettingsDialog/VBox/SensitivitySlider")
			if not _sensitivity_slider: _sensitivity_slider = get_node_or_null("Overlay/SettingsDialog/VBox/SensitivitySlider")
		return _sensitivity_slider

var _sensitivity_title: Label
var sensitivity_title: Label:
	get:
		if not _sensitivity_title:
			_sensitivity_title = get_node_or_null("SettingsLayer/SettingsDialog/VBox/SensitivityTitle")
			if not _sensitivity_title: _sensitivity_title = get_node_or_null("Overlay/SettingsDialog/VBox/SensitivityTitle")
		return _sensitivity_title

var _sensitivity_dec_btn: BaseButton
var sensitivity_dec_btn: BaseButton:
	get:
		if not _sensitivity_dec_btn: _sensitivity_dec_btn = get_node_or_null("SettingsLayer/SettingsDialog/VBox/SensitivityRow/SensitivityDecBtn")
		return _sensitivity_dec_btn

var _sensitivity_inc_btn: BaseButton
var sensitivity_inc_btn: BaseButton:
	get:
		if not _sensitivity_inc_btn: _sensitivity_inc_btn = get_node_or_null("SettingsLayer/SettingsDialog/VBox/SensitivityRow/SensitivityIncBtn")
		return _sensitivity_inc_btn

var _master_vol_slider: Slider
var master_vol_slider: Slider:
	get:
		if not _master_vol_slider:
			_master_vol_slider = get_node_or_null("SettingsLayer/SettingsDialog/VBox/MasterVolRow/MasterVolSlider")
			if not _master_vol_slider: _master_vol_slider = get_node_or_null("SettingsLayer/SettingsDialog/VBox/MasterVolSlider")
		return _master_vol_slider

var _master_vol_title: Label
var master_vol_title: Label:
	get:
		if not _master_vol_title: _master_vol_title = get_node_or_null("SettingsLayer/SettingsDialog/VBox/MasterVolTitle")
		return _master_vol_title

var _master_vol_dec_btn: BaseButton
var master_vol_dec_btn: BaseButton:
	get:
		if not _master_vol_dec_btn: _master_vol_dec_btn = get_node_or_null("SettingsLayer/SettingsDialog/VBox/MasterVolRow/MasterVolDecBtn")
		return _master_vol_dec_btn

var _master_vol_inc_btn: BaseButton
var master_vol_inc_btn: BaseButton:
	get:
		if not _master_vol_inc_btn: _master_vol_inc_btn = get_node_or_null("SettingsLayer/SettingsDialog/VBox/MasterVolRow/MasterVolIncBtn")
		return _master_vol_inc_btn

var _bgm_vol_slider: Slider
var bgm_vol_slider: Slider:
	get:
		if not _bgm_vol_slider:
			_bgm_vol_slider = get_node_or_null("SettingsLayer/SettingsDialog/VBox/BGMVolRow/BGMVolSlider")
			if not _bgm_vol_slider: _bgm_vol_slider = get_node_or_null("SettingsLayer/SettingsDialog/VBox/BGMVolSlider")
		return _bgm_vol_slider

var _bgm_vol_title: Label
var bgm_vol_title: Label:
	get:
		if not _bgm_vol_title: _bgm_vol_title = get_node_or_null("SettingsLayer/SettingsDialog/VBox/BGMVolTitle")
		return _bgm_vol_title

var _bgm_vol_dec_btn: BaseButton
var bgm_vol_dec_btn: BaseButton:
	get:
		if not _bgm_vol_dec_btn: _bgm_vol_dec_btn = get_node_or_null("SettingsLayer/SettingsDialog/VBox/BGMVolRow/BGMVolDecBtn")
		return _bgm_vol_dec_btn

var _bgm_vol_inc_btn: BaseButton
var bgm_vol_inc_btn: BaseButton:
	get:
		if not _bgm_vol_inc_btn: _bgm_vol_inc_btn = get_node_or_null("SettingsLayer/SettingsDialog/VBox/BGMVolRow/BGMVolIncBtn")
		return _bgm_vol_inc_btn

var _sfx_vol_slider: Slider
var sfx_vol_slider: Slider:
	get:
		if not _sfx_vol_slider:
			_sfx_vol_slider = get_node_or_null("SettingsLayer/SettingsDialog/VBox/SFXVolRow/SFXVolSlider")
			if not _sfx_vol_slider: _sfx_vol_slider = get_node_or_null("SettingsLayer/SettingsDialog/VBox/SFXVolSlider")
		return _sfx_vol_slider

var _sfx_vol_title: Label
var sfx_vol_title: Label:
	get:
		if not _sfx_vol_title: _sfx_vol_title = get_node_or_null("SettingsLayer/SettingsDialog/VBox/SFXVolTitle")
		return _sfx_vol_title

var _sfx_vol_dec_btn: BaseButton
var sfx_vol_dec_btn: BaseButton:
	get:
		if not _sfx_vol_dec_btn: _sfx_vol_dec_btn = get_node_or_null("SettingsLayer/SettingsDialog/VBox/SFXVolRow/SFXVolDecBtn")
		return _sfx_vol_dec_btn

var _sfx_vol_inc_btn: BaseButton
var sfx_vol_inc_btn: BaseButton:
	get:
		if not _sfx_vol_inc_btn: _sfx_vol_inc_btn = get_node_or_null("SettingsLayer/SettingsDialog/VBox/SFXVolRow/SFXVolIncBtn")
		return _sfx_vol_inc_btn

var _fullscreen_btn: BaseButton
var fullscreen_btn: BaseButton:
	get:
		if not _fullscreen_btn:
			_fullscreen_btn = get_node_or_null("SettingsLayer/SettingsDialog/VBox/FullscreenBtn")
			if not _fullscreen_btn: _fullscreen_btn = get_node_or_null("Overlay/SettingsDialog/VBox/FullscreenBtn")
		return _fullscreen_btn

var _close_settings_btn: BaseButton
var close_settings_btn: BaseButton:
	get:
		if not _close_settings_btn:
			_close_settings_btn = get_node_or_null("SettingsLayer/SettingsDialog/VBox/CloseSettingsBtn")
			if not _close_settings_btn: _close_settings_btn = get_node_or_null("Overlay/SettingsDialog/VBox/CloseSettingsBtn")
		return _close_settings_btn

var _viewmodel: FPSViewModel
var viewmodel: FPSViewModel:
	get:
		if not _viewmodel: _viewmodel = get_node_or_null("FPSViewModel")
		return _viewmodel

func _ready() -> void:
	if victory_panel: victory_panel.visible = false
	if defeat_panel: defeat_panel.visible = false
	if reload_label: reload_label.visible = false
	if settings_layer: settings_layer.visible = false
	if armory_shop: armory_shop.visible = false
	if viewmodel:
		viewmodel.visible = true
		_update_viewmodel_texture(GameSession.equipped_weapon_id)
		
	if OS.has_feature("mobile") and help_label:
		help_label.visible = false
	
	if victory_restart_btn and not victory_restart_btn.pressed.is_connected(_on_restart_clicked):
		victory_restart_btn.pressed.connect(_on_restart_clicked)
	if victory_menu_btn and not victory_menu_btn.pressed.is_connected(_on_menu_clicked):
		victory_menu_btn.pressed.connect(_on_menu_clicked)
	if defeat_restart_btn and not defeat_restart_btn.pressed.is_connected(_on_restart_clicked):
		defeat_restart_btn.pressed.connect(_on_restart_clicked)
	if defeat_menu_btn and not defeat_menu_btn.pressed.is_connected(_on_menu_clicked):
		defeat_menu_btn.pressed.connect(_on_menu_clicked)
	
	if shop_btn and not shop_btn.pressed.is_connected(_on_shop_pressed):
		shop_btn.pressed.connect(_on_shop_pressed)
	if settings_btn and not settings_btn.pressed.is_connected(_on_settings_pressed):
		settings_btn.pressed.connect(_on_settings_pressed)
	if close_settings_btn and not close_settings_btn.pressed.is_connected(_on_settings_close_pressed):
		close_settings_btn.pressed.connect(_on_settings_close_pressed)
	if fullscreen_btn and not fullscreen_btn.pressed.is_connected(_on_fullscreen_pressed):
		fullscreen_btn.pressed.connect(_on_fullscreen_pressed)
	
	if armory_shop:
		if not armory_shop.weapon_equipped.is_connected(_on_weapon_equipped_from_shop):
			armory_shop.weapon_equipped.connect(_on_weapon_equipped_from_shop)
		if not armory_shop.closed.is_connected(_on_modal_closed):
			armory_shop.closed.connect(_on_modal_closed)
	
	_init_settings_ui()
	update_credits(GameSession.credits)

func _on_restart_clicked() -> void:
	AudioManager.play_sound("click")
	restart_requested.emit()

func _on_menu_clicked() -> void:
	AudioManager.play_sound("click")
	menu_requested.emit()

func _on_fullscreen_pressed() -> void:
	AudioManager.play_sound("click")
	GameSettings.toggle_fullscreen()

func _sync_settings_from_game_settings() -> void:
	if sensitivity_slider:
		sensitivity_slider.value = GameSettings.get_aim_sensitivity()
		_update_sensitivity_label(sensitivity_slider.value)
	if master_vol_slider:
		master_vol_slider.value = GameSettings.get_master_volume()
		_update_master_vol_label(master_vol_slider.value)
	if bgm_vol_slider:
		bgm_vol_slider.value = GameSettings.get_bgm_volume()
		_update_bgm_vol_label(bgm_vol_slider.value)
	if sfx_vol_slider:
		sfx_vol_slider.value = GameSettings.get_sfx_volume()
		_update_sfx_vol_label(sfx_vol_slider.value)

func _step_sensitivity(step: float) -> void:
	if sensitivity_slider:
		var new_val := clampf(sensitivity_slider.value + step, sensitivity_slider.min_value, sensitivity_slider.max_value)
		sensitivity_slider.value = new_val
		GameSettings.set_aim_sensitivity(new_val)
		_update_sensitivity_label(new_val)
		AudioManager.play_sound("click")

func _step_master_vol(step: float) -> void:
	if master_vol_slider:
		var new_val := clampf(master_vol_slider.value + step, master_vol_slider.min_value, master_vol_slider.max_value)
		master_vol_slider.value = new_val
		GameSettings.set_master_volume(new_val)
		_update_master_vol_label(new_val)
		AudioManager.play_sound("click")

func _step_bgm_vol(step: float) -> void:
	if bgm_vol_slider:
		var new_val := clampf(bgm_vol_slider.value + step, bgm_vol_slider.min_value, bgm_vol_slider.max_value)
		bgm_vol_slider.value = new_val
		GameSettings.set_bgm_volume(new_val)
		_update_bgm_vol_label(new_val)
		AudioManager.play_sound("click")

func _step_sfx_vol(step: float) -> void:
	if sfx_vol_slider:
		var new_val := clampf(sfx_vol_slider.value + step, sfx_vol_slider.min_value, sfx_vol_slider.max_value)
		sfx_vol_slider.value = new_val
		GameSettings.set_sfx_volume(new_val)
		_update_sfx_vol_label(new_val)
		AudioManager.play_sound("click")

func _on_sens_dec_pressed() -> void: _step_sensitivity(-0.05)
func _on_sens_inc_pressed() -> void: _step_sensitivity(0.05)

func _on_master_dec_pressed() -> void: _step_master_vol(-0.05)
func _on_master_inc_pressed() -> void: _step_master_vol(0.05)

func _on_bgm_dec_pressed() -> void: _step_bgm_vol(-0.05)
func _on_bgm_inc_pressed() -> void: _step_bgm_vol(0.05)

func _on_sfx_dec_pressed() -> void: _step_sfx_vol(-0.05)
func _on_sfx_inc_pressed() -> void: _step_sfx_vol(0.05)

func _init_settings_ui() -> void:
	_sync_settings_from_game_settings()
	
	if sensitivity_slider and not sensitivity_slider.value_changed.is_connected(_on_sensitivity_changed):
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	if sensitivity_dec_btn and not sensitivity_dec_btn.pressed.is_connected(_on_sens_dec_pressed):
		sensitivity_dec_btn.pressed.connect(_on_sens_dec_pressed)
	if sensitivity_inc_btn and not sensitivity_inc_btn.pressed.is_connected(_on_sens_inc_pressed):
		sensitivity_inc_btn.pressed.connect(_on_sens_inc_pressed)
		
	if master_vol_slider and not master_vol_slider.value_changed.is_connected(_on_master_vol_changed):
		master_vol_slider.value_changed.connect(_on_master_vol_changed)
	if master_vol_dec_btn and not master_vol_dec_btn.pressed.is_connected(_on_master_dec_pressed):
		master_vol_dec_btn.pressed.connect(_on_master_dec_pressed)
	if master_vol_inc_btn and not master_vol_inc_btn.pressed.is_connected(_on_master_inc_pressed):
		master_vol_inc_btn.pressed.connect(_on_master_inc_pressed)
		
	if bgm_vol_slider and not bgm_vol_slider.value_changed.is_connected(_on_bgm_vol_changed):
		bgm_vol_slider.value_changed.connect(_on_bgm_vol_changed)
	if bgm_vol_dec_btn and not bgm_vol_dec_btn.pressed.is_connected(_on_bgm_dec_pressed):
		bgm_vol_dec_btn.pressed.connect(_on_bgm_dec_pressed)
	if bgm_vol_inc_btn and not bgm_vol_inc_btn.pressed.is_connected(_on_bgm_inc_pressed):
		bgm_vol_inc_btn.pressed.connect(_on_bgm_inc_pressed)
		
	if sfx_vol_slider and not sfx_vol_slider.value_changed.is_connected(_on_sfx_vol_changed):
		sfx_vol_slider.value_changed.connect(_on_sfx_vol_changed)
	if sfx_vol_dec_btn and not sfx_vol_dec_btn.pressed.is_connected(_on_sfx_dec_pressed):
		sfx_vol_dec_btn.pressed.connect(_on_sfx_dec_pressed)
	if sfx_vol_inc_btn and not sfx_vol_inc_btn.pressed.is_connected(_on_sfx_inc_pressed):
		sfx_vol_inc_btn.pressed.connect(_on_sfx_inc_pressed)

func _on_shop_pressed() -> void:
	AudioManager.play_sound("click")
	if armory_shop:
		armory_shop.open_shop()
		modal_visibility_changed.emit(true)

func _on_settings_pressed() -> void:
	AudioManager.play_sound("click")
	_sync_settings_from_game_settings()
	if settings_layer:
		settings_layer.visible = true
	elif settings_dialog:
		settings_dialog.visible = true
	modal_visibility_changed.emit(true)

func _on_settings_close_pressed() -> void:
	AudioManager.play_sound("click")
	if settings_layer:
		settings_layer.visible = false
	elif settings_dialog:
		settings_dialog.visible = false
	_on_modal_closed()

func _on_modal_closed() -> void:
	modal_visibility_changed.emit(false)

func _on_weapon_equipped_from_shop(w_id: String) -> void:
	_update_viewmodel_texture(w_id)
	weapon_changed.emit(w_id)

func _update_viewmodel_texture(w_id: String) -> void:
	if not viewmodel:
		return
	var path := "res://data/weapons.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var test_json := JSON.new()
	if test_json.parse(file.get_as_text()) == OK:
		var data: Dictionary = test_json.data
		if data.has(w_id):
			var tex_path: String = data[w_id].get("texture", "res://assets/textures/tex_fps_iron_sights.png")
			if ResourceLoader.exists(tex_path):
				var tex = load(tex_path)
				viewmodel.set_weapon_texture(tex)

func _on_sensitivity_changed(val: float) -> void:
	GameSettings.set_aim_sensitivity(val)
	_update_sensitivity_label(val)

func _update_sensitivity_label(val: float) -> void:
	if sensitivity_title:
		var pct := int(val * 100.0)
		var desc := "안정적 (권장)" if pct <= 65 else ("표준 감도" if pct <= 100 else "고속 회전")
		sensitivity_title.text = "과녁 조준 감도 (Aim Sensitivity): %d%% [%s]" % [pct, desc]

func _on_master_vol_changed(val: float) -> void:
	GameSettings.set_master_volume(val)
	_update_master_vol_label(val)

func _update_master_vol_label(val: float) -> void:
	if master_vol_title:
		master_vol_title.text = "전체 음량 (Master Volume): %d%%" % int(val * 100.0)

func _on_bgm_vol_changed(val: float) -> void:
	GameSettings.set_bgm_volume(val)
	_update_bgm_vol_label(val)

func _update_bgm_vol_label(val: float) -> void:
	if bgm_vol_title:
		bgm_vol_title.text = "배경음악 음량 (BGM Volume): %d%%" % int(val * 100.0)

func _on_sfx_vol_changed(val: float) -> void:
	GameSettings.set_sfx_volume(val)
	_update_sfx_vol_label(val)
	AudioManager.play_sound("click")

func _update_sfx_vol_label(val: float) -> void:
	if sfx_vol_title:
		sfx_vol_title.text = "효과음 음량 (SFX Volume): %d%%" % int(val * 100.0)

func update_player_health(current: float, max_val: float) -> void:
	if player_hp_bar:
		player_hp_bar.max_value = max_val
		player_hp_bar.value = current
	if player_hp_label:
		player_hp_label.text = "병사 HP: %d / %d" % [int(current), int(max_val)]

func update_base_health(current: float, max_val: float) -> void:
	if base_hp_bar:
		base_hp_bar.max_value = max_val
		base_hp_bar.value = current
	if base_hp_label:
		base_hp_label.text = "참호 거점: %d / %d" % [int(current), int(max_val)]

func update_revives(revives_left: int) -> void:
	if revives_label:
		revives_label.text = "즉시 부활: %d / 1" % revives_left

func update_ammo(current: int, reserve: int) -> void:
	if ammo_label:
		ammo_label.text = "%d / %d" % [current, reserve]
	if ammo_bar:
		ammo_bar.max_value = 30 # standard scale
		ammo_bar.value = current

func set_reload_indicator(is_reloading: bool) -> void:
	if reload_label:
		reload_label.visible = is_reloading
	if viewmodel:
		viewmodel.set_reloading(is_reloading)

func trigger_weapon_fire() -> void:
	if viewmodel:
		viewmodel.on_fire()

func update_stage_and_wave(stage_id: int, total_stages: int, stage_wave: int, total_stage_waves: int, diff_text: String = "", info_text: String = "") -> void:
	if level_title_label:
		level_title_label.text = "STAGE %d/%d" % [stage_id, total_stages]
	if wave_title_label:
		wave_title_label.text = "WAVE %d/%d" % [stage_wave, total_stage_waves]
	if wave_info_label:
		var prefix := "[%s] " % diff_text if diff_text != "" else ""
		wave_info_label.text = prefix + (info_text if info_text != "" else "작전 구역 방어")
	if defense_bar and total_stage_waves > 0:
		defense_bar.max_value = float(total_stage_waves)
		defense_bar.value = float(stage_wave)

func update_wave(current_wave: int, max_waves: int, info_text: String = "") -> void:
	if wave_title_label:
		wave_title_label.text = "WAVE %02d / %02d" % [current_wave, max_waves]
	if wave_info_label:
		wave_info_label.text = info_text if info_text != "" else "PHASE %d" % current_wave
	if level_title_label:
		level_title_label.text = "LEVEL %02d" % current_wave
	if defense_bar and max_waves > 0:
		defense_bar.max_value = float(max_waves)
		defense_bar.value = float(current_wave)

func update_credits(amount: int) -> void:
	if credits_label:
		credits_label.text = "전공 점수: %d P" % amount

func set_crosshair_aim(is_aiming: bool) -> void:
	if crosshair_ring:
		var target_scale := Vector2(0.55, 0.55) if is_aiming else Vector2(1.0, 1.0)
		var target_mod := Color(0.2, 0.95, 1.0, 0.95) if is_aiming else Color(1.0, 1.0, 1.0, 0.8)
		crosshair_ring.scale = target_scale
		crosshair_ring.modulate = target_mod
	if crosshair_dot:
		crosshair_dot.color = Color(1.0, 0.25, 0.25) if is_aiming else Color(1.0, 1.0, 1.0)
	if viewmodel:
		viewmodel.set_aiming(is_aiming)

func open_armory_shop() -> void:
	_on_shop_pressed()

func open_settings() -> void:
	_on_settings_pressed()

func show_toast(msg: String, duration: float = 2.0) -> void:
	if help_label:
		help_label.visible = true
		help_label.text = msg
		help_label.modulate = Color(1.0, 0.9, 0.35, 1.0)
		var t := create_tween()
		t.tween_interval(duration)
		t.tween_property(help_label, "modulate:a", 0.0, 0.5)
		t.tween_callback(func():
			if help_label:
				help_label.text = "[화살표/마우스] 조준 | [좌클릭/스페이스] 사격 | [우클릭/C] 정밀조준 | [G] 수류탄 | [R] 재장전 | [E] 포탑설치 | [Q/1~7] 무기교체 | [B] 상점 | [O] 설정"
				help_label.modulate = Color(0.85, 0.9, 0.95, 0.75)
		)

func show_weapon_toast(w_id: String) -> void:
	var w_name := w_id
	var path := "res://data/weapons.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var test_json := JSON.new()
			if test_json.parse(file.get_as_text()) == OK and test_json.data.has(w_id):
				var d: Dictionary = test_json.data[w_id]
				w_name = "[%s] %s" % [d.get("country", ""), d.get("name", w_id)]
	show_toast("무기 전환 완료: %s" % w_name, 2.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var is_settings_open: bool = (settings_layer and settings_layer.visible) or (settings_dialog and settings_dialog.visible)
		if is_settings_open:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_O:
				_on_settings_close_pressed()
				get_viewport().set_input_as_handled()
				return
				
		if victory_panel and victory_panel.visible:
			if event.keycode == KEY_R or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
				_on_restart_clicked()
				get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_ESCAPE or event.keycode == KEY_M:
				_on_menu_clicked()
				get_viewport().set_input_as_handled()
				return
				
		if defeat_panel and defeat_panel.visible:
			if event.keycode == KEY_R or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
				_on_restart_clicked()
				get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_ESCAPE or event.keycode == KEY_M:
				_on_menu_clicked()
				get_viewport().set_input_as_handled()
				return

func show_victory() -> void:
	hide_boss_bar()
	if victory_panel:
		victory_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func show_defeat(reason: String) -> void:
	hide_boss_bar()
	if defeat_panel:
		defeat_panel.visible = true
		if defeat_reason_label:
			if reason == "BASE_DESTROYED":
				defeat_reason_label.text = "참호 방어선이 완전히 함락되었습니다."
			elif reason == "PLAYER_DEAD":
				defeat_reason_label.text = "아군 병사가 전사하였습니다."
			else:
				defeat_reason_label.text = "작전 실패: %s" % reason
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func show_boss_bar(boss_title: String, max_hp: float) -> void:
	if boss_container:
		boss_container.visible = true
	if boss_name_label:
		boss_name_label.text = "⚠️ [BOSS] %s" % boss_title
	if boss_hp_bar:
		boss_hp_bar.max_value = max_hp
		boss_hp_bar.value = max_hp
	if boss_hp_label:
		boss_hp_label.text = "%d / %d HP" % [int(max_hp), int(max_hp)]

func update_boss_hp(cur_hp: float, max_hp: float) -> void:
	if boss_hp_bar:
		boss_hp_bar.max_value = max_hp
		boss_hp_bar.value = maxf(0.0, cur_hp)
	if boss_hp_label:
		boss_hp_label.text = "%d / %d HP" % [int(maxf(0.0, cur_hp)), int(max_hp)]

func hide_boss_bar() -> void:
	if boss_container:
		boss_container.visible = false

var alert_timer: float = 0.0

func show_tactical_alert(alert_text: String, duration: float = 3.5) -> void:
	if tactical_alert_banner and tactical_alert_label:
		tactical_alert_label.text = alert_text
		tactical_alert_banner.visible = true
		tactical_alert_banner.modulate = Color(1, 1, 1, 1)
		alert_timer = duration

func _process(delta: float) -> void:
	if alert_timer > 0.0:
		alert_timer -= delta
		if alert_timer <= 0.0:
			if tactical_alert_banner and is_inside_tree():
				var tw := create_tween()
				tw.tween_property(tactical_alert_banner, "modulate:a", 0.0, 0.4)
				tw.tween_callback(func():
					if tactical_alert_banner:
						tactical_alert_banner.visible = false
				)
