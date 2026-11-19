extends SceneTree

const EnemyProjectileScript = preload("res://scripts/effects/enemy_projectile.gd")

func _init() -> void:
	print("--- Running Test Suite: Enemy Modern Warfare Weapons & Projectiles & 5-Stage Region ---")
	test_weapon_textures_exist()
	test_enemy_scenes_have_weapons()
	test_enemy_projectile_mechanics()
	test_5_stages_wave_plan()
	test_wave_director_stage_progression()
	print("=== ALL ENEMY WEAPONS, PROJECTILES & 5-STAGE TESTS PASSED! ===")
	quit(0)

func test_weapon_textures_exist() -> void:
	print("[Test 1] Checking Modern Warfare enemy weapon textures...")
	var textures := [
		"res://assets/textures/weapons/tex_wpn_enemy_ak12.png",
		"res://assets/textures/weapons/tex_wpn_enemy_rpg7v2.png",
		"res://assets/textures/weapons/tex_wpn_enemy_drone_turret.png",
		"res://assets/textures/weapons/tex_wpn_enemy_robot_chaingun.png",
		"res://assets/textures/weapons/tex_wpn_boss_drone_commander.png",
		"res://assets/textures/weapons/tex_wpn_boss_siege_railgun.png",
		"res://assets/textures/weapons/tex_wpn_boss_apex_battery.png"
	]
	for t_path in textures:
		assert(ResourceLoader.exists(t_path), "Texture missing: " + t_path)
		var tex := load(t_path) as Texture2D
		assert(tex != null, "Failed to load texture: " + t_path)
		assert(tex.get_width() > 0 and tex.get_height() > 0, "Texture dimensions invalid: " + t_path)
	print(" -> All 7 Modern Warfare enemy weapon textures verified successfully.")

func test_enemy_scenes_have_weapons() -> void:
	print("[Test 2] Checking enemy scenes for rendered weapon systems...")
	
	# 1. Basic Infantry (AK-12)
	var scn_inf := load("res://scenes/actors/enemy_infantry.tscn") as PackedScene
	var inst_inf := scn_inf.instantiate() as CharacterBody3D
	var wpn_inf := inst_inf.get_node_or_null("VisualMesh/WeaponSprite") as Sprite3D
	assert(wpn_inf != null, "Infantry must have WeaponSprite")
	assert(wpn_inf.texture != null, "Infantry WeaponSprite texture missing")
	inst_inf.free()
	
	# 2. RPG Infantry (RPG-7V2)
	var scn_rpg := load("res://scenes/actors/enemy_rpg.tscn") as PackedScene
	var inst_rpg := scn_rpg.instantiate() as CharacterBody3D
	var wpn_rpg := inst_rpg.get_node_or_null("VisualMesh/WeaponSprite") as Sprite3D
	assert(wpn_rpg != null, "RPG Soldier must have WeaponSprite")
	assert(wpn_rpg.texture != null, "RPG WeaponSprite texture missing")
	inst_rpg.free()
	
	# 3. Attack Drone (Turret & Missile Pods)
	var scn_drone := load("res://scenes/actors/enemy_drone.tscn") as PackedScene
	var inst_drone := scn_drone.instantiate() as CharacterBody3D
	var wpn_drone := inst_drone.get_node_or_null("VisualMesh/TurretSprite") as Sprite3D
	assert(wpn_drone != null, "Drone must have TurretSprite")
	inst_drone.free()
	
	# 4. Combat Robot (Dual Chainguns)
	var scn_robot := load("res://scenes/actors/enemy_robot.tscn") as PackedScene
	var inst_robot := scn_robot.instantiate() as CharacterBody3D
	var wpn_l := inst_robot.get_node_or_null("VisualMesh/LeftWeaponSprite") as Sprite3D
	var wpn_r := inst_robot.get_node_or_null("VisualMesh/RightWeaponSprite") as Sprite3D
	assert(wpn_l != null and wpn_r != null, "Combat robot must have Left and Right weapon sprites")
	inst_robot.free()
	
	# 5. Boss 1 (Drone Swarm Commander)
	var scn_b1 := load("res://scenes/actors/boss_drone_commander.tscn") as PackedScene
	var inst_b1 := scn_b1.instantiate() as CharacterBody3D
	var wpn_b1 := inst_b1.get_node_or_null("VisualMesh/WeaponSuiteSprite") as Sprite3D
	assert(wpn_b1 != null, "Boss 1 must have WeaponSuiteSprite")
	inst_b1.free()
	
	# 6. Boss 2 (Armored Robot Boss)
	var scn_b2 := load("res://scenes/actors/boss_armored_robot.tscn") as PackedScene
	var inst_b2 := scn_b2.instantiate() as CharacterBody3D
	var wpn_b2_l := inst_b2.get_node_or_null("VisualMesh/LeftRailgunSprite") as Sprite3D
	var wpn_b2_r := inst_b2.get_node_or_null("VisualMesh/RightRailgunSprite") as Sprite3D
	assert(wpn_b2_l != null and wpn_b2_r != null, "Boss 2 must have twin railgun sprites")
	inst_b2.free()
	
	# 7. Boss 3 (Final Assault Boss)
	var scn_b3 := load("res://scenes/actors/boss_final_assault.tscn") as PackedScene
	var inst_b3 := scn_b3.instantiate() as CharacterBody3D
	var wpn_b3 := inst_b3.get_node_or_null("VisualMesh/BatterySprite") as Sprite3D
	assert(wpn_b3 != null, "Boss 3 must have BatterySprite")
	inst_b3.free()
	print(" -> All 7 enemy weapon system scene nodes verified successfully.")

func test_enemy_projectile_mechanics() -> void:
	print("[Test 3] Testing EnemyProjectile flight & impact mechanics...")
	var scn_proj := load("res://scenes/effects/enemy_projectile.tscn") as PackedScene
	assert(scn_proj != null, "EnemyProjectile scene must exist")
	
	# Test Bullet
	var bullet = scn_proj.instantiate()
	root.add_child(bullet)
	var start := Vector3(0, 1, -30)
	var dest := Vector3(0, 1, 0)
	bullet.setup(start, dest, EnemyProjectileScript.ProjectileType.BULLET, 12.0, 60.0, 0.0)
	assert(bullet.speed == 60.0, "Bullet speed must be 60.0")
	assert(bullet.damage == 12.0, "Bullet damage must be 12.0")
	bullet._process(0.1) # Fly 6 meters
	assert(bullet.distance_traveled > 5.5, "Bullet must travel forward physically")
	bullet.impact(dest)
	assert(bullet.has_impacted, "Bullet must impact")
	
	# Test Rocket with splash damage
	var rocket = scn_proj.instantiate()
	root.add_child(rocket)
	rocket.setup(start, dest, EnemyProjectileScript.ProjectileType.ROCKET, 35.0, 34.0, 5.0)
	assert(rocket.projectile_type == EnemyProjectileScript.ProjectileType.ROCKET, "Type must be ROCKET")
	assert(rocket.blast_radius == 5.0, "Blast radius must be 5.0")
	rocket.impact(dest)
	assert(rocket.has_impacted, "Rocket must impact and explode")
	print(" -> Enemy projectile flight and detonation verified successfully.")

func test_5_stages_wave_plan() -> void:
	print("[Test 4] Verifying 5 stages and difficulty wave counts in wave_plan.json...")
	var file := FileAccess.open("res://data/wave_plan.json", FileAccess.READ)
	assert(file != null, "wave_plan.json must exist")
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	assert(err == OK, "wave_plan.json must be valid JSON")
	var data: Dictionary = json.data
	
	assert(int(data.get("total_stages", 0)) == 5, "Total stages in region must be 5")
	var stages: Array = data.get("stages", [])
	assert(stages.size() == 5, "stages array must have 5 entries")
	
	var expected_waves := [2, 3, 4, 5, 6]
	for i in range(5):
		var st: Dictionary = stages[i]
		assert(int(st.get("stage_id", 0)) == (i + 1), "Stage id must match")
		var w_count := int(st.get("total_waves", 0))
		assert(w_count == expected_waves[i], "Stage %d wave count must be %d (got %d)" % [i + 1, expected_waves[i], w_count])
		var st_waves: Array = st.get("waves", [])
		assert(st_waves.size() == expected_waves[i], "Stage %d wave array length must match" % [i + 1])
	print(" -> 5-Stage Region plan verified: Wave counts = [2, 3, 4, 5, 6] (Easy -> Extreme).")

func test_wave_director_stage_progression() -> void:
	print("[Test 5] Testing WaveDirector stage initialization & progression...")
	var wd := WaveDirector.new()
	root.add_child(wd)
	assert(wd.max_stages_in_region == 5, "WaveDirector max_stages_in_region must be 5")
	
	# Load stage 1
	wd.start_stage(1)
	assert(wd.current_stage_id == 1, "Current stage must be 1")
	assert(wd.total_waves_in_stage == 2, "Stage 1 must have 2 waves")
	
	# Load stage 3
	wd.start_stage(3)
	assert(wd.current_stage_id == 3, "Current stage must be 3")
	assert(wd.total_waves_in_stage == 4, "Stage 3 must have 4 waves")
	
	# Load stage 5
	wd.start_stage(5)
	assert(wd.current_stage_id == 5, "Current stage must be 5")
	assert(wd.total_waves_in_stage == 6, "Stage 5 must have 6 waves")
	
	wd.queue_free()
	print(" -> WaveDirector stage progression verified successfully.")
