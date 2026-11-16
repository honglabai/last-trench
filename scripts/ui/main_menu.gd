class_name MainMenu
extends Control

var _start_button: BaseButton
var start_button: BaseButton:
	get:
		if not _start_button: _start_button = get_node_or_null("CenterContainer/VBoxContainer/StartButton")
		return _start_button

var _guide_button: BaseButton
var guide_button: BaseButton:
	get:
		if not _guide_button: _guide_button = get_node_or_null("CenterContainer/VBoxContainer/GuideButton")
		return _guide_button

var _settings_button: BaseButton
var settings_button: BaseButton:
	get:
		if not _settings_button: _settings_button = get_node_or_null("CenterContainer/VBoxContainer/SettingsButton")
		return _settings_button

var _exit_button: BaseButton
var exit_button: BaseButton:
	get:
		if not _exit_button: _exit_button = get_node_or_null("CenterContainer/VBoxContainer/ExitButton")
		return _exit_button

var _guide_dialog: Control
var guide_dialog: Control:
	get:
		if not _guide_dialog: _guide_dialog = get_node_or_null("GuideDialog")
		return _guide_dialog

var _close_guide_btn: BaseButton
var close_guide_btn: BaseButton:
	get:
		if not _close_guide_btn: _close_guide_btn = get_node_or_null("GuideDialog/VBox/CloseButton")
		return _close_guide_btn

var _settings_dialog: Control
var settings_dialog: Control:
	get:
		if not _settings_dialog: _settings_dialog = get_node_or_null("SettingsDialog")
		return _settings_dialog

var _sensitivity_slider: Slider
var sensitivity_slider: Slider:
	get:
		if not _sensitivity_slider: _sensitivity_slider = get_node_or_null("SettingsDialog/VBox/SensitivitySlider")
		return _sensitivity_slider

var _sensitivity_title: Label
var sensitivity_title: Label:
	get:
		if not _sensitivity_title: _sensitivity_title = get_node_or_null("SettingsDialog/VBox/SensitivityTitle")
		return _sensitivity_title

var _fullscreen_btn: BaseButton
var fullscreen_btn: BaseButton:
	get:
		if not _fullscreen_btn: _fullscreen_btn = get_node_or_null("SettingsDialog/VBox/FullscreenBtn")
		return _fullscreen_btn

var _close_settings_btn: BaseButton
var close_settings_btn: BaseButton:
	get:
		if not _close_settings_btn: _close_settings_btn = get_node_or_null("SettingsDialog/VBox/CloseSettingsBtn")
		return _close_settings_btn

func _ready() -> void:
	AudioManager.ensure_instance(self)
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
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
	if sensitivity_slider:
		sensitivity_slider.value = GameSettings.get_aim_sensitivity()
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
		_update_sensitivity_label(sensitivity_slider.value)
	if guide_dialog:
		guide_dialog.visible = false
	if settings_dialog:
		settings_dialog.visible = false

func _on_start_pressed() -> void:
	AudioManager.play_sound("click")
	# Attempt entering immersive fullscreen on launch
	GameSettings.toggle_fullscreen()
	get_tree().change_scene_to_file("res://scenes/app/game_root.tscn")

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
		if sensitivity_slider:
			sensitivity_slider.value = GameSettings.get_aim_sensitivity()
			_update_sensitivity_label(sensitivity_slider.value)
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

func _on_fullscreen_pressed() -> void:
	GameSettings.toggle_fullscreen()

func _on_exit_pressed() -> void:
	if OS.has_feature("web"):
		if guide_dialog:
			guide_dialog.visible = true
	else:
		get_tree().quit()
