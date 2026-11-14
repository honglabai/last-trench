class_name BulletTracer
extends Node3D

@export var speed: float = 160.0 # Bullet flight velocity in m/s
@export var tracer_color: Color = Color(1.0, 0.85, 0.25, 1.0)
@export var tracer_length: float = 0.9

var start_point: Vector3 = Vector3.ZERO
var target_point: Vector3 = Vector3.ZERO
var travel_direction: Vector3 = Vector3.FORWARD
var total_distance: float = 0.0
var distance_traveled: float = 0.0
var max_lifetime: float = 1.2
var elapsed_time: float = 0.0

@onready var tracer_mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	if not tracer_mesh:
		_create_visual_mesh()

func setup(origin: Vector3, destination: Vector3, custom_speed: float = 160.0, custom_color: Color = Color(1.0, 0.85, 0.25)) -> void:
	start_point = origin
	target_point = destination
	speed = custom_speed
	tracer_color = custom_color
	global_position = origin
	
	var diff := destination - origin
	total_distance = diff.length()
	if total_distance > 0.001:
		travel_direction = diff.normalized()
		var up_vec := Vector3.UP
		if abs(travel_direction.dot(Vector3.UP)) > 0.95:
			up_vec = Vector3.RIGHT
		look_at(global_position + travel_direction, up_vec)
		
	if tracer_mesh and tracer_mesh.get_surface_override_material(0):
		var mat := tracer_mesh.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.albedo_color = tracer_color
			mat.emission = tracer_color

func _create_visual_mesh() -> void:
	tracer_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.035
	cyl.bottom_radius = 0.035
	cyl.height = tracer_length
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tracer_color
	mat.emission_enabled = true
	mat.emission = tracer_color
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	tracer_mesh.mesh = cyl
	tracer_mesh.set_surface_override_material(0, mat)
	tracer_mesh.rotation.x = deg_to_rad(90.0)
	add_child(tracer_mesh)

func _process(delta: float) -> void:
	elapsed_time += delta
	if elapsed_time > max_lifetime:
		queue_free()
		return
		
	var step := speed * delta
	distance_traveled += step
	global_position += travel_direction * step
	
	if distance_traveled >= total_distance:
		queue_free()
