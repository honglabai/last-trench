class_name EnemyBase
extends CharacterBody3D

signal enemy_damaged(amount: float, current_hp: float, max_hp: float)
signal enemy_died(enemy: EnemyBase)
signal attack_performed(target: Node3D, damage: float)
signal projectile_launched(p_type: int, start_pos: Vector3, target_pos: Vector3, damage: float, speed: float, radius: float, receiver: Node)

enum State { SPAWN, APPROACH, ATTACK, HIT, DEAD }

@export var max_health: float = 60.0
@export var move_speed: float = 3.0
@export var attack_range: float = 14.0
@export var attack_damage: float = 8.0
@export var attack_cooldown: float = 1.5
@export var gravity: float = 9.8

var current_health: float = 60.0
var current_state: State = State.SPAWN
var is_dead: bool = false
var target: Node3D = null

var attack_timer: float = 0.0
var death_event_emitted: bool = false

var _collision_shape: CollisionShape3D
var collision_shape: CollisionShape3D:
	get:
		if not _collision_shape:
			_collision_shape = get_node_or_null("CollisionShape3D")
		return _collision_shape

var _visual_mesh: Node3D
var visual_mesh: Node3D:
	get:
		if not _visual_mesh:
			_visual_mesh = get_node_or_null("VisualMesh")
		return _visual_mesh

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	collision_layer = 4 # Enemy layer
	collision_mask = 1 # Environment
	var dmg_comp := get_node_or_null("DamageableComponent") as DamageableComponent
	if dmg_comp:
		dmg_comp.max_health = max_health
		dmg_comp.current_health = max_health

func is_alive() -> bool:
	return not is_dead and current_health > 0.0

func set_target(new_target: Node3D) -> void:
	target = new_target

func launch_projectile(p_type: int, origin: Vector3, dest: Vector3, dmg: float, spd: float, rad: float = 0.0, receiver: Node = null) -> void:
	projectile_launched.emit(p_type, origin, dest, dmg, spd, rad, receiver if receiver else target)
	attack_performed.emit(target, dmg)
	# If running in standalone test without GameRoot, apply direct fallback damage
	if projectile_launched.get_connections().is_empty():
		var recv: Node = receiver if receiver else target
		if recv and is_instance_valid(recv) and recv.has_method("apply_damage"):
			recv.apply_damage(dmg)

func change_state(new_state: State) -> void:
	if current_state == State.DEAD:
		return
	current_state = new_state

func apply_damage(amount: float) -> void:
	if is_dead:
		return
	current_health = maxf(0.0, current_health - amount)
	var dmg_comp := get_node_or_null("DamageableComponent") as DamageableComponent
	if dmg_comp:
		dmg_comp.current_health = current_health
	enemy_damaged.emit(amount, current_health, max_health)
	
	if current_health <= 0.0:
		die()
	elif current_state != State.ATTACK:
		change_state(State.HIT)

func die() -> void:
	if is_dead or death_event_emitted:
		return
	is_dead = true
	death_event_emitted = true
	change_state(State.DEAD)
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	var dmg_comp := get_node_or_null("DamageableComponent") as DamageableComponent
	if dmg_comp:
		dmg_comp.is_alive = false
		dmg_comp.destroyed.emit()
		
	enemy_died.emit(self)
