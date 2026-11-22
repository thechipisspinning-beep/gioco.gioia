class_name Emote
extends Node3D
## Piccolo effetto sopra la testa di un animale: cuoricini (felicità),
## nuvoletta grigia (rifiuto), "zzz" (sonno), punto esclamativo (spavento).
## Si autodistrugge al termine.

enum Kind { HEARTS, BIG_HEARTS, CLOUD, ALERT }

const HEART_COLOR: Color = Color("ff6f91")


static func spawn(parent: Node3D, at_global: Vector3, kind: Kind) -> void:
	var e: Emote = Emote.new()
	parent.get_tree().current_scene.add_child(e)
	e.global_position = at_global
	e._play(kind)


func _play(kind: Kind) -> void:
	match kind:
		Kind.HEARTS, Kind.BIG_HEARTS:
			var count: int = 3 if kind == Kind.HEARTS else 6
			for i: int in count:
				var h: Node3D = _heart(HEART_COLOR.lightened(randf() * 0.2))
				h.position = Vector3(randf_range(-0.25, 0.25), 0.0, randf_range(-0.1, 0.1))
				h.scale = Vector3.ONE * 0.01
				var t: Tween = create_tween().set_parallel(true)
				var delay: float = i * 0.12
				t.tween_property(h, "scale", Vector3.ONE * randf_range(0.8, 1.1), 0.25).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				t.tween_property(h, "position:y", randf_range(0.5, 0.8), 1.2).set_delay(delay).set_ease(Tween.EASE_OUT)
				t.tween_property(h, "scale", Vector3.ONE * 0.01, 0.3).set_delay(delay + 0.95)
		Kind.CLOUD:
			for i: int in 3:
				var puff: MeshInstance3D = _ball(0.07 + i * 0.015, Color("b9b6c4"))
				puff.position = Vector3(i * 0.09 - 0.09, 0.0, 0.0)
				var t: Tween = create_tween()
				t.tween_property(puff, "position:y", 0.35, 1.0)
				t.parallel().tween_property(puff, "scale", Vector3.ONE * 0.01, 1.0).set_delay(0.4)
		Kind.ALERT:
			var bar: MeshInstance3D = MeshInstance3D.new()
			var box: BoxMesh = BoxMesh.new()
			box.size = Vector3(0.05, 0.2, 0.05)
			bar.mesh = box
			bar.material_override = ToonMaterials.get_material(Palette.FLOWER_YELLOW)
			bar.position.y = 0.15
			add_child(bar)
			add_child(_ball(0.035, Palette.FLOWER_YELLOW))
			var t: Tween = create_tween()
			t.tween_property(self, "position:y", position.y + 0.2, 0.15)
			t.tween_interval(0.6)
	var life: SceneTreeTimer = get_tree().create_timer(1.8)
	life.timeout.connect(queue_free)


func _heart(color: Color) -> Node3D:
	# Cuore 3D: due sfere + un cubo ruotato di 45°.
	var h: Node3D = Node3D.new()
	add_child(h)
	var mat: Material = ToonMaterials.get_material(color)
	for side: float in [-1.0, 1.0]:
		var lobe: MeshInstance3D = MeshInstance3D.new()
		var s: SphereMesh = SphereMesh.new()
		s.radius = 0.045
		s.height = 0.09
		s.radial_segments = 8
		s.rings = 4
		lobe.mesh = s
		lobe.material_override = mat
		lobe.position = Vector3(side * 0.034, 0.03, 0.0)
		h.add_child(lobe)
	var tip: MeshInstance3D = MeshInstance3D.new()
	var b: BoxMesh = BoxMesh.new()
	b.size = Vector3(0.068, 0.068, 0.06)
	tip.mesh = b
	tip.material_override = mat
	tip.rotation.z = PI * 0.25
	h.add_child(tip)
	return h


func _ball(radius: float, color: Color) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var s: SphereMesh = SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 8
	s.rings = 4
	mi.mesh = s
	mi.material_override = ToonMaterials.get_material(color)
	add_child(mi)
	return mi
