class_name ExplosionEffect
extends Node3D

@export var max_duration: float = 0.55

var blast_radius: float = 6.5
var timer: float = 0.0

var fireball: MeshInstance3D
var shockwave: MeshInstance3D
var smoke: MeshInstance3D
var light: OmniLight3D

func setup(pos: Vector3, radius: float = 6.5) -> void:
	if is_inside_tree():
		global_position = pos
	else:
		position = pos
	blast_radius = maxf(2.0, radius)

func _ready() -> void:
	_create_visuals()
	AudioManager.play_sound("explosion", 0.04, 2.5)

func _create_visuals() -> void:
	# 1. Fireball Sphere
	fireball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	fireball.mesh = sphere
	
	var mat_fire := StandardMaterial3D.new()
	mat_fire.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_fire.albedo_color = Color(1.0, 0.7, 0.15, 0.95)
	mat_fire.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fireball.material_override = mat_fire
	add_child(fireball)
	
	# 2. Ground Shockwave Ring
	shockwave = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.4
	torus.outer_radius = 0.6
	shockwave.mesh = torus
	
	var mat_wave := StandardMaterial3D.new()
	mat_wave.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_wave.albedo_color = Color(1.0, 0.9, 0.4, 0.85)
	mat_wave.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shockwave.material_override = mat_wave
	shockwave.position.y = 0.05
	add_child(shockwave)
	
	# 3. Billowing Smoke Puff
	smoke = MeshInstance3D.new()
	var s_sphere := SphereMesh.new()
	s_sphere.radius = 0.6
	s_sphere.height = 1.2
	smoke.mesh = s_sphere
	
	var mat_smoke := StandardMaterial3D.new()
	mat_smoke.albedo_color = Color(0.25, 0.22, 0.20, 0.8)
	mat_smoke.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_smoke.roughness = 0.9
	smoke.material_override = mat_smoke
	add_child(smoke)
	
	# 4. Flash Light
	light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.65, 0.2)
	light.light_energy = 8.0
	light.omni_range = blast_radius * 2.5
	add_child(light)

func _process(delta: float) -> void:
	timer += delta
	var progress := timer / max_duration
	if progress >= 1.0:
		queue_free()
		return
		
	# Fireball expands fast and fades
	var fire_scale := lerpf(0.5, blast_radius * 0.9, ease(minf(progress * 2.5, 1.0), 0.25))
	if fireball:
		fireball.scale = Vector3.ONE * fire_scale
		var mat := fireball.material_override as StandardMaterial3D
		if mat:
			var alpha := clampf(1.0 - progress * 1.5, 0.0, 1.0)
			mat.albedo_color = Color(1.0, 0.4 + (1.0 - progress) * 0.4, 0.1, alpha)
			
	# Shockwave ring expands out to blast radius
	var wave_scale := lerpf(1.0, blast_radius * 1.2, ease(progress, 0.3))
	if shockwave:
		shockwave.scale = Vector3(wave_scale, 1.0, wave_scale)
		var mat := shockwave.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color.a = clampf(1.0 - progress * 1.2, 0.0, 1.0)
			
	# Smoke expands slowly and rises
	var smoke_scale := lerpf(0.8, blast_radius * 0.75, ease(progress, 0.5))
	if smoke:
		smoke.scale = Vector3.ONE * smoke_scale
		smoke.position.y += delta * 4.5
		var mat := smoke.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color.a = clampf(0.85 - progress * 0.9, 0.0, 1.0)
			
	# Flash light decays
	if light:
		light.light_energy = lerpf(8.0, 0.0, progress * 2.0)
