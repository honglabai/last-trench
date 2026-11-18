class_name FPSViewModel
extends Control

var _rifle_rect: TextureRect
var rifle_rect: TextureRect:
	get:
		if not _rifle_rect: _rifle_rect = get_node_or_null("RifleRect")
		return _rifle_rect

var _muzzle_flash: Control
var muzzle_flash: Control:
	get:
		if not _muzzle_flash: _muzzle_flash = get_node_or_null("RifleRect/MuzzleFlash")
		return _muzzle_flash

# Center coordinate of the front sight post in the rifle texture (1280x720)
const SIGHT_POST_TEX_COORD := Vector2(640.0, 322.0)

var target_offset: Vector2 = Vector2.ZERO
var current_offset: Vector2 = Vector2.ZERO
var recoil_offset: Vector2 = Vector2.ZERO

var sway_time: float = 0.0
var is_aiming: bool = false
var is_reloading: bool = false
var flash_timer: float = 0.0

func _ready() -> void:
	if muzzle_flash:
		muzzle_flash.visible = false

func _process(delta: float) -> void:
	# 1. Subtle idle breathing sway
	sway_time += delta * 2.0
	var sway_x := sin(sway_time) * (0.6 if not is_aiming else 0.15)
	var sway_y := cos(sway_time * 2.0) * (0.8 if not is_aiming else 0.20)
	
	# 2. Recoil decay
	recoil_offset = recoil_offset.lerp(Vector2.ZERO, 18.0 * delta)
	
	# 3. Target offset (Iron Sights ADS or Ready or Reload)
	var desired := Vector2.ZERO
	if is_reloading:
		desired = Vector2(0.0, 200.0) # Lower rifle out of sight during reload
	elif is_aiming:
		desired = Vector2(0.0, 0.0) # Full iron sight picture: front sight post pulled directly onto crosshair
	else:
		desired = Vector2(0.0, 42.0) # Lower in ready stance for broad battlefield view
		
	current_offset = current_offset.lerp(desired, 14.0 * delta)
	
	# 4. Dynamically anchor front sight post to screen center on all aspect ratios
	if rifle_rect:
		var vp_center: Vector2 = get_viewport_rect().size * 0.5
		# When current_offset is (0, 0), sight post (640, 322) lands exactly on vp_center!
		var base_pos: Vector2 = vp_center - SIGHT_POST_TEX_COORD
		rifle_rect.global_position = base_pos + current_offset + recoil_offset + Vector2(sway_x, sway_y)
		
	# 5. Muzzle flash timer
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and muzzle_flash:
			muzzle_flash.visible = false

func on_fire() -> void:
	# Recoil impulse
	recoil_offset.y += 18.0 # Recoil kick
	recoil_offset.x += randf_range(-1.2, 1.2)
	flash_timer = 0.05
	if muzzle_flash:
		muzzle_flash.visible = true

func set_aiming(aiming: bool) -> void:
	is_aiming = aiming

func set_reloading(reloading: bool) -> void:
	is_reloading = reloading

func set_weapon_texture(tex: Texture2D) -> void:
	if rifle_rect and tex:
		rifle_rect.texture = tex
