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

var rest_position: Vector2 = Vector2.ZERO
var target_offset: Vector2 = Vector2.ZERO
var current_offset: Vector2 = Vector2.ZERO
var recoil_offset: Vector2 = Vector2.ZERO

var sway_time: float = 0.0
var is_aiming: bool = false
var is_reloading: bool = false
var flash_timer: float = 0.0

func _ready() -> void:
	if rifle_rect:
		rest_position = rifle_rect.position
	if muzzle_flash:
		muzzle_flash.visible = false

func _process(delta: float) -> void:
	# 1. Subtle idle breathing sway
	sway_time += delta * 2.0
	var sway_x := sin(sway_time) * (0.8 if not is_aiming else 0.25)
	var sway_y := cos(sway_time * 2.0) * (1.2 if not is_aiming else 0.35)
	
	# 2. Recoil decay
	recoil_offset = recoil_offset.lerp(Vector2.ZERO, 18.0 * delta)
	
	# 3. Target offset (Iron Sights ADS or Ready or Reload)
	var desired := Vector2.ZERO
	if is_reloading:
		desired = Vector2(0.0, 180.0) # Lower rifle out of sight during reload
	elif is_aiming:
		desired = Vector2(0.0, 0.0) # Full iron sight picture: 가늠좌/가늠쇠 aligned with crosshair
	else:
		desired = Vector2(0.0, 32.0) # Lower slightly in ready stance for broad field awareness
		
	current_offset = current_offset.lerp(desired, 14.0 * delta)
	
	if rifle_rect:
		rifle_rect.position = rest_position + current_offset + recoil_offset + Vector2(sway_x, sway_y)
		
	# 4. Muzzle flash timer
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and muzzle_flash:
			muzzle_flash.visible = false

func on_fire() -> void:
	# Recoil impulse
	recoil_offset.y += 18.0 # Recoil kick
	recoil_offset.x += randf_range(-1.5, 1.5)
	flash_timer = 0.05
	if muzzle_flash:
		muzzle_flash.visible = true

func set_aiming(aiming: bool) -> void:
	is_aiming = aiming

func set_reloading(reloading: bool) -> void:
	is_reloading = reloading
