extends Node3D
## Interno della casa di Gioia (GDD § 8, D-14): stanze affiancate costruite da
## `GameState.home`, mobili posizionati, porta d'uscita, catalogo per arredare.
## Stile "casa delle bambole": parete di fondo alta, pareti laterali e frontali
## basse, così la telecamera vede sempre dentro.

const PLAYER_SCENE: PackedScene = preload("res://systems/player/player.tscn")
const CAMERA_SCENE: PackedScene = preload("res://systems/camera/camera_rig.tscn")
const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")
const ISLAND: String = "res://scenes/world/island.tscn"
const WALL_H: float = 2.6
const LOW_WALL_H: float = 0.9
const WALL_T: float = 0.2

var player: PlayerController
var camera_rig: CameraRig
var build_mode: BuildMode
var _rooms_root: Node3D
var _furniture_root: Node3D


func _ready() -> void:
	_build_environment()
	_rooms_root = Node3D.new()
	_rooms_root.name = "Rooms"
	add_child(_rooms_root)
	_furniture_root = Node3D.new()
	_furniture_root.name = "Furniture"
	add_child(_furniture_root)
	rebuild()
	GameState.home.changed.connect(rebuild)

	player = PLAYER_SCENE.instantiate() as PlayerController
	player.position = entrance_position() + Vector3(0, 0.1, -1.0)
	player.rotation.y = PI
	var saved: Dictionary = SaveManager.take_pending_player(scene_file_path)
	if not saved.is_empty():
		player.position = Vector3(float(saved["x"]), float(saved["y"]) + 0.1, float(saved["z"]))
	SceneRouter.take_spawn()
	add_child(player)
	camera_rig = CAMERA_SCENE.instantiate() as CameraRig
	camera_rig.target = player
	camera_rig.max_distance = 6.0
	camera_rig.distance = 5.0
	camera_rig.initial_pitch_degrees = -38.0
	camera_rig.auto_align_enabled = false
	add_child(camera_rig)
	player.camera_rig = camera_rig

	var companions: CompanionManager = CompanionManager.new()
	companions.has_home = false
	add_child(companions)

	build_mode = BuildMode.new()
	build_mode.camera_rig = camera_rig
	build_mode.player = player
	add_child(build_mode)

	var hud: Node = HUD_SCENE.instantiate()
	add_child(hud)
	hud.call("setup", player, camera_rig)
	hud.call("attach_build_mode", build_mode)


func _exit_tree() -> void:
	if GameState.home.changed.is_connected(rebuild):
		GameState.home.changed.disconnect(rebuild)


## Centro della porta d'ingresso (a terra, sul bordo sud del soggiorno).
func entrance_position() -> Vector3:
	return Vector3(HomeLayout.ROOM_CELLS.x * HomeLayout.CELL * 0.5, 0.0, HomeLayout.ROOM_CELLS.y * HomeLayout.CELL)


## Ricostruisce stanze e mobili (dopo ogni modifica alla casa).
func rebuild() -> void:
	for c: Node in _rooms_root.get_children():
		c.queue_free()
	for c: Node in _furniture_root.get_children():
		c.queue_free()
	var home: HomeLayout = GameState.home
	var rw: float = HomeLayout.ROOM_CELLS.x * HomeLayout.CELL
	var rd: float = HomeLayout.ROOM_CELLS.y * HomeLayout.CELL
	var b: LevelBuilder = LevelBuilder.new(_rooms_root)
	for i: int in home.rooms.size():
		var room: StringName = home.rooms[i]
		var x0: float = i * rw
		b.solid_box(Vector3(rw, 0.2, rd), Vector3(x0 + rw * 0.5, -0.1, rd * 0.5), home.floor_color(room))
		# Parete di fondo (alta)
		b.solid_box(Vector3(rw, WALL_H, WALL_T), Vector3(x0 + rw * 0.5, WALL_H * 0.5, -WALL_T * 0.5), home.wall_color(room))
		_window(b, Vector3(x0 + rw * 0.5, 1.55, 0.01))
		# Parete frontale bassa, con apertura per la porta nel soggiorno
		var wall_color: Color = home.wall_color(room).darkened(0.05)
		if i == 0:
			var door_w: float = (HomeLayout.DOOR_HALF * 2 + 1) * HomeLayout.CELL
			var side: float = (rw - door_w) * 0.5
			b.solid_box(Vector3(side, LOW_WALL_H, WALL_T), Vector3(x0 + side * 0.5, LOW_WALL_H * 0.5, rd + WALL_T * 0.5), wall_color)
			b.solid_box(Vector3(side, LOW_WALL_H, WALL_T), Vector3(x0 + rw - side * 0.5, LOW_WALL_H * 0.5, rd + WALL_T * 0.5), wall_color)
		else:
			b.solid_box(Vector3(rw, LOW_WALL_H, WALL_T), Vector3(x0 + rw * 0.5, LOW_WALL_H * 0.5, rd + WALL_T * 0.5), wall_color)
		# Pareti laterali basse (con passaggio tra stanze)
		if i == 0:
			b.solid_box(Vector3(WALL_T, LOW_WALL_H, rd), Vector3(x0 - WALL_T * 0.5, LOW_WALL_H * 0.5, rd * 0.5), wall_color)
		if i == home.rooms.size() - 1:
			b.solid_box(Vector3(WALL_T, LOW_WALL_H, rd), Vector3(x0 + rw + WALL_T * 0.5, LOW_WALL_H * 0.5, rd * 0.5), wall_color)
		else:
			var gap: float = (HomeLayout.DOOR_HALF * 2 + 1) * HomeLayout.CELL
			var seg: float = (rd - gap) * 0.5
			b.solid_box(Vector3(WALL_T, WALL_H, seg), Vector3(x0 + rw, WALL_H * 0.5, seg * 0.5), wall_color)
			b.solid_box(Vector3(WALL_T, WALL_H, seg), Vector3(x0 + rw, WALL_H * 0.5, rd - seg * 0.5), wall_color)
	# Porta d'uscita e catalogo dell'arredamento
	var exit_door: ExitDoor = ExitDoor.new()
	exit_door.position = entrance_position() + Vector3(0, 0, 0.4)
	exit_door.target_scene = ISLAND
	exit_door.target_spawn = &"home_door"
	exit_door.title_key = "DOOR_EXIT"
	_rooms_root.add_child(exit_door)
	var catalog: FurnitureCatalogStand = FurnitureCatalogStand.new()
	catalog.position = entrance_position() + Vector3(-2.6, 0, -0.6)
	_rooms_root.add_child(catalog)
	for p: Dictionary in home.placements:
		_furniture_root.add_child(make_furniture_node(p))


## Nodo di un mobile posizionato, con collisione (tranne i tappeti).
static func make_furniture_node(p: Dictionary) -> Node3D:
	var id: StringName = p["id"]
	var rot: int = int(p["rot"])
	var fp: Vector2i = FurnitureCatalog.footprint(id, rot)
	var color: Color = FurnitureCatalog.COLORS[int(p["color"]) % FurnitureCatalog.COLORS.size()]
	var root: StaticBody3D = StaticBody3D.new()
	root.collision_layer = 0 if FurnitureCatalog.is_flat(id) else 1
	root.position = Vector3((int(p["x"]) + fp.x * 0.5) * HomeLayout.CELL, 0.0, (int(p["y"]) + fp.y * 0.5) * HomeLayout.CELL)
	var model: Node3D = FurnitureBuilder.build(id, color)
	model.rotation.y = -rot * PI * 0.5
	root.add_child(model)
	if not FurnitureCatalog.is_flat(id):
		var cs: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(fp.x * HomeLayout.CELL * 0.9, 1.0, fp.y * HomeLayout.CELL * 0.9)
		cs.shape = box
		cs.position.y = 0.5
		root.add_child(cs)
	return root


func _window(b: LevelBuilder, pos: Vector3) -> void:
	var frame: BoxMesh = BoxMesh.new()
	frame.size = Vector3(1.3, 1.0, 0.05)
	b.decor(frame, pos, Palette.FLOWER_WHITE)
	var glass: BoxMesh = BoxMesh.new()
	glass.size = Vector3(1.1, 0.8, 0.06)
	b.decor(glass, pos + Vector3(0, 0, 0.01), Color("bfe6f7"))


func _build_environment() -> void:
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("2b2436")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("ffe9d0")
	env.ambient_light_energy = Lighting.ambient_energy(0.45)
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60, -25, 0)
	light.light_color = Color("fff1d6")
	light.light_energy = Lighting.sun_energy(0.65)
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 30.0
	add_child(light)
