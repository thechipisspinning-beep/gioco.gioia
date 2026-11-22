class_name Collectible
extends Node3D
## Oggetto da raccogliere nel mondo (GDD § 7.8): fiore, conchiglia, fungo,
## erba, frutti di bosco. Ogni punto ha un ID stabile e ricompare il giorno dopo.

const FLAG: String = "picked"

var item_id: StringName
var collectible_id: String


static func create(item: StringName, id: String, pos: Vector3) -> Collectible:
	var c: Collectible = Collectible.new()
	c.item_id = item
	c.collectible_id = id
	c.position = pos
	return c


static func is_picked_today(id: String) -> bool:
	var picked: Dictionary = GameState.flags.get(FLAG, {}) as Dictionary
	return int(picked.get(id, -1)) == GameState.current_day()


func _ready() -> void:
	if is_picked_today(collectible_id):
		queue_free()
		return
	add_to_group(&"interactable")
	_build_model()


func get_interaction_title() -> String:
	var def: ItemDefinition = Database.item(item_id)
	return tr(def.name_key) if def != null else String(item_id)


func get_interaction_actions() -> Array[Dictionary]:
	return [{"id": "pick", "label": tr("ACTION_PICK"), "enabled": true}]


func perform_interaction(_action_id: String) -> void:
	var picked: Dictionary = GameState.flags.get(FLAG, {}) as Dictionary
	# Si tengono solo i raccolti di oggi: il dizionario non cresce all'infinito.
	for k: Variant in picked.keys():
		if int(picked[k]) != GameState.current_day():
			picked.erase(k)
	picked[collectible_id] = GameState.current_day()
	GameState.flags[FLAG] = picked
	GameState.inventory.add(item_id)
	EventBus.item_collected.emit(item_id, 1)
	EventBus.player_gesture.emit(&"feed")
	EventBus.notification_requested.emit(tr("NOTIFY_PICKED") % get_interaction_title())
	remove_from_group(&"interactable")
	var t: Tween = create_tween()
	t.tween_property(self, "scale", Vector3.ONE * 0.01, 0.25)
	t.tween_callback(queue_free)


func _build_model() -> void:
	var b: LevelBuilder = LevelBuilder.new(self)
	match item_id:
		&"flower":
			b.decor(PropMeshes.get_mesh(&"flower"), Vector3.ZERO, Color.WHITE, Vector3.ZERO, Vector3.ONE * 2.2, self).material_override = ToonMaterials.get_material(Palette.FLOWER_PINK)
			_ball(b, 0.07, Vector3(0, 0.5, 0), Palette.FLOWER_YELLOW)
		&"seashell":
			var s: SphereMesh = SphereMesh.new()
			s.radius = 0.12
			s.height = 0.12
			b.decor(s, Vector3(0, 0.04, 0), Color("ffe0cc"), Vector3(0, 0, 20), Vector3(1.0, 0.6, 1.2), self)
			_ball(b, 0.05, Vector3(0.06, 0.06, -0.08), Color("ffc4b0"))
		&"mushroom":
			var stem: CylinderMesh = CylinderMesh.new()
			stem.top_radius = 0.05
			stem.bottom_radius = 0.06
			stem.height = 0.18
			b.decor(stem, Vector3(0, 0.09, 0), Palette.FLOWER_WHITE, Vector3.ZERO, Vector3.ONE, self)
			var cap: SphereMesh = SphereMesh.new()
			cap.radius = 0.14
			cap.height = 0.14
			b.decor(cap, Vector3(0, 0.19, 0), Color("e0574a"), Vector3.ZERO, Vector3.ONE, self)
			for o: Vector3 in [Vector3(0.05, 0.25, 0.04), Vector3(-0.05, 0.24, -0.03), Vector3(0.0, 0.26, -0.07)]:
				_ball(b, 0.025, o, Palette.FLOWER_WHITE)
		&"herb":
			for i: int in 5:
				var a: float = TAU * i / 5.0
				var leaf: SphereMesh = SphereMesh.new()
				leaf.radius = 0.06
				leaf.height = 0.2
				b.decor(leaf, Vector3(cos(a) * 0.06, 0.12, sin(a) * 0.06), Color("6fbf6a"), Vector3(cos(a) * 25, 0, sin(a) * 25), Vector3.ONE, self)
		&"berries":
			b.decor(PropMeshes.get_mesh(&"bush"), Vector3.ZERO, Color.WHITE, Vector3.ZERO, Vector3.ONE * 0.7, self).material_override = ToonMaterials.get_vertex_color_material()
			for o: Vector3 in [Vector3(0.2, 0.4, 0.25), Vector3(-0.15, 0.45, 0.2), Vector3(0.05, 0.5, 0.3), Vector3(0.25, 0.3, -0.1)]:
				_ball(b, 0.05, o, Color("8c3fa0"))


func _ball(b: LevelBuilder, r: float, pos: Vector3, color: Color) -> void:
	var s: SphereMesh = SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 8
	s.rings = 4
	b.decor(s, pos, color, Vector3.ZERO, Vector3.ONE, self)
