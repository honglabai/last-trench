extends SceneTree

func _init() -> void:
	print("[TEST] Running Viewmodels & Ground Stability Verification Tests...")
	
	# 1. Verify Trench Map Ground Mesh spans (No Z-fighting overlap)
	var map_scene = load("res://scenes/maps/trench_map.tscn")
	if not map_scene:
		push_error("Failed to load trench_map.tscn")
		quit(1)
		return
		
	var map = map_scene.instantiate() as TrenchMap
	root.add_child(map)
	
	var front_ground = map.get_node_or_null("Environment/FrontGround")
	var rear_ground = map.get_node_or_null("Environment/RearGround")
	
	if not front_ground or not rear_ground:
		push_error("FrontGround or RearGround missing from trench map")
		quit(1)
		return
		
	var front_col = front_ground.get_node("CollisionShape3D").shape as BoxShape3D
	var rear_col = rear_ground.get_node("CollisionShape3D").shape as BoxShape3D
	
	var front_pos_z = front_ground.position.z
	var front_len_z = front_col.size.z
	var front_max_z = front_pos_z + (front_len_z * 0.5)
	
	var rear_pos_z = rear_ground.position.z
	var rear_len_z = rear_col.size.z
	var rear_min_z = rear_pos_z - (rear_len_z * 0.5)
	
	print("[INFO] FrontGround max Z: ", front_max_z, ", RearGround min Z: ", rear_min_z)
	if front_max_z > rear_min_z:
		push_error("Z-fighting detected! FrontGround and RearGround overlap between Z=" + str(rear_min_z) + " and " + str(front_max_z))
		quit(1)
		return
		
	print("[PASS] Ground geometry non-overlapping verified (0mm overlap, zero Z-fighting)")
	
	# 2. Verify all weapon textures in weapons.json
	var file = FileAccess.open("res://data/weapons.json", FileAccess.READ)
	if not file:
		push_error("Failed to read weapons.json")
		quit(1)
		return
		
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	if err != OK:
		push_error("Failed to parse weapons.json")
		quit(1)
		return
		
	var weapons_data: Dictionary = json.data
	for w_id in weapons_data:
		var w_info: Dictionary = weapons_data[w_id]
		var tex_path: String = w_info.get("texture", "")
		if tex_path.is_empty():
			push_error("Weapon " + w_id + " missing texture path")
			quit(1)
			return
			
		var tex = load(tex_path) as Texture2D
		if not tex:
			push_error("Failed to load weapon texture: " + tex_path)
			quit(1)
			return
			
		var img = tex.get_image()
		if not img:
			push_error("Failed to get image from texture: " + tex_path)
			quit(1)
			return
			
		if img.detect_alpha() == Image.ALPHA_NONE:
			push_error("Weapon texture MUST have an alpha channel for transparency: " + tex_path)
			quit(1)
			return
			
		var w = img.get_width()
		var h = img.get_height()
		if w != 1280 or h != 720:
			push_error("Weapon texture dimensions must be 1280x720: " + tex_path + " was " + str(w) + "x" + str(h))
			quit(1)
			return
			
		print("[PASS] Verified weapon " + w_id + " texture: " + tex_path + " (1280x720 RGBA)")
		
	print("[TEST COMPLETE] Viewmodels & ground fix verification passed with 0 errors!")
	quit(0)
