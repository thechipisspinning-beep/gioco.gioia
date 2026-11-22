class_name DayNight
extends Node3D
## Ciclo giorno/notte (GDD § 5.3): sole e luna che attraversano il cielo,
## colori di cielo, luce e nebbia che cambiano con l'ora, stelle di notte.
## L'ora viene da `GameClock`.

## Fotogrammi chiave per ora del giorno: cielo alto, orizzonte, luce del sole,
## energia del sole, luce ambientale, energia ambientale.
const KEYS: Array[Dictionary] = [
	{"h": 0.0, "top": Color("0e1633"), "hor": Color("23305a"), "sun": Color("8aa0ff"), "se": 0.0, "amb": Color("4a5a99"), "ae": 0.22},
	{"h": 5.0, "top": Color("1c2550"), "hor": Color("6b5a86"), "sun": Color("ffb27a"), "se": 0.0, "amb": Color("6a6a9a"), "ae": 0.24},
	{"h": 6.5, "top": Color("6fa4e0"), "hor": Color("ffc9a0"), "sun": Color("ffc590"), "se": 0.55, "amb": Color("c8b8c8"), "ae": 0.3},
	{"h": 9.0, "top": Color("6fb4f0"), "hor": Color("cfe9fb"), "sun": Color("fff1d6"), "se": 0.78, "amb": Color("b8c8e6"), "ae": 0.32},
	{"h": 16.0, "top": Color("6fb4f0"), "hor": Color("d8ecf8"), "sun": Color("fff1d6"), "se": 0.78, "amb": Color("b8c8e6"), "ae": 0.32},
	{"h": 18.5, "top": Color("6a86c8"), "hor": Color("ffb38a"), "sun": Color("ffab70"), "se": 0.5, "amb": Color("d0a8b0"), "ae": 0.3},
	{"h": 20.0, "top": Color("27306a"), "hor": Color("8a6a9a"), "sun": Color("ff9a70"), "se": 0.0, "amb": Color("6a6a9a"), "ae": 0.24},
	{"h": 24.0, "top": Color("0e1633"), "hor": Color("23305a"), "sun": Color("8aa0ff"), "se": 0.0, "amb": Color("4a5a99"), "ae": 0.22},
]
const MOON_ENERGY: float = 0.22

## 0 = cielo limpido, 1 = molto nuvoloso (impostato dal meteo).
var weather_dim: float = 0.0
var environment: Environment
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var _sky_material: ShaderMaterial


func _ready() -> void:
	_sky_material = ShaderMaterial.new()
	_sky_material.shader = preload("res://art/shaders/sky.gdshader")
	var sky: Sky = Sky.new()
	sky.sky_material = _sky_material
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	# Bagliore solo sulle luci molto forti: con soglia bassa anche i lampioni
	# chiari al sole "brillavano" creando macchie bianche lontane.
	environment.glow_enabled = Settings.get_quality() >= Settings.Quality.MEDIUM
	environment.glow_intensity = 0.25
	environment.glow_hdr_threshold = 1.6
	environment.fog_enabled = true
	# Foschia leggera solo in lontananza (dà profondità senza slavare i colori);
	# il cielo non viene velato.
	environment.fog_density = 0.0011
	environment.fog_aerial_perspective = 0.15
	environment.fog_sky_affect = 0.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.08
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = environment
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	# Ombre più vicine e semplici con qualità bassa (telefoni, web).
	sun.directional_shadow_max_distance = [30.0, 45.0, 60.0][Settings.get_quality()]
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if Settings.get_quality() == Settings.Quality.LOW else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)
	moon = DirectionalLight3D.new()
	moon.name = "Moon"
	moon.light_color = Color("9fb4ff")
	moon.shadow_enabled = false
	add_child(moon)
	apply_hour(GameClock.time.get_hour() + GameClock.time.get_minute() / 60.0)


func _process(_delta: float) -> void:
	apply_hour(GameClock.time.get_day_fraction() * 24.0)


## Applica l'aspetto dell'ora indicata (0–24, con decimali).
func apply_hour(hour: float) -> void:
	var k: Dictionary = _interpolate(hour)
	# Sole: sorge a est (+X) alle 6, è alto a mezzogiorno (verso sud), tramonta a ovest alle 18.
	var phase: float = (hour - 6.0) / 12.0 * PI
	var sun_dir: Vector3 = Vector3(cos(phase), sin(phase) * 0.92, 0.38).normalized()
	var moon_dir: Vector3 = Vector3(-sun_dir.x, -sun_dir.y, 0.25).normalized()
	sun.look_at_from_position(Vector3.ZERO, -sun_dir, Vector3.UP if absf(sun_dir.y) < 0.99 else Vector3.FORWARD)
	moon.look_at_from_position(Vector3.ZERO, -moon_dir, Vector3.UP if absf(moon_dir.y) < 0.99 else Vector3.FORWARD)
	var sun_up: float = smoothstep(-0.05, 0.12, sun_dir.y)
	var moon_up: float = smoothstep(-0.05, 0.12, moon_dir.y)
	sun.light_color = k["sun"]
	sun.light_energy = Lighting.sun_energy(float(k["se"]) * sun_up * (1.0 - weather_dim * 0.6))
	sun.visible = sun.light_energy > 0.01
	moon.light_energy = Lighting.sun_energy(MOON_ENERGY * moon_up * (1.0 - sun_up))
	moon.visible = moon.light_energy > 0.01
	environment.ambient_light_color = k["amb"]
	environment.ambient_light_energy = Lighting.ambient_energy(float(k["ae"]))
	environment.fog_light_color = k["hor"]
	var grey: Color = Color("9aa3b5")
	_sky_material.set_shader_parameter("top_color", (k["top"] as Color).lerp(grey, weather_dim * 0.7))
	_sky_material.set_shader_parameter("horizon_color", (k["hor"] as Color).lerp(grey.lightened(0.2), weather_dim * 0.6))
	_sky_material.set_shader_parameter("ground_color", (k["hor"] as Color).lerp(Palette.GRASS, 0.4))
	_sky_material.set_shader_parameter("sun_direction", sun_dir)
	_sky_material.set_shader_parameter("moon_direction", moon_dir)
	_sky_material.set_shader_parameter("sun_color", k["sun"])
	_sky_material.set_shader_parameter("night", 1.0 - smoothstep(-0.15, 0.1, sun_dir.y))


## Quanto è notte (0 = giorno pieno, 1 = notte), utile ad altri sistemi.
func night_factor() -> float:
	return 1.0 - smoothstep(0.0, 0.15, sun.global_transform.basis.z.y)


static func _interpolate(hour: float) -> Dictionary:
	hour = fposmod(hour, 24.0)
	for i: int in KEYS.size() - 1:
		var a: Dictionary = KEYS[i]
		var b: Dictionary = KEYS[i + 1]
		if hour >= float(a["h"]) and hour <= float(b["h"]):
			var t: float = (hour - float(a["h"])) / maxf(float(b["h"]) - float(a["h"]), 0.001)
			var out: Dictionary = {}
			for key: String in ["top", "hor", "sun", "amb"]:
				out[key] = (a[key] as Color).lerp(b[key] as Color, t)
			for key: String in ["se", "ae"]:
				out[key] = lerpf(float(a[key]), float(b[key]), t)
			return out
	return KEYS[0]
