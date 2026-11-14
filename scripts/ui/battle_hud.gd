class_name BattleHUD
extends CanvasLayer

signal restart_requested()
signal menu_requested()

var _player_hp_bar: ProgressBar
var player_hp_bar: ProgressBar:
	get:
		if not _player_hp_bar: _player_hp_bar = get_node_or_null("TopLeft/VBox/PlayerHPBar")
		return _player_hp_bar

var _player_hp_label: Label
var player_hp_label: Label:
	get:
		if not _player_hp_label: _player_hp_label = get_node_or_null("TopLeft/VBox/PlayerHPBar/Label")
		return _player_hp_label

var _revives_label: Label
var revives_label: Label:
	get:
		if not _revives_label: _revives_label = get_node_or_null("TopLeft/VBox/RevivesLabel")
		return _revives_label

var _base_hp_bar: ProgressBar
var base_hp_bar: ProgressBar:
	get:
		if not _base_hp_bar: _base_hp_bar = get_node_or_null("TopLeft/VBox/BaseHPBar")
		return _base_hp_bar

var _base_hp_label: Label
var base_hp_label: Label:
	get:
		if not _base_hp_label: _base_hp_label = get_node_or_null("TopLeft/VBox/BaseHPBar/Label")
		return _base_hp_label

var _wave_title_label: Label
var wave_title_label: Label:
	get:
		if not _wave_title_label: _wave_title_label = get_node_or_null("TopCenter/VBox/WaveTitleLabel")
		return _wave_title_label

var _wave_info_label: Label
var wave_info_label: Label:
	get:
		if not _wave_info_label: _wave_info_label = get_node_or_null("TopCenter/VBox/WaveInfoLabel")
		return _wave_info_label

var _ammo_label: Label
var ammo_label: Label:
	get:
		if not _ammo_label: _ammo_label = get_node_or_null("BottomRight/VBox/AmmoLabel")
		return _ammo_label

var _reload_label: Label
var reload_label: Label:
	get:
		if not _reload_label: _reload_label = get_node_or_null("BottomRight/VBox/ReloadLabel")
		return _reload_label

var _help_label: Label
var help_label: Label:
	get:
		if not _help_label: _help_label = get_node_or_null("BottomCenter/HelpLabel")
		return _help_label

var _crosshair_dot: Control
var crosshair_dot: Control:
	get:
		if not _crosshair_dot: _crosshair_dot = get_node_or_null("Center/Crosshair/Dot")
		return _crosshair_dot

var _crosshair_ring: Control
var crosshair_ring: Control:
	get:
		if not _crosshair_ring: _crosshair_ring = get_node_or_null("Center/Crosshair/Ring")
		return _crosshair_ring

var _victory_panel: Control
var victory_panel: Control:
	get:
		if not _victory_panel: _victory_panel = get_node_or_null("Overlay/VictoryPanel")
		return _victory_panel

var _defeat_panel: Control
var defeat_panel: Control:
	get:
		if not _defeat_panel: _defeat_panel = get_node_or_null("Overlay/DefeatPanel")
		return _defeat_panel

var _defeat_reason_label: Label
var defeat_reason_label: Label:
	get:
		if not _defeat_reason_label: _defeat_reason_label = get_node_or_null("Overlay/DefeatPanel/VBox/ReasonLabel")
		return _defeat_reason_label

var _victory_restart_btn: Button
var victory_restart_btn: Button:
	get:
		if not _victory_restart_btn: _victory_restart_btn = get_node_or_null("Overlay/VictoryPanel/VBox/RestartBtn")
		return _victory_restart_btn

var _victory_menu_btn: Button
var victory_menu_btn: Button:
	get:
		if not _victory_menu_btn: _victory_menu_btn = get_node_or_null("Overlay/VictoryPanel/VBox/MenuBtn")
		return _victory_menu_btn

var _defeat_restart_btn: Button
var defeat_restart_btn: Button:
	get:
		if not _defeat_restart_btn: _defeat_restart_btn = get_node_or_null("Overlay/DefeatPanel/VBox/RestartBtn")
		return _defeat_restart_btn

var _defeat_menu_btn: Button
var defeat_menu_btn: Button:
	get:
		if not _defeat_menu_btn: _defeat_menu_btn = get_node_or_null("Overlay/DefeatPanel/VBox/MenuBtn")
		return _defeat_menu_btn

func _ready() -> void:
	if victory_panel: victory_panel.visible = false
	if defeat_panel: defeat_panel.visible = false
	if reload_label: reload_label.visible = false
	if OS.has_feature("mobile") and help_label:
		help_label.visible = false
	
	if victory_restart_btn: victory_restart_btn.pressed.connect(func(): restart_requested.emit())
	if victory_menu_btn: victory_menu_btn.pressed.connect(func(): menu_requested.emit())
	if defeat_restart_btn: defeat_restart_btn.pressed.connect(func(): restart_requested.emit())
	if defeat_menu_btn: defeat_menu_btn.pressed.connect(func(): menu_requested.emit())

func update_player_health(current: float, max_val: float) -> void:
	if player_hp_bar:
		player_hp_bar.max_value = max_val
		player_hp_bar.value = current
	if player_hp_label:
		player_hp_label.text = "병사 HP: %d / %d" % [int(current), int(max_val)]

func update_revives(left: int, max_revives: int = 1) -> void:
	if revives_label:
		revives_label.text = "즉시 부활: %d / %d" % [left, max_revives]

func update_base_health(current: float, max_val: float) -> void:
	if base_hp_bar:
		base_hp_bar.max_value = max_val
		base_hp_bar.value = current
	if base_hp_label:
		base_hp_label.text = "참호 거점: %d / %d" % [int(current), int(max_val)]

func update_wave(wave_num: int, total_waves: int, info_str: String = "") -> void:
	if wave_title_label:
		wave_title_label.text = "WAVE %d / %d" % [wave_num, total_waves]
	if wave_info_label:
		wave_info_label.text = info_str

func update_ammo(current: int, reserve: int) -> void:
	if ammo_label:
		ammo_label.text = "%d / %d" % [current, reserve]

func set_reload_indicator(is_reloading: bool) -> void:
	if reload_label:
		reload_label.visible = is_reloading

func set_crosshair_aim(is_aiming: bool) -> void:
	if crosshair_ring:
		if is_aiming:
			crosshair_ring.scale = Vector2(0.5, 0.5)
			crosshair_ring.modulate = Color(0.2, 1.0, 0.4)
		else:
			crosshair_ring.scale = Vector2(1.0, 1.0)
			crosshair_ring.modulate = Color(1.0, 1.0, 1.0)

func show_victory() -> void:
	if victory_panel:
		victory_panel.visible = true

func show_defeat(reason: String) -> void:
	if defeat_panel:
		defeat_panel.visible = true
	if defeat_reason_label:
		if reason == "BASE_DESTROYED":
			defeat_reason_label.text = "참호 거점이 파괴되었습니다!"
		elif reason == "PLAYER_DEAD":
			defeat_reason_label.text = "병사가 전사하였습니다!"
		else:
			defeat_reason_label.text = "작전 실패: " + reason
