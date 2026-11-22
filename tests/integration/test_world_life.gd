extends TestCase
## Fase 12: specie, popolazione, produzione, abilità dei compagni, meteo.


func before_each() -> void:
	GameState.start_new_game()
	GameClock.reset(GameTime.new())


func test_all_species_valid_and_buildable() -> void:
	var zone_ids: Array[String] = ["beach"]
	for z: Dictionary in IslandLayout.ZONES:
		zone_ids.append(String(z["id"]))
	var species: Array[SpeciesDefinition] = Database.all_species()
	assert_gt(float(species.size()), 20.0, "più di 20 specie (D-09)")
	for s: SpeciesDefinition in species:
		assert_false(s.zones.is_empty(), "%s ha una zona" % s.id)
		for z: String in s.zones:
			assert_true(zone_ids.has(z), "%s: zona %s esiste" % [s.id, z])
		for f: String in s.favorite_foods + s.accepted_foods:
			assert_true(Database.item(StringName(f)) != null, "%s: cibo %s esiste" % [s.id, f])
		for it: StringName in [s.companion_item, s.produce_item]:
			assert_true(it == &"" or Database.item(it) != null, "%s: oggetto %s esiste" % [s.id, it])
		assert_true(tr(s.name_key) != s.name_key, "%s ha un nome tradotto" % s.id)
		var v: AnimalVisual = AnimalVisual.create_for(s)
		tree.root.add_child(v)
		v.setup(s, 0)
		assert_gt(float(v.get_child_count()), 0.0, "%s: modello costruito" % s.id)
		v.queue_free()
	await tree.process_frame


func test_population_activates_near_and_releases_far() -> void:
	var root: Node3D = Node3D.new()
	tree.root.add_child(root)
	tree.current_scene = root
	LevelBuilder.new(root).solid_box(Vector3(2000, 1, 2000), Vector3(0, -0.5, 0), Palette.GRASS)
	var player: Node3D = Node3D.new()
	player.add_to_group(&"player")
	root.add_child(player)
	var pop: AnimalPopulation = AnimalPopulation.new()
	root.add_child(pop)
	assert_gt(float(pop.entries.size()), 40.0, "molti punti di comparsa sull'isola")
	var village: Dictionary = pop.entries.filter(func(e: Dictionary) -> bool: return e["id"] == &"village_dog")[0]
	player.global_position = Vector3((village["pos"] as Vector2).x, 0, (village["pos"] as Vector2).y)
	pop._timer = 0.0
	await tree.process_frame
	assert_true(pop.is_active(&"village_dog"), "il cane del villaggio compare vicino a Gioia")
	assert_true(pop.active_count() <= pop.max_active, "limite di animali attivi rispettato")
	assert_false(GameState.animals.has(&"village_dog"), "senza interazioni non entra nei salvataggi")
	player.global_position = Vector3(3000, 0, 3000)
	pop._timer = 0.0
	await tree.process_frame
	await tree.process_frame
	assert_false(pop.is_active(&"village_dog"), "lontano viene rilasciato")
	root.queue_free()
	await tree.process_frame


func test_daily_production() -> void:
	var hen: AnimalState = GameState.animals.ensure(&"hen", &"chicken")
	hen.friendship = 90.0
	for d: int in 3:
		hen.record_visit(d + 1)
	assert_true(AnimalCare.adopt(hen, "Chicchi"))
	var eggs: int = GameState.inventory.count(&"egg")
	assert_eq(AnimalCare.produce(), 1)
	assert_eq(GameState.inventory.count(&"egg"), eggs + 1, "un uovo al giorno (D-24)")
	AnimalCare.set_companion(hen, true)
	assert_eq(AnimalCare.produce(), 0, "solo chi è a casa produce")


func test_companion_finds_items() -> void:
	var dog: AnimalState = GameState.animals.ensure(&"cdog", &"dog")
	dog.friendship = 80.0
	dog.record_visit(1)
	AnimalCare.adopt(dog, "Trova")
	AnimalCare.set_companion(dog, true)
	var flowers: int = GameState.inventory.count(&"flower")
	AnimalCare._companion_finds(1.0)
	assert_eq(GameState.inventory.count(&"flower"), flowers + 1, "il cane trova un fiore (D-18)")


func test_weather_is_deterministic_and_rain_waters_garden() -> void:
	assert_eq(WeatherModel.at(1, 10), WeatherModel.Kind.CLEAR, "il primo giorno è sereno")
	assert_eq(WeatherModel.at(7, 14), WeatherModel.at(7, 15), "stesso blocco, stesso meteo")
	var rainy: int = 0
	var day_rain: Vector2i = Vector2i(-1, -1)
	for d: int in range(2, 60):
		for h: int in [0, 6, 12, 18]:
			if WeatherModel.is_raining(d, h):
				rainy += 1
				if day_rain.x < 0:
					day_rain = Vector2i(d, h)
	assert_gt(float(rainy), 10.0, "piove ogni tanto")
	assert_lt(float(rainy), 80.0, "ma non sempre")
	GameState.garden.plant(0, &"carrot", 0.0)
	GameClock.reset(GameTime.new(float((day_rain.x - 1) * 1440 + day_rain.y * 60 + 30)))
	AnimalCare.tick()
	assert_true(GameState.garden.is_watered(0, GameClock.time.get_total_minutes()), "la pioggia annaffia l'orto")


func test_story_reaches_new_chapters() -> void:
	var ids: Array[StringName] = []
	for q: Dictionary in QuestData.all():
		ids.append(q["id"])
	for id: StringName in [&"m13_farm", &"m15_beach", &"m16_lake", &"m17_mountain", &"m18_shelter_reborn"]:
		assert_true(ids.has(id), "capitolo %s" % id)
