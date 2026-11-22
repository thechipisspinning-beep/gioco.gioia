extends TestCase
## Isola: caricamento dei blocchi, acqua profonda, giorno/notte, prestazioni.

const PLAYER_SCENE: PackedScene = preload("res://systems/player/player.tscn")

var _root: Node3D


func before_each() -> void:
	GameState.start_new_game()
	_root = Node3D.new()
	tree.root.add_child(_root)
	tree.current_scene = _root


func after_each() -> void:
	WorldQuery.ground_height = Callable()
	for a: StringName in [&"move_forward", &"run"]:
		Input.action_release(a)
	_root.queue_free()
	await tree.process_frame


func test_streamer_loads_and_unloads_chunks() -> void:
	var s: WorldStreamer = WorldStreamer.new()
	s.load_radius = 2
	s.detail_radius = 1
	var t: Node3D = Node3D.new()
	_root.add_child(t)
	_root.add_child(s)
	s.target = t
	s.build_all_now()
	assert_eq(s.loaded_count(), 25, "5 × 5 blocchi attorno al giocatore")
	assert_true(s.is_loaded(Vector2i(0, 0)))
	# Il giocatore si sposta lontano: i vecchi blocchi vengono scaricati.
	t.global_position = Vector3(640.0, 0.0, 0.0)
	for i: int in 40:
		await tree.process_frame
	assert_false(s.is_loaded(Vector2i(0, 0)), "blocco lontano scaricato")
	assert_true(s.is_loaded(Vector2i(10, 0)), "blocco vicino caricato")
	assert_lt(float(s.loaded_count()), 40.0, "la memoria non cresce")


func test_chunk_build_time_is_reasonable() -> void:
	var terrain: TerrainModel = TerrainModel.new()
	# Un blocco attraversato da sentieri (caso peggiore) e uno lontano da ogni sentiero.
	var ms: float = 0.0
	for c: Vector2i in [Vector2i(0, 1), Vector2i(-8, 6)]:
		var start: int = Time.get_ticks_usec()
		var chunk: TerrainChunk = TerrainChunk.new()
		chunk.build(terrain, c, true)
		_root.add_child(chunk)
		var t: float = (Time.get_ticks_usec() - start) / 1000.0
		print("    blocco %s con dettagli: %.1f ms" % [c, t])
		ms = maxf(ms, t)
	assert_lt(ms, 400.0, "un blocco deve costruirsi in tempi accettabili")


func test_player_walks_on_terrain_and_stops_at_deep_water() -> void:
	var s: WorldStreamer = WorldStreamer.new()
	s.load_radius = 2
	_root.add_child(s)
	WorldQuery.ground_height = s.height_at
	# Punto di partenza sulla costa est, rivolti verso il mare (+X).
	var x: float = 700.0
	while s.height_at(x, 0.0) > 3.0 and x < 1100.0:
		x += 4.0
	x -= 30.0
	var player: PlayerController = PLAYER_SCENE.instantiate() as PlayerController
	player.position = Vector3(x, s.height_at(x, 0.0) + 0.5, 0.0)
	var holder: Node3D = Node3D.new()
	_root.add_child(holder)
	holder.global_position = player.position
	s.target = holder
	s.build_all_now()
	_root.add_child(player)
	s.target = player
	player.rotation.y = PI * 0.5
	await wait_physics_frames(10)
	Input.action_press(&"move_right")  # senza telecamera: +X
	Input.action_press(&"run")
	await wait_physics_frames(600)
	Input.action_release(&"move_right")
	Input.action_release(&"run")
	var ground: float = s.height_at(player.global_position.x, player.global_position.z)
	assert_gt(player.global_position.x, x + 10.0, "Gioia ha camminato verso il mare")
	assert_gt(ground, IslandLayout.DEEP_WATER, "ma non è entrata nell'acqua profonda")
	assert_gt(player.global_position.y, ground - 0.5, "ed è rimasta sopra il terreno")


func test_day_night_sun_and_moon() -> void:
	var dn: DayNight = DayNight.new()
	_root.add_child(dn)
	dn.apply_hour(12.0)
	assert_true(dn.sun.visible, "a mezzogiorno c'è il sole")
	assert_lt(dn.sun.global_transform.basis.z.y * -1.0, -0.5, "e la luce viene dall'alto")
	assert_false(dn.moon.visible, "niente luna di giorno")
	dn.apply_hour(0.0)
	assert_false(dn.sun.visible, "a mezzanotte niente sole")
	assert_true(dn.moon.visible, "c'è la luna")
	assert_lt(dn.environment.ambient_light_energy, Lighting.ambient_energy(0.3), "la notte è più buia")
