extends Node3D
## L'isola di Animal World (Fase 5): terreno a blocchi caricati in streaming,
## mare, ciclo giorno/notte, villaggio, casa di Gioia, animali.

const PLAYER_SCENE: PackedScene = preload("res://systems/player/player.tscn")
const CAMERA_SCENE: PackedScene = preload("res://systems/camera/camera_rig.tscn")
const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")

var player: PlayerController
var camera_rig: CameraRig
var streamer: WorldStreamer
var day_night: DayNight


func _ready() -> void:
	day_night = DayNight.new()
	add_child(day_night)
	streamer = WorldStreamer.new()
	streamer.name = "Terrain"
	add_child(streamer)
	WorldQuery.ground_height = streamer.height_at
	_build_sea()

	player = PLAYER_SCENE.instantiate() as PlayerController
	var start: Vector2 = IslandLayout.PLAYER_START
	player.position = Vector3(start.x, streamer.height_at(start.x, start.y) + 0.3, start.y)
	player.rotation.y = PI
	if SceneRouter.take_spawn() == &"home_door":
		var door: Vector3 = home_door_position()
		player.position = door + Vector3(0, 0.3, 1.6)
		player.rotation.y = 0.0
	var saved: Dictionary = SaveManager.take_pending_player(scene_file_path)
	if not saved.is_empty():
		player.position = Vector3(float(saved["x"]), float(saved["y"]) + 0.3, float(saved["z"]))
		player.rotation.y = float(saved.get("yaw", 0.0))
	# Il terreno sotto Gioia deve esistere prima che la fisica parta.
	var holder: Node3D = Node3D.new()
	add_child(holder)
	holder.global_position = player.position
	streamer.target = holder
	streamer.build_all_now()
	holder.queue_free()
	add_child(player)
	streamer.target = player

	camera_rig = CAMERA_SCENE.instantiate() as CameraRig
	camera_rig.target = player
	add_child(camera_rig)
	player.camera_rig = camera_rig

	_build_village()
	_build_home()
	_spawn_animals()
	_spawn_villagers()

	var tracker: ZoneTracker = ZoneTracker.new()
	tracker.target = player
	add_child(tracker)

	var hud: Node = HUD_SCENE.instantiate()
	add_child(hud)
	hud.call("setup", player, camera_rig)
	if SaveManager.current_slot > 0 and not GameState.flags.get("appearance_done", false):
		hud.call_deferred("open_customization")


func _exit_tree() -> void:
	WorldQuery.ground_height = Callable()


func ground(x: float, z: float) -> float:
	return streamer.height_at(x, z)


func _build_sea() -> void:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(4200, 4200)
	plane.subdivide_width = 0
	plane.subdivide_depth = 0
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = preload("res://art/shaders/water.gdshader")
	var sea: MeshInstance3D = MeshInstance3D.new()
	sea.name = "Sea"
	sea.mesh = plane
	sea.material_override = mat
	sea.position.y = IslandLayout.SEA_LEVEL - 0.05
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sea)


func _build_village() -> void:
	var village: Node3D = Node3D.new()
	village.name = "Village"
	add_child(village)
	var center: Vector2 = IslandLayout.FLAT_AREAS[0]["center"]
	var h: float = ground(center.x, center.y)
	var c: Vector3 = Vector3(center.x, h, center.y)
	BuildingKit.fountain(village, c)
	# Piazza lastricata
	var plaza: CylinderMesh = CylinderMesh.new()
	plaza.top_radius = 11.0
	plaza.bottom_radius = 11.0
	plaza.height = 0.06
	plaza.radial_segments = 40
	LevelBuilder.new(village).decor(plaza, c + Vector3(0, 0.03, 0), Palette.PATH.lerp(Palette.STONE, 0.4))
	# Casette disposte attorno alla piazza, rivolte verso il centro
	var roofs: Array[Color] = [Palette.ROOF_RED, Color("6aa8e8"), Color("8ccf6b"), Color("c79be8"), Color("ffb36b"), Palette.ROOF_RED]
	var walls: Array[Color] = [Palette.WALL_CREAM, Color("fde3d0"), Palette.WALL_CREAM, Color("e9f3ff"), Color("fff3c4"), Color("fde3d0")]
	for i: int in 6:
		var a: float = deg_to_rad(30.0 + i * 60.0)
		var p: Vector3 = c + Vector3(cos(a), 0.0, sin(a)) * 26.0
		p.y = ground(p.x, p.z)
		var yaw: float = rad_to_deg(atan2(c.x - p.x, c.z - p.z))
		BuildingKit.cottage(village, p, yaw, walls[i], roofs[i])
	for i: int in 8:
		var a: float = TAU * i / 8.0 + 0.2
		var p: Vector3 = c + Vector3(cos(a), 0.0, sin(a)) * 13.0
		BuildingKit.lamp_post(village, Vector3(p.x, ground(p.x, p.z), p.z))
	for i: int in 4:
		var a: float = TAU * i / 4.0 + 0.6
		var p: Vector3 = c + Vector3(cos(a), 0.0, sin(a)) * 7.0
		BuildingKit.bench(village, Vector3(p.x, ground(p.x, p.z), p.z), rad_to_deg(atan2(c.x - p.x, c.z - p.z)))
	var kiosk: VetKiosk = VetKiosk.new()
	kiosk.position = c + Vector3(9.0, 0.0, -6.0)
	kiosk.position.y = ground(kiosk.position.x, kiosk.position.z)
	village.add_child(kiosk)


## Porta della casa di Gioia (a terra, sul lato sud).
func home_door_position() -> Vector3:
	var hp: Vector2 = IslandLayout.HOME_POSITION
	var p: Vector3 = Vector3(hp.x, 0.0, hp.y - 6.0 + 2.5 + 0.1)
	p.y = ground(p.x, p.z)
	return p


func _build_home() -> void:
	var home: Node3D = Node3D.new()
	home.name = "GioiaHome"
	add_child(home)
	var hp: Vector2 = IslandLayout.HOME_POSITION
	var base: Vector3 = Vector3(hp.x, ground(hp.x, hp.y), hp.y)
	# Il vecchio rifugio della nonna (D-12): più grande, tetto verde.
	var layout: HomeLayout = GameState.home
	var wall: Color = FurnitureCatalog.WALL_COLORS[layout.exterior_wall]
	var roof: Color = FurnitureCatalog.ROOF_COLORS[layout.exterior_roof]
	# La casa si allarga quando si aggiungono stanze (GDD § 8).
	var width: float = 7.0 + (layout.room_count() - 1) * 3.0
	BuildingKit.cottage(home, base + Vector3((layout.room_count() - 1) * 1.5, 0, -6), 0.0, wall, roof, Vector3(width, 3.2, 5.0))
	var door: ExitDoor = ExitDoor.new()
	door.position = home_door_position() + Vector3(-(layout.room_count() - 1) * 0.0, 0, 0.5)
	door.target_scene = "res://scenes/interiors/home_interior.tscn"
	door.target_spawn = &"entrance"
	door.title_key = "DOOR_ENTER_HOME"
	home.add_child(door)
	var feeder: Feeder = Feeder.new()
	feeder.position = base + Vector3(-6.0, 0.0, 4.0)
	feeder.position.y = ground(feeder.position.x, feeder.position.z)
	home.add_child(feeder)
	# Recinto del giardino
	var g: Callable = ground
	var corners: Array[Vector3] = [base + Vector3(-12, 0, -1), base + Vector3(12, 0, -1), base + Vector3(12, 0, 14), base + Vector3(-12, 0, 14)]
	BuildingKit.fence_line(home, corners[0], corners[1] + Vector3(-9.5, 0, 0), g)
	BuildingKit.fence_line(home, corners[1] + Vector3(-7.5, 0, 0), corners[1], g)
	BuildingKit.fence_line(home, corners[1], corners[2], g)
	BuildingKit.fence_line(home, corners[2], corners[3], g)
	BuildingKit.fence_line(home, corners[3], corners[0], g)
	var mirror: Mirror = Mirror.new()
	mirror.position = base + Vector3(5.0, 0.0, -3.0)
	mirror.position.y = ground(mirror.position.x, mirror.position.z)
	home.add_child(mirror)
	var companions: CompanionManager = CompanionManager.new()
	companions.home_yard = base + Vector3(0, 0.2, 6)
	companions.yard_radius = 7.0
	add_child(companions)


func _spawn_animals() -> void:
	var village: Vector2 = IslandLayout.FLAT_AREAS[0]["center"]
	_spawn(&"village_dog", &"dog", Vector2(village.x - 8.0, village.y + 12.0))
	_spawn(&"forest_fox", &"fox", Vector2(-230.0, 10.0))


func _spawn_villagers() -> void:
	var plaza: Vector2 = IslandLayout.FLAT_AREAS[0]["center"]
	for d: Dictionary in VillagerData.ALL:
		var v: Villager = preload("res://systems/npc/villager.tscn").instantiate() as Villager
		var p: Vector2 = plaza + (d["offset"] as Vector2)
		var anchor: Vector3 = Vector3(p.x, ground(p.x, p.y) + 0.2, p.y)
		v.setup(d, anchor)
		v.position = anchor
		add_child(v)


func _spawn(id: StringName, species: StringName, p: Vector2) -> void:
	AnimalSpawner.spawn(self, id, species, Vector3(p.x, ground(p.x, p.y) + 0.3, p.y))
