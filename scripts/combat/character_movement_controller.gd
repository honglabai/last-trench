class_name CharacterMovementController
extends Node

## 공통 Character Movement Controller
## 단순 위치 이동이 아닌 가속, 감속, 회전 각속도 보간 및 이동 상태를 산출하여
## AI 행동 결정과 실제 물리/시각 이동을 분리하는 공통 컨트롤러

signal velocity_updated(new_velocity: Vector3, horizontal_speed: float)
signal reached_target()

@export var acceleration: float = 14.0
@export var deceleration: float = 18.0
@export var rotation_speed: float = 10.0
@export var max_speed: float = 3.5

var parent_body: CharacterBody3D = null
var current_horizontal_speed: float = 0.0
var target_horizontal_velocity: Vector3 = Vector3.ZERO
var heading_direction: Vector3 = Vector3.FORWARD
var movement_ratio: float = 0.0 # 0.0 ~ 1.0 (실제 수평속도 / max_speed)
var is_moving: bool = false
var velocity_vector: Vector3 = Vector3.ZERO

func _ready() -> void:
	if not parent_body:
		parent_body = get_parent() as CharacterBody3D

func setup(body: CharacterBody3D, p_max_speed: float, p_accel: float = 14.0, p_decel: float = 18.0, p_rot_speed: float = 10.0) -> void:
	parent_body = body
	max_speed = p_max_speed
	acceleration = p_accel
	deceleration = p_decel
	rotation_speed = p_rot_speed

## 목표 방향과 원하는 속도를 기반으로 가속·감속을 적용한 수평 속도 계산 및 반환
func calculate_step(desired_dir: Vector3, desired_speed: float, delta: float) -> Vector3:
	var target_speed := clampf(desired_speed, 0.0, max_speed)
	var horiz_dir := Vector3(desired_dir.x, 0.0, desired_dir.z)
	
	if horiz_dir.length_squared() > 0.0001:
		horiz_dir = horiz_dir.normalized()
		heading_direction = horiz_dir
	
	var target_vel := horiz_dir * target_speed
	var current_vel := Vector3.ZERO
	if parent_body:
		current_vel = Vector3(parent_body.velocity.x, 0.0, parent_body.velocity.z)
	else:
		current_vel = Vector3(velocity_vector.x, 0.0, velocity_vector.z)
		
	var speed_rate := acceleration if target_speed > current_vel.length() else deceleration
	var new_vel := current_vel.move_toward(target_vel, speed_rate * delta)
	
	current_horizontal_speed = new_vel.length()
	movement_ratio = clampf(current_horizontal_speed / maxf(0.001, max_speed), 0.0, 1.0)
	is_moving = current_horizontal_speed > 0.05
	
	if parent_body:
		parent_body.velocity.x = new_vel.x
		parent_body.velocity.z = new_vel.z
	velocity_vector = Vector3(new_vel.x, parent_body.velocity.y if parent_body else 0.0, new_vel.z)
	
	velocity_updated.emit(velocity_vector, current_horizontal_speed)
	return new_vel

## 제동 감속 (완전 정지)
func apply_braking(delta: float) -> Vector3:
	return calculate_step(Vector3.ZERO, 0.0, delta)

## 시각 메시(VisualMesh) 부드러운 회전 보간
func smooth_rotate_visual(visual_node: Node3D, target_forward: Vector3, delta: float, override_rot_speed: float = -1.0) -> void:
	if not visual_node or target_forward.length_squared() < 0.0001:
		return
	var speed := rotation_speed if override_rot_speed <= 0.0 else override_rot_speed
	var target_angle := atan2(target_forward.x, target_forward.z)
	visual_node.rotation.y = lerp_angle(visual_node.rotation.y, target_angle, speed * delta)

## 이동 속도와 보폭 주기를 1:1 선형 연동하기 위한 애니메이션 재생 배율 계산
## base_walk_speed: 애니메이션 1.0배속 기준 캐릭터 이동 속도
func get_stride_playback_scale(base_walk_speed: float = 3.2) -> float:
	if not is_moving or base_walk_speed <= 0.001:
		return 1.0
	return clampf(current_horizontal_speed / base_walk_speed, 0.2, 2.5)
