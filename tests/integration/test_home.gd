extends TestCase
## Casa: interno costruito dai dati, arredamento, mangiatoia automatica.

const INTERIOR: PackedScene = preload("res://scenes/interiors/home_interior.tscn")

var _scene: Node3D


func before_each() -> void:
	GameState.start_new_game()


func after_each() -> void:
	if _scene != null:
		_scene.queue_free()
		_scene = null
	await tree.process_frame


func _open_interior() -> Node3D:
	_scene = INTERIOR.instantiate() as Node3D
	tree.root.add_child(_scene)
	tree.current_scene = _scene
	return _scene


func test_interior_builds_furniture_from_layout() -> void:
	var s: Node3D = _open_interior()
	await tree.process_frame
	var furniture: Node = s.get_node("Furniture")
	assert_eq(furniture.get_child_count(), GameState.home.placements.size(), "un nodo per ogni mobile")


func test_build_mode_place_and_pick_up() -> void:
	var s: Node3D = _open_interior()
	await tree.process_frame
	var bm: BuildMode = s.get("build_mode") as BuildMode
	bm.open()
	var chairs_before: int = GameState.inventory.count(GameState.furniture_item(&"chair"))
	bm.select(&"chair")
	bm.cursor = Vector2i(2, 8)
	bm.place_or_pick()
	assert_eq(GameState.inventory.count(GameState.furniture_item(&"chair")), chairs_before - 1, "sedia tolta dall'inventario")
	assert_eq(GameState.home.count_of(&"chair"), 1, "sedia in casa")
	await tree.process_frame
	assert_eq((s.get_node("Furniture") as Node).get_child_count(), GameState.home.placements.size(), "la scena si aggiorna")
	# Raccogliere il letto per spostarlo
	bm.select(&"")
	bm.cursor = Vector2i(1, 1)
	bm.place_or_pick()
	assert_eq(bm.selected, &"bed", "letto raccolto e selezionato")
	assert_eq(GameState.home.count_of(&"bed"), 0)
	# Cerca un punto libero qualsiasi per rimettere il letto.
	var spot: Vector2i = Vector2i(-1, -1)
	for y: int in HomeLayout.ROOM_CELLS.y:
		for x: int in HomeLayout.ROOM_CELLS.x:
			if spot.x < 0 and GameState.home.can_place(&"bed", x, y, bm.rot):
				spot = Vector2i(x, y)
	assert_true(spot.x >= 0, "c'è un posto libero per il letto")
	bm.cursor = spot
	bm.place_or_pick()
	assert_eq(GameState.home.count_of(&"bed"), 1, "letto rimesso altrove")
	bm.close()
	assert_false(bm.active)


func test_cannot_place_on_top_of_other_furniture() -> void:
	var s: Node3D = _open_interior()
	await tree.process_frame
	var bm: BuildMode = s.get("build_mode") as BuildMode
	bm.open()
	bm.select(&"lamp")
	bm.cursor = Vector2i(2, 2)  # sopra il letto
	bm.place_or_pick()
	assert_eq(GameState.home.count_of(&"lamp"), 0, "posizione occupata")
	bm.close()


func test_feeder_feeds_hungry_animals_at_home() -> void:
	var a: AnimalState = GameState.animals.ensure(&"hungry", &"dog")
	a.friendship = 80.0
	a.record_visit(1)
	AnimalCare.adopt(a, "Fame")
	a.hunger = 0.1
	var before: int = Feeder.portions()
	assert_eq(Feeder.feed_hungry_animals(), 1)
	assert_almost_eq(a.hunger, 1.0)
	assert_eq(Feeder.portions(), before - 1)
	AnimalCare.set_companion(a, true)
	a.hunger = 0.1
	assert_eq(Feeder.feed_hungry_animals(), 0, "chi è a passeggio non mangia dalla mangiatoia")


func test_feeder_refill_uses_kibble() -> void:
	var f: Feeder = Feeder.new()
	tree.root.add_child(f)
	GameState.flags[Feeder.FLAG] = 0
	var kibble: int = GameState.inventory.count(&"kibble")
	f.perform_interaction("refill")
	assert_eq(GameState.inventory.count(&"kibble"), kibble - Feeder.KIBBLE_PER_REFILL)
	assert_eq(Feeder.portions(), Feeder.KIBBLE_PER_REFILL * Feeder.PORTIONS_PER_KIBBLE)
	f.queue_free()


func test_expansion_needs_permit() -> void:
	assert_eq(int(GameState.flags.get("room_tokens", 0)), 0)
	GameState.flags["room_tokens"] = 1
	var room: StringName = GameState.home.unlock_next_room()
	assert_eq(room, &"bedroom")
