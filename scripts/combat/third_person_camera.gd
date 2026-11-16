class_name ThirdPersonCamera
extends Node3D

@export var is_first_person: bool = true
@export var normal_fov: float = 75.0
@export var aim_fov: float = 50.0
@export var normal_arm_length: float = 0.0
@export var aim_arm_length: float = 0.0
@export var normal_offset: Vector3 = Vector3.ZERO
@export var aim_offset: Vector3 = Vector3.ZERO
@export var transition_speed: float = 12.0
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -65.0
@export var max_pitch: float = 65.0

var is_aiming: bool = false
var pitch: float = 0.0
var yaw: float = 0.0

var _spring_arm: SpringArm3D
var spring_arm: SpringArm3D:
	get:
		if not _spring_arm:
			_spring_arm = get_node_or_null("SpringArm3D")
		return _spring_arm

var _camera: Camera3D
var camera: Camera3D:
	get:
		if not _camera:
			_camera = get_node_or_null("SpringArm3D/Camera3D")
		return _camera

func _ready() -> void:
	if is_first_person:
		normal_arm_length = 0.0
		aim_arm_length = 0.0
		normal_offset = Vector3.ZERO
		aim_offset = Vector3.ZERO
	if spring_arm:
		spring_arm.spring_length = normal_arm_length
		spring_arm.position = normal_offset
	if camera:
		camera.fov = normal_fov
		if is_first_person:
			camera.position = Vector3.ZERO

func _process(delta: float) -> void:
	var target_fov := aim_fov if is_aiming else normal_fov
	var target_length := aim_arm_length if is_aiming else normal_arm_length
	var target_offset := aim_offset if is_aiming else normal_offset
	
	if camera:
		camera.fov = lerpf(camera.fov, target_fov, transition_speed * delta)
	if spring_arm:
		if is_first_person:
			spring_arm.spring_length = 0.0
			spring_arm.position = Vector3.ZERO
		else:
			spring_arm.spring_length = lerpf(spring_arm.spring_length, target_length, transition_speed * delta)
			spring_arm.position = spring_arm.position.lerp(target_offset, transition_speed * delta)

func handle_look_input(relative: Vector2) -> void:
	# Clamp per-frame relative delta to prevent single-frame teleport flips
	var clamped_rel := Vector2(clampf(relative.x, -50.0, 50.0), clampf(relative.y, -50.0, 50.0))
	var sens := mouse_sensitivity * GameSettings.get_aim_sensitivity()
	if is_aiming:
		sens *= 0.65 # Slower, steadier precision control when aiming down iron sights
	yaw -= clamped_rel.x * sens
	pitch = clampf(pitch - clamped_rel.y * sens, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
	
	rotation.y = yaw
	rotation.x = pitch

func set_aiming(aiming: bool) -> void:
	is_aiming = aiming

func get_camera_forward() -> Vector3:
	if camera:
		return -camera.global_transform.basis.z
	return -global_transform.basis.z

func get_yaw_basis() -> Basis:
	return Basis(Vector3.UP, yaw)
