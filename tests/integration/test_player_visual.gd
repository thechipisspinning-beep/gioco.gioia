extends TestCase
## Gioia si costruisce correttamente con ogni stile, e cambia aspetto dal vivo.

const PLAYER_SCENE: PackedScene = preload("res://systems/player/player.tscn")

var _root: Node3D


func before_each() -> void:
	GameState.start_new_game()
	_root = Node3D.new()
	tree.root.add_child(_root)


func after_each() -> void:
	_root.queue_free()
	await tree.process_frame


func _mesh_count(n: Node) -> int:
	var c: int = 1 if n is MeshInstance3D else 0
	for child: Node in n.get_children():
		c += _mesh_count(child)
	return c


func test_every_style_builds() -> void:
	var player: PlayerController = PLAYER_SCENE.instantiate() as PlayerController
	_root.add_child(player)
	var visual: PlayerVisual = player.get_node("Visual") as PlayerVisual
	var all_unlocked: Dictionary = {}
	for key: Variant in CharacterCatalog.LOCKED.values():
		all_unlocked[key] = true
	var a: CharacterAppearance = GameState.appearance
	for slot: StringName in [&"hair", &"outfit", &"shoes", &"accessory"]:
		for i: int in CharacterCatalog.styles_for(slot).size():
			a.cycle_style(slot, 1, all_unlocked)
			await tree.process_frame
			var meshes: int = _mesh_count(visual)
			assert_gt(float(meshes), 15.0, "%s/%s costruito" % [slot, a.style_id(slot)])
	for h: int in 3:
		a.cycle_style(&"height", 1, {})
		await tree.process_frame
		var root: Node3D = visual.get_node("ScaleRoot") as Node3D
		assert_almost_eq(root.scale.y, a.height_scale(), 0.001, "statura")


func test_appearance_is_restored_from_save() -> void:
	var player: PlayerController = PLAYER_SCENE.instantiate() as PlayerController
	_root.add_child(player)
	var visual: PlayerVisual = player.get_node("Visual") as PlayerVisual
	var d: Dictionary = GameState.appearance.to_dict()
	d["hair_style"] = 4
	GameState.from_dict({"appearance": d})
	assert_eq(visual.appearance.style_id(&"hair"), &"bun", "il modello usa l'aspetto caricato")


func test_gestures_do_not_break_animation() -> void:
	var player: PlayerController = PLAYER_SCENE.instantiate() as PlayerController
	_root.add_child(player)
	for g: StringName in [&"pet", &"feed", &"throw", &"brush"]:
		EventBus.player_gesture.emit(g)
		await wait_physics_frames(10)
	await wait_physics_frames(120)
	var visual: PlayerVisual = player.get_node("Visual") as PlayerVisual
	assert_true(visual.is_inside_tree())
