class_name FurnitureCatalogStand
extends StaticBody3D
## Leggio con il catalogo dell'arredamento: apre la modalità arredamento.


func _ready() -> void:
	add_to_group(&"interactable")
	collision_layer = 1
	var b: LevelBuilder = LevelBuilder.new(self)
	var post: BoxMesh = BoxMesh.new()
	post.size = Vector3(0.12, 0.95, 0.12)
	b.decor(post, Vector3(0, 0.48, 0), Palette.WOOD_DARK, Vector3.ZERO, Vector3.ONE, self)
	var top: BoxMesh = BoxMesh.new()
	top.size = Vector3(0.55, 0.05, 0.4)
	b.decor(top, Vector3(0, 0.98, 0), Palette.WOOD, Vector3(-20, 0, 0), Vector3.ONE, self)
	var book: BoxMesh = BoxMesh.new()
	book.size = Vector3(0.42, 0.05, 0.3)
	b.decor(book, Vector3(0, 1.02, 0.01), Palette.FLOWER_PINK, Vector3(-20, 0, 0), Vector3.ONE, self)
	var cs: CollisionShape3D = CollisionShape3D.new()
	var bs: BoxShape3D = BoxShape3D.new()
	bs.size = Vector3(0.5, 1.0, 0.4)
	cs.shape = bs
	cs.position.y = 0.5
	add_child(cs)


func get_interaction_title() -> String:
	return tr("CATALOG_TITLE")


func get_interaction_actions() -> Array[Dictionary]:
	return [{"id": "build", "label": tr("CATALOG_OPEN"), "enabled": true}]


func perform_interaction(_action_id: String) -> void:
	EventBus.build_mode_requested.emit()
