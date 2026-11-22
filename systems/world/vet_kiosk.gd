class_name VetKiosk
extends StaticBody3D
## Cassetta del veterinario (D-36, versione iniziale): una volta al giorno
## Gioia può prendere una medicina per curare un animale malato.
## In Fase 9 diventerà l'ambulatorio con il veterinario del villaggio.

const FLAG_LAST_DAY: String = "vet_kiosk_last_day"


func _ready() -> void:
	add_to_group(&"interactable")
	collision_layer = 1
	var b: LevelBuilder = LevelBuilder.new(self)
	var post: BoxMesh = BoxMesh.new()
	post.size = Vector3(0.12, 1.1, 0.12)
	b.decor(post, Vector3(0, 0.55, 0), Palette.WOOD_DARK, Vector3.ZERO, Vector3.ONE, self)
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.7, 0.5, 0.45)
	b.decor(box, Vector3(0, 1.3, 0), Palette.WALL_CREAM, Vector3.ZERO, Vector3.ONE, self)
	var roof: PrismMesh = PrismMesh.new()
	roof.size = Vector3(0.85, 0.25, 0.6)
	b.decor(roof, Vector3(0, 1.67, 0), Palette.GRASS_DARK, Vector3.ZERO, Vector3.ONE, self)
	# Simbolo: impronta di zampa verde (non una croce rossa, che è un emblema protetto).
	var pad: SphereMesh = SphereMesh.new()
	pad.radius = 0.09
	pad.height = 0.06
	b.decor(pad, Vector3(0, 1.25, 0.23), Palette.LEAF, Vector3(90, 0, 0), Vector3.ONE, self)
	for i: int in 4:
		var toe: SphereMesh = SphereMesh.new()
		toe.radius = 0.04
		toe.height = 0.04
		b.decor(toe, Vector3(-0.1 + i * 0.067, 1.38 - absf(1.5 - i) * 0.025, 0.23), Palette.LEAF, Vector3(90, 0, 0), Vector3.ONE, self)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var bs: BoxShape3D = BoxShape3D.new()
	bs.size = Vector3(0.7, 1.7, 0.45)
	shape.shape = bs
	shape.position.y = 0.85
	add_child(shape)


func get_interaction_title() -> String:
	return tr("VET_KIOSK_TITLE")


func get_status_text() -> String:
	return tr("VET_KIOSK_DONE_TODAY") if _taken_today() else tr("VET_KIOSK_HINT")


func get_interaction_actions() -> Array[Dictionary]:
	return [{"id": "take", "label": tr("VET_KIOSK_TAKE"), "enabled": not _taken_today()}]


func perform_interaction(action_id: String) -> void:
	if action_id != "take" or _taken_today():
		return
	GameState.flags[FLAG_LAST_DAY] = GameState.current_day()
	GameState.inventory.add(&"medicine")
	EventBus.notification_requested.emit(tr("NOTIFY_GOT_MEDICINE"))


func _taken_today() -> bool:
	return int(GameState.flags.get(FLAG_LAST_DAY, 0)) == GameState.current_day()
