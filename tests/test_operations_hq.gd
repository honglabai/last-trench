extends SceneTree

func _init() -> void:
	print("[TEST] Running Operations HQ, Stage Selection & Progression Tests...")
	
	# 1. Test Operations HQ Scene Instantiation
	var hq_scene := load("res://scenes/ui/operations_hq.tscn") as PackedScene
	assert(hq_scene != null, "OperationsHQ scene must exist and load successfully")
	
	const OperationsHQScript = preload("res://scripts/ui/operations_hq.gd")
	var hq = hq_scene.instantiate()
	root.add_child(hq)
	hq._ready()
	
	assert(hq.stage_container != null, "StageContainer must exist in OperationsHQ")
	assert(hq.stage_card_buttons.size() == 5, "Must have exactly 5 stage cards (Stages 1~5)")
	print("[PASS] OperationsHQ instantiated with 5 stage cards")
	
	# 2. Test Stage 1 Default Unlocked, Stages 2~5 Locked initially
	GameSession.highest_unlocked_stage = 1
	GameSession.cleared_stages = {}
	GameSession.select_stage(1)
	hq.refresh_hq_ui()
	
	assert(GameSession.is_stage_unlocked(1) == true, "Stage 1 must be unlocked by default")
	assert(GameSession.is_stage_unlocked(2) == false, "Stage 2 must be locked initially")
	assert(GameSession.is_stage_unlocked(5) == false, "Stage 5 must be locked initially")
	print("[PASS] Initial stage lock state verified: Stage 1 unlocked, 2~5 locked")
	
	# 3. Test Stage Information & Difficulty Escalation
	var st1: Dictionary = hq.get_stage_info(1)
	var st2: Dictionary = hq.get_stage_info(2)
	var st3: Dictionary = hq.get_stage_info(3)
	var st4: Dictionary = hq.get_stage_info(4)
	var st5: Dictionary = hq.get_stage_info(5)
	
	assert(st1.get("total_waves") == 10, "Stage 1 must have 10 waves")
	assert(st2.get("total_waves") == 10, "Stage 2 must have 10 waves")
	assert(st3.get("total_waves") == 10, "Stage 3 must have 10 waves")
	assert(st4.get("total_waves") == 10, "Stage 4 must have 10 waves")
	assert(st5.get("total_waves") == 10, "Stage 5 must have 10 waves")
	
	assert("보통" in st1.get("difficulty"), "Stage 1 difficulty must be 보통 (EASY)")
	assert("숙련" in st2.get("difficulty"), "Stage 2 difficulty must be 숙련 (NORMAL)")
	assert("정예" in st3.get("difficulty"), "Stage 3 difficulty must be 정예 (HARD)")
	assert("특수작전" in st4.get("difficulty"), "Stage 4 difficulty must be 특수작전 (VERY HARD)")
	assert("최종 결전" in st5.get("difficulty"), "Stage 5 difficulty must be 최종 결전 (EXTREME / HELL)")
	print("[PASS] Verified 5 Stages, each with 10 waves and escalating difficulty")
	
	# 4. Test Stage Selection & Briefing Refresh
	hq.stage_card_buttons[1].pressed.emit()
	assert(hq.selected_stage_id == 1, "Selected stage should be 1")
	assert("제1작전" in hq.briefing_title.text, "Briefing title should display Stage 1")
	
	# Attempt to select locked Stage 2 -> should remain on 1
	hq.stage_card_buttons[2].pressed.emit()
	assert(hq.selected_stage_id == 1, "Selecting locked Stage 2 should not change selected_stage_id")
	print("[PASS] Locked stage selection rejection verified")
	
	# 5. Test Stage Completion & Progression Unlocking
	GameSession.on_stage_completed(1, 1500)
	assert(GameSession.is_stage_cleared(1) == true, "Stage 1 must now be cleared")
	assert(GameSession.is_stage_unlocked(2) == true, "Stage 2 must now be unlocked after clearing Stage 1")
	
	hq.refresh_hq_ui()
	# Now selecting Stage 2 should succeed!
	hq.stage_card_buttons[2].pressed.emit()
	assert(hq.selected_stage_id == 2, "Selecting unlocked Stage 2 must succeed")
	assert("제2작전" in hq.briefing_title.text, "Briefing title should display Stage 2")
	print("[PASS] Stage 1 completion and Stage 2 unlock verified")
	
	# Complete Stages 2, 3, 4, 5
	GameSession.on_stage_completed(2, 2500)
	GameSession.on_stage_completed(3, 3500)
	GameSession.on_stage_completed(4, 5000)
	GameSession.on_stage_completed(5, 8000)
	
	assert(GameSession.is_stage_cleared(5) == true, "Stage 5 must be cleared")
	hq.refresh_hq_ui()
	assert(hq.progress_bar.value == 5, "Progress bar should show 5/5 cleared")
	assert("100%" in hq.progress_label.text, "Progress label should show 100%")
	print("[PASS] Full 5-stage progression to 100% campaign completion verified")
	
	# 6. Test Font & Glyph Safety (No boxed tofu or unsupported symbols)
	var forbidden_glyphs := ["✓", "★", "·", "■", "▲", "▼", "◆", "※"]
	var check_strings := [
		hq.briefing_title.text,
		hq.briefing_diff_label.text,
		hq.briefing_waves_label.text,
		hq.briefing_desc_label.text,
		hq.briefing_threats_label.text,
		hq.briefing_reward_label.text,
		hq.deploy_button.text,
		hq.progress_label.text,
		hq.credits_label.text
	]
	for c_btn in hq.stage_card_buttons.values():
		check_strings.append(c_btn.text)
		
	for s in check_strings:
		for fg in forbidden_glyphs:
			assert(not fg in s, "Text must not contain glyph '%s': %s" % [fg, s])
	print("[PASS] Font and glyph safety verified: ZERO boxed tofu glyphs across all Operations HQ text")
	
	hq.queue_free()
	print("[TEST COMPLETE] Operations HQ tests passed with 0 errors!")
	quit(0)
