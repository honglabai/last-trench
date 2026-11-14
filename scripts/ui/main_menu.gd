class_name MainMenu
extends Control

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ExitButton

func _ready() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/app/game_root.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
