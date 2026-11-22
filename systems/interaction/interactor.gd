class_name Interactor
extends Node
## Trova l'oggetto interagibile migliore vicino a Gioia (animali, oggetti, NPC)
## e gestisce la pressione del tasto "interagisci".
##
## Un nodo è interagibile se è nel gruppo `interactable` e implementa:
##   get_interaction_title() -> String
##   get_interaction_actions() -> Array[Dictionary]   # {id, label, enabled}
##   perform_interaction(action_id: String) -> void
## Facoltativi: get_hearts() -> int, get_status_text() -> String, is_busy() -> bool

## Cambiato l'oggetto puntato (null se nessuno).
signal focus_changed(target: Node3D)
## Il giocatore vuole interagire con `target` (la UI apre il menu delle azioni).
signal interact_requested(target: Node3D)

@export var max_distance: float = 2.4
## Peso della direzione: 0 = conta solo la distanza, 1 = conta molto lo sguardo.
@export var facing_weight: float = 0.6
@export var scan_interval: float = 0.1

var player: PlayerController
var focus: Node3D
## Disattivato mentre un menu è aperto.
var enabled: bool = true

var _scan_timer: float = 0.0


func _ready() -> void:
	player = get_parent() as PlayerController


func _physics_process(delta: float) -> void:
	_scan_timer -= delta
	if _scan_timer > 0.0:
		return
	_scan_timer = scan_interval
	var best: Node3D = _find_best() if enabled else null
	if best != focus:
		focus = best
		focus_changed.emit(focus)


func _unhandled_input(event: InputEvent) -> void:
	if enabled and focus != null and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interact_requested.emit(focus)


func _find_best() -> Node3D:
	var best: Node3D = null
	var best_score: float = INF
	var forward: Vector3 = player.global_transform.basis.z
	for node: Node in get_tree().get_nodes_in_group(&"interactable"):
		var n: Node3D = node as Node3D
		if n == null or not n.is_visible_in_tree():
			continue
		var to: Vector3 = n.global_position - player.global_position
		to.y = 0.0
		var dist: float = to.length()
		if dist > max_distance:
			continue
		var facing: float = forward.dot(to.normalized()) if dist > 0.01 else 1.0
		if facing < -0.2:
			continue  # alle spalle di Gioia
		var score: float = dist * (1.0 + facing_weight * (1.0 - facing))
		if score < best_score:
			best_score = score
			best = n
	return best
