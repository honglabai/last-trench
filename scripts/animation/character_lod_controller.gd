class_name CharacterLODController
extends Node

## 거리별 애니메이션 품질 조정 및 모바일 30FPS 보장 LOD 컨트롤러
## 카메라 및 플레이어와의 거리에 따라 관절 연산 빈도를 조절하고 화면 밖을 감지

enum LODLevel {
	LOD_NEAR,   # < 25m: 60 FPS 매 프레임 전체 관절/레이캐스트 갱신
	LOD_MID,    # 25m ~ 50m: 30 FPS 격프레임 갱신 (홀수/짝수 프레임 분산)
	LOD_FAR,    # > 50m: 기본 위치/회전 보간만 유지, 미세 관절 생략
	LOD_CULLED  # 화면 밖 / 비가시: 관절 물리 완전 절전
}

signal lod_changed(new_lod: LODLevel)

@export var near_threshold: float = 24.0
@export var mid_threshold: float = 48.0

var parent_node: Node3D = null
var current_lod: LODLevel = LODLevel.LOD_NEAR
var current_distance: float = 0.0
var frame_tick: int = 0
var is_on_screen: bool = true
var target_reference: Node3D = null

func _ready() -> void:
	parent_node = get_parent() as Node3D
	# 시작 프레임 지터를 주어 여러 적이 동시에 같은 프레임에 연산하지 않도록 분산
	frame_tick = randi() % 4

func setup(node: Node3D, near_dist: float = 24.0, mid_dist: float = 48.0) -> void:
	parent_node = node
	near_threshold = near_dist
	mid_threshold = mid_dist

## 특정 프레임에서 애니메이션/관절 계산을 수행해야 하는지 여부 반환
func should_update_animation() -> bool:
	frame_tick += 1
	if not is_on_screen and current_distance > near_threshold:
		return false
		
	match current_lod:
		LODLevel.LOD_NEAR:
			return true # 매 프레임 갱신
		LODLevel.LOD_MID:
			return (frame_tick % 2) == 0 # 격프레임 (30 FPS)
		LODLevel.LOD_FAR:
			return (frame_tick % 4) == 0 # 4프레임당 1회 (15 FPS)
		LODLevel.LOD_CULLED:
			return false
	return true

## 카메라 또는 플레이어 위치를 기준으로 거리 및 LOD 등급 갱신
func update_lod_distance(reference_pos: Vector3) -> LODLevel:
	if not parent_node:
		return current_lod
		
	var my_pos: Vector3 = parent_node.global_position if parent_node.is_inside_tree() else parent_node.position
	current_distance = my_pos.distance_to(reference_pos)
	
	var next_lod: LODLevel
	if current_distance <= near_threshold:
		next_lod = LODLevel.LOD_NEAR
	elif current_distance <= mid_threshold:
		next_lod = LODLevel.LOD_MID
	else:
		next_lod = LODLevel.LOD_FAR
		
	if next_lod != current_lod:
		current_lod = next_lod
		lod_changed.emit(current_lod)
		
	return current_lod
