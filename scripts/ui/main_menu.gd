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
@onready var sensitivity_slider: HSlider = $SettingsDialog/VBox/SensitivitySlider
@onready var sensitivity_title: Label = $SettingsDialog/VBox/SensitivityTitle
@onready var master_vol_slider: HSlider = $SettingsDialog/VBox/MasterVolSlider
@onready var master_vol_title: Label = $SettingsDialog/VBox/MasterVolTitle
@onready var bgm_vol_slider: HSlider = $SettingsDialog/VBox/BGMVolSlider
@onready var bgm_vol_title: Label = $SettingsDialog/VBox/BGMVolTitle
@onready var sfx_vol_slider: HSlider = $SettingsDialog/VBox/SFXVolSlider
@onready var sfx_vol_title: Label = $SettingsDialog/VBox/SFXVolTitle
@onready var fullscreen_btn: BaseButton = $SettingsDialog/VBox/FullscreenBtn
@onready var close_settings_btn: BaseButton = $SettingsDialog/VBox/CloseSettingsBtn

@onready var armory_shop: ArmoryShop = $ArmoryShop

func _ready() -> void:
	AudioManager.ensure_instance(self)
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if shop_button:
		shop_button.pressed.connect(_on_shop_pressed)
	if guide_button:
		guide_button.pressed.connect(_on_guide_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
	if close_guide_btn:
		close_guide_btn.pressed.connect(_on_guide_close_pressed)
	if close_settings_btn:
		close_settings_btn.pressed.connect(_on_settings_close_pressed)
	if fullscreen_btn:
		fullscreen_btn.pressed.connect(_on_fullscreen_pressed)
		
	_init_settings_sliders()
	
	if guide_dialog:
		guide_dialog.visible = false
	if settings_dialog:
		settings_dialog.visible = false
	if armory_shop:
		armory_shop.visible = false

func _init_settings_sliders() -> void:
	if sensitivity_slider:
		sensitivity_slider.value = GameSettings.get_aim_sensitivity()
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
		_update_sensitivity_label(sensitivity_slider.value)
		
	if master_vol_slider:
		master_vol_slider.value = GameSettings.get_master_volume()
		master_vol_slider.value_changed.connect(_on_master_vol_changed)
		_update_master_vol_label(master_vol_slider.value)
		
	if bgm_vol_slider:
		bgm_vol_slider.value = GameSettings.get_bgm_volume()
		bgm_vol_slider.value_changed.connect(_on_bgm_vol_changed)
		_update_bgm_vol_label(bgm_vol_slider.value)
		
	if sfx_vol_slider:
		sfx_vol_slider.value = GameSettings.get_sfx_volume()
		sfx_vol_slider.value_changed.connect(_on_sfx_vol_changed)
		_update_sfx_vol_label(sfx_vol_slider.value)

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

func _update_sfx_vol_label(val: float) -> void:
	if sfx_vol_title:
		sfx_vol_title.text = "효과음 음량 (SFX Volume): %d%%" % int(val * 100.0)

func _on_fullscreen_pressed() -> void:
	GameSettings.toggle_fullscreen()

func _on_exit_pressed() -> void:
	AudioManager.play_sound("click")
	get_tree().quit()
