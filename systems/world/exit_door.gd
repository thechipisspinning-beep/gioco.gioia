class_name ExitDoor
extends Node3D
## Porta che porta in un'altra scena (entrare/uscire di casa, negozi…).
## Invisibile: è solo il punto di interazione davanti alla porta disegnata.

@export var target_scene: String
@export var target_spawn: StringName
@export var title_key: String = "DOOR_ENTER"


func _ready() -> void:
	add_to_group(&"interactable")


func get_interaction_title() -> String:
	return tr(title_key)


func get_interaction_actions() -> Array[Dictionary]:
	return [{"id": "go", "label": tr(title_key), "enabled": not SceneRouter.is_busy()}]


func perform_interaction(_action_id: String) -> void:
	SceneRouter.go_to(target_scene, target_spawn)
