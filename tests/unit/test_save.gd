extends TestCase
## Salvataggi: formato, migrazione, scrittura sicura, copia di riserva,
## ripristino completo dello stato.

const TEST_DIR: String = "user://test_saves"


func before_each() -> void:
	SaveManager.save_dir = TEST_DIR
	for i: int in range(1, SaveManager.SLOT_COUNT + 1):
		SaveManager.delete_slot(i)
	GameState.start_new_game()
	GameClock.reset(GameTime.new())


func after_each() -> void:
	for i: int in range(1, SaveManager.SLOT_COUNT + 1):
		SaveManager.delete_slot(i)
	SaveManager.save_dir = SaveManager.SAVE_DIR
	SaveManager.current_slot = 0


func test_codec_roundtrip() -> void:
	var text: String = SaveCodec.encode({"a": 1}, {"day": 3}, 1000)
	var doc: Dictionary = SaveCodec.decode(text)
	assert_eq(int(doc["schema_version"]), SaveCodec.CURRENT_VERSION)
	assert_eq(int((doc["game"] as Dictionary)["a"]), 1)


func test_codec_rejects_garbage_and_future_versions() -> void:
	assert_true(SaveCodec.decode("non è json {{{").is_empty())
	assert_true(SaveCodec.decode("{\"ciao\": 1}").is_empty())
	assert_true(SaveCodec.decode(JSON.stringify({"schema_version": 999, "game": {}})).is_empty(), "salvataggio di una versione futura")


func test_full_state_roundtrip() -> void:
	var dog: AnimalState = GameState.animals.ensure(&"dog_x", &"dog", 2)
	dog.friendship = 80.0
	dog.record_visit(1)
	AnimalCare.adopt(dog, "Biscotto")
	AnimalCare.set_companion(dog, true)
	GameState.inventory.add(&"medicine", 2)
	GameState.discoveries.mark_species_met(&"dog", 1, 9)
	GameState.discoveries.mark_favorite_food(&"dog", &"kibble")
	GameState.serene_mode = true
	GameState.flags["prova"] = 7
	GameClock.time.advance_game_minutes(3000.0)
	var minutes: float = GameClock.time.get_total_minutes()
	assert_true(SaveManager.save_game(2))

	GameState.start_new_game()
	GameClock.reset(GameTime.new())
	assert_true(SaveManager.load_game(2))
	var d: AnimalState = GameState.animals.get_animal(&"dog_x")
	assert_true(d != null, "animale ripristinato")
	assert_eq(d.given_name, "Biscotto")
	assert_eq(d.location, AnimalState.Location.COMPANION)
	assert_eq(d.variant, 2)
	assert_eq(GameState.inventory.count(&"medicine"), 2)
	assert_true(GameState.discoveries.has_met(&"dog"))
	assert_eq(GameState.discoveries.known_favorite_foods(&"dog"), [&"kibble"] as Array[StringName])
	assert_true(GameState.serene_mode)
	assert_eq(int(GameState.flags["prova"]), 7)
	assert_almost_eq(GameClock.time.get_total_minutes(), minutes)
	assert_eq(SaveManager.current_slot, 2)


func test_slots_are_independent() -> void:
	GameState.inventory.add(&"apple", 50)
	SaveManager.save_game(1)
	GameState.start_new_game()
	SaveManager.save_game(3)
	SaveManager.load_game(1)
	assert_gt(float(GameState.inventory.count(&"apple")), 50.0)
	SaveManager.load_game(3)
	assert_lt(float(GameState.inventory.count(&"apple")), 50.0)
	assert_true(SaveManager.read_slot(2).is_empty(), "slot 2 vuoto")


func test_corrupted_save_falls_back_to_backup() -> void:
	GameState.inventory.add(&"apple", 1)
	SaveManager.save_game(1)  # prima versione
	GameState.inventory.add(&"apple", 1)
	SaveManager.save_game(1)  # seconda versione: la prima diventa .bak
	var path: String = TEST_DIR.path_join("slot_1.json")
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{ rovinato")  # simula un file danneggiato
	f.close()
	assert_true(SaveManager.load_game(1), "si carica la copia di riserva")
	assert_eq(GameState.inventory.count(&"apple"), 6, "dalla copia di riserva (5 iniziali + 1)")


func test_summary_for_menu() -> void:
	var dog: AnimalState = GameState.animals.ensure(&"dog_x", &"dog")
	dog.friendship = 80.0
	dog.record_visit(1)
	AnimalCare.adopt(dog, "Biscotto")
	GameState.discoveries.mark_species_met(&"dog", 1, 9)
	SaveManager.save_game(1)
	var s: Dictionary = SaveManager.slot_summary(1)
	assert_eq(int(s["day"]), 1)
	assert_eq(int(s["adopted"]), 1)
	assert_eq(int(s["species_met"]), 1)
	assert_true(SaveManager.slot_summary(2).is_empty())


func test_most_recent_slot() -> void:
	assert_eq(SaveManager.most_recent_slot(), 0)
	assert_false(SaveManager.has_any_save())
	SaveManager.save_game(2)
	assert_eq(SaveManager.most_recent_slot(), 2)
	assert_true(SaveManager.has_any_save())


func test_invalid_slot_rejected() -> void:
	assert_false(SaveManager.save_game(0))
	assert_false(SaveManager.save_game(SaveManager.SLOT_COUNT + 1))
	assert_false(SaveManager.load_game(2), "slot vuoto")
