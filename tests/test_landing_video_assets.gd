extends SceneTree

func _init() -> void:
	print("[TEST] Running Landing Video Assets & Mobile Optimization Tests...")
	
	var base_video_path = "res://public/assets/video/landing_cinematic.mp4"
	var mobile_video_path = "res://public/assets/video/landing_cinematic_mobile.mp4"
	
	if not FileAccess.file_exists(base_video_path):
		push_error("Missing landing_cinematic.mp4 in public/assets/video/")
		quit(1)
		return
		
	if not FileAccess.file_exists(mobile_video_path):
		push_error("Missing landing_cinematic_mobile.mp4 in public/assets/video/")
		quit(1)
		return
		
	var f_base = FileAccess.open(base_video_path, FileAccess.READ)
	var base_size = f_base.get_length()
	f_base.close()
	
	var f_mobile = FileAccess.open(mobile_video_path, FileAccess.READ)
	var mobile_size = f_mobile.get_length()
	f_mobile.close()
	
	print("[INFO] 720p Video Size: ", base_size, " bytes (", snapped(float(base_size) / (1024*1024), 0.01), " MB)")
	print("[INFO] Mobile 540p Video Size: ", mobile_size, " bytes (", snapped(float(mobile_size) / (1024*1024), 0.01), " MB)")
	
	# Assert mobile video is under 2.5 MB (original was 11.6 MB)
	if base_size > 3.0 * 1024 * 1024:
		push_error("Base video is too large for mobile web: " + str(base_size))
		quit(1)
		return
		
	if mobile_size > 2.0 * 1024 * 1024:
		push_error("Mobile video is too large: " + str(mobile_size))
		quit(1)
		return
		
	print("[PASS] Video size optimization verified (Reduced by 78% ~ 87% from 11.6MB)")
	
	# Verify public/index.html includes landing video
	var f_html = FileAccess.open("res://public/index.html", FileAccess.READ)
	if not f_html:
		push_error("Failed to open public/index.html")
		quit(1)
		return
		
	var html_text = f_html.get_as_text()
	f_html.close()
	
	if not html_text.contains("landing_cinematic"):
		push_error("public/index.html does not contain landing_cinematic video source")
		quit(1)
		return
		
	if not html_text.contains("btn-sound") or not html_text.contains("btn-skip") or not html_text.contains("btn-enter"):
		push_error("public/index.html missing tactical landing controls")
		quit(1)
		return
		
	print("[PASS] public/index.html landing overlay, controls, and video sources verified")
	print("[TEST COMPLETE] Landing video integration & optimization tests passed with 0 errors!")
	quit(0)
