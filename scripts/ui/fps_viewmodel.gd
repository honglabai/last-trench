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
	var sway_x := sin(sway_time) * (1.5 if not is_aiming else 0.5)
	var sway_y := cos(sway_time * 2.0) * (2.0 if not is_aiming else 0.8)
	
	# 2. Recoil decay
	recoil_offset = recoil_offset.lerp(Vector2.ZERO, 16.0 * delta)
	
	# 3. Target offset (ADS or Reload)
	var desired := Vector2.ZERO
	if is_reloading:
		desired = Vector2(0.0, 150.0) # Lower rifle during reload
	elif is_aiming:
		desired = Vector2(-25.0, -15.0) # Tighten towards center crosshair
		
	current_offset = current_offset.lerp(desired, 12.0 * delta)
	
	if rifle_rect:
		rifle_rect.position = rest_position + current_offset + recoil_offset + Vector2(sway_x, sway_y)
		
	# 4. Muzzle flash timer
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and muzzle_flash:
			muzzle_flash.visible = false

func on_fire() -> void:
	# Recoil impulse
	recoil_offset.y += 22.0 # Kick back
	recoil_offset.x += randf_range(-2.5, 2.5)
	flash_timer = 0.05
	if muzzle_flash:
		muzzle_flash.visible = true

func set_aiming(aiming: bool) -> void:
	is_aiming = aiming

func set_reloading(reloading: bool) -> void:
	is_reloading = reloading
