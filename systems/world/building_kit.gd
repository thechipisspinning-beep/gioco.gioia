class_name BuildingKit
extends RefCounted
## Edifici e arredi esterni del villaggio, costruiti con forme semplici e
## materiali della palette. Ogni funzione crea un nodo con collisione.


## Casetta: pareti, tetto a capanna, porta, finestre, comignolo.
static func cottage(parent: Node3D, pos: Vector3, yaw_deg: float, wall: Color, roof: Color, size: Vector3 = Vector3(5.0, 3.0, 4.2)) -> Node3D:
	var root: Node3D = Node3D.new()
	root.position = pos
	root.rotation_degrees.y = yaw_deg
	parent.add_child(root)
	var b: LevelBuilder = LevelBuilder.new(root)
	b.solid_box(Vector3(size.x + 0.4, 0.3, size.z + 0.4), Vector3(0, 0.15, 0), Palette.STONE_DARK)
	b.solid_box(size, Vector3(0, size.y * 0.5 + 0.3, 0), wall)
	var roof_mesh: PrismMesh = PrismMesh.new()
	roof_mesh.size = Vector3(size.x + 0.8, size.y * 0.6, size.z + 0.6)
	b.decor(roof_mesh, Vector3(0, size.y + 0.3 + size.y * 0.3, 0), roof)
	var chimney: BoxMesh = BoxMesh.new()
	chimney.size = Vector3(0.5, 1.0, 0.5)
	b.decor(chimney, Vector3(size.x * 0.25, size.y + 1.2, -size.z * 0.15), Palette.STONE)
	var door: BoxMesh = BoxMesh.new()
	door.size = Vector3(1.0, 1.9, 0.08)
	b.decor(door, Vector3(0, 1.25, size.z * 0.5 + 0.03), Palette.WOOD_DARK)
	var knob: SphereMesh = SphereMesh.new()
	knob.radius = 0.05
	knob.height = 0.1
	b.decor(knob, Vector3(0.32, 1.2, size.z * 0.5 + 0.09), Palette.FLOWER_YELLOW)
	var window: BoxMesh = BoxMesh.new()
	window.size = Vector3(0.8, 0.8, 0.08)
	var frame: BoxMesh = BoxMesh.new()
	frame.size = Vector3(0.95, 0.95, 0.06)
	for x: float in [-size.x * 0.3, size.x * 0.3]:
		b.decor(frame, Vector3(x, 1.9, size.z * 0.5 + 0.02), Palette.FLOWER_WHITE)
		b.decor(window, Vector3(x, 1.9, size.z * 0.5 + 0.05), Color("a8dcf2"))
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(0.9, 0.2, 0.25)
		b.decor(box, Vector3(x, 1.4, size.z * 0.5 + 0.15), Palette.WOOD)
		for k: int in 3:
			var f: SphereMesh = SphereMesh.new()
			f.radius = 0.09
			f.height = 0.15
			b.decor(f, Vector3(x - 0.28 + k * 0.28, 1.55, size.z * 0.5 + 0.17), [Palette.FLOWER_PINK, Palette.FLOWER_YELLOW, Palette.FLOWER_WHITE][k])
	return root


## Fontana rotonda con acqua.
static func fountain(parent: Node3D, pos: Vector3) -> void:
	var root: Node3D = Node3D.new()
	root.position = pos
	parent.add_child(root)
	var b: LevelBuilder = LevelBuilder.new(root)
	var body: StaticBody3D = StaticBody3D.new()
	root.add_child(body)
	var cs: CollisionShape3D = CollisionShape3D.new()
	var cyl: CylinderShape3D = CylinderShape3D.new()
	cyl.radius = 2.2
	cyl.height = 0.9
	cs.shape = cyl
	cs.position.y = 0.45
	body.add_child(cs)
	var basin: CylinderMesh = CylinderMesh.new()
	basin.top_radius = 2.2
	basin.bottom_radius = 2.35
	basin.height = 0.8
	basin.radial_segments = 24
	b.decor(basin, Vector3(0, 0.4, 0), Palette.STONE)
	var water: CylinderMesh = CylinderMesh.new()
	water.top_radius = 1.95
	water.bottom_radius = 1.95
	water.height = 0.05
	water.radial_segments = 24
	b.decor(water, Vector3(0, 0.72, 0), Palette.WATER)
	var column: CylinderMesh = CylinderMesh.new()
	column.top_radius = 0.25
	column.bottom_radius = 0.35
	column.height = 1.6
	b.decor(column, Vector3(0, 1.2, 0), Palette.STONE)
	var bowl: SphereMesh = SphereMesh.new()
	bowl.radius = 0.7
	bowl.height = 0.5
	b.decor(bowl, Vector3(0, 2.0, 0), Palette.STONE_DARK)


static func lamp_post(parent: Node3D, pos: Vector3) -> void:
	var b: LevelBuilder = LevelBuilder.new(parent)
	b.solid_box(Vector3(0.14, 2.6, 0.14), pos + Vector3(0, 1.3, 0), Palette.EYE_DARK)
	var lamp: SphereMesh = SphereMesh.new()
	lamp.radius = 0.22
	lamp.height = 0.4
	b.decor(lamp, pos + Vector3(0, 2.75, 0), Color("fff1b8"))


static func bench(parent: Node3D, pos: Vector3, yaw_deg: float) -> void:
	var root: Node3D = Node3D.new()
	root.position = pos
	root.rotation_degrees.y = yaw_deg
	parent.add_child(root)
	var b: LevelBuilder = LevelBuilder.new(root)
	b.solid_box(Vector3(1.8, 0.1, 0.5), Vector3(0, 0.45, 0), Palette.WOOD)
	b.solid_box(Vector3(1.8, 0.5, 0.08), Vector3(0, 0.75, -0.22), Palette.WOOD)
	for x: float in [-0.75, 0.75]:
		b.solid_box(Vector3(0.1, 0.45, 0.45), Vector3(x, 0.22, 0), Palette.WOOD_DARK)


static func fence_line(parent: Node3D, from: Vector3, to: Vector3, ground: Callable) -> void:
	var b: LevelBuilder = LevelBuilder.new(parent)
	var length: float = from.distance_to(to)
	var posts: int = maxi(2, int(length / 1.6) + 1)
	for i: int in posts:
		var p: Vector3 = from.lerp(to, float(i) / (posts - 1))
		p.y = float(ground.call(p.x, p.z))
		b.solid_box(Vector3(0.14, 0.95, 0.14), p + Vector3(0, 0.47, 0), Palette.WOOD)
		if i > 0:
			var prev: Vector3 = from.lerp(to, float(i - 1) / (posts - 1))
			prev.y = float(ground.call(prev.x, prev.z))
			var mid: Vector3 = (prev + p) * 0.5
			var seg: float = prev.distance_to(p)
			var rail: BoxMesh = BoxMesh.new()
			rail.size = Vector3(0.06, 0.1, seg)
			var yaw: float = rad_to_deg(atan2(p.x - prev.x, p.z - prev.z))
			for hgt: float in [0.35, 0.7]:
				b.decor(rail, mid + Vector3(0, hgt, 0), Palette.WOOD, Vector3(0, yaw, 0))
