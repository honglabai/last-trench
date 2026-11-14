extends SceneTree

func _init() -> void:
	print("[TEST] Running P09 1-Time Revive & Composite Defeat Tests...")
	
	var player_scene = load("res://scenes/actors/player.tscn")
	if not player_scene:
		push_error("Failed to load player scene")
		quit(1)
		return
		
	var player = player_scene.instantiate() as PlayerController
	root.add_child(player)
	player._ready()
	
	var base = BaseObjective.new()
	base.max_health = 500.0
	base._ready()
	root.add_child(base)
	
	var session = GameSession.new()
	root.add_child(session)
	session.start_session(player, base)
	
	# 1. Verification of Initial State
	if session.revives_remaining != 1 or session.current_result != GameSession.Result.NONE:
		push_error("Initial session state invalid")
		quit(1)
		return
	print("[PASS] Initial session state verified: revives_remaining = 1")
	
	# 2. Player 1st Death -> Immediate Auto-Revive
	var revive_events := []
	session.player_revived.connect(func(left, hp): revive_events.append([left, hp]))
	
	# Fatal blow to player
	player.apply_damage(100.0)
	
	if session.revives_remaining != 0 or revive_events.is_empty():
		push_error("First death did not consume revive token or fire revive event")
		quit(1)
		return
	if player.is_dead or player.current_health != 80.0:
		push_error("Player HP was not restored to 80.0 on revive: HP is " + str(player.current_health))
		quit(1)
		return
	if not player.is_invulnerable or not session.is_invulnerable:
		push_error("Invulnerability guard not active after revive")
		quit(1)
		return
	print("[PASS] 1st death auto-revived successfully: revives_remaining = 0, HP = 80.0, invulnerable = true")
	
	# 3. Invulnerability Guard Test (Rapid continuous damage must NOT bypass revive or decrement token)
	player.apply_damage(100.0)
	player.apply_damage(100.0)
	if player.current_health != 80.0 or session.revives_remaining != 0:
		push_error("Damage breached invulnerability window!")
		quit(1)
		return
	print("[PASS] Invulnerability guard blocked multi-hit damage without token underflow")
	
	# 4. Advance time past invulnerability window
	session._process(1.6)
	if session.is_invulnerable or player.is_invulnerable:
		push_error("Invulnerability failed to expire after duration")
		quit(1)
		return
	print("[PASS] Invulnerability expired normally")
	
	# 5. Player 2nd Death -> Session Defeat
	var defeat_events := []
	session.session_defeat.connect(func(reason): defeat_events.append(reason))
	
	player.apply_damage(100.0)
	if defeat_events.size() != 1 or defeat_events[0] != "PLAYER_DEAD":
		push_error("Second death failed to trigger PLAYER_DEAD defeat event: " + str(defeat_events))
		quit(1)
		return
	if session.current_result != GameSession.Result.DEFEAT:
		push_error("Session result not marked DEFEAT")
		quit(1)
		return
	print("[PASS] Second death triggered PLAYER_DEAD defeat event exactly once")
	
	# Further damage must NOT duplicate defeat event
	player.apply_damage(50.0)
	if defeat_events.size() != 1:
		push_error("Duplicate defeat event emitted!")
		quit(1)
		return
	print("[PASS] Duplicate defeat event blocked")
	
	# 6. Base Objective Destruction Test (Defeat regardless of remaining revives)
	var fresh_player = player_scene.instantiate() as PlayerController
	root.add_child(fresh_player)
	fresh_player._ready()
	
	var fresh_base = BaseObjective.new()
	fresh_base.max_health = 500.0
	fresh_base._ready()
	root.add_child(fresh_base)
	
	var base_defeat_events := []
	var fresh_session = GameSession.new()
	root.add_child(fresh_session)
	fresh_session.session_defeat.connect(func(reason): base_defeat_events.append(reason))
	fresh_session.start_session(fresh_player, fresh_base)
	
	# Base destroyed while revives_remaining is still 1
	fresh_base.apply_damage(500.0)
	if base_defeat_events.size() != 1 or base_defeat_events[0] != "BASE_DESTROYED":
		push_error("Base destruction did not trigger BASE_DESTROYED defeat event: " + str(base_defeat_events))
		quit(1)
		return
	if fresh_session.revives_remaining != 1:
		push_error("Revive token unexpectedly altered by base destruction")
		quit(1)
		return
	print("[PASS] Rule Invariant Verified: Base destruction caused immediate defeat regardless of 1 revive remaining")
	
	player.queue_free()
	base.queue_free()
	session.queue_free()
	fresh_player.queue_free()
	fresh_base.queue_free()
	fresh_session.queue_free()
	
	print("[TEST COMPLETE] P09 session tests passed with 0 errors!")
	quit(0)
