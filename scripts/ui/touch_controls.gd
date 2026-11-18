class_name TouchControls
extends CanvasLayer

signal move_vector_changed(vector: Vector2)
signal look_delta_produced(delta: Vector2)
signal fire_pressed(pressed: bool)
signal aim_toggled()
signal reload_requested()
signal interact_requested()
signal weapon_switch_requested()
signal touch_detected()

@export var joystick_radius: float = 70.0
@export var look_sensitivity: float = 1.5
@export var joystick_look_speed: float = 850.0

var joystick_touch_id: int = -1
var look_touch_id: int = -1
var fire_touch_id: int = -1

var joystick_center: Vector2 = Vector2.ZERO
var current_move_vector: Vector2 = Vector2.ZERO
var is_aim_active: bool = false
var can_interact: bool = false
var _is_firing: bool = false
var is_input_locked: bool = false

func set_input_locked(locked: bool) -> void:
	is_input_locked = locked
	if locked:
		_on_fire_up()
		_reset_joystick()
		fire_touch_id = -1
		joystick_touch_id = -1
		look_touch_id = -1

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

var _switch_button: Button
var switch_button: Button:
	get:
		if not _switch_button:
			_switch_button = get_node_or_null("RightZone/ActionButtons/SwitchButton")
		return _switch_button

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
		interact_button.visible = true
		set_interact_available(false)
		
	if switch_button:
		if not switch_button.pressed.is_connected(_on_switch_pressed):
			switch_button.pressed.connect(_on_switch_pressed)

func _process(delta: float) -> void:
	if is_input_locked:
		return
	# Left joystick controls direction: held deflection continuously pans the view/aim direction
	if current_move_vector.length_squared() > 0.01:
		var look_delta := current_move_vector * joystick_look_speed * delta
		look_delta_produced.emit(look_delta)

func _on_fire_down() -> void:
	if not _is_firing:
		_is_firing = true
		fire_pressed.emit(true)

func _on_fire_up() -> void:
	if _is_firing:
		_is_firing = false
		fire_pressed.emit(false)

var _last_action_times: Dictionary = {}

func _debounce(action_name: String, window_sec: float = 0.18) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	var last: float = float(_last_action_times.get(action_name, -999.0))
	if now - last < window_sec:
		return false
	_last_action_times[action_name] = now
	return true

func _on_reload_pressed() -> void:
	if not _debounce("reload"): return
	AudioManager.play_sound("click")
	reload_requested.emit()

func _on_interact_pressed() -> void:
	if not _debounce("interact"): return
	AudioManager.play_sound("click")
	interact_requested.emit()

func _on_switch_pressed() -> void:
	if not _debounce("switch"): return
	AudioManager.play_sound("click")
	weapon_switch_requested.emit()

func set_interact_available(available: bool, label_text: String = "포탑 설치") -> void:
	can_interact = available
	if interact_button:
		interact_button.visible = true
		interact_button.text = label_text
		if available:
			interact_button.modulate = Color(0.3, 1.0, 0.5, 1.0) # Bright glowing green active
		else:
			interact_button.modulate = Color(1.0, 1.0, 1.0, 0.85) # High visibility tactical cyan

func _on_aim_pressed() -> void:
	if not _debounce("aim"): return
	AudioManager.play_sound("click")
	is_aim_active = not is_aim_active
	aim_toggled.emit()
	if aim_button:
		aim_button.modulate = Color(1.0, 0.8, 0.2) if is_aim_active else Color(1.0, 1.0, 1.0)

func _input(event: InputEvent) -> void:
	if is_input_locked:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	touch_detected.emit()
	var viewport_size := get_viewport().get_visible_rect().size
	var half_width := viewport_size.x * 0.45
	
	if event.pressed:
		# 1. Right Fire Button check (firing happens ONLY on this button)
		if fire_button and fire_button.is_visible_in_tree() and fire_button.get_global_rect().has_point(event.position):
			fire_touch_id = event.index
			_on_fire_down()
			get_viewport().set_input_as_handled()
			return
			
		# 2. Check other action buttons (Aim, Reload, Interact, Switch)
		if _is_touch_on_other_buttons(event.position):
			if aim_button and aim_button.is_visible_in_tree() and aim_button.get_global_rect().has_point(event.position):
				_on_aim_pressed()
			elif reload_button and reload_button.is_visible_in_tree() and reload_button.get_global_rect().has_point(event.position):
				_on_reload_pressed()
			elif interact_button and interact_button.is_visible_in_tree() and interact_button.get_global_rect().has_point(event.position):
				_on_interact_pressed()
			elif switch_button and switch_button.is_visible_in_tree() and switch_button.get_global_rect().has_point(event.position):
				_on_switch_pressed()
			get_viewport().set_input_as_handled()
			return
			
		# 3. Left side: Joystick (STRICTLY FIXED POSITION, NEVER MOVES ITS BASE)
		if event.position.x < half_width and joystick_touch_id == -1:
			joystick_touch_id = event.index
			# Calculate deflection relative to the permanent, fixed joystick base position
			_update_joystick(event.position)
			get_viewport().set_input_as_handled()
		# 4. Right side: Look drag zone (swiping for fine aim - only when NOT touching buttons)
		elif event.position.x >= half_width and look_touch_id == -1:
			if not _is_touch_on_buttons(event.position):
				look_touch_id = event.index
				get_viewport().set_input_as_handled()
	else:
		if event.index == fire_touch_id:
			fire_touch_id = -1
			_on_fire_up()
			get_viewport().set_input_as_handled()
		elif event.index == joystick_touch_id:
			joystick_touch_id = -1
			_reset_joystick()
			get_viewport().set_input_as_handled()
		elif event.index == look_touch_id:
			look_touch_id = -1
			get_viewport().set_input_as_handled()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == fire_touch_id:
		get_viewport().set_input_as_handled()
		return
	elif event.index == joystick_touch_id:
		_update_joystick(event.position)
		get_viewport().set_input_as_handled()
	elif event.index == look_touch_id:
		var rel := event.relative * look_sensitivity
		# Clamp drag relative to prevent sudden touch jumps
		rel.x = clampf(rel.x, -80.0, 80.0)
		rel.y = clampf(rel.y, -80.0, 80.0)
		look_delta_produced.emit(rel)
		get_viewport().set_input_as_handled()

func _is_touch_on_buttons(pos: Vector2) -> bool:
	var buttons = [fire_button, aim_button, reload_button, interact_button, switch_button]
	for btn in buttons:
		if btn and btn.is_visible_in_tree():
			if btn.get_global_rect().has_point(pos):
				return true
	return false

func _is_touch_on_other_buttons(pos: Vector2) -> bool:
	var buttons = [aim_button, reload_button, interact_button, switch_button]
	for btn in buttons:
		if btn and btn.is_visible_in_tree():
			if btn.get_global_rect().has_point(pos):
				return true
	return false

func _update_joystick(touch_pos: Vector2) -> void:
	if not joystick_base:
		return
	# Fixed center: Never reassigns joystick_base.global_position!
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
