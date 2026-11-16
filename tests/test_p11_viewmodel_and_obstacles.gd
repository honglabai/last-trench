extends SceneTree

func _init() -> void:
	print("[TEST] Running P11 FPS ViewModel, Parapet & Obstacle Non-blocking Tests...")
	
	# 1. Test FPS ViewModel component with Iron Sights
	var vm_scene = load("res://scenes/ui/fps_viewmodel.tscn")
	if not vm_scene:
		push_error("Failed to load res://scenes/ui/fps_viewmodel.tscn")
		quit(1)
		return
		
	var vm = vm_scene.instantiate() as FPSViewModel
	if not vm:
		push_error("Failed to instantiate FPSViewModel")
		quit(1)
		return
	root.add_child(vm)
	
	if not vm.rifle_rect or not vm.rifle_rect.texture or not vm.rifle_rect.texture.resource_path.contains("tex_fps_iron_sights"):
		push_error("FPSViewModel iron sights texture missing or not tex_fps_iron_sights")
		quit(1)
		return
	print("[PASS] FPSViewModel instantiated with true iron sights texture: ", vm.rifle_rect.texture.resource_path)
	
	# Test firing recoil
	var pre_recoil = vm.recoil_offset
	vm.on_fire()
	if vm.recoil_offset.y <= pre_recoil.y or not vm.muzzle_flash.visible:
		push_error("FPSViewModel recoil impulse or muzzle flash failed")
		quit(1)
		return
	print("[PASS] FPSViewModel firing recoil and muzzle flash verified (recoil.y = %f)" % vm.recoil_offset.y)
	
	# Test aiming ADS offset and reload lowering
	vm.set_aiming(true)
	if not vm.is_aiming:
		push_error("FPSViewModel set_aiming failed")
		quit(1)
		return
	vm.set_aiming(false)
	vm.set_reloading(true)
	if not vm.is_reloading:
		push_error("FPSViewModel set_reloading failed")
		quit(1)
		return
	print("[PASS] FPSViewModel ADS aim toggle and reload lowering states verified")
	vm.queue_free()
	
	# 2. Test BattleHUD integration with FPSViewModel
	var hud_scene = load("res://scenes/ui/battle_hud.tscn")
	var hud = hud_scene.instantiate() as BattleHUD
	root.add_child(hud)
	
	if not hud.viewmodel:
		push_error("BattleHUD does not contain viewmodel")
		quit(1)
		return
	hud.trigger_weapon_fire()
	if hud.viewmodel.flash_timer <= 0.0:
		push_error("BattleHUD trigger_weapon_fire failed to activate viewmodel")
		quit(1)
		return
	print("[PASS] BattleHUD -> FPSViewModel firing signal propagation verified")
	hud.queue_free()
	
	# 3. Test Czech Hedgehog is purely visual (no blocking collider)
	var hedgehog_scene = load("res://scenes/defenses/czech_hedgehog.tscn")
	if not hedgehog_scene:
		push_error("Failed to load czech_hedgehog.tscn")
		quit(1)
		return
	var hedgehog = hedgehog_scene.instantiate()
	root.add_child(hedgehog)
	
	var col_shape = hedgehog.find_child("CollisionShape3D", true, false)
	if col_shape != null:
		push_error("CzechHedgehog still contains a CollisionShape3D! It must be non-blocking decorative prop")
		quit(1)
		return
	if hedgehog is StaticBody3D or hedgehog is CollisionObject3D:
		push_error("CzechHedgehog must not be a CollisionObject3D so bullets and infantry pass through")
		quit(1)
		return
	print("[PASS] CzechHedgehog non-blocking prop verified (0 colliders, enemies and bullets pass freely)")
	hedgehog.queue_free()
	
	# 4. Test TrenchMap stacked sandbag parapet, banquette step & line of sight
	var map_scene = load("res://scenes/maps/trench_map.tscn")
	var map = map_scene.instantiate() as TrenchMap
	root.add_child(map)
	
	var sandbag_center = map.find_child("SandbagCenter", true, false) as Node3D
	if not sandbag_center:
		push_error("SandbagCenter cover missing in TrenchMap")
		quit(1)
		return
	var sandbag_mesh = sandbag_center.find_child("MeshInstance3D", true, false) as MeshInstance3D
	var mat = sandbag_mesh.get_surface_override_material(0) as StandardMaterial3D
	if not mat or not mat.albedo_texture or not mat.albedo_texture.resource_path.contains("tex_sandbag_stacked"):
		push_error("SandbagCenter not using tex_sandbag_stacked texture")
		quit(1)
		return
	print("[PASS] Stacked burlap sandbag parapet verified with texture: ", mat.albedo_texture.resource_path)
	
	var banquette = map.find_child("BanquetteStep", true, false)
	if not banquette:
		push_error("BanquetteStep missing in TrenchMap Environment")
		quit(1)
		return
	print("[PASS] Trench banquette firing step verified")
	
	var p_start = map.get_player_start_transform()
	# Eye level is at Y = p_start.origin.y + 1.5
	var eye_y = p_start.origin.y + 1.5
	# Sandbag top is at sandbag_center.position.y + 0.25 (half of 0.5 height)
	var sandbag_top_y = sandbag_center.position.y + 0.25
	if eye_y <= sandbag_top_y:
		push_error("Player eye level (%f) is below or equal to sandbag top (%f)!" % [eye_y, sandbag_top_y])
		quit(1)
		return
	var clearance = eye_y - sandbag_top_y
	print("[PASS] Clear line of sight verified: Eye level = %.2fm, Sandbag top = %.2fm (Clearance = +%.2fm)" % [eye_y, sandbag_top_y, clearance])
	
	# 5. Test central combat sector obstacle clearance (enemies cannot hide)
	var hedgehogs = map.find_child("Hedgehogs", true, false)
	if hedgehogs:
		for child in hedgehogs.get_children():
			if child is Node3D and abs(child.position.x) < 7.0:
				push_error("Hedgehog found in central combat sector X=%f (enemies could hide behind it)" % child.position.x)
				quit(1)
				return
	var wires = map.find_child("BarbedWires", true, false)
	if wires:
		for child in wires.get_children():
			if child is Node3D and abs(child.position.x) < 7.0:
				push_error("Barbed wire found in central combat sector X=%f (enemies could hide behind it)" % child.position.x)
				quit(1)
				return
	print("[PASS] Open central killzone verified (zero obstacles between X=-7.0 and X=+7.0, enemies cannot hide)")
	map.queue_free()
	
	print("[TEST COMPLETE] P11 FPS ViewModel, Parapet & Obstacle tests passed with 0 errors!")
	quit(0)
