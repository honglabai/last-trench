class_name GameSession
extends Node

signal session_started()
signal player_revived(revives_left: int, restored_hp: float)
signal session_defeat(reason: String)
signal session_victory()

enum Result { NONE, VICTORY, DEFEAT }

@export var max_revives_per_run: int = 1
@export var revive_hp_ratio: float = 0.8
@export var invulnerability_duration: float = 1.5

var revives_remaining: int = 1
var current_result: Result = Result.NONE
var defeat_reason: String = ""
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0

var current_player: PlayerController = null
var current_base: BaseObjective = null
var current_wave_director: WaveDirector = null

func _process(delta: float) -> void:
	if is_invulnerable:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0.0:
			is_invulnerable = false
			if current_player and is_instance_valid(current_player):
				current_player.is_invulnerable = false

func start_session(player: PlayerController, base: BaseObjective, director: WaveDirector = null) -> void:
	current_player = player
	current_base = base
	current_wave_director = director
	
	revives_remaining = max_revives_per_run
	current_result = Result.NONE
	defeat_reason = ""
	is_invulnerable = false
	invulnerability_timer = 0.0
	
	if current_player and is_instance_valid(current_player):
		current_player.is_invulnerable = false
		if not current_player.player_died.is_connected(_on_player_died):
			current_player.player_died.connect(_on_player_died)
			
	if current_base and is_instance_valid(current_base):
		if not current_base.base_destroyed.is_connected(_on_base_destroyed):
			current_base.base_destroyed.connect(_on_base_destroyed)
			
	if current_wave_director and is_instance_valid(current_wave_director):
		if not current_wave_director.run_victory.is_connected(_on_victory):
			current_wave_director.run_victory.connect(_on_victory)
			
	session_started.emit()

func _on_player_died() -> void:
	if current_result != Result.NONE:
		return
	if is_invulnerable:
		return
		
	# Rule Invariant: Exactly 1 immediate auto-revive per run
	if revives_remaining > 0:
		revives_remaining -= 1
		is_invulnerable = true
		invulnerability_timer = invulnerability_duration
		
		if current_player and is_instance_valid(current_player):
			current_player.is_invulnerable = true
			var restore_hp: float = current_player.max_health * revive_hp_ratio
			current_player.revive(restore_hp)
			
		player_revived.emit(revives_remaining, current_player.current_health if current_player else 0.0)
	else:
		_trigger_defeat("PLAYER_DEAD")

func _on_base_destroyed() -> void:
	# Rule Invariant: Base destroyed = immediate defeat regardless of remaining revives
	_trigger_defeat("BASE_DESTROYED")

func _trigger_defeat(reason: String) -> void:
	if current_result != Result.NONE:
		return
	current_result = Result.DEFEAT
	defeat_reason = reason
	session_defeat.emit(defeat_reason)

func _on_victory() -> void:
	if current_result != Result.NONE:
		return
	current_result = Result.VICTORY
	session_victory.emit()
