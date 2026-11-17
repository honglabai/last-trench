class_name MainMenu
extends Control

@onready var start_button: BaseButton = $CenterContainer/VBoxContainer/StartButton
@onready var shop_button: BaseButton = $CenterContainer/VBoxContainer/ShopButton
@onready var guide_button: BaseButton = $CenterContainer/VBoxContainer/GuideButton
@onready var settings_button: BaseButton = $CenterContainer/VBoxContainer/SettingsButton
@onready var exit_button: BaseButton = $CenterContainer/VBoxContainer/ExitButton

@onready var guide_dialog: Panel = $GuideDialog
@onready var close_guide_btn: BaseButton = $GuideDialog/VBox/CloseButton

@onready var settings_dialog: Panel = $SettingsDialog

var sensitivity_slider: HSlider:
	get:
		var s := get_node_or_null("SettingsDialog/VBox/SensitivityRow/SensitivitySlider") as HSlider
		return s if s else (get_node_or_null("SettingsDialog/VBox/SensitivitySlider") as HSlider)

var sensitivity_title: Label:
	get: return get_node_or_null("SettingsDialog/VBox/SensitivityTitle") as Label

var sensitivity_dec_btn: BaseButton:
	get: return get_node_or_null("SettingsDialog/VBox/SensitivityRow/SensitivityDecBtn") as BaseButton

var sensitivity_inc_btn: BaseButton:
	get: return get_node_or_null("SettingsDialog/VBox/SensitivityRow/SensitivityIncBtn") as BaseButton

var master_vol_slider: HSlider:
	get:
		var s := get_node_or_null("SettingsDialog/VBox/MasterVolRow/MasterVolSlider") as HSlider
		return s if s else (get_node_or_null("SettingsDialog/VBox/MasterVolSlider") as HSlider)

var master_vol_title: Label:
	get: return get_node_or_null("SettingsDialog/VBox/MasterVolTitle") as Label

var master_vol_dec_btn: BaseButton:
	get: return get_node_or_null("SettingsDialog/VBox/MasterVolRow/MasterVolDecBtn") as BaseButton

var master_vol_inc_btn: BaseButton:
	get: return get_node_or_null("SettingsDialog/VBox/MasterVolRow/MasterVolIncBtn") as BaseButton

var bgm_vol_slider: HSlider:
	get:
		var s := get_node_or_null("SettingsDialog/VBox/BGMVolRow/BGMVolSlider") as HSlider
		return s if s else (get_node_or_null("SettingsDialog/VBox/BGMVolSlider") as HSlider)

var bgm_vol_title: Label:
	get: return get_node_or_null("SettingsDialog/VBox/BGMVolTitle") as Label

var bgm_vol_dec_btn: BaseButton:
	get: return get_node_or_null("SettingsDialog/VBox/BGMVolRow/BGMVolDecBtn") as BaseButton

var bgm_vol_inc_btn: BaseButton:
	get: return get_node_or_null("SettingsDialog/VBox/BGMVolRow/BGMVolIncBtn") as BaseButton

var sfx_vol_slider: HSlider:
	get:
		var s := get_node_or_null("SettingsDialog/VBox/SFXVolRow/SFXVolSlider") as HSlider
		return s if s else (get_node_or_null("SettingsDialog/VBox/SFXVolSlider") as HSlider)

var sfx_vol_title: Label:
	get: return get_node_or_null("SettingsDialog/VBox/SFXVolTitle") as Label

var sfx_vol_dec_btn: BaseButton:
	get: return get_node_or_null("SettingsDialog/VBox/SFXVolRow/SFXVolDecBtn") as BaseButton

var sfx_vol_inc_btn: BaseButton:
	get: return get_node_or_null("SettingsDialog/VBox/SFXVolRow/SFXVolIncBtn") as BaseButton

@onready var fullscreen_btn: BaseButton = $SettingsDialog/VBox/FullscreenBtn
@onready var close_settings_btn: BaseButton = $SettingsDialog/VBox/CloseSettingsBtn

@onready var armory_shop: ArmoryShop = $ArmoryShop

func _ready() -> void:
	AudioManager.ensure_instance(self)
	if start_button and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if shop_button and not shop_button.pressed.is_connected(_on_shop_pressed):
		shop_button.pressed.connect(_on_shop_pressed)
	if guide_button and not guide_button.pressed.is_connected(_on_guide_pressed):
		guide_button.pressed.connect(_on_guide_pressed)
	if settings_button and not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)
	if exit_button and not exit_button.pressed.is_connected(_on_exit_pressed):
		exit_button.pressed.connect(_on_exit_pressed)
	if close_guide_btn and not close_guide_btn.pressed.is_connected(_on_guide_close_pressed):
		close_guide_btn.pressed.connect(_on_guide_close_pressed)
	if close_settings_btn and not close_settings_btn.pressed.is_connected(_on_settings_close_pressed):
		close_settings_btn.pressed.connect(_on_settings_close_pressed)
	if fullscreen_btn and not fullscreen_btn.pressed.is_connected(_on_fullscreen_pressed):
		fullscreen_btn.pressed.connect(_on_fullscreen_pressed)
		
	_init_settings_sliders()
	
	if guide_dialog:
		guide_dialog.visible = false
	if settings_dialog:
		settings_dialog.visible = false
	if armory_shop:
		armory_shop.visible = false

func _sync_settings_sliders() -> void:
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

func _init_settings_sliders() -> void:
	_sync_settings_sliders()
	
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

func _on_start_pressed() -> void:
	AudioManager.play_sound("click")
	GameSettings.toggle_fullscreen()
	get_tree().change_scene_to_file("res://scenes/app/game_root.tscn")

func _on_shop_pressed() -> void:
	AudioManager.play_sound("click")
	if armory_shop:
		armory_shop.open_shop()

func _on_guide_pressed() -> void:
	AudioManager.play_sound("click")
	if guide_dialog:
		guide_dialog.visible = true
	if settings_dialog:
		settings_dialog.visible = false

func _on_guide_close_pressed() -> void:
	AudioManager.play_sound("click")
	if guide_dialog:
		guide_dialog.visible = false

func _on_settings_pressed() -> void:
	AudioManager.play_sound("click")
	_sync_settings_sliders()
	if settings_dialog:
		settings_dialog.visible = true
	if guide_dialog:
		guide_dialog.visible = false

func _on_settings_close_pressed() -> void:
	AudioManager.play_sound("click")
	if settings_dialog:
		settings_dialog.visible = false

func _on_sensitivity_changed(val: float) -> void:
	GameSettings.set_aim_sensitivity(val)
	_update_sensitivity_label(val)

func _update_sensitivity_label(val: float) -> void:
	if sensitivity_title:
		var pct := int(val * 100.0)
		var desc := "매우 안정적 (권장)" if pct <= 65 else ("표준 속도" if pct <= 100 else "고속 회전")
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

func _on_fullscreen_pressed() -> void:
	GameSettings.toggle_fullscreen()

func _on_exit_pressed() -> void:
	AudioManager.play_sound("click")
	get_tree().quit()
