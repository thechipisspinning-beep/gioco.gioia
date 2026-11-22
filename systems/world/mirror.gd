class_name Mirror
extends StaticBody3D
## Specchio con armadio: apre la personalizzazione di Gioia (GDD § 4.2).


func _ready() -> void:
	add_to_group(&"interactable")
	collision_layer = 1
	var b: LevelBuilder = LevelBuilder.new(self)
	var frame: BoxMesh = BoxMesh.new()
	frame.size = Vector3(0.9, 1.7, 0.12)
	b.decor(frame, Vector3(0, 0.85, 0), Palette.WOOD, Vector3.ZERO, Vector3.ONE, self)
	var glass: BoxMesh = BoxMesh.new()
	glass.size = Vector3(0.7, 1.45, 0.02)
	b.decor(glass, Vector3(0, 0.88, 0.065), Color("cfeaf7"), Vector3.ZERO, Vector3.ONE, self)
	var top: SphereMesh = SphereMesh.new()
	top.radius = 0.12
	top.height = 0.12
	b.decor(top, Vector3(0, 1.75, 0), Palette.FLOWER_PINK, Vector3.ZERO, Vector3.ONE, self)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var bs: BoxShape3D = BoxShape3D.new()
	bs.size = Vector3(0.9, 1.7, 0.2)
	shape.shape = bs
	shape.position.y = 0.85
	add_child(shape)


func get_interaction_title() -> String:
	return tr("MIRROR_TITLE")


func get_interaction_actions() -> Array[Dictionary]:
	return [{"id": "customize", "label": tr("MIRROR_CUSTOMIZE"), "enabled": true}]


func perform_interaction(_action_id: String) -> void:
	EventBus.customization_requested.emit()
