extends SceneTree

func _init() -> void:
	print("[TEST] Running 5-Stage Campaign Flow, 10 Waves per Stage & HQ Progression Tests...")
	
	# 1. Test wave_plan.json structure
	var file := FileAccess.open("res://data/wave_plan.json", FileAccess.READ)
	assert(file != null, "wave_plan.json must exist")
	var plan_data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	
	var stages: Array = plan_data.get("stages", [])
	assert(stages.size() == 10, "Must have exactly 10 stages, got: %d" % stages.size())
	
	var difficulties = ["매우 쉬움", "쉬움", "보통", "보통+", "어려움", "어려움+", "매우 어려움", "매우 어려움+", "극한", "지옥"]
	for i in range(10):
		var st: Dictionary = stages[i]
		assert(int(st.get("stage_id")) == i + 1, "Stage %d id mismatch" % (i + 1))
		assert(difficulties[i] in str(st.get("difficulty")), "Stage %d difficulty expected %s, got: %s" % [i + 1, difficulties[i], st.get("difficulty")])
		assert(int(st.get("total_waves")) == 10, "Stage %d must have exactly 10 waves" % (i + 1))
		var w_list: Array = st.get("waves", [])
		assert(w_list.size() == 10, "Stage %d wave list size must be 10, got %d" % [i + 1, w_list.size()])
	print("[PASS] Verified all 10 stages defined with 10 waves each and escalating difficulty (Stage 10 = 지옥)")
	
	# 2. Test WaveDirector stage execution for Stage 1 (Fast Simulation)
	var director := WaveDirector.new()
	root.add_child(director)
	director.preparation_duration = 0.001
	director.default_spawn_interval = 0.001
	director.max_active_enemies = 12
	
	var stage_started_log := []
	var stage_cleared_log := []
	var wave_cleared_log := []
	var victory_fired := [false]
	
	director.stage_started.connect(func(st_id, st_name, diff, total_w):
		stage_started_log.append({"id": st_id, "name": st_name, "diff": diff, "waves": total_w})
	)
	director.stage_cleared.connect(func(cl_id, st_name, reward, next_st):
		stage_cleared_log.append({"id": cl_id, "name": st_name, "reward": reward, "next": next_st})
	)
	director.wave_cleared.connect(func(w): wave_cleared_log.append(w))
	director.run_victory.connect(func(): victory_fired[0] = true)
	
	# Start Stage 1
	director.start_stage(1)
	assert(stage_started_log.size() == 1, "stage_started must be emitted")
	assert(stage_started_log[0]["id"] == 1, "Started stage id must be 1")
	assert(stage_started_log[0]["waves"] == 10, "Stage 1 must have 10 waves")
	
	# Simulate 10 waves of Stage 1
	for w in range(1, 11):
		director._process(0.01) # Transition to COMBAT
		while not director.pending_spawn_queue.is_empty():
			director._process(0.01)
			for e in director.active_enemies.duplicate():
				e.die()
				e.queue_free()
		for e in director.active_enemies.duplicate():
			e.die()
			e.queue_free()
		director._process(0.01) # Wave cleared
		
	assert(wave_cleared_log.size() == 10, "Expected 10 waves cleared in Stage 1, got: %d" % wave_cleared_log.size())
	assert(stage_cleared_log.size() == 1, "stage_cleared must be emitted upon finishing Wave 10")
	assert(stage_cleared_log[0]["id"] == 1, "Cleared stage must be 1")
	assert(stage_cleared_log[0]["next"] == 2, "Next stage must be 2")
	assert(victory_fired[0], "Stage completion must trigger victory event for transition to HQ")
	print("[PASS] Stage 1 (10 waves) full simulation completed: stage_cleared and victory emitted")
	director.queue_free()
	
	# 3. Test GameSession Profile progression and persistence
	GameSession._ensure_profile_loaded()
	GameSession.highest_unlocked_stage = 1
	GameSession.cleared_stages = {}
	var pre_credits := GameSession.credits
	GameSession.on_stage_completed(1, 1500)
	
	assert(GameSession.is_stage_cleared(1) == true, "Stage 1 must be marked cleared")
	assert(GameSession.is_stage_unlocked(2) == true, "Stage 2 must be unlocked")
	assert(GameSession.credits == pre_credits + 1500, "Credits must increase by 1500 reward (got: %d, expected: %d)" % [GameSession.credits, pre_credits + 1500])
	print("[PASS] GameSession stage clear: Stage 2 unlocked, reward credits added")
	
	# 4. Test Operations HQ with updated progression
	var hq_scene := load("res://scenes/ui/operations_hq.tscn") as PackedScene
	assert(hq_scene != null, "OperationsHQ scene must exist")
	var hq = hq_scene.instantiate()
	root.add_child(hq)
	hq._ready()
	
	assert(hq.progress_bar.value == 1, "HQ progress bar must show 1/10 cleared")
	assert("10%" in hq.progress_label.text, "HQ progress label must show 10%")
	
	# Select Stage 2
	hq.stage_card_buttons[2].pressed.emit()
	assert(hq.selected_stage_id == 2, "Selected stage should be 2")
	assert("제2작전" in hq.briefing_title.text, "Briefing should update to Stage 2")
	assert("10 웨이브" in hq.briefing_waves_label.text or "10" in hq.briefing_waves_label.text, "Briefing should mention 10 waves")
	
	# Complete remaining stages up to Stage 10
	for st_id in range(2, 11):
		GameSession.on_stage_completed(st_id, 1500)
	
	hq.refresh_hq_ui()
	assert(hq.progress_bar.value == 10, "Progress bar should show 10/10")
	assert("100%" in hq.progress_label.text, "Progress label should show 100%")
	
	# Select Stage 10 (Climax Nightmare)
	hq.stage_card_buttons[10].pressed.emit()
	assert(hq.selected_stage_id == 10, "Selected stage should be 10")
	assert("제10작전" in hq.briefing_title.text, "Briefing title should display Stage 10")
	assert("지옥" in hq.briefing_diff_label.text, "Stage 10 must be 지옥 (NIGHTMARE)")
	print("[PASS] Full 10-stage progression from Outpost Defense to Final Trench Stand verified")
	
	# 5. Test Zero Tofu / Forbidden Character Guarantee
	var forbidden_chars := ["✓", "★", "·", "■", "▲", "▼", "◆", "※", "⚠️", "🏆", "🚩", "🚨", "🌙", "🚀", "🚁"]
	var texts_to_check := [
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
	for btn in hq.stage_card_buttons.values():
		texts_to_check.append(btn.text)
	for t in texts_to_check:
		for fc in forbidden_chars:
			assert(not fc in t, "Forbidden glyph or emoji '%s' found in text: %s" % [fc, t])
	print("[PASS] Zero tofu / missing glyph boxed characters verified across all texts")
	
	hq.queue_free()
	print("[TEST COMPLETE] 5-Stage Campaign Flow & Operations HQ tests PASSED with 0 errors!")
	quit(0)
