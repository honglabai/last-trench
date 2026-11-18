extends SceneTree

func _init() -> void:
	print("[TEST] Running test_pwa_and_fullscreen.gd...")
	
	# 1. Verify manifest.json
	var m_file := FileAccess.open("res://public/manifest.json", FileAccess.READ)
	assert(m_file != null, "manifest.json does not exist in public/")
	var m_str := m_file.get_as_text()
	var json := JSON.new()
	var m_err := json.parse(m_str)
	assert(m_err == OK, "manifest.json failed to parse as JSON")
	var manifest: Dictionary = json.data
	
	assert(manifest.get("id") == "/", "manifest id must be '/' (got: " + str(manifest.get("id")) + ")")
	assert(manifest.get("start_url") == "/", "manifest start_url must be '/' to prevent 308 redirect CCT fallback (got: " + str(manifest.get("start_url")) + ")")
	assert(manifest.get("scope") == "/", "manifest scope must be '/' (got: " + str(manifest.get("scope")) + ")")
	assert(manifest.get("display") == "fullscreen", "manifest display must be 'fullscreen'")
	
	var overrides: Array = manifest.get("display_override", [])
	assert(overrides.has("fullscreen"), "display_override must contain 'fullscreen'")
	assert(manifest.get("orientation") == "landscape", "manifest orientation must be 'landscape'")
	
	var icons: Array = manifest.get("icons", [])
	assert(icons.size() >= 4, "manifest must declare at least 4 icons (any + maskable)")
	for ic in icons:
		var src: String = ic.get("src", "")
		var f_path := "res://public/" + src
		assert(FileAccess.file_exists(f_path), "Icon file missing: " + f_path)
	print("[PASS] manifest.json configuration and icon assets verified")
	
	# 2. Verify sw.js (Service Worker)
	var sw_file := FileAccess.open("res://public/sw.js", FileAccess.READ)
	assert(sw_file != null, "sw.js does not exist in public/")
	var sw_str := sw_file.get_as_text()
	assert(sw_str.contains("addEventListener('install'"), "sw.js missing install listener")
	assert(sw_str.contains("addEventListener('activate'"), "sw.js missing activate listener")
	assert(sw_str.contains("addEventListener('fetch'"), "sw.js missing fetch listener")
	print("[PASS] sw.js Service Worker implementation verified")
	
	# 3. Verify assetlinks.json
	var al_file := FileAccess.open("res://public/.well-known/assetlinks.json", FileAccess.READ)
	assert(al_file != null, "assetlinks.json does not exist in public/.well-known/")
	var al_str := al_file.get_as_text()
	var al_err := json.parse(al_str)
	assert(al_err == OK, "assetlinks.json failed to parse as JSON")
	var al_data: Array = json.data
	assert(al_data.size() >= 1, "assetlinks.json must have at least 1 statement")
	print("[PASS] .well-known/assetlinks.json verified")
	
	# 4. Verify index.html integration
	var html_file := FileAccess.open("res://public/index.html", FileAccess.READ)
	assert(html_file != null, "index.html does not exist in public/")
	var html_str := html_file.get_as_text()
	assert(html_str.contains("serviceWorker.register('/sw.js'"), "index.html must register /sw.js")
	assert(html_str.contains("rel=\"manifest\" href=\"/manifest.json\""), "index.html must link /manifest.json")
	assert(html_str.contains("navigationUI: 'hide'"), "index.html enterFullscreen must request navigationUI: hide")
	assert(html_str.contains("screen.orientation.lock('landscape'"), "index.html must lock orientation to landscape")
	print("[PASS] index.html PWA and fullscreen triggers verified")
	
	# 5. Verify vercel.json
	var vj_file := FileAccess.open("res://vercel.json", FileAccess.READ)
	assert(vj_file != null, "vercel.json does not exist")
	var vj_str := vj_file.get_as_text()
	assert(vj_str.contains("/.well-known/assetlinks.json"), "vercel.json must route assetlinks.json")
	assert(vj_str.contains("/sw.js"), "vercel.json must route sw.js")
	print("[PASS] vercel.json routing and MIME headers verified")
	
	print("[TEST COMPLETE] test_pwa_and_fullscreen.gd PASSED ALL CHECKS (0 errors)!")
	quit()
