class_name GardenPlot
extends Node3D
## Una parcella dell'orto (GDD § 7.6): pianta, annaffia, raccogli.
## Mostra la pianta nella fase di crescita attuale e il terreno scuro se bagnato.

var index: int = 0
var _visual: Node3D
var _soil: MeshInstance3D
var _last_stage: int = -2
var _last_wet: bool = false


func _ready() -> void:
	add_to_group(&"interactable")
	_soil = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(1.4, 0.18, 1.4)
	_soil.mesh = box
	_soil.position.y = 0.06
	add_child(_soil)
	var b: LevelBuilder = LevelBuilder.new(self)
	for side: Vector3 in [Vector3(0, 0.1, 0.72), Vector3(0, 0.1, -0.72)]:
		var plank: BoxMesh = BoxMesh.new()
		plank.size = Vector3(1.55, 0.2, 0.08)
		b.decor(plank, side, Palette.WOOD, Vector3.ZERO, Vector3.ONE, self)
	for side: Vector3 in [Vector3(0.72, 0.1, 0), Vector3(-0.72, 0.1, 0)]:
		var plank: BoxMesh = BoxMesh.new()
		plank.size = Vector3(0.08, 0.2, 1.55)
		b.decor(plank, side, Palette.WOOD, Vector3.ZERO, Vector3.ONE, self)
	GameState.garden.changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if GameState.garden.changed.is_connected(_refresh):
		GameState.garden.changed.disconnect(_refresh)


func _process(_delta: float) -> void:
	# La terra cambia colore quando l'acqua finisce, anche senza eventi.
	if GameState.garden.is_watered(index, GameClock.time.get_total_minutes()) != _last_wet:
		_refresh()


func get_interaction_title() -> String:
	var g: Garden = GameState.garden
	if g.is_empty(index):
		return tr("GARDEN_PLOT")
	return tr("PLANT_" + String(g.plots[index]["plant"]).to_upper())


func get_status_text() -> String:
	var g: Garden = GameState.garden
	if g.is_empty(index):
		return tr("GARDEN_EMPTY")
	if g.is_ready(index):
		return tr("GARDEN_READY")
	var wet: bool = g.is_watered(index, GameClock.time.get_total_minutes())
	return (tr("GARDEN_GROWING_WET") if wet else tr("GARDEN_GROWING_DRY")) % [g.stage(index), Garden.STAGES]


func get_interaction_actions() -> Array[Dictionary]:
	var g: Garden = GameState.garden
	var now: float = GameClock.time.get_total_minutes()
	var actions: Array[Dictionary] = []
	if g.is_empty(index):
		for p: StringName in Garden.PLANTS.keys():
			var seed: StringName = Garden.PLANTS[p]["seed"]
			var n: int = GameState.inventory.count(seed)
			if n > 0:
				actions.append({"id": "plant:" + String(p), "label": tr("GARDEN_PLANT") % [tr("PLANT_" + String(p).to_upper()), n], "enabled": true})
		if actions.is_empty():
			actions.append({"id": "none", "label": tr("GARDEN_NO_SEEDS"), "enabled": false})
	elif g.is_ready(index):
		actions.append({"id": "harvest", "label": tr("GARDEN_HARVEST"), "enabled": true})
	else:
		actions.append({"id": "water", "label": tr("GARDEN_WATER"), "enabled": not g.is_watered(index, now)})
	return actions


func perform_interaction(action_id: String) -> void:
	var g: Garden = GameState.garden
	var now: float = GameClock.time.get_total_minutes()
	if action_id.begins_with("plant:"):
		var p: StringName = StringName(action_id.trim_prefix("plant:"))
		if GameState.inventory.try_remove(Garden.PLANTS[p]["seed"]) and g.plant(index, p, now):
			EventBus.player_gesture.emit(&"pet")
			EventBus.gameplay_event.emit("plant", p, 1)
			g.water(index, now)  # appena piantato, Gioia annaffia subito
	elif action_id == "water":
		if g.water(index, now):
			EventBus.player_gesture.emit(&"feed")
			EventBus.gameplay_event.emit("water", &"", 1)
	elif action_id == "harvest":
		var plant_id: StringName = g.plots[index]["plant"]
		var got: Dictionary = g.harvest(index)
		for item: Variant in got.keys():
			GameState.inventory.add(StringName(str(item)), int(got[item]))
		EventBus.player_gesture.emit(&"pet")
		EventBus.gameplay_event.emit("harvest", plant_id, 1)
		EventBus.notification_requested.emit(tr("GARDEN_HARVESTED") % tr("PLANT_" + String(plant_id).to_upper()))


func _refresh() -> void:
	var g: Garden = GameState.garden
	var st: int = g.stage(index)
	var wet: bool = g.is_watered(index, GameClock.time.get_total_minutes())
	_last_wet = wet
	_soil.material_override = ToonMaterials.get_material(Color("6b4a35") if wet else Color("9b7354"))
	if st == _last_stage and _visual != null:
		return
	_last_stage = st
	if _visual != null:
		_visual.queue_free()
		_visual = null
	if st < 0:
		return
	_visual = _plant_model(g.plots[index]["plant"], st)
	add_child(_visual)


func _plant_model(plant: StringName, st: int) -> Node3D:
	var root: Node3D = Node3D.new()
	var b: LevelBuilder = LevelBuilder.new(root)
	var size: float = [0.25, 0.5, 0.8, 1.0][clampi(st, 0, 3)]
	for o: Vector3 in [Vector3(-0.35, 0, -0.35), Vector3(0.35, 0, -0.35), Vector3(-0.35, 0, 0.35), Vector3(0.35, 0, 0.35)]:
		var leaves: SphereMesh = SphereMesh.new()
		leaves.radius = 0.16 * size
		leaves.height = 0.32 * size
		b.decor(leaves, o + Vector3(0, 0.18 + 0.12 * size, 0), Palette.LEAF if st < 3 else Palette.LEAF_LIGHT, Vector3.ZERO, Vector3.ONE, root)
		if st >= 3:
			var fruit: SphereMesh = SphereMesh.new()
			fruit.radius = 0.07
			fruit.height = 0.14
			var c: Color = {&"carrot": Color("ff9a3c"), &"strawberry": Color("f04e5a"), &"herb": Color("7ad26a"), &"flower": Palette.FLOWER_PINK}.get(plant, Color.WHITE)
			b.decor(fruit, o + Vector3(0.06, 0.32, 0.06), c, Vector3.ZERO, Vector3.ONE, root)
	return root
