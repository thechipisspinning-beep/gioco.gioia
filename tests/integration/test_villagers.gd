extends TestCase
## Abitanti, veterinaria, negozio e oggetti da raccogliere.

const VILLAGER: PackedScene = preload("res://systems/npc/villager.tscn")

var _root: Node3D


func before_each() -> void:
	GameState.start_new_game()
	GameClock.reset(GameTime.new())
	_root = Node3D.new()
	tree.root.add_child(_root)
	tree.current_scene = _root
	LevelBuilder.new(_root).solid_box(Vector3(100, 1, 100), Vector3(0, -0.5, 0), Palette.GRASS)


func after_each() -> void:
	_root.queue_free()
	await tree.process_frame


func _villager(id: StringName) -> Villager:
	for d: Dictionary in VillagerData.ALL:
		if d["id"] == id:
			var v: Villager = VILLAGER.instantiate() as Villager
			v.setup(d, Vector3(0, 0.1, 0))
			v.position = Vector3(0, 0.1, 0)
			_root.add_child(v)
			return v
	return null


func test_villager_is_not_the_player_and_wanders_nearby() -> void:
	var v: Villager = _villager(&"sofia")
	await wait_physics_frames(300)
	assert_false(v.is_in_group(&"player"), "un abitante non è Gioia")
	assert_lt(v.global_position.distance_to(v.anchor), 5.5, "resta vicino al suo posto")


func test_talking_advances_quests_and_shows_dialogue() -> void:
	var v: Villager = _villager(&"sofia")
	var said: Array[String] = []
	var on_line: Callable = func(_who: String, text: String) -> void: said.append(text)
	EventBus.dialogue_requested.connect(on_line)
	v.perform_interaction("talk")
	EventBus.dialogue_requested.disconnect(on_line)
	assert_eq(said.size(), 1, "una battuta")
	assert_eq(GameState.quests.status(&"m01_welcome"), QuestLog.Status.COMPLETED, "parlare con Sofia completa la prima missione")


func test_vet_cures_sick_animals_for_coins() -> void:
	var v: Villager = _villager(&"marta")
	var a: AnimalState = GameState.animals.ensure(&"vdog", &"dog")
	a.friendship = 80.0
	a.record_visit(1)
	AnimalCare.adopt(a, "Malatino")
	a.health = AnimalState.Health.SICK
	a.sick_since_minutes = GameClock.time.get_total_minutes()
	GameState.coins = 100
	var ids: Array[String] = []
	for act: Dictionary in v.get_interaction_actions():
		ids.append(str(act["id"]))
	assert_true(ids.has("vet"))
	v.perform_interaction("vet")
	assert_eq(a.health, AnimalState.Health.CONVALESCENT, "curato")
	assert_eq(GameState.coins, 100 - VillagerData.VET_PRICE)


func test_shop_buy_and_sell() -> void:
	var shop: ShopPanel = ShopPanel.new()
	_root.add_child(shop)
	GameState.coins = 50
	var before: int = GameState.inventory.count(&"kibble")
	shop._buy(8, func() -> void: GameState.inventory.add(&"kibble"))
	assert_eq(GameState.coins, 42)
	assert_eq(GameState.inventory.count(&"kibble"), before + 1)
	shop._buy(999, func() -> void: GameState.inventory.add(&"kibble"))
	assert_eq(GameState.coins, 42, "niente acquisti senza monete")
	shop.close()


func test_collectible_pick_and_daily_respawn() -> void:
	var c: Collectible = Collectible.create(&"flower", "test_flower_1", Vector3.ZERO)
	_root.add_child(c)
	var flowers: int = GameState.inventory.count(&"flower")
	c.perform_interaction("pick")
	assert_eq(GameState.inventory.count(&"flower"), flowers + 1)
	assert_true(Collectible.is_picked_today("test_flower_1"))
	var again: Collectible = Collectible.create(&"flower", "test_flower_1", Vector3.ZERO)
	_root.add_child(again)
	await tree.process_frame
	assert_false(is_instance_valid(again), "lo stesso giorno non ricompare")
	GameClock.time.advance_game_minutes(1440.0)
	assert_false(Collectible.is_picked_today("test_flower_1"), "il giorno dopo ricompare")
