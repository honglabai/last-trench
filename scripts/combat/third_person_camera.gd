class_name ThirdPersonCamera
extends Node3D

@export var normal_fov: float = 75.0
@export var aim_fov: float = 55.0
@export var normal_arm_length: float = 3.5
@export var aim_arm_length: float = 1.6
@export var normal_offset: Vector3 = Vector3(0.0, 0.2, 0.0)
@export var aim_offset: Vector3 = Vector3(0.55, 0.1, 0.0)
@export var transition_speed: float = 10.0
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -70.0
@export var max_pitch: float = 60.0

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
	if spring_arm:
		spring_arm.spring_length = normal_arm_length
		spring_arm.position = normal_offset
	if camera:
		camera.fov = normal_fov

func _process(delta: float) -> void:
	var target_fov := aim_fov if is_aiming else normal_fov
	var target_length := aim_arm_length if is_aiming else normal_arm_length
	var target_offset := aim_offset if is_aiming else normal_offset
	
	if camera:
		camera.fov = lerpf(camera.fov, target_fov, transition_speed * delta)
	if spring_arm:
		spring_arm.spring_length = lerpf(spring_arm.spring_length, target_length, transition_speed * delta)
		spring_arm.position = spring_arm.position.lerp(target_offset, transition_speed * delta)

func handle_look_input(relative: Vector2) -> void:
	yaw -= relative.x * mouse_sensitivity
	pitch = clampf(pitch - relative.y * mouse_sensitivity, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
	
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
