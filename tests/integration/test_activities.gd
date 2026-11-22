extends TestCase
## Orto, fornello e piatti di Gioia nel gioco.


func before_each() -> void:
	GameState.start_new_game()
	GameClock.reset(GameTime.new())


func test_garden_plot_full_cycle() -> void:
	var plot: GardenPlot = GardenPlot.new()
	plot.index = 0
	tree.root.add_child(plot)
	var ids: Array[String] = []
	for a: Dictionary in plot.get_interaction_actions():
		ids.append(str(a["id"]))
	assert_true(ids.has("plant:carrot"), "si possono piantare le carote (semi iniziali)")
	plot.perform_interaction("plant:carrot")
	assert_eq(GameState.garden.plots[0]["plant"], &"carrot")
	assert_true(GameState.garden.is_watered(0, GameClock.time.get_total_minutes()), "annaffiata appena piantata")
	# Un giorno annaffiando due volte: pronta
	GameClock.time.advance_game_minutes(12.0 * 60.0)
	AnimalCare.tick()
	plot.perform_interaction("water")
	GameClock.time.advance_game_minutes(12.0 * 60.0)
	AnimalCare.tick()
	assert_true(GameState.garden.is_ready(0), "carote pronte")
	var carrots: int = GameState.inventory.count(&"carrot")
	plot.perform_interaction("harvest")
	assert_eq(GameState.inventory.count(&"carrot"), carrots + 3)
	assert_true(GameState.garden.is_empty(0))
	plot.queue_free()


func test_cooking_quest_and_meal_buff() -> void:
	GameState.inventory.add(&"apple", 2)
	GameState.inventory.add(&"strawberry", 2)
	var panel: CookingPanel = CookingPanel.new()
	tree.root.add_child(panel)
	panel._finish(RecipeData.get_recipe(&"fruit_salad"), 0)
	assert_eq(GameState.inventory.count(&"fruit_salad"), 1)
	assert_false(GameState.has_buff(&"good_mood"))
	assert_true(GameState.eat_meal(&"fruit_salad"))
	assert_true(GameState.has_buff(&"good_mood"), "buonumore attivo")
	GameClock.time.advance_game_minutes(200.0)
	assert_false(GameState.has_buff(&"good_mood"), "il bonus finisce")
	panel.close()
	panel.queue_free()


func test_good_mood_boosts_friendship() -> void:
	var dog: SpeciesDefinition = Database.species(&"dog")
	var a: AnimalState = AnimalState.new(&"x", &"dog")
	var b: AnimalState = AnimalState.new(&"y", &"dog")
	var normal: float = TrustModel.interact(a, dog, TrustModel.Action.PET, 1).gain
	var happy: float = TrustModel.interact(b, dog, TrustModel.Action.PET, 1, 1, 1.25).gain
	assert_almost_eq(happy, normal * 1.25)


func test_pet_treats_are_dog_favorite() -> void:
	assert_eq(Database.species(&"dog").food_preference(&"pet_treat"), 2)
	assert_eq(Database.species(&"fox").food_preference(&"berry_mix"), 2)
	assert_eq(Database.species(&"dog").food_preference(&"fruit_salad"), 0, "i piatti di Gioia non sono per animali")
