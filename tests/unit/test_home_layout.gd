extends TestCase


func test_place_and_overlap() -> void:
	var h: HomeLayout = HomeLayout.new()
	assert_true(h.place(&"table", 2, 2, 0))
	assert_false(h.can_place(&"chair", 3, 3, 0), "sovrapposto al tavolo")
	assert_true(h.can_place(&"chair", 5, 2, 0))


func test_rug_can_go_under_furniture() -> void:
	var h: HomeLayout = HomeLayout.new()
	assert_true(h.place(&"rug", 2, 2, 0))
	assert_true(h.place(&"table", 3, 3, 0), "tavolo sopra il tappeto")
	assert_false(h.can_place(&"rug", 3, 3, 0), "due tappeti non si sovrappongono")
	assert_eq(String(h.placements[h.index_at(3, 3)]["id"]), "table", "si seleziona il mobile, non il tappeto")


func test_bounds_and_rotation() -> void:
	var h: HomeLayout = HomeLayout.new()
	assert_false(h.can_place(&"sofa", 14, 0, 0), "esce dalla stanza")
	assert_true(h.can_place(&"sofa", 14, 0, 1), "ruotato ci sta")
	assert_eq(FurnitureCatalog.footprint(&"sofa", 1), Vector2i(2, 5))


func test_entrance_must_stay_free() -> void:
	var h: HomeLayout = HomeLayout.new()
	var door_x: int = HomeLayout.ROOM_CELLS.x / 2
	assert_false(h.can_place(&"plant", door_x, HomeLayout.ROOM_CELLS.y - 1, 0), "la porta resta libera")
	assert_true(h.can_place(&"rug", door_x - 2, HomeLayout.ROOM_CELLS.y - 4, 0), "un tappeto davanti alla porta va bene")


func test_rooms_unlock_and_expand_grid() -> void:
	var h: HomeLayout = HomeLayout.new()
	assert_false(h.can_place(&"bed", 18, 2, 0), "la camera non c'è ancora")
	assert_eq(h.unlock_next_room(), &"bedroom")
	assert_true(h.can_place(&"bed", 18, 2, 0))
	assert_eq(h.room_at_cell(18), &"bedroom")
	assert_false(h.can_place(&"lamp", 16, HomeLayout.ROOM_CELLS.y / 2, 0), "passaggio tra le stanze libero")
	h.unlock_next_room()
	h.unlock_next_room()
	assert_eq(h.unlock_next_room(), &"", "tutte le stanze sbloccate")
	assert_eq(h.room_count(), 4)


func test_remove_returns_item() -> void:
	var h: HomeLayout = HomeLayout.new()
	h.place(&"lamp", 1, 1, 0, 3)
	var removed: Dictionary = h.remove_at(1, 1)
	assert_eq(removed["id"], &"lamp")
	assert_eq(int(removed["color"]), 3)
	assert_true(h.remove_at(1, 1).is_empty())


func test_roundtrip() -> void:
	var h: HomeLayout = HomeLayout.new()
	h.unlock_next_room()
	h.place(&"bed", 18, 2, 1, 2)
	h.set_wall_color(&"living", 3)
	h.set_floor_color(&"bedroom", 2)
	h.exterior_roof = 4
	var c: HomeLayout = HomeLayout.new()
	c.from_dict(h.to_dict())
	assert_eq(c.to_dict(), h.to_dict())
	c.from_dict({"placements": [{"id": "non_esiste"}], "rooms": ["boh"]})
	assert_eq(c.placements.size(), 0, "mobili sconosciuti scartati")
	assert_eq(c.rooms, [&"living"] as Array[StringName])
