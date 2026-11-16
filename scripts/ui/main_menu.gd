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

func _ready() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if guide_button:
		guide_button.pressed.connect(_on_guide_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
	if close_guide_btn:
		close_guide_btn.pressed.connect(_on_guide_close_pressed)
	if guide_dialog:
		guide_dialog.visible = false

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/app/game_root.tscn")

func _on_guide_pressed() -> void:
	if guide_dialog:
		guide_dialog.visible = true

func _on_guide_close_pressed() -> void:
	if guide_dialog:
		guide_dialog.visible = false

func _on_exit_pressed() -> void:
	if OS.has_feature("web"):
		# In web browser, show briefing dialog or reload
		if guide_dialog:
			guide_dialog.visible = true
	else:
		get_tree().quit()
