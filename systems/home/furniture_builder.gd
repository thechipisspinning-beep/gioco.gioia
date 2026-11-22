class_name FurnitureBuilder
extends RefCounted
## Modelli 3D dei mobili, costruiti con forme semplici. Il nodo restituito ha
## l'origine al centro dell'ingombro, a terra; il fronte è +Z.


static func build(id: StringName, color: Color) -> Node3D:
	var root: Node3D = Node3D.new()
	var b: LevelBuilder = LevelBuilder.new(root)
	match id:
		&"bed":
			_box(b, Vector3(1.9, 0.35, 2.4), Vector3(0, 0.2, 0), Palette.WOOD)
			_box(b, Vector3(1.8, 0.2, 2.3), Vector3(0, 0.45, 0.02), Palette.FLOWER_WHITE)
			_box(b, Vector3(1.82, 0.12, 1.5), Vector3(0, 0.56, 0.42), color)
			_box(b, Vector3(0.7, 0.16, 0.4), Vector3(-0.42, 0.62, -0.85), Palette.FLOWER_WHITE)
			_box(b, Vector3(0.7, 0.16, 0.4), Vector3(0.42, 0.62, -0.85), Palette.FLOWER_WHITE)
			_box(b, Vector3(1.95, 0.9, 0.12), Vector3(0, 0.55, -1.18), Palette.WOOD_DARK)
		&"table":
			_box(b, Vector3(1.3, 0.08, 1.3), Vector3(0, 0.75, 0), Palette.WOOD)
			for o: Vector2 in [Vector2(-0.55, -0.55), Vector2(0.55, -0.55), Vector2(-0.55, 0.55), Vector2(0.55, 0.55)]:
				_box(b, Vector3(0.09, 0.72, 0.09), Vector3(o.x, 0.36, o.y), Palette.WOOD_DARK)
			_sphere(b, 0.12, Vector3(0, 0.88, 0), Palette.FLOWER_PINK)
		&"chair":
			_box(b, Vector3(0.6, 0.08, 0.6), Vector3(0, 0.45, 0), color)
			_box(b, Vector3(0.6, 0.6, 0.08), Vector3(0, 0.75, -0.26), Palette.WOOD)
			for o: Vector2 in [Vector2(-0.25, -0.25), Vector2(0.25, -0.25), Vector2(-0.25, 0.25), Vector2(0.25, 0.25)]:
				_box(b, Vector3(0.06, 0.45, 0.06), Vector3(o.x, 0.22, o.y), Palette.WOOD_DARK)
		&"sofa":
			_box(b, Vector3(2.4, 0.4, 0.9), Vector3(0, 0.25, 0.05), color)
			_box(b, Vector3(2.4, 0.6, 0.25), Vector3(0, 0.6, -0.35), color.darkened(0.08))
			_box(b, Vector3(0.25, 0.55, 0.9), Vector3(-1.1, 0.45, 0.05), color.darkened(0.12))
			_box(b, Vector3(0.25, 0.55, 0.9), Vector3(1.1, 0.45, 0.05), color.darkened(0.12))
			_sphere(b, 0.2, Vector3(-0.6, 0.6, -0.1), Palette.FLOWER_YELLOW)
		&"rug":
			var rug: CylinderMesh = CylinderMesh.new()
			rug.top_radius = 1.0
			rug.bottom_radius = 1.0
			rug.height = 0.02
			rug.radial_segments = 28
			b.decor(rug, Vector3(0, 0.012, 0), color, Vector3.ZERO, Vector3(1.22, 1.0, 0.98))
			b.decor(rug, Vector3(0, 0.016, 0), color.lightened(0.25), Vector3.ZERO, Vector3(0.8, 1.0, 0.64))
		&"lamp":
			_box(b, Vector3(0.3, 0.05, 0.3), Vector3(0, 0.03, 0), Palette.EYE_DARK)
			_box(b, Vector3(0.05, 1.3, 0.05), Vector3(0, 0.68, 0), Palette.EYE_DARK)
			var shade: CylinderMesh = CylinderMesh.new()
			shade.top_radius = 0.15
			shade.bottom_radius = 0.25
			shade.height = 0.3
			b.decor(shade, Vector3(0, 1.42, 0), color)
		&"plant":
			var pot: CylinderMesh = CylinderMesh.new()
			pot.top_radius = 0.2
			pot.bottom_radius = 0.15
			pot.height = 0.32
			b.decor(pot, Vector3(0, 0.16, 0), Palette.ROOF_RED)
			_sphere(b, 0.26, Vector3(0, 0.5, 0), Palette.LEAF)
			_sphere(b, 0.18, Vector3(0.1, 0.72, 0.05), Palette.LEAF_LIGHT)
		&"bookshelf":
			_box(b, Vector3(1.9, 1.8, 0.4), Vector3(0, 0.9, 0), Palette.WOOD)
			var colors: Array[Color] = [Palette.FLOWER_PINK, Palette.FLOWER_BLUE, Palette.FLOWER_YELLOW, Palette.LEAF, Palette.ROOF_RED]
			for row: int in 3:
				for i: int in 7:
					_box(b, Vector3(0.18, 0.38, 0.28), Vector3(-0.75 + i * 0.25, 0.3 + row * 0.55, 0.08), colors[(i + row) % colors.size()])
		&"pet_bed":
			var bed: CylinderMesh = CylinderMesh.new()
			bed.top_radius = 0.48
			bed.bottom_radius = 0.45
			bed.height = 0.22
			bed.radial_segments = 20
			b.decor(bed, Vector3(0, 0.11, 0), color)
			var cushion: CylinderMesh = CylinderMesh.new()
			cushion.top_radius = 0.36
			cushion.bottom_radius = 0.36
			cushion.height = 0.1
			b.decor(cushion, Vector3(0, 0.2, 0), Palette.FLOWER_WHITE)
		&"pet_bowl":
			var bowl: CylinderMesh = CylinderMesh.new()
			bowl.top_radius = 0.2
			bowl.bottom_radius = 0.14
			bowl.height = 0.1
			b.decor(bowl, Vector3(0, 0.05, 0), color)
			_sphere(b, 0.12, Vector3(0, 0.08, 0), Palette.WOOD)
		&"scratching_post":
			_box(b, Vector3(0.45, 0.06, 0.45), Vector3(0, 0.03, 0), Palette.WOOD_DARK)
			var post: CylinderMesh = CylinderMesh.new()
			post.top_radius = 0.09
			post.bottom_radius = 0.09
			post.height = 1.0
			b.decor(post, Vector3(0, 0.55, 0), Color("e3c79b"))
			_box(b, Vector3(0.4, 0.05, 0.4), Vector3(0, 1.07, 0), Palette.WOOD)
		&"toy_box":
			_box(b, Vector3(0.9, 0.45, 0.45), Vector3(0, 0.22, 0), color)
			_sphere(b, 0.1, Vector3(-0.2, 0.5, 0), Palette.ROOF_RED)
			_sphere(b, 0.08, Vector3(0.15, 0.48, 0.05), Palette.FLOWER_BLUE)
		&"stove":
			_box(b, Vector3(0.9, 0.85, 0.85), Vector3(0, 0.43, 0), Palette.FLOWER_WHITE)
			for o: Vector2 in [Vector2(-0.2, -0.15), Vector2(0.2, -0.15), Vector2(-0.2, 0.2), Vector2(0.2, 0.2)]:
				var burner: CylinderMesh = CylinderMesh.new()
				burner.top_radius = 0.12
				burner.bottom_radius = 0.12
				burner.height = 0.02
				b.decor(burner, Vector3(o.x, 0.87, o.y), Palette.EYE_DARK)
			_box(b, Vector3(0.6, 0.3, 0.02), Vector3(0, 0.45, 0.43), Palette.EYE_DARK)
		&"counter":
			_box(b, Vector3(1.4, 0.85, 0.9), Vector3(0, 0.43, 0), color)
			_box(b, Vector3(1.45, 0.06, 0.95), Vector3(0, 0.88, 0), Palette.WOOD)
		_:
			_box(b, Vector3(0.5, 0.5, 0.5), Vector3(0, 0.25, 0), color)
	return root


static func _box(b: LevelBuilder, size: Vector3, pos: Vector3, color: Color) -> void:
	var m: BoxMesh = BoxMesh.new()
	m.size = size
	b.decor(m, pos, color)


static func _sphere(b: LevelBuilder, r: float, pos: Vector3, color: Color) -> void:
	var m: SphereMesh = SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 12
	m.rings = 6
	b.decor(m, pos, color)
