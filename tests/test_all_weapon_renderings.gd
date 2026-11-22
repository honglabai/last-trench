extends SceneTree

func _init() -> void:
	print("[TEST] Running test_all_weapon_renderings.gd...")
	
	# 1. Load weapons.json
	var file := FileAccess.open("res://data/weapons.json", FileAccess.READ)
	assert(file != null, "Failed to open weapons.json")
	var json_str := file.get_as_text()
	var json := JSON.new()
	var parse_err := json.parse(json_str)
	assert(parse_err == OK, "Failed to parse weapons.json")
	var catalog: Dictionary = json.data
	
	var weapons_to_check := [
		"k2c1_rifle",
		"k5_pistol",
		"k413_grenade",
		"m4a1_carbine",
		"hk416_elite",
		"scar_h_battle",
		"usas12_shotgun",
		"k14_sniper",
		"rpg7_launcher",
		"hyungung_atgm"
	]
	
	for w_id in weapons_to_check:
		assert(catalog.has(w_id), "Catalog missing weapon: " + w_id)
		var w_data: Dictionary = catalog[w_id]
		
		# Check viewmodel texture
		var tex_path: String = w_data.get("texture", "")
		assert(ResourceLoader.exists(tex_path), "Texture missing: " + tex_path)
		var tex := load(tex_path) as Texture2D
		assert(tex != null, "Failed to load Texture2D: " + tex_path)
		var img := tex.get_image()
		assert(img != null, "Failed to get Image from texture: " + tex_path)
		assert(img.get_width() == 1280 and img.get_height() == 720, "Texture " + tex_path + " not 1280x720: " + str(img.get_size()))
		
		# Check top transparency (top-left pixel should be fully transparent alpha == 0)
		var top_left_pixel := img.get_pixel(10, 10)
		assert(top_left_pixel.a == 0.0, "Top-left of " + tex_path + " must be transparent (got alpha=" + str(top_left_pixel.a) + ")")
		
		# Check thumbnail
		var thumb_path: String = w_data.get("thumbnail", "")
		assert(ResourceLoader.exists(thumb_path), "Thumbnail missing: " + thumb_path)
		var thumb := load(thumb_path) as Texture2D
		assert(thumb != null, "Failed to load thumbnail: " + thumb_path)
		var thumb_img := thumb.get_image()
		assert(thumb_img != null, "Failed to get Image from thumbnail: " + thumb_path)
		assert(thumb_img.get_width() == 160 and thumb_img.get_height() == 100, "Thumbnail " + thumb_path + " not 160x100: " + str(thumb_img.get_size()))
		
		print("[PASS] " + w_id + " (" + w_data.get("name", "") + "): 1280x720 viewmodel & 160x100 thumbnail verified")
		
	# 2. Test FPSViewModel switching across all weapons
	var viewmodel_scene := load("res://scenes/ui/fps_viewmodel.tscn") as PackedScene
	assert(viewmodel_scene != null, "Failed to load fps_viewmodel.tscn")
	var vm := viewmodel_scene.instantiate() as FPSViewModel
	root.add_child(vm)
	
	for w_id in weapons_to_check:
		var tex_path: String = catalog[w_id].get("texture", "")
		var tex := load(tex_path) as Texture2D
		vm.set_weapon_texture(tex)
		assert(vm.rifle_rect.texture == tex, "FPSViewModel failed to display " + w_id)
		
	vm.queue_free()
	print("[PASS] FPSViewModel cycled through all 10 realistic weapon viewmodels successfully")
	
	print("[TEST COMPLETE] test_all_weapon_renderings.gd PASSED ALL CHECKS (0 errors)!")
	quit()
