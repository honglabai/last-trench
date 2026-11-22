class_name GameSession
extends Node

signal session_started()
signal player_revived(revives_left: int, restored_hp: float)
signal session_defeat(reason: String)
signal session_victory()
signal credits_changed(new_credits: int)
signal weapon_equipped(weapon_id: String, level: int)
signal grenade_count_changed(count: int)

enum Result { NONE, VICTORY, DEFEAT }

const SAVE_FILE := "user://player_profile.cfg"

# Persistent across runs
static var credits: int = 5000
static var owned_weapons: Dictionary = { "k2c1_rifle": 1, "k5_pistol": 1 }
static var grenade_count: int = 3
static var max_grenades: int = 10
static var equipped_weapon_id: String = "k2c1_rifle"
static var is_profile_loaded: bool = false
static var current_instance: GameSession = null

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

static func _ensure_profile_loaded() -> void:
	if is_profile_loaded:
		return
	is_profile_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_FILE) == OK:
		credits = cfg.get_value("armory", "credits", 5000)
		if credits < 2000:
			credits = 5000
		var saved_owned = cfg.get_value("armory", "owned_weapons", { "k2c1_rifle": 1, "k5_pistol": 1 })
		if saved_owned is Dictionary and not saved_owned.is_empty():
			owned_weapons = saved_owned
		else:
			owned_weapons = { "k2c1_rifle": 1, "k5_pistol": 1 }
		# Ensure the basic pair (Rifle, Pistol) is always available
		if not owned_weapons.has("k2c1_rifle"):
			owned_weapons["k2c1_rifle"] = 1
		if not owned_weapons.has("k5_pistol"):
			owned_weapons["k5_pistol"] = 1
		if owned_weapons.has("k413_grenade"):
			owned_weapons.erase("k413_grenade")
		if cfg.has_section_key("armory", "grenade_count"):
			grenade_count = clampi(int(cfg.get_value("armory", "grenade_count", 3)), 0, max_grenades)
		else:
			grenade_count = 3
		equipped_weapon_id = cfg.get_value("armory", "equipped_weapon_id", "k2c1_rifle")
		if equipped_weapon_id == "k413_grenade":
			equipped_weapon_id = "k2c1_rifle"
	else:
		credits = 5000
		owned_weapons = { "k2c1_rifle": 1, "k5_pistol": 1 }
		grenade_count = 3
		equipped_weapon_id = "k2c1_rifle"
		save_profile()

static func save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("armory", "credits", credits)
	cfg.set_value("armory", "owned_weapons", owned_weapons)
	cfg.set_value("armory", "grenade_count", grenade_count)
	cfg.set_value("armory", "equipped_weapon_id", equipped_weapon_id)
	cfg.save(SAVE_FILE)

static func get_grenade_count() -> int:
	_ensure_profile_loaded()
	return grenade_count

static func set_grenade_count(count: int) -> void:
	_ensure_profile_loaded()
	grenade_count = clampi(count, 0, max_grenades)
	save_profile()
	if current_instance and is_instance_valid(current_instance):
		current_instance.grenade_count_changed.emit(grenade_count)

static func ensure_initial_grenades(min_count: int = 3) -> void:
	_ensure_profile_loaded()
	if grenade_count < min_count:
		grenade_count = min_count
		save_profile()
		if current_instance and is_instance_valid(current_instance):
			current_instance.grenade_count_changed.emit(grenade_count)

static func use_grenade() -> bool:
	_ensure_profile_loaded()
	if grenade_count > 0:
		grenade_count -= 1
		save_profile()
		if current_instance and is_instance_valid(current_instance):
			current_instance.grenade_count_changed.emit(grenade_count)
		return true
	return false

static func add_grenades(amount: int) -> void:
	_ensure_profile_loaded()
	grenade_count = mini(max_grenades, grenade_count + amount)
	save_profile()
	if current_instance and is_instance_valid(current_instance):
		current_instance.grenade_count_changed.emit(grenade_count)

static func add_credits(amount: int) -> void:
	_ensure_profile_loaded()
	credits += amount
	save_profile()
	if current_instance and is_instance_valid(current_instance):
		current_instance.credits_changed.emit(credits)

static func spend_credits(amount: int) -> bool:
	_ensure_profile_loaded()
	if credits >= amount:
		credits -= amount
		save_profile()
		if current_instance and is_instance_valid(current_instance):
			current_instance.credits_changed.emit(credits)
		return true
	return false

static func get_weapon_level(w_id: String) -> int:
	_ensure_profile_loaded()
	return int(owned_weapons.get(w_id, 0))

static func buy_weapon(w_id: String, cost: int) -> bool:
	_ensure_profile_loaded()
	if owned_weapons.has(w_id):
		return true
	if spend_credits(cost):
		owned_weapons[w_id] = 1
		save_profile()
		return true
	return false

static func upgrade_weapon(w_id: String, cost: int) -> bool:
	_ensure_profile_loaded()
	var cur_lvl := get_weapon_level(w_id)
	if cur_lvl <= 0 or cur_lvl >= 5:
		return false
	if spend_credits(cost):
		owned_weapons[w_id] = cur_lvl + 1
		save_profile()
		return true
	return false

static func equip_weapon(w_id: String) -> void:
	_ensure_profile_loaded()
	if owned_weapons.has(w_id):
		equipped_weapon_id = w_id
		save_profile()

static func get_next_owned_weapon(current_id: String = "") -> String:
	_ensure_profile_loaded()
	var cur := current_id if current_id != "" else equipped_weapon_id
	var weapon_order := [
		"k2c1_rifle",
		"k5_pistol",
		"m4a1_carbine",
		"hk416_elite",
		"scar_h_battle",
		"k14_sniper",
		"rpg7_launcher",
		"hyungung_atgm"
	]
	var owned: Array[String] = []
	for w in weapon_order:
		if owned_weapons.has(w) and w != "k413_grenade":
			owned.append(w)
	for w in owned_weapons.keys():
		var sw := str(w)
		if not owned.has(sw) and sw != "k413_grenade":
			owned.append(sw)
	if owned.is_empty():
		return cur
	var idx := owned.find(cur)
	if idx == -1:
		return owned[0]
	var next_idx := (idx + 1) % owned.size()
	return owned[next_idx]

func _enter_tree() -> void:
	current_instance = self
	GameSession._ensure_profile_loaded()

func _ready() -> void:
	current_instance = self
	GameSession._ensure_profile_loaded()

func _process(delta: float) -> void:
	if is_invulnerable:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0.0:
			is_invulnerable = false
			if current_player and is_instance_valid(current_player):
				current_player.is_invulnerable = false

func start_session(player: PlayerController, base: BaseObjective, director: WaveDirector = null) -> void:
	current_instance = self
	current_player = player
	current_base = base
	current_wave_director = director
	
	revives_remaining = max_revives_per_run
	current_result = Result.NONE
	defeat_reason = ""
	is_invulnerable = false
	invulnerability_timer = 0.0
	
	_ensure_profile_loaded()
	
	if current_player and is_instance_valid(current_player):
		current_player.is_invulnerable = false
		if not current_player.player_died.is_connected(_on_player_died):
			current_player.player_died.connect(_on_player_died)
			
		# Reset weapon ammo states for a fresh combat run and load initial weapon
		var w_id = GameSession.equipped_weapon_id
		var w_lvl = GameSession.get_weapon_level(w_id)
		if current_player.weapon:
			current_player.weapon.reset_all_ammo_states()
			current_player.weapon.load_weapon_data(w_id, w_lvl)
			
	if current_base and is_instance_valid(current_base):
		if not current_base.base_destroyed.is_connected(_on_base_destroyed):
			current_base.base_destroyed.connect(_on_base_destroyed)
			
	if current_wave_director and is_instance_valid(current_wave_director):
		if not current_wave_director.run_victory.is_connected(_on_victory):
			current_wave_director.run_victory.connect(_on_victory)
		if not current_wave_director.enemy_killed.is_connected(_on_enemy_killed):
			current_wave_director.enemy_killed.connect(_on_enemy_killed)
		if not current_wave_director.wave_cleared.is_connected(_on_wave_cleared):
			current_wave_director.wave_cleared.connect(_on_wave_cleared)
			
	session_started.emit()

func _on_enemy_killed(_enemy, _rem, _act) -> void:
	# Award credits for enemy takedown
	GameSession.add_credits(25)
	credits_changed.emit(GameSession.credits)

func _on_wave_cleared(wave_num: int) -> void:
	# Award escalating credits for wave defense completion
	var wave_reward := 250 + (wave_num * 60)
	if wave_num == 5:
		wave_reward += 500 # Boss 1 bonus
	elif wave_num == 10:
		wave_reward += 1000 # Boss 2 bonus
	elif wave_num == 15:
		wave_reward += 2500 # Final Boss victory bonus
	GameSession.add_credits(wave_reward)
	credits_changed.emit(GameSession.credits)

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
