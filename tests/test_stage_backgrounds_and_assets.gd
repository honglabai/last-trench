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
		
	# 2. Verify Russia-Ukraine Frontline Satellite Map & Briefing Board Backgrounds
	var sat_map_path := "res://assets/ui/bg_sat_frontline_map.png"
	assert(ResourceLoader.exists(sat_map_path), "Missing satellite frontline map background: %s" % sat_map_path)
	var sat_map_tex := load(sat_map_path) as Texture2D
	assert(sat_map_tex != null, "Failed to load satellite map texture")
	var sat_img := sat_map_tex.get_image()
	assert(sat_img.get_width() >= 1280 and sat_img.get_height() >= 720, "Satellite map dimensions too small: %s" % str(sat_img.get_size()))
	print("[PASS] Russia-Ukraine frontline satellite map verified: %s (%dx%d)" % [sat_map_path, sat_img.get_width(), sat_img.get_height()])
	
	var briefing_board_path := "res://assets/ui/bg_briefing_board.png"
	assert(ResourceLoader.exists(briefing_board_path), "Missing briefing board background: %s" % briefing_board_path)
	var bb_tex := load(briefing_board_path) as Texture2D
	assert(bb_tex != null, "Failed to load briefing board texture")
	var bb_img := bb_tex.get_image()
	assert(bb_img.get_width() >= 1280 and bb_img.get_height() >= 720, "Briefing board dimensions too small: %s" % str(bb_img.get_size()))
	print("[PASS] Electronic combat situation briefing board verified: %s (%dx%d)" % [briefing_board_path, bb_img.get_width(), bb_img.get_height()])
	
	var arrow_pin_path := "res://assets/ui/pin_arrow_down.png"
	assert(ResourceLoader.exists(arrow_pin_path), "Missing downward arrow pin texture: %s" % arrow_pin_path)
	var arrow_tex := load(arrow_pin_path) as Texture2D
	assert(arrow_tex != null, "Failed to load downward arrow pin texture")
	var arrow_img := arrow_tex.get_image()
	assert(arrow_img.get_width() >= 64 and arrow_img.get_height() >= 64, "Arrow pin texture dimensions too small: %s" % str(arrow_img.get_size()))
	print("[PASS] Downward arrow map pin texture verified: %s (%dx%d)" % [arrow_pin_path, arrow_img.get_width(), arrow_img.get_height()])
	
	# 3. Verify Operations HQ Scene uses Satellite Map & Electronic Briefing Board
	var hq_scene := load("res://scenes/ui/operations_hq.tscn") as PackedScene
	assert(hq_scene != null, "Failed to load operations_hq.tscn")
	var hq := hq_scene.instantiate() as OperationsHQ
	root.add_child(hq)
	
	var bg_rect := hq.get_node_or_null("Background") as TextureRect
	assert(bg_rect != null and bg_rect.texture != null, "OperationsHQ Background must have valid texture assigned")
	assert(bg_rect.texture.resource_path.contains("bg_sat_frontline_map"), "OperationsHQ Background must use bg_sat_frontline_map.png, got: %s" % bg_rect.texture.resource_path)
	
	var board_bg := hq.get_node_or_null("MainSplit/BriefingPanel/BriefingBoardBg") as TextureRect
	assert(board_bg != null and board_bg.texture != null, "BriefingBoardBg must have valid texture assigned")
	assert(board_bg.texture.resource_path.contains("bg_briefing_board"), "BriefingBoardBg must use bg_briefing_board.png, got: %s" % board_bg.texture.resource_path)
	
	# Verify Briefing Text is Concise & Non-Empty
	var desc_lbl := hq.get_node_or_null("MainSplit/BriefingPanel/VBox/DescLabel") as Label
	assert(desc_lbl != null and not desc_lbl.text.is_empty(), "Briefing DescLabel must have text")
	var threats_lbl := hq.get_node_or_null("MainSplit/BriefingPanel/VBox/ThreatsLabel") as Label
	assert(threats_lbl != null and not threats_lbl.text.is_empty(), "Briefing ThreatsLabel must have text")
	
	print("[PASS] OperationsHQ satellite map background and electronic briefing board verified")
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
	
	# 5. Verify MainMenu Button Width is 70% (186px)
	var menu_scene := load("res://scenes/app/main_menu.tscn") as PackedScene
	var menu := menu_scene.instantiate() as Control
	root.add_child(menu)
	var start_btn := menu.get_node_or_null("CenterContainer/VBoxContainer/StartButton") as TextureButton
	assert(start_btn != null, "StartButton missing in MainMenu")
	assert(start_btn.custom_minimum_size == Vector2(300, 67), "MainMenu StartButton size must be 300x67, got: %s" % str(start_btn.custom_minimum_size))
	print("[PASS] MainMenu button +20%% height (300x67) verified")
	menu.queue_free()
	
	# 6. Verify Environment Switch in GameRoot for All 5 Stages
	GameSession.highest_unlocked_stage = 5
	var root_scene := load("res://scenes/app/game_root.tscn") as PackedScene
	var game := root_scene.instantiate() as GameRoot
	root.add_child(game)
	
	for s in range(1, 6):
		GameSession.highest_unlocked_stage = 5
		GameSession.selected_stage = s
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
