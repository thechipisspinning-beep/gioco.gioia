class_name CookingStation
extends Node3D
## Punto in cui si cucina (fornello in casa o fuoco da campo in giardino).
## Apre la finestra delle ricette (GDD § 9).

@export var title_key: String = "COOK_STOVE"
@export var build_campfire: bool = false


func _ready() -> void:
	add_to_group(&"interactable")
	if build_campfire:
		_build_campfire()


func get_interaction_title() -> String:
	return tr(title_key)


func get_interaction_actions() -> Array[Dictionary]:
	return [{"id": "cook", "label": tr("COOK_OPEN"), "enabled": true}]


func perform_interaction(_action_id: String) -> void:
	EventBus.cooking_requested.emit()


func _build_campfire() -> void:
	var body: StaticBody3D = StaticBody3D.new()
	add_child(body)
	var cs: CollisionShape3D = CollisionShape3D.new()
	var cyl: CylinderShape3D = CylinderShape3D.new()
	cyl.radius = 0.7
	cyl.height = 0.5
	cs.shape = cyl
	cs.position.y = 0.25
	body.add_child(cs)
	var b: LevelBuilder = LevelBuilder.new(self)
	for i: int in 8:
		var a: float = TAU * i / 8.0
		var stone: SphereMesh = SphereMesh.new()
		stone.radius = 0.16
		stone.height = 0.22
		b.decor(stone, Vector3(cos(a) * 0.6, 0.08, sin(a) * 0.6), Palette.STONE_DARK, Vector3.ZERO, Vector3.ONE, self)
	for i: int in 3:
		var log: CylinderMesh = CylinderMesh.new()
		log.top_radius = 0.07
		log.bottom_radius = 0.07
		log.height = 0.8
		b.decor(log, Vector3(0, 0.12, 0), Palette.WOOD_DARK, Vector3(90, i * 60, 0), Vector3.ONE, self)
	var pot: CylinderMesh = CylinderMesh.new()
	pot.top_radius = 0.28
	pot.bottom_radius = 0.22
	pot.height = 0.3
	b.decor(pot, Vector3(0, 0.45, 0), Palette.EYE_DARK, Vector3.ZERO, Vector3.ONE, self)
	var flame: SphereMesh = SphereMesh.new()
	flame.radius = 0.16
	flame.height = 0.35
	b.decor(flame, Vector3(0, 0.22, 0), Color("ffb347"), Vector3.ZERO, Vector3.ONE, self)
