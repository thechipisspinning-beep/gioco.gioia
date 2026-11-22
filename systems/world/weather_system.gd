class_name WeatherSystem
extends Node3D
## Effetti del meteo (D-07): nuvole che scuriscono il cielo, pioggia (o neve
## in alta montagna) che segue la telecamera. Le particelle sono CPU, quindi
## funzionano anche sul web e sui telefoni più vecchi.

var day_night: DayNight
var _rain: CPUParticles3D
var _snow: CPUParticles3D
var _dim: float = 0.0


func _ready() -> void:
	_rain = _particles(Vector3(0.02, 0.5, 0.02), Color(0.75, 0.85, 1.0, 0.6), 18.0, 600)
	_snow = _particles(Vector3(0.07, 0.07, 0.07), Color(1, 1, 1, 0.95), 2.0, 300)


func current() -> WeatherModel.Kind:
	return WeatherModel.at(GameClock.time.get_day(), GameClock.time.get_hour())


func _process(delta: float) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	var kind: WeatherModel.Kind = current()
	var target_dim: float = {WeatherModel.Kind.CLEAR: 0.0, WeatherModel.Kind.CLOUDY: 0.35, WeatherModel.Kind.RAIN: 0.6}[kind]
	_dim = lerpf(_dim, target_dim, 1.0 - exp(-0.5 * delta))
	if day_night != null:
		day_night.weather_dim = _dim
	var raining: bool = kind == WeatherModel.Kind.RAIN
	var high: bool = cam != null and cam.global_position.y > WeatherModel.SNOW_ALTITUDE
	_rain.emitting = raining and not high
	_snow.emitting = raining and high
	if cam != null:
		_rain.global_position = cam.global_position + Vector3(0, 8, 0)
		_snow.global_position = cam.global_position + Vector3(0, 8, 0)


func _particles(size: Vector3, color: Color, fall_speed: float, amount: int) -> CPUParticles3D:
	var p: CPUParticles3D = CPUParticles3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mesh.material = mat
	p.mesh = mesh
	p.amount = amount
	p.lifetime = 1.4 if fall_speed > 5.0 else 6.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(18, 1, 18)
	p.direction = Vector3(0.05, -1, 0)
	p.spread = 4.0 if fall_speed > 5.0 else 25.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = fall_speed
	p.initial_velocity_max = fall_speed * 1.2
	p.local_coords = false
	p.emitting = false
	add_child(p)
	return p
