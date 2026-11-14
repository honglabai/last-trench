class_name GameRoot
extends Node3D

@onready var status_label: Label = $UI/StatusLabel

func _ready() -> void:
	if status_label:
		status_label.text = "전투 준비 중..."

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/app/main_menu.tscn")
