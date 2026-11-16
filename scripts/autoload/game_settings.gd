class_name GameSettings
extends RefCounted

const SETTINGS_FILE := "user://settings.cfg"

# Default sensitivity: 0.60 (60% of original, steady & controllable)
static var aim_sensitivity: float = 0.60
static var is_loaded: bool = false

static func get_aim_sensitivity() -> float:
	_ensure_loaded()
	return aim_sensitivity

static func set_aim_sensitivity(val: float) -> void:
	aim_sensitivity = clampf(val, 0.20, 2.0)
	save_settings()

static func _ensure_loaded() -> void:
	if is_loaded:
		return
	is_loaded = true
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_FILE)
	if err == OK:
		aim_sensitivity = config.get_value("controls", "aim_sensitivity", 0.60)
	else:
		aim_sensitivity = 0.60

static func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("controls", "aim_sensitivity", aim_sensitivity)
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
