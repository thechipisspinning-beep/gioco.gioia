extends TestCase
## La storia principale avanza con gli eventi reali e consegna le ricompense.


func before_each() -> void:
	GameState.start_new_game()
	GameClock.reset(GameTime.new())


func test_story_progression_and_rewards() -> void:
	assert_eq(GameState.quests.status(&"m01_welcome"), QuestLog.Status.ACTIVE, "la prima missione parte subito")
	var coins: int = GameState.coins
	EventBus.npc_talked.emit(&"sofia")
	assert_eq(GameState.quests.status(&"m01_welcome"), QuestLog.Status.COMPLETED)
	assert_eq(GameState.coins, coins + 50, "ricompensa in monete")
	assert_eq(GameState.quests.status(&"m02_first_friend"), QuestLog.Status.ACTIVE, "si sblocca la successiva")
	# Due cuori con un cane
	var dog: AnimalState = GameState.animals.ensure(&"qdog", &"dog")
	dog.friendship = 45.0
	EventBus.friendship_changed.emit(&"qdog", dog.friendship)
	assert_eq(GameState.quests.status(&"m02_first_friend"), QuestLog.Status.COMPLETED)
	# Adozione
	dog.record_visit(1)
	dog.friendship = 70.0
	AnimalCare.adopt(dog, "Biscotto")
	assert_eq(GameState.quests.status(&"m03_adopt"), QuestLog.Status.COMPLETED)
	assert_eq(GameState.inventory.count(GameState.furniture_item(&"pet_bowl")), 2, "ciotola ricevuta in regalo")


func test_room_permit_reward() -> void:
	for id: StringName in [&"m01_welcome", &"m02_first_friend", &"m03_adopt", &"m04_cozy_home"]:
		GameState.quests._status[id] = QuestLog.Status.COMPLETED
	GameState.quests.refresh(QuestData.all())
	assert_eq(GameState.quests.status(&"m05_carpenter"), QuestLog.Status.ACTIVE)
	assert_eq(QuestService.talk_line_for(&"paolo"), "DLG_PAOLO_PERMIT")
	EventBus.npc_talked.emit(&"paolo")
	assert_eq(int(GameState.flags.get("room_tokens", 0)), 1, "permesso di ampliamento")


func test_caretaker_keeps_home_animals_happy() -> void:
	GameState.flags["caretaker"] = true
	var a: AnimalState = GameState.animals.ensure(&"cdog", &"dog")
	a.friendship = 80.0
	a.record_visit(1)
	AnimalCare.adopt(a, "Coccolo")
	a.happiness = 0.0
	a.cleanliness = 0.0
	AnimalCare.tick()
	assert_gt(a.happiness, 0.45)
	assert_gt(a.cleanliness, 0.45)


func test_daily_quests_present() -> void:
	var dailies: int = 0
	for id: StringName in GameState.quests.active_ids():
		if QuestData.get_quest(id).get("kind", "") == "daily":
			dailies += 1
	assert_eq(dailies, 3)
