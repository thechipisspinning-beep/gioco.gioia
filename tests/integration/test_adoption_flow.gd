extends TestCase
## Flusso completo nel mondo: adozione → compagno che segue Gioia →
## trascuratezza → malattia → medicina → guarigione; e morte senza cure.

const PLAYER_SCENE: PackedScene = preload("res://systems/player/player.tscn")

var _root: Node3D
var _player: PlayerController
var _manager: CompanionManager


func before_each() -> void:
	GameState.start_new_game()
	GameClock.reset(GameTime.new(10.0 * 60.0))
	GameClock.time.paused = true
	_root = Node3D.new()
	tree.root.add_child(_root)
	tree.current_scene = _root
	LevelBuilder.new(_root).solid_box(Vector3(200.0, 1.0, 200.0), Vector3(0.0, -0.5, 0.0), Palette.GRASS)
	_player = PLAYER_SCENE.instantiate() as PlayerController
	_player.position = Vector3(0.0, 0.05, 0.0)
	_root.add_child(_player)
	_manager = CompanionManager.new()
	_manager.home_yard = Vector3(-10.0, 0.1, 0.0)
	_root.add_child(_manager)


func after_each() -> void:
	Input.action_release(&"move_forward")
	GameClock.time.paused = false
	_root.queue_free()
	await tree.process_frame


func _friendly_dog() -> AnimalAgent:
	var dog: AnimalAgent = AnimalSpawner.spawn(_root, &"flow_dog", &"dog", Vector3(1.5, 0.1, 0.0))
	dog.data.friendship = 70.0
	dog.data.record_visit(1)
	return dog


func _action_ids(agent: AnimalAgent) -> Array[String]:
	var ids: Array[String] = []
	for a: Dictionary in agent.get_interaction_actions():
		ids.append(str(a["id"]))
	return ids


func test_adopt_action_appears_and_adoption_works() -> void:
	var dog: AnimalAgent = _friendly_dog()
	await wait_physics_frames(5)
	assert_true(_action_ids(dog).has("adopt"), "con abbastanza amicizia compare \"Adotta\"")
	assert_true(AnimalCare.adopt(dog.data, "biscotto"))
	assert_eq(dog.get_interaction_title(), "Biscotto", "ora ha il suo nome")
	assert_false(_action_ids(dog).has("adopt"))
	assert_true(_action_ids(dog).has("follow"))


func test_companion_follows_player() -> void:
	var dog: AnimalAgent = _friendly_dog()
	await wait_physics_frames(5)
	AnimalCare.adopt(dog.data, "Biscotto")
	dog.perform_interaction("follow")
	await wait_physics_frames(5)
	assert_eq(dog.get_state_name(), "FOLLOW")
	_player.rotation.y = 0.0
	Input.action_press(&"move_forward")  # senza telecamera: verso -Z
	await wait_physics_frames(240)
	Input.action_release(&"move_forward")
	await wait_physics_frames(120)
	assert_lt(_player.global_position.z, -8.0, "Gioia ha camminato")
	assert_lt(dog.global_position.distance_to(_player.global_position), 3.5, "il compagno le è rimasto vicino")


func test_go_home_stops_following() -> void:
	var dog: AnimalAgent = _friendly_dog()
	await wait_physics_frames(5)
	AnimalCare.adopt(dog.data, "Biscotto")
	dog.perform_interaction("follow")
	await wait_physics_frames(5)
	dog.perform_interaction("stay")
	await wait_physics_frames(5)
	assert_false(dog.get_state_name() == "FOLLOW")
	assert_eq(dog.home_position, _manager.home_yard, "vive nel giardino di casa")


func test_neglect_sickness_and_medicine() -> void:
	var dog: AnimalAgent = _friendly_dog()
	await wait_physics_frames(5)
	AnimalCare.adopt(dog.data, "Biscotto")
	# Passano due giorni e mezzo senza cure (40 ore per finire la fame + 12 di trascuratezza).
	GameClock.time.advance_game_minutes(2.5 * 1440.0)
	AnimalCare.tick()
	assert_eq(dog.data.health, AnimalState.Health.SICK, "trascurato si ammala")
	await wait_physics_frames(10)
	assert_true(dog.get_state_name() in ["LIE", "SLEEP"], "da malato resta sdraiato (o dorme, di notte)")
	assert_true(_action_ids(dog).has("medicine"), "compare \"Dai la medicina\"")
	assert_false(_action_ids(dog).has("follow"), "malato non può seguire Gioia")
	GameState.inventory.add(&"medicine")
	dog.perform_interaction("medicine")
	assert_eq(dog.data.health, AnimalState.Health.CONVALESCENT)
	assert_eq(GameState.inventory.count(&"medicine"), 0, "medicina consumata")


func test_untreated_sickness_is_fatal_and_animal_leaves() -> void:
	var dog: AnimalAgent = _friendly_dog()
	await wait_physics_frames(5)
	AnimalCare.adopt(dog.data, "Biscotto")
	GameClock.time.advance_game_minutes(6.0 * 1440.0)
	AnimalCare.tick()
	assert_eq(dog.data.health, AnimalState.Health.DEAD, "D-17")
	await wait_physics_frames(220)
	assert_false(is_instance_valid(dog), "l'animale esce di scena")
	assert_true(GameState.animals.has(&"flow_dog"), "ma resta nel registro (diario)")


func test_serene_mode_keeps_animal_alive() -> void:
	GameState.serene_mode = true
	var dog: AnimalAgent = _friendly_dog()
	await wait_physics_frames(5)
	AnimalCare.adopt(dog.data, "Biscotto")
	GameClock.time.advance_game_minutes(10.0 * 1440.0)
	AnimalCare.tick()
	assert_eq(dog.data.health, AnimalState.Health.SICK, "D-38")


func test_vet_kiosk_gives_one_medicine_per_day() -> void:
	var kiosk: VetKiosk = VetKiosk.new()
	_root.add_child(kiosk)
	kiosk.perform_interaction("take")
	kiosk.perform_interaction("take")
	assert_eq(GameState.inventory.count(&"medicine"), 1, "una sola al giorno")
	GameClock.time.advance_game_minutes(1440.0)
	kiosk.perform_interaction("take")
	assert_eq(GameState.inventory.count(&"medicine"), 2, "il giorno dopo un'altra")


func test_companion_spawned_when_missing() -> void:
	# Un compagno adottato altrove compare vicino a Gioia anche se non è nella scena.
	var state: AnimalState = GameState.animals.ensure(&"elsewhere_dog", &"dog")
	state.friendship = 80.0
	state.record_visit(1)
	AnimalCare.adopt(state, "Lontano")
	AnimalCare.set_companion(state, true)
	await wait_physics_frames(5)
	var found: bool = false
	for n: Node in tree.get_nodes_in_group(&"animals"):
		if (n as AnimalAgent).data.id == &"elsewhere_dog" and _root.is_ancestor_of(n):
			found = true
	assert_true(found, "il compagno è stato creato nella scena")
