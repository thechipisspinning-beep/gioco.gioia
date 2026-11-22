extends TestCase
## Verifica il "feeling" del movimento con la fisica reale (headless):
## velocità di camminata/corsa, frenata, salto, pendenze, recupero da cadute.

const PLAYER_SCENE: PackedScene = preload("res://systems/player/player.tscn")
const ACTIONS: Array[StringName] = [&"move_forward", &"move_back", &"move_left", &"move_right", &"run", &"jump"]

var _root: Node3D
var _player: PlayerController


func before_each() -> void:
	_root = Node3D.new()
	tree.root.add_child(_root)
	var b: LevelBuilder = LevelBuilder.new(_root)
	b.solid_box(Vector3(200.0, 1.0, 200.0), Vector3(0.0, -0.5, 0.0), Palette.GRASS)
	_player = PLAYER_SCENE.instantiate() as PlayerController
	_player.position = Vector3(0.0, 0.05, 0.0)
	_root.add_child(_player)


func after_each() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)
	_root.queue_free()
	await tree.process_frame


func test_walk_reaches_walk_speed() -> void:
	await wait_physics_frames(10)
	Input.action_press(&"move_forward")
	await wait_physics_frames(60)
	assert_almost_eq(_player.get_horizontal_speed(), _player.walk_speed, 0.1, "velocità di camminata")
	assert_lt(_player.global_position.z, -2.0, "Gioia è avanzata verso -Z")


func test_run_reaches_run_speed() -> void:
	await wait_physics_frames(10)
	Input.action_press(&"move_forward")
	Input.action_press(&"run")
	await wait_physics_frames(60)
	assert_true(_player.is_running(), "stato di corsa")
	assert_almost_eq(_player.get_horizontal_speed(), _player.run_speed, 0.1, "velocità di corsa")


func test_analog_input_walks_slower() -> void:
	await wait_physics_frames(10)
	Input.action_press(&"move_forward", 0.5)
	await wait_physics_frames(60)
	var speed: float = _player.get_horizontal_speed()
	assert_lt(speed, _player.walk_speed * 0.8, "con mezzo stick si cammina piano")
	assert_gt(speed, _player.walk_speed * 0.2, "ma ci si muove")


func test_stops_quickly_when_released() -> void:
	await wait_physics_frames(10)
	Input.action_press(&"move_forward")
	Input.action_press(&"run")
	await wait_physics_frames(60)
	Input.action_release(&"move_forward")
	Input.action_release(&"run")
	await wait_physics_frames(18)  # 0,3 s
	assert_lt(_player.get_horizontal_speed(), 0.05, "fermata entro 0,3 s")


func test_turns_to_face_movement() -> void:
	await wait_physics_frames(10)
	Input.action_press(&"move_right")
	await wait_physics_frames(45)
	# Verso +X il corpo (fronte = +Z locale) deve avere yaw ≈ +90°.
	assert_almost_eq(wrapf(_player.rotation.y, -PI, PI), PI * 0.5, 0.1, "orientamento verso destra")


func test_jump_height_is_small() -> void:
	await wait_physics_frames(20)
	var start_y: float = _player.global_position.y
	Input.action_press(&"jump")
	await wait_physics_frames(1)
	Input.action_release(&"jump")
	var apex: float = start_y
	for i: int in 60:
		await tree.physics_frame
		apex = maxf(apex, _player.global_position.y)
	var height: float = apex - start_y
	assert_gt(height, 0.7, "salto abbastanza alto per gradini da 0,7 m")
	assert_lt(height, 1.0, "salto piccolo (D-13)")
	assert_true(_player.is_on_floor(), "atterrata")


func test_cannot_jump_in_air_twice() -> void:
	await wait_physics_frames(20)
	Input.action_press(&"jump")
	await wait_physics_frames(1)
	Input.action_release(&"jump")
	await wait_physics_frames(15)
	var vy_before: float = _player.velocity.y
	Input.action_press(&"jump")
	await wait_physics_frames(1)
	Input.action_release(&"jump")
	assert_lt(_player.velocity.y, vy_before + 0.01, "nessun doppio salto")


func test_climbs_30_degree_slope() -> void:
	var b: LevelBuilder = LevelBuilder.new(_root)
	var top: float = b.ramp(3.0, 6.0, 30.0, Vector3(0.0, 0.0, -1.0), Palette.STONE)
	await wait_physics_frames(10)
	Input.action_press(&"move_forward")
	await wait_physics_frames(150)
	assert_gt(_player.global_position.y, top * 0.8, "salita sulla rampa a 30°")


func test_cannot_climb_55_degree_slope() -> void:
	var b: LevelBuilder = LevelBuilder.new(_root)
	b.ramp(3.0, 6.0, 55.0, Vector3(0.0, 0.0, -1.0), Palette.STONE)
	await wait_physics_frames(10)
	Input.action_press(&"move_forward")
	Input.action_press(&"run")
	await wait_physics_frames(180)
	assert_lt(_player.global_position.y, 1.0, "rampa a 55° troppo ripida")


func test_climbs_stairs() -> void:
	var b: LevelBuilder = LevelBuilder.new(_root)
	b.stairs(2.4, 8, 0.2, 0.42, Vector3(0.0, 0.0, -1.0), Palette.WOOD)
	b.solid_box(Vector3(4.0, 1.6, 4.0), Vector3(0.0, 0.8, -1.0 - 3.36 - 2.0), Palette.WOOD_DARK)
	await wait_physics_frames(10)
	Input.action_press(&"move_forward")
	await wait_physics_frames(150)
	assert_gt(_player.global_position.y, 1.5, "in cima alla scala")


func test_respawns_after_falling_off_world() -> void:
	await wait_physics_frames(60)  # memorizza il punto sicuro
	var safe: Vector3 = _player.global_position
	_player.global_position = Vector3(500.0, -30.0, 500.0)
	await wait_physics_frames(2)
	assert_lt(_player.global_position.distance_to(safe), 0.5, "riportata al punto sicuro")
