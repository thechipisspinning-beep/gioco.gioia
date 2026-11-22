class_name Villager
extends PlayerController
## Abitante del villaggio (D-11): stesso modello e animazioni di Gioia con un
## aspetto proprio, gira tranquillo attorno al suo posto, si ferma e guarda
## Gioia quando si avvicina, parla e (secondo il ruolo) apre il negozio o cura
## gli animali.

var villager_id: StringName
var data: Dictionary
var anchor: Vector3
var _target: Vector3
var _wait: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _talking: bool = false
var _player_ref: Node3D
var _badge: Node3D


func _ready() -> void:
	is_player = false
	super._ready()
	add_to_group(&"interactable")
	add_to_group(&"villagers")
	# Gli abitanti non usano l'Interactor di Gioia.
	var interactor: Node = get_node_or_null("Interactor")
	if interactor != null:
		interactor.queue_free()
	walk_speed = 1.6
	_rng.seed = hash(String(villager_id))
	_target = anchor
	_badge = _make_badge()
	add_child(_badge)


## Va chiamato prima di aggiungere il nodo alla scena.
func setup(d: Dictionary, anchor_point: Vector3) -> void:
	data = d
	villager_id = d["id"]
	anchor = anchor_point
	var look: CharacterAppearance = CharacterAppearance.new()
	look.from_dict(d.get("look", {}) as Dictionary)
	(get_node("Visual") as PlayerVisual).appearance = look


func _physics_process(delta: float) -> void:
	_think(delta)
	super._physics_process(delta)
	_badge.visible = QuestService.has_quest_from(villager_id) or QuestService.talk_line_for(villager_id) != ""
	_badge.rotation.y += delta * 2.0


func _think(delta: float) -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		_player_ref = get_tree().get_first_node_in_group(&"player") as Node3D
	var near_player: bool = _player_ref != null and global_position.distance_to(_player_ref.global_position) < 3.0
	if _talking or near_player:
		ai_move_input = Vector2.ZERO
		if _player_ref != null:
			face_towards(_player_ref.global_position)
		return
	var to: Vector3 = _target - global_position
	to.y = 0.0
	if to.length() < 0.5:
		ai_move_input = Vector2.ZERO
		_wait -= delta
		if _wait <= 0.0:
			_wait = _rng.randf_range(2.0, 6.0)
			var a: float = _rng.randf() * TAU
			_target = anchor + Vector3(cos(a), 0.0, sin(a)) * _rng.randf_range(0.5, 4.0)
	else:
		# Senza telecamera: x = destra (+X), y negativo = avanti (-Z).
		var d: Vector3 = to.normalized()
		ai_move_input = Vector2(d.x, d.z) * 0.6


func get_interaction_title() -> String:
	return tr(str(data["name_key"]))


func get_interaction_actions() -> Array[Dictionary]:
	var actions: Array[Dictionary] = [{"id": "talk", "label": tr("NPC_TALK"), "enabled": true}]
	match str(data.get("role", "")):
		"shop":
			actions.append({"id": "shop", "label": tr("NPC_SHOP"), "enabled": true})
			actions.append({"id": "sell", "label": tr("NPC_SELL"), "enabled": true})
		"vet":
			var sick: int = _sick_count()
			var label: String = tr("NPC_VET_CURE") % [sick, sick * VillagerData.VET_PRICE] if sick > 0 else tr("NPC_VET_NONE")
			actions.append({"id": "vet", "label": label, "enabled": sick > 0 and GameState.coins >= sick * VillagerData.VET_PRICE})
	return actions


func perform_interaction(action_id: String) -> void:
	match action_id:
		"talk":
			_talking = true
			var line: String = QuestService.talk_line_for(villager_id)
			if line == "":
				var lines: Array = data.get("lines", []) as Array
				line = str(lines[_rng.randi() % lines.size()]) if not lines.is_empty() else "..."
			EventBus.dialogue_requested.emit(get_interaction_title(), tr(line))
			EventBus.npc_talked.emit(villager_id)
			get_tree().create_timer(4.0).timeout.connect(func() -> void: _talking = false)
		"shop":
			EventBus.shop_requested.emit(false)
		"sell":
			EventBus.shop_requested.emit(true)
		"vet":
			_cure_all()


func _sick_count() -> int:
	var n: int = 0
	for a: AnimalState in GameState.animals.adopted():
		if a.health == AnimalState.Health.SICK:
			n += 1
	return n


## La veterinaria cura tutti gli animali malati, ovunque siano (D-36).
func _cure_all() -> void:
	var now: float = GameClock.time.get_total_minutes()
	for a: AnimalState in GameState.animals.adopted():
		if a.health != AnimalState.Health.SICK or GameState.coins < VillagerData.VET_PRICE:
			continue
		var species: SpeciesDefinition = Database.species(a.species_id)
		if species != null and AnimalHealth.cure(a, species, now, GameState.serene_mode):
			GameState.coins -= VillagerData.VET_PRICE
			EventBus.notification_requested.emit(tr("NOTIFY_CURED_BY_VET") % a.given_name)
			EventBus.gameplay_event.emit("cure", a.species_id, 1)
			EventBus.animal_health_changed.emit(a.id, a.health)


## Punto esclamativo che gira sopra la testa quando l'abitante ha qualcosa da dire.
func _make_badge() -> Node3D:
	var n: Node3D = Node3D.new()
	n.position.y = 1.85
	var b: LevelBuilder = LevelBuilder.new(n)
	var bar: BoxMesh = BoxMesh.new()
	bar.size = Vector3(0.09, 0.3, 0.09)
	b.decor(bar, Vector3(0, 0.12, 0), Palette.FLOWER_YELLOW, Vector3.ZERO, Vector3.ONE, n)
	var dot: SphereMesh = SphereMesh.new()
	dot.radius = 0.06
	dot.height = 0.12
	b.decor(dot, Vector3(0, -0.12, 0), Palette.FLOWER_YELLOW, Vector3.ZERO, Vector3.ONE, n)
	return n
