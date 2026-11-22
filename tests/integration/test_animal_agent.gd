extends TestCase
## Comportamento degli animali con la fisica reale: curiosità, interazioni,
## gioco della pallina, timidezza della volpe, sonno.

const PLAYER_SCENE: PackedScene = preload("res://systems/player/player.tscn")

var _root: Node3D
var _player: PlayerController


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


func after_each() -> void:
	for a: StringName in [&"move_forward", &"run"]:
		Input.action_release(a)
	GameClock.time.paused = false
	_root.queue_free()
	await tree.process_frame


func _spawn(species: StringName, pos: Vector3) -> AnimalAgent:
	return AnimalSpawner.spawn(_root, StringName("test_" + String(species)), species, pos)


func test_dog_registers_discovery_when_near() -> void:
	_spawn(&"dog", Vector3(3.0, 0.1, 0.0))
	await wait_physics_frames(5)
	assert_true(GameState.discoveries.has_met(&"dog"), "cane nel diario")


func test_dog_comes_to_say_hello() -> void:
	var dog: AnimalAgent = _spawn(&"dog", Vector3(5.0, 0.1, 0.0))
	await wait_physics_frames(240)
	assert_lt(dog.global_position.distance_to(_player.global_position), 2.0, "il cane si è avvicinato a Gioia")


func test_petting_gives_friendship_and_hearts() -> void:
	var dog: AnimalAgent = _spawn(&"dog", Vector3(1.0, 0.1, 0.0))
	await wait_physics_frames(5)
	var ids: Array[String] = []
	for a: Dictionary in dog.get_interaction_actions():
		ids.append(str(a["id"]))
	assert_true(ids.has("pet"), "si può accarezzare")
	assert_true(ids.has("feed:kibble"), "si possono dare le crocchette")
	assert_true(ids.has("play"), "si può giocare con la pallina")
	dog.perform_interaction("pet")
	assert_gt(dog.data.friendship, 0.0)
	assert_true(dog.is_busy(), "durante le coccole l'animale è occupato")
	assert_true(dog.get_interaction_actions().is_empty(), "niente menu mentre è occupato")
	await wait_physics_frames(200)
	assert_false(dog.is_busy(), "finite le coccole torna disponibile")


func test_feeding_consumes_food() -> void:
	var dog: AnimalAgent = _spawn(&"dog", Vector3(1.0, 0.1, 0.0))
	await wait_physics_frames(5)
	var before: int = GameState.inventory.count(&"kibble")
	dog.perform_interaction("feed:kibble")
	assert_eq(GameState.inventory.count(&"kibble"), before - 1)
	assert_gt(dog.data.friendship, 10.0, "il cibo preferito dà molta amicizia")


func test_refused_food_is_not_consumed() -> void:
	var dog: AnimalAgent = _spawn(&"dog", Vector3(1.0, 0.1, 0.0))
	await wait_physics_frames(5)
	var before: int = GameState.inventory.count(&"berries")
	dog.perform_interaction("feed:berries")
	assert_eq(GameState.inventory.count(&"berries"), before, "cibo rifiutato non viene consumato")
	assert_almost_eq(dog.data.friendship, 0.0)


func test_fetch_completes_and_returns() -> void:
	var dog: AnimalAgent = _spawn(&"dog", Vector3(1.0, 0.1, 0.0))
	await wait_physics_frames(5)
	dog.perform_interaction("play")
	var went_far: bool = false
	for i: int in 600:
		await tree.physics_frame
		if dog.global_position.distance_to(_player.global_position) > 4.0:
			went_far = true
		if went_far and not dog.is_busy():
			break
	assert_true(went_far, "il cane corre a prendere la pallina")
	assert_lt(dog.global_position.distance_to(_player.global_position), 2.5, "e la riporta a Gioia")
	assert_gt(dog.data.friendship, 0.0, "giocare dà amicizia")
	assert_eq(GameState.inventory.count(&"ball"), 1, "la pallina non si consuma")


func test_fox_keeps_distance_and_has_no_actions() -> void:
	GameClock.reset(GameTime.new(18.0 * 60.0))  # la volpe è attiva la sera
	GameClock.time.paused = true
	var fox: AnimalAgent = _spawn(&"fox", Vector3(2.0, 0.1, 0.0))
	await wait_physics_frames(120)
	assert_gt(fox.global_position.distance_to(_player.global_position), 3.0, "la volpe si allontana")
	assert_false(fox.species.likes_fetch)


func test_fox_flees_when_player_runs_close() -> void:
	GameClock.reset(GameTime.new(18.0 * 60.0))
	GameClock.time.paused = true
	var fox: AnimalAgent = _spawn(&"fox", Vector3(0.0, 0.1, -7.0))
	fox.data.friendship = 50.0  # abbastanza fiducia da farsi avvicinare camminando
	await wait_physics_frames(10)
	_player.rotation.y = PI
	Input.action_press(&"move_forward")
	Input.action_press(&"run")
	await wait_physics_frames(50)
	assert_eq(fox.get_state_name(), "FLEE", "correndo la si spaventa")
	assert_lt(fox.data.friendship, 50.0, "e perde un po' di fiducia")


func test_animals_sleep_outside_active_hours() -> void:
	GameClock.reset(GameTime.new(2.0 * 60.0))  # 02:00, il cane dorme
	GameClock.time.paused = true
	var dog: AnimalAgent = _spawn(&"dog", Vector3(3.0, 0.1, 0.0))
	await wait_physics_frames(5)
	assert_eq(dog.get_state_name(), "SLEEP")
	assert_true(dog.get_interaction_actions().is_empty(), "non si disturba chi dorme")
