class_name AudioManager
extends Node

static var instance: AudioManager = null

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_voices: int = 12
var current_sfx_index: int = 0

var streams: Dictionary = {}
var is_bgm_playing: bool = false
var _audio_unlocked: bool = false

var master_vol_scale: float = 0.85
var bgm_vol_scale: float = 0.70
var sfx_vol_scale: float = 0.85

const AUDIO_DIR := "res://assets/audio/"
const SOUND_FILES := {
	"bgm": "bgm_battlefield.wav",
	"rifle_shot": "sfx_rifle_shot.wav",
	"reload": "sfx_reload.wav",
	"enemy_shot": "sfx_enemy_shot.wav",
	"turret_shot": "sfx_turret_shot.wav",
	"drone_rocket": "sfx_drone_rocket.wav",
	"explosion": "sfx_explosion.wav",
	"drone_hum": "sfx_drone_hum.wav",
	"hit_enemy": "sfx_hit_enemy.wav",
	"click": "sfx_ui_click.wav",
	"dry_fire": "sfx_dry_fire.wav"
}

static func ensure_instance(parent: Node = null) -> AudioManager:
	if instance and is_instance_valid(instance):
		return instance
	var am := AudioManager.new()
	am.name = "AudioManager"
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.call_deferred("add_child", am)
	elif parent and is_instance_valid(parent):
		parent.add_child(am)
	instance = am
	return am

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Load volume values from GameSettings
	master_vol_scale = GameSettings.get_master_volume()
	bgm_vol_scale = GameSettings.get_bgm_volume()
	sfx_vol_scale = GameSettings.get_sfx_volume()
	
	# Apply Master volume to AudioServer
	_apply_master_volume()
	
	# 1. Setup BGM player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Master"
	add_child(bgm_player)
	_apply_bgm_volume()
	
	# 2. Setup SFX polyphonic voice pool
	for i in range(max_sfx_voices):
		var p := AudioStreamPlayer.new()
		p.name = "SFXVoice_%d" % i
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)
		
	# 3. Preload all streams
	for key in SOUND_FILES:
		var path: String = AUDIO_DIR + SOUND_FILES[key]
		if ResourceLoader.exists(path):
			var res = load(path)
			if res is AudioStreamWAV:
				if key == "bgm" or key == "drone_hum":
					res.loop_mode = AudioStreamWAV.LOOP_FORWARD
			streams[key] = res
			
	# Auto-start BGM
	play_bgm()

func _input(event: InputEvent) -> void:
	# Unlock and start audio on first user touch/click/keypress for Web Audio API policy
	var is_gesture: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventKey and event.pressed)
	if is_gesture:
		if not _audio_unlocked or (bgm_player and not bgm_player.playing and bgm_vol_scale > 0.005):
			_audio_unlocked = true
			play_bgm()

func set_master_volume(pct: float) -> void:
	master_vol_scale = clampf(pct, 0.0, 1.0)
	_apply_master_volume()

func _apply_master_volume() -> void:
	if master_vol_scale <= 0.005:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, linear_to_db(master_vol_scale))
	_apply_bgm_volume()

func set_bgm_volume(pct: float) -> void:
	bgm_vol_scale = clampf(pct, 0.0, 1.0)
	_apply_bgm_volume()

func set_sfx_volume(pct: float) -> void:
	sfx_vol_scale = clampf(pct, 0.0, 1.0)

func _apply_bgm_volume() -> void:
	if not bgm_player:
		return
	if bgm_vol_scale <= 0.005:
		bgm_player.volume_db = -80.0
	else:
		bgm_player.volume_db = linear_to_db(bgm_vol_scale) - 3.0

func play_bgm() -> void:
	if not streams.has("bgm") or not bgm_player:
		return
	if not bgm_player.playing:
		bgm_player.stream = streams["bgm"]
		_apply_bgm_volume()
		bgm_player.play()
		is_bgm_playing = true

func stop_bgm() -> void:
	if bgm_player and bgm_player.playing:
		bgm_player.stop()
		is_bgm_playing = false

func play_sfx(sound_name: String, pitch_range: float = 0.05, volume_db: float = 0.0) -> void:
	if not streams.has(sound_name) or sfx_players.is_empty():
		return
	if sfx_vol_scale <= 0.005:
		return # Muted
		
	var stream: AudioStream = streams[sound_name]
	var player := sfx_players[current_sfx_index]
	current_sfx_index = (current_sfx_index + 1) % max_sfx_voices
	
	player.stream = stream
	player.volume_db = volume_db + linear_to_db(sfx_vol_scale)
	if pitch_range > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	else:
		player.pitch_scale = 1.0
	player.play()

func play_sfx_at(sound_name: String, world_pos: Vector3, listener_pos: Vector3, max_dist: float = 45.0) -> void:
	if not streams.has(sound_name):
		return
	var dist := (world_pos - listener_pos).length()
	if dist > max_dist:
		return
	var atten_ratio := clampf(1.0 - (dist / max_dist), 0.0, 1.0)
	var vol_db := -24.0 * (1.0 - atten_ratio)
	play_sfx(sound_name, 0.04, vol_db)

# Static convenient helpers for anywhere in the codebase
static func play_sound(sound_name: String, pitch_range: float = 0.05, volume_db: float = 0.0) -> void:
	var am := ensure_instance()
	if am and is_instance_valid(am):
		am.play_sfx(sound_name, pitch_range, volume_db)

static func play_sound_at(sound_name: String, world_pos: Vector3, listener_pos: Vector3, max_dist: float = 45.0) -> void:
	var am := ensure_instance()
	if am and is_instance_valid(am):
		am.play_sfx_at(sound_name, world_pos, listener_pos, max_dist)
