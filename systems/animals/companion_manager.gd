class_name CompanionManager
extends Node3D
## Gestisce gli animali adottati presenti nella scena:
## - quelli che vivono a casa girano nel giardino (`home_yard`);
## - i compagni (max 3) seguono Gioia in formazione;
## - se un animale adottato non è presente nella scena, viene creato
##   (in giardino se la scena contiene la casa, vicino a Gioia se è un compagno).

## La scena contiene la casa di Gioia: qui vivono gli animali adottati.
@export var has_home: bool = true
@export var home_yard: Vector3 = Vector3.ZERO
@export var yard_radius: float = 5.0


func _ready() -> void:
	EventBus.companions_changed.connect(refresh)
	EventBus.animal_adopted.connect(func(_id: StringName, _sp: StringName) -> void: refresh())
	refresh.call_deferred()


func refresh() -> void:
	# Durante un cambio di scena la scena vecchia esiste ancora per un frame:
	# solo il gestore della scena corrente deve agire.
	var scene: Node = get_tree().current_scene if is_inside_tree() else null
	if scene == null or not (scene == self or scene.is_ancestor_of(self)):
		return
	var agents: Dictionary = {}
	for n: Node in get_tree().get_nodes_in_group(&"animals"):
		var a: AnimalAgent = n as AnimalAgent
		if a != null and scene.is_ancestor_of(a):
			agents[a.data.id] = a
	var companions: Array[AnimalState] = GameState.animals.companions()
	companions.sort_custom(func(x: AnimalState, y: AnimalState) -> bool: return String(x.id) < String(y.id))
	for state: AnimalState in GameState.animals.adopted():
		if not state.is_alive():
			continue
		var agent: AnimalAgent = agents.get(state.id) as AnimalAgent
		var is_companion: bool = state.location == AnimalState.Location.COMPANION
		if agent == null:
			if not is_companion and not has_home:
				continue
			agent = AnimalSpawner.spawn(get_parent_node_3d(), state.id, state.species_id, _spawn_point(is_companion))
			if agent == null:
				continue
		if has_home:
			agent.home_position = home_yard
		if is_companion:
			agent.set_follow_slot(companions.find(state))


func _spawn_point(near_player: bool) -> Vector3:
	if near_player:
		var player: Node3D = get_tree().get_first_node_in_group(&"player") as Node3D
		if player != null:
			return player.global_position - player.global_transform.basis.z * 1.5 + Vector3.UP * 0.2
	var a: float = randf() * TAU
	return home_yard + Vector3(cos(a), 0.0, sin(a)) * randf() * yard_radius + Vector3.UP * 0.2
