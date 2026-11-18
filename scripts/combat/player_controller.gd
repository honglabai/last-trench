class_name PlayerController
extends CharacterBody3D

signal aiming_changed(is_aiming: bool)
signal player_damaged(current_hp: float, max_hp: float)
signal player_died()

@export var move_speed: float = 4.5
@export var aim_move_speed: float = 2.5
@export var acceleration: float = 14.0
@export var gravity: float = 9.8
@export var max_health: float = 100.0
@export var stationary_defense_mode: bool = true

var current_health: float = 100.0
var is_aiming: bool = false
var is_dead: bool = false
var is_invulnerable: bool = false

# Input adapter fields (can be driven by keys or mobile touch adapter in P10)
# Convention: X = (-1 Left, +1 Right), Y = (-1 Forward, +1 Backward) matching Input.get_vector
var input_move_vector: Vector2 = Vector2.ZERO
var input_look_vector: Vector2 = Vector2.ZERO
var manual_input_override: bool = false
var is_firing_requested: bool = false
var is_reload_requested: bool = false

var _camera_rig: ThirdPersonCamera
var camera_rig: ThirdPersonCamera:
	get:
		if not _camera_rig:
			_camera_rig = get_node_or_null("CameraRig")
		return _camera_rig

var _visual_mesh: Node3D
var visual_mesh: Node3D:
	get:
		if not _visual_mesh:
			_visual_mesh = get_node_or_null("VisualMesh")
		return _visual_mesh

var _weapon: WeaponComponent
var weapon: WeaponComponent:
	get:
		if not _weapon:
			_weapon = get_node_or_null("WeaponComponent")
		return _weapon

func _ready() -> void:
	current_health = max_health
	if camera_rig and camera_rig.is_first_person:
		if visual_mesh:
			visual_mesh.visible = false
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		manual_input_override = true

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	if event is InputEventMouseMotion:
		# In touch/mobile mode, ignore synthetic mouse motion
		if manual_input_override:
			return
		# Ignore massive sudden spikes (e.g. pointer lock transitions)
		if event.relative.length_squared() > 10000.0:
			return
		if camera_rig:
			camera_rig.handle_look_input(event.relative)

func set_aiming(aiming: bool) -> void:
	is_aiming = aiming
	if camera_rig:
		camera_rig.set_aiming(aiming)
	aiming_changed.emit(aiming)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# 1. Read input (Supports both Keyboard/Mouse and Mobile Touch)
	var keyboard_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_vec := Vector2.ZERO
	if keyboard_vec.length_squared() > 0.01:
		move_vec = keyboard_vec
	elif manual_input_override:
		move_vec = input_move_vector
		
	if manual_input_override:
		# is_aiming is maintained as set by set_aiming() / touch controls
		pass
	elif Input.is_action_pressed("aim"):
		is_aiming = true
	else:
		is_aiming = false
		
	if camera_rig:
		camera_rig.set_aiming(is_aiming)
	aiming_changed.emit(is_aiming)
	
	# 2. Gravity
	if is_inside_tree() and is_on_floor():
		velocity.y = -0.1
	else:
		velocity.y -= gravity * delta
		
	# 3. Horizontal movement
	var camera_yaw := Basis.IDENTITY
	if camera_rig:
		camera_yaw = camera_rig.get_yaw_basis()
		
	var forward: Vector3 = -camera_yaw.z
	var right: Vector3 = camera_yaw.x
	
	if stationary_defense_mode:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		# move_vec.y is negative when moving forward (Godot convention)
		var target_dir: Vector3 = (right * move_vec.x + forward * (-move_vec.y)).normalized()
		var current_speed := aim_move_speed if is_aiming else move_speed
		var target_vel := target_dir * current_speed
		velocity.x = lerpf(velocity.x, target_vel.x, acceleration * delta)
		velocity.z = lerpf(velocity.z, target_vel.z, acceleration * delta)
	
	# 4. Mesh rotation
	if visual_mesh and is_inside_tree() and visual_mesh.visible:
		var target_dir: Vector3 = (right * move_vec.x + forward * (-move_vec.y)).normalized()
		if is_aiming and camera_rig:
			var look_dir := Vector3(forward.x, 0.0, forward.z).normalized()
			if look_dir.length_squared() > 0.001:
				visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(look_dir.x, look_dir.z), 15.0 * delta)
		elif target_dir.length_squared() > 0.01:
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, atan2(target_dir.x, target_dir.z), 12.0 * delta)
			
	# 5. Move and slide (if inside a valid physics space)
	if is_inside_tree() and get_world_3d() and get_world_3d().space.is_valid():
		move_and_slide()
		
	# 6. Firing and Reloading (Supports both Keyboard/Mouse and Mobile Touch)
	var wants_reload := Input.is_action_just_pressed("reload") or (manual_input_override and is_reload_requested)
	var wants_fire := false
	if manual_input_override:
		# In mobile / touch mode, firing triggers ONLY when FIRE button is held or Spacebar is pressed
		# Never check Input.is_action_pressed("fire") here because touch-to-mouse emulation synthesizes left clicks on all screen touches!
		wants_fire = is_firing_requested or Input.is_physical_key_pressed(KEY_SPACE)
	else:
		wants_fire = is_firing_requested or Input.is_action_pressed("fire")
	
	if wants_reload and weapon:
		weapon.start_reload()
		
	if wants_fire and weapon:
		var origin := global_position + Vector3(0.0, 1.5, 0.0)
		if camera_rig and camera_rig.camera:
			origin = camera_rig.camera.global_position
		var fire_dir := -camera_yaw.z
		if camera_rig:
			fire_dir = camera_rig.get_camera_forward()
		var space := get_world_3d().direct_space_state if is_inside_tree() and get_world_3d() else null
		var did_fire: bool = weapon.try_fire(origin, fire_dir, space, [get_rid()])
		if did_fire:
			trigger_haptic(25) # Weak vibration on bullet fire

func apply_damage(amount: float) -> void:
	if is_dead or is_invulnerable:
		return
	current_health = maxf(0.0, current_health - amount)
	trigger_haptic(120) # Stronger vibration when hit by enemy bullets
	player_damaged.emit(current_health, max_health)
	if current_health <= 0.0:
		is_dead = true
		player_died.emit()

static func trigger_haptic(duration_ms: int) -> void:
	# 1. Native Mobile (Android / iOS)
	if Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(duration_ms)
	# 2. Web Mobile (HTML5 Navigator Vibration API)
	if Engine.has_singleton("JavaScriptBridge"):
		var js = Engine.get_singleton("JavaScriptBridge")
		if js:
			js.eval("if (typeof window !== 'undefined' && window.navigator && window.navigator.vibrate) { try { window.navigator.vibrate(%d); } catch(e) {} }" % duration_ms)

func revive(restore_hp: float) -> void:
	is_dead = false
	current_health = minf(max_health, restore_hp)
	player_damaged.emit(current_health, max_health)
