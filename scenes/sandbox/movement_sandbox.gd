extends Node3D
## Sandbox della Fase 3: area di prova per movimento e telecamera.
##
## Ospita anche i primi animali (Fase 6): un cane e una volpe.
## Contiene: prato con fiori, sentiero, rampe di pendenza crescente (l'ultima
## troppo ripida da salire), scala, piattaforme per il salto (una troppo alta),
## tunnel e casetta per verificare che la telecamera non attraversi i muri,
## laghetto con acqua profonda non attraversabile (D-13), alberi e rocce.

const PLAYER_SCENE: PackedScene = preload("res://systems/player/player.tscn")
const CAMERA_SCENE: PackedScene = preload("res://systems/camera/camera_rig.tscn")
const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")

const SPAWN_POSITION: Vector3 = Vector3(0.0, 0.2, 8.0)

var player: PlayerController
var camera_rig: CameraRig


func _ready() -> void:
	_build_environment()
	_build_level()
	_spawn_player()


func _build_environment() -> void:
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("6fb4f0")
	sky_material.sky_horizon_color = Color("cfe9fb")
	sky_material.ground_horizon_color = Color("cfe9fb")
	sky_material.ground_bottom_color = Color("9dc9a0")
	sky_material.sun_angle_max = 20.0
	var sky: Sky = Sky.new()
	sky.sky_material = sky_material

	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	# Luce ambientale a colore fisso (non dal cielo): controllo preciso sul tono
	# delle zone in ombra, tipico dello stile illustrato.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b8c8e6")
	env.ambient_light_energy = Lighting.ambient_energy(0.32)
	# Tonemapping lineare: con luce totale ~1 i colori della palette restano fedeli.
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = true
	env.glow_intensity = 0.25
	env.glow_hdr_threshold = 1.1
	env.fog_enabled = true
	env.fog_light_color = Color("cfe9fb")
	env.fog_density = 0.004
	env.fog_aerial_perspective = 0.4
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08

	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color("fff1d6")
	sun.light_energy = Lighting.sun_energy(0.78)
	sun.rotation_degrees = Vector3(-48.0, -38.0, 0.0)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 55.0
	add_child(sun)


func _build_level() -> void:
	var b: LevelBuilder = LevelBuilder.new(self)

	# Terreno e sentiero
	b.solid_box(Vector3(160.0, 1.0, 160.0), Vector3(0.0, -0.5, 0.0), Palette.GRASS)
	var path_mesh: BoxMesh = BoxMesh.new()
	path_mesh.size = Vector3(2.6, 0.02, 40.0)
	b.decor(path_mesh, Vector3(0.0, 0.01, -4.0), Palette.PATH)
	var cross_mesh: BoxMesh = BoxMesh.new()
	cross_mesh.size = Vector3(34.0, 0.02, 2.6)
	b.decor(cross_mesh, Vector3(0.0, 0.012, 2.0), Palette.PATH)

	# Rampe: 15° e 30° salibili, 55° troppo ripida (Gioia scivola indietro).
	var h1: float = b.ramp(3.0, 7.0, 15.0, Vector3(9.0, 0.0, 0.0), Palette.STONE)
	b.solid_box(Vector3(3.0, h1, 3.0), Vector3(9.0, h1 * 0.5, -7.0 * cos(deg_to_rad(15.0)) - 1.5), Palette.STONE)
	var h2: float = b.ramp(3.0, 5.0, 30.0, Vector3(13.0, 0.0, 0.0), Palette.STONE_DARK)
	b.solid_box(Vector3(3.0, h2, 3.0), Vector3(13.0, h2 * 0.5, -5.0 * cos(deg_to_rad(30.0)) - 1.5), Palette.STONE_DARK)
	var h3: float = b.ramp(3.0, 4.0, 55.0, Vector3(17.0, 0.0, 0.0), Palette.ROOF_RED)
	b.solid_box(Vector3(3.0, h3, 3.0), Vector3(17.0, h3 * 0.5, -4.0 * cos(deg_to_rad(55.0)) - 1.5), Palette.ROOF_RED)

	# Scala di legno che porta su un terrazzo
	b.stairs(2.4, 8, 0.2, 0.42, Vector3(-9.0, 0.0, 0.0), Palette.WOOD)
	b.solid_box(Vector3(4.0, 1.6, 4.0), Vector3(-9.0, 0.8, -3.36 - 2.0), Palette.WOOD_DARK)

	# Piattaforme del salto: 0,4 m e 0,7 m raggiungibili, 1,3 m no.
	b.solid_box(Vector3(1.6, 0.4, 1.6), Vector3(-4.0, 0.2, 9.0), Palette.FLOWER_YELLOW)
	b.solid_box(Vector3(1.6, 0.7, 1.6), Vector3(-6.2, 0.35, 9.0), Palette.FLOWER_BLUE)
	b.solid_box(Vector3(1.6, 1.3, 1.6), Vector3(-8.4, 0.65, 9.0), Palette.FLOWER_PINK)

	# Tunnel: la telecamera deve avvicinarsi senza attraversare le pareti.
	b.solid_box(Vector3(0.6, 2.6, 8.0), Vector3(-1.9, 1.3, -16.0), Palette.STONE)
	b.solid_box(Vector3(0.6, 2.6, 8.0), Vector3(1.9, 1.3, -16.0), Palette.STONE)
	b.solid_box(Vector3(4.4, 0.6, 8.0), Vector3(0.0, 2.9, -16.0), Palette.STONE_DARK)

	_build_cottage(b, Vector3(7.0, 0.0, -14.0))
	_build_pond(b, Vector3(-13.0, 0.0, -12.0), 5.0)
	_build_fence(b, Vector3(-4.0, 0.0, 14.0), 12, Vector3.RIGHT)

	# Alberi e rocce
	var tree_spots: Array[Vector3] = [
		Vector3(-18, 0, 4), Vector3(-22, 0, -4), Vector3(20, 0, -18), Vector3(24, 0, 6),
		Vector3(-6, 0, -26), Vector3(12, 0, 16), Vector3(-16, 0, 18), Vector3(26, 0, -6),
		Vector3(4, 0, -28), Vector3(-26, 0, -18)]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	for spot: Vector3 in tree_spots:
		var color: Color = Palette.LEAF if rng.randf() < 0.6 else Palette.LEAF_LIGHT
		b.tree(spot, rng.randf_range(2.8, 4.2), color)
	for i: int in 8:
		var rock: SphereMesh = SphereMesh.new()
		rock.radius = rng.randf_range(0.3, 0.7)
		rock.height = rock.radius * 1.2
		rock.radial_segments = 8
		rock.rings = 5
		b.decor(rock, Vector3(rng.randf_range(-28, 28), 0.05, rng.randf_range(-28, 28)), Palette.STONE)

	# Erba e fiori (MultiMesh): evitano sentieri e costruzioni.
	var avoid: Array[Rect2] = [
		Rect2(-1.6, -24.0, 3.2, 40.0), Rect2(-17.0, 0.6, 34.0, 2.8),
		Rect2(6.0, -10.0, 13.0, 11.0), Rect2(-11.5, -8.0, 5.0, 8.5),
		Rect2(-19.0, -18.0, 12.0, 12.0), Rect2(-2.5, -21.0, 5.0, 10.0), Rect2(3.0, -18.0, 8.0, 8.0)]
	var tuft: CylinderMesh = CylinderMesh.new()
	tuft.top_radius = 0.0
	tuft.bottom_radius = 0.07
	tuft.height = 0.28
	tuft.radial_segments = 4
	b.scatter(tuft, 2500, Vector3(0, 0.12, 0), Vector2(32, 32), [Palette.GRASS_DARK, Palette.LEAF_LIGHT] as Array[Color], 0.7, 1.4, 11, avoid)
	var flower: SphereMesh = SphereMesh.new()
	flower.radius = 0.07
	flower.height = 0.1
	flower.radial_segments = 8
	flower.rings = 4
	b.scatter(flower, 700, Vector3(0, 0.12, 0), Vector2(30, 30),
		[Palette.FLOWER_PINK, Palette.FLOWER_YELLOW, Palette.FLOWER_WHITE, Palette.FLOWER_BLUE] as Array[Color], 0.8, 1.3, 23, avoid)


func _build_cottage(b: LevelBuilder, base: Vector3) -> void:
	b.solid_box(Vector3(5.0, 3.0, 4.0), base + Vector3(0.0, 1.5, 0.0), Palette.WALL_CREAM)
	var roof: PrismMesh = PrismMesh.new()
	roof.size = Vector3(5.8, 1.8, 4.6)
	b.decor(roof, base + Vector3(0.0, 3.9, 0.0), Palette.ROOF_RED)
	var door: BoxMesh = BoxMesh.new()
	door.size = Vector3(1.0, 1.8, 0.1)
	b.decor(door, base + Vector3(0.0, 0.9, 2.03), Palette.WOOD_DARK)
	var window: BoxMesh = BoxMesh.new()
	window.size = Vector3(0.8, 0.8, 0.1)
	b.decor(window, base + Vector3(-1.6, 1.8, 2.03), Palette.WATER)
	b.decor(window, base + Vector3(1.6, 1.8, 2.03), Palette.WATER)


func _build_pond(b: LevelBuilder, center: Vector3, radius: float) -> void:
	var water: CylinderMesh = CylinderMesh.new()
	water.top_radius = radius
	water.bottom_radius = radius
	water.height = 0.04
	water.radial_segments = 40
	b.decor(water, center + Vector3(0.0, 0.02, 0.0), Palette.WATER)
	# Acqua profonda: un limite invisibile morbido (cilindro) impedisce di entrare oltre la riva.
	var deep: CylinderShape3D = CylinderShape3D.new()
	deep.radius = radius - 0.9
	deep.height = 3.0
	b.invisible_wall(deep, center + Vector3(0.0, 1.5, 0.0))
	# Sassi sulla riva
	for i: int in 14:
		var a: float = TAU * i / 14.0
		var pebble: SphereMesh = SphereMesh.new()
		pebble.radius = 0.22 + 0.08 * sin(i * 1.7)
		pebble.height = pebble.radius * 1.1
		pebble.radial_segments = 8
		pebble.rings = 4
		b.decor(pebble, center + Vector3(cos(a) * (radius + 0.15), 0.06, sin(a) * (radius + 0.15)), Palette.STONE_DARK)


func _build_fence(b: LevelBuilder, start: Vector3, posts: int, direction: Vector3) -> void:
	for i: int in posts:
		b.solid_box(Vector3(0.14, 0.9, 0.14), start + direction * (i * 1.2) + Vector3(0, 0.45, 0), Palette.WOOD)
	var rail_length: float = (posts - 1) * 1.2
	var rail: BoxMesh = BoxMesh.new()
	rail.size = Vector3(rail_length, 0.1, 0.06)
	var mid: Vector3 = start + direction * rail_length * 0.5
	b.decor(rail, mid + Vector3(0, 0.65, 0), Palette.WOOD)
	b.decor(rail, mid + Vector3(0, 0.35, 0), Palette.WOOD)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as PlayerController
	player.position = SPAWN_POSITION
	player.rotation.y = PI  # guarda verso il centro della sandbox (-Z)
	add_child(player)

	camera_rig = CAMERA_SCENE.instantiate() as CameraRig
	camera_rig.target = player
	add_child(camera_rig)
	player.camera_rig = camera_rig

	var hud: Node = HUD_SCENE.instantiate()
	add_child(hud)
	hud.call("setup", player, camera_rig)

	# Animali: un cane socievole nel prato e una volpe timida vicino al laghetto.
	AnimalSpawner.spawn(self, &"sandbox_dog", &"dog", Vector3(-2.0, 0.1, 3.0))
	AnimalSpawner.spawn(self, &"sandbox_fox", &"fox", Vector3(-20.0, 0.1, -6.0))
