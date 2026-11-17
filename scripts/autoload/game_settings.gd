class_name GameSettings
extends RefCounted

const SETTINGS_FILE := "user://settings.cfg"

# Controls & Sensitivity
static var aim_sensitivity: float = 0.60 # 60% default: steady & controllable

# Audio Volumes (0.0 ~ 1.0 scale)
static var master_volume: float = 0.85
static var bgm_volume: float = 0.70
static var sfx_volume: float = 0.85

static var is_loaded: bool = false

# --- Controls ---
static func get_aim_sensitivity() -> float:
	_ensure_loaded()
	return aim_sensitivity

static func set_aim_sensitivity(val: float) -> void:
	aim_sensitivity = clampf(val, 0.15, 2.0)
	save_settings()

# --- Audio ---
static func get_master_volume() -> float:
	_ensure_loaded()
	return master_volume

static func set_master_volume(val: float) -> void:
	master_volume = clampf(val, 0.0, 1.0)
	var am := AudioManager.ensure_instance()
	if am and is_instance_valid(am):
		am.set_master_volume(master_volume)
	save_settings()

static func get_bgm_volume() -> float:
	_ensure_loaded()
	return bgm_volume

static func set_bgm_volume(val: float) -> void:
	bgm_volume = clampf(val, 0.0, 1.0)
	var am := AudioManager.ensure_instance()
	if am and is_instance_valid(am):
		am.set_bgm_volume(bgm_volume)
	save_settings()

static func get_sfx_volume() -> float:
	_ensure_loaded()
	return sfx_volume

static func set_sfx_volume(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)
	var am := AudioManager.ensure_instance()
	if am and is_instance_valid(am):
		am.set_sfx_volume(sfx_volume)
	save_settings()

static func _ensure_loaded() -> void:
	if is_loaded:
		return
	is_loaded = true
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_FILE)
	if err == OK:
		aim_sensitivity = config.get_value("controls", "aim_sensitivity", 0.60)
		master_volume = config.get_value("audio", "master_volume", 0.85)
		bgm_volume = config.get_value("audio", "bgm_volume", 0.70)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.85)
	else:
		aim_sensitivity = 0.60
		master_volume = 0.85
		bgm_volume = 0.70
		sfx_volume = 0.85

static func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("controls", "aim_sensitivity", aim_sensitivity)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "bgm_volume", bgm_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.save(SETTINGS_FILE)

static func toggle_fullscreen() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			var doc = window.document;
			var docEl = doc.documentElement;
			var req = docEl.requestFullscreen || docEl.webkitRequestFullScreen || docEl.mozRequestFullScreen || docEl.msRequestFullscreen;
			var exit = doc.exitFullscreen || doc.webkitExitFullscreen || doc.mozCancelFullScreen || doc.msExitFullscreen;
			if (!doc.fullscreenElement && !doc.webkitFullscreenElement) {
				if (req) {
					req.call(docEl).then(function() {
						if (screen.orientation && screen.orientation.lock) {
							screen.orientation.lock('landscape').catch(function(){});
						}
					}).catch(function(){});
				}
			} else {
				if (exit) exit.call(doc).catch(function(){});
			}
		""")
	else:
		var mode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
