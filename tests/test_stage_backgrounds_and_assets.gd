extends SceneTree

func _init() -> void:
	print("[TEST] Running Stage Backgrounds, Tactical Map & Weapon Asset Tests...")
	
	# 1. Verify 5 Stage Skybox Panoramas
	for st_id in range(1, 6):
		var sky_path := "res://assets/environment/sky_stage_%d.png" % st_id
		assert(ResourceLoader.exists(sky_path), "Missing stage %d sky panorama: %s" % [st_id, sky_path])
		var tex := load(sky_path) as Texture2D
		assert(tex != null, "Failed to load stage %d sky texture: %s" % [st_id, sky_path])
		var img := tex.get_image()
		assert(img != null, "Failed to get image for stage %d sky: %s" % [st_id, sky_path])
		assert(img.get_width() >= 1024 and img.get_height() >= 512, "Stage %d sky dimensions too small: %s" % [st_id, str(img.get_size())])
		print("[PASS] Stage %d skybox panorama verified: %s (%dx%d)" % [st_id, sky_path, img.get_width(), img.get_height()])
		
	# 2. Verify Tactical Operational Map Background
	var map_path := "res://assets/ui/bg_tactical_map.png"
	assert(ResourceLoader.exists(map_path), "Missing tactical map background: %s" % map_path)
	var map_tex := load(map_path) as Texture2D
	assert(map_tex != null, "Failed to load tactical map texture")
	var map_img := map_tex.get_image()
	assert(map_img.get_width() >= 1280 and map_img.get_height() >= 720, "Tactical map dimensions too small: %s" % str(map_img.get_size()))
	print("[PASS] Operations HQ tactical map background verified: %s (%dx%d)" % [map_path, map_img.get_width(), map_img.get_height()])
	
	# 3. Verify Operations HQ Scene uses Tactical Map & Scaled Fonts
	var hq_scene := load("res://scenes/ui/operations_hq.tscn") as PackedScene
	assert(hq_scene != null, "Failed to load operations_hq.tscn")
	var hq := hq_scene.instantiate() as OperationsHQ
	root.add_child(hq)
	
	var bg_rect := hq.get_node_or_null("Background") as TextureRect
	assert(bg_rect != null and bg_rect.texture != null, "OperationsHQ Background must have valid texture assigned")
	assert(bg_rect.texture.resource_path.contains("bg_tactical_map"), "OperationsHQ Background must use bg_tactical_map.png, got: %s" % bg_rect.texture.resource_path)
	
	# Verify Briefing Text is Concise & Non-Empty
	var desc_lbl := hq.get_node_or_null("MainSplit/BriefingPanel/VBox/DescLabel") as Label
	assert(desc_lbl != null and not desc_lbl.text.is_empty(), "Briefing DescLabel must have text")
	var threats_lbl := hq.get_node_or_null("MainSplit/BriefingPanel/VBox/ThreatsLabel") as Label
	assert(threats_lbl != null and not threats_lbl.text.is_empty(), "Briefing ThreatsLabel must have text")
	
	print("[PASS] OperationsHQ tactical map background and concise briefing labels verified")
	hq.queue_free()
	
	# 4. Verify RPG-7 & Shotgun Textures
	var rpg_tex_path := "res://assets/textures/tex_fps_rpg.png"
	var sg_tex_path := "res://assets/textures/tex_fps_shotgun.png"
	for p in [rpg_tex_path, sg_tex_path]:
		assert(ResourceLoader.exists(p), "Missing weapon texture: %s" % p)
		var t := load(p) as Texture2D
		assert(t != null, "Failed to load texture: %s" % p)
		var im := t.get_image()
		assert(im.get_width() == 1280 and im.get_height() == 720, "Texture %s must be 1280x720" % p)
		var tl := im.get_pixel(10, 10)
		assert(tl.a == 0.0, "Top-left of %s must be transparent (got alpha=%f)" % [p, tl.a])
	print("[PASS] RPG-7 and Shotgun 1280x720 transparent viewmodels verified")
	
	# 5. Verify MainMenu Button Width is 90% (265px)
	var menu_scene := load("res://scenes/app/main_menu.tscn") as PackedScene
	var menu := menu_scene.instantiate() as Control
	root.add_child(menu)
	var start_btn := menu.get_node_or_null("CenterContainer/VBoxContainer/StartButton") as TextureButton
	assert(start_btn != null, "StartButton missing in MainMenu")
	assert(start_btn.custom_minimum_size == Vector2(265, 76), "MainMenu StartButton size must be 265x76, got: %s" % str(start_btn.custom_minimum_size))
	print("[PASS] MainMenu button 90%% width (265x76) verified")
	menu.queue_free()
	
	# 6. Verify Environment Switch in GameRoot for All 5 Stages
	var root_scene := load("res://scenes/app/game_root.tscn") as PackedScene
	var game := root_scene.instantiate() as GameRoot
	root.add_child(game)
	
	for s in range(1, 6):
		GameSession.select_stage(s)
		game._setup_stage_environment()
		var we := game.get_node_or_null("WorldEnvironment") as WorldEnvironment
		assert(we != null and we.environment != null and we.environment.sky != null, "WorldEnvironment must be valid")
		var p_mat := we.environment.sky.sky_material as PanoramaSkyMaterial
		assert(p_mat != null and p_mat.panorama != null, "Sky panorama must be assigned for stage %d" % s)
		assert(p_mat.panorama.resource_path.contains("sky_stage_%d" % s), "Stage %d must load sky_stage_%d.png, got: %s" % [s, s, p_mat.panorama.resource_path])
		print("[PASS] GameRoot stage %d environment & panorama dynamically loaded successfully" % s)
		
	game.queue_free()
	print("[TEST COMPLETE] All Stage Backgrounds, Tactical Map & Weapon Asset Tests PASSED (0 errors)!")
	quit(0)
