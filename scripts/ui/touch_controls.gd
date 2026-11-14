class_name TouchControls
extends CanvasLayer

signal move_vector_changed(vector: Vector2)
signal look_delta_produced(delta: Vector2)
signal fire_pressed(pressed: bool)
signal aim_toggled()
signal reload_requested()
signal interact_requested()

@export var joystick_radius: float = 70.0
@export var look_sensitivity: float = 1.0

var joystick_touch_id: int = -1
var look_touch_id: int = -1

var joystick_center: Vector2 = Vector2.ZERO
var current_move_vector: Vector2 = Vector2.ZERO
var is_aim_active: bool = false
var can_interact: bool = false

var _joystick_base: Control
var joystick_base: Control:
	get:
		if not _joystick_base:
			_joystick_base = get_node_or_null("LeftZone/JoystickBase")
		return _joystick_base

var _joystick_knob: Control
var joystick_knob: Control:
	get:
		if not _joystick_knob:
			_joystick_knob = get_node_or_null("LeftZone/JoystickBase/Knob")
		return _joystick_knob

var _fire_button: Button
var fire_button: Button:
	get:
		if not _fire_button:
			_fire_button = get_node_or_null("RightZone/ActionButtons/FireButton")
		return _fire_button

var _aim_button: Button
var aim_button: Button:
	get:
		if not _aim_button:
			_aim_button = get_node_or_null("RightZone/ActionButtons/AimButton")
		return _aim_button

var _reload_button: Button
var reload_button: Button:
	get:
		if not _reload_button:
			_reload_button = get_node_or_null("RightZone/ActionButtons/ReloadButton")
		return _reload_button

var _interact_button: Button
var interact_button: Button:
	get:
		if not _interact_button:
			_interact_button = get_node_or_null("RightZone/ActionButtons/InteractButton")
		return _interact_button

func _ready() -> void:
	if joystick_base:
		joystick_center = joystick_base.size / 2.0
		_reset_joystick()
		
	if fire_button:
		if not fire_button.button_down.is_connected(_on_fire_down):
			fire_button.button_down.connect(_on_fire_down)
		if not fire_button.button_up.is_connected(_on_fire_up):
			fire_button.button_up.connect(_on_fire_up)
		
	if aim_button:
		if not aim_button.pressed.is_connected(_on_aim_pressed):
			aim_button.pressed.connect(_on_aim_pressed)
		
	if reload_button:
		if not reload_button.pressed.is_connected(_on_reload_pressed):
			reload_button.pressed.connect(_on_reload_pressed)
		
	if interact_button:
		if not interact_button.pressed.is_connected(_on_interact_pressed):
			interact_button.pressed.connect(_on_interact_pressed)
		interact_button.visible = false

func _on_fire_down() -> void:
	fire_pressed.emit(true)

func _on_fire_up() -> void:
	fire_pressed.emit(false)

func _on_reload_pressed() -> void:
	reload_requested.emit()

func _on_interact_pressed() -> void:
	interact_requested.emit()

func set_interact_available(available: bool, label_text: String = "설치/수리") -> void:
	can_interact = available
	if interact_button:
		interact_button.visible = available
		interact_button.text = label_text

func _on_aim_pressed() -> void:
	is_aim_active = not is_aim_active
	aim_toggled.emit()
	if aim_button:
		aim_button.modulate = Color(1.0, 0.8, 0.2) if is_aim_active else Color(1.0, 1.0, 1.0)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var half_width := viewport_size.x * 0.45
	
	if event.pressed:
		# Left side: Joystick
		if event.position.x < half_width and joystick_touch_id == -1:
			joystick_touch_id = event.index
			if joystick_base:
				joystick_base.global_position = event.position - joystick_center
				_update_joystick(event.position)
		# Right side: Look drag zone (only if outside action button area)
		elif event.position.x >= half_width and look_touch_id == -1:
			if not _is_touch_on_buttons(event.position):
				look_touch_id = event.index
	else:
		if event.index == joystick_touch_id:
			joystick_touch_id = -1
			_reset_joystick()
		elif event.index == look_touch_id:
			look_touch_id = -1

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == joystick_touch_id:
		_update_joystick(event.position)
	elif event.index == look_touch_id:
		look_delta_produced.emit(event.relative * look_sensitivity)

func _is_touch_on_buttons(pos: Vector2) -> bool:
	var buttons = [fire_button, aim_button, reload_button, interact_button]
	for btn in buttons:
		if btn and btn.is_visible_in_tree():
			if btn.get_global_rect().has_point(pos):
				return true
	return false

func _update_joystick(touch_pos: Vector2) -> void:
	if not joystick_base:
		return
	var base_center := joystick_base.global_position + joystick_center
	var diff := touch_pos - base_center
	var dist := diff.length()
	var clamped_diff := diff
	
	if dist > joystick_radius:
		clamped_diff = diff.normalized() * joystick_radius
		
	if joystick_knob:
		joystick_knob.position = joystick_center + clamped_diff - (joystick_knob.size / 2.0)
		
	# Normalized vector: X in [-1, 1], Y in [-1, 1] (UP is -1 in Godot convention)
	current_move_vector = Vector2(clamped_diff.x / joystick_radius, clamped_diff.y / joystick_radius)
	move_vector_changed.emit(current_move_vector)

func _reset_joystick() -> void:
	current_move_vector = Vector2.ZERO
	move_vector_changed.emit(Vector2.ZERO)
	if joystick_knob:
		joystick_knob.position = joystick_center - (joystick_knob.size / 2.0)
