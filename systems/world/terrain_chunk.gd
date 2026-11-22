class_name TerrainChunk
extends Node3D
## Un blocco di terreno (CHUNK_SIZE × CHUNK_SIZE metri) con mesh, collisione
## e vegetazione. Costruito in modo deterministico da `TerrainModel`.

const CHUNK_SIZE: float = 64.0
## Distanza tra i vertici (m).
const CELL: float = 2.0
const RES: int = int(CHUNK_SIZE / CELL) + 1

var coord: Vector2i
var tree_positions: PackedVector3Array = PackedVector3Array()
## Il blocco è attraversato (o sfiorato) da un sentiero? Se no si saltano i calcoli relativi.
var _near_path: bool = true


## Costruisce il blocco. `with_details` aggiunge erba e fiori (solo vicino al giocatore).
func build(terrain: TerrainModel, chunk_coord: Vector2i, with_details: bool) -> void:
	coord = chunk_coord
	name = "Chunk_%d_%d" % [coord.x, coord.y]
	var origin: Vector2 = Vector2(coord.x * CHUNK_SIZE, coord.y * CHUNK_SIZE)
	position = Vector3(origin.x, 0.0, origin.y)
	var center: Vector2 = origin + Vector2.ONE * CHUNK_SIZE * 0.5
	_near_path = IslandLayout.distance_to_path(center) < CHUNK_SIZE * 0.72 + 6.0
	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize(RES * RES)
	for j: int in RES:
		for i: int in RES:
			heights[j * RES + i] = terrain.height_at(origin.x + i * CELL, origin.y + j * CELL)
	var all_below_sea: bool = true
	for h: float in heights:
		if h > IslandLayout.DEEP_WATER - 1.0:
			all_below_sea = false
			break
	if all_below_sea:
		return  # mare aperto: nessuna mesh (lo copre l'acqua), nessuna collisione necessaria
	_build_mesh(terrain, origin, heights)
	_build_collision(heights)
	_build_vegetation(terrain, origin, with_details)


func _build_mesh(terrain: TerrainModel, origin: Vector2, heights: PackedFloat32Array) -> void:
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	verts.resize(RES * RES)
	normals.resize(RES * RES)
	colors.resize(RES * RES)
	for j: int in RES:
		for i: int in RES:
			var h: float = heights[j * RES + i]
			var hl: float = heights[j * RES + maxi(i - 1, 0)]
			var hr: float = heights[j * RES + mini(i + 1, RES - 1)]
			var hd: float = heights[maxi(j - 1, 0) * RES + i]
			var hu: float = heights[mini(j + 1, RES - 1) * RES + i]
			var n: Vector3 = Vector3(hl - hr, 2.0 * CELL, hd - hu).normalized()
			var k: int = j * RES + i
			verts[k] = Vector3(i * CELL, h, j * CELL)
			normals[k] = n
			colors[k] = terrain.color_at(origin.x + i * CELL, origin.y + j * CELL, h, 1.0 - n.y, _near_path)
	for j: int in RES - 1:
		for i: int in RES - 1:
			var a: int = j * RES + i
			indices.append_array([a, a + 1, a + RES, a + 1, a + RES + 1, a + RES])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = ToonMaterials.get_vertex_color_material()
	add_child(mi)


func _build_collision(heights: PackedFloat32Array) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var shape: HeightMapShape3D = HeightMapShape3D.new()
	shape.map_width = RES
	shape.map_depth = RES
	shape.map_data = heights
	var cs: CollisionShape3D = CollisionShape3D.new()
	cs.shape = shape
	# La heightmap è centrata sull'origine della forma e ha celle da 1 m: la si scala.
	cs.position = Vector3(CHUNK_SIZE * 0.5, 0.0, CHUNK_SIZE * 0.5)
	cs.scale = Vector3(CELL, 1.0, CELL)
	body.add_child(cs)


func _build_vegetation(terrain: TerrainModel, origin: Vector2, with_details: bool) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(coord)
	var trees: Dictionary = {&"tree_round": [], &"tree_round_light": [], &"tree_pine": [], &"bush": [], &"rock": [], &"reed": []}
	var tree_body: StaticBody3D = null
	for n: int in 70:
		var x: float = origin.x + rng.randf() * CHUNK_SIZE
		var z: float = origin.y + rng.randf() * CHUNK_SIZE
		var h: float = terrain.height_at(x, z)
		if h < 1.4 and not (h > -0.5 and h < 0.4):
			continue
		var p2: Vector2 = Vector2(x, z)
		if (_near_path and IslandLayout.distance_to_path(p2) < 4.0) or _in_flat_area(p2):
			continue
		var zone: StringName = IslandLayout.zone_at(p2)
		var kind: StringName = _pick_kind(zone, h, rng)
		if kind == &"":
			continue
		var s: float = rng.randf_range(0.8, 1.3)
		var xf: Transform3D = Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s), Vector3(x - origin.x, h - 0.05, z - origin.y))
		(trees[kind] as Array).append(xf)
		if kind.begins_with("tree"):
			tree_positions.append(Vector3(x, h, z))
			if tree_body == null:
				tree_body = StaticBody3D.new()
				tree_body.collision_layer = 1
				tree_body.collision_mask = 0
				add_child(tree_body)
			var cs: CollisionShape3D = CollisionShape3D.new()
			var cyl: CylinderShape3D = CylinderShape3D.new()
			cyl.radius = 0.3 * s
			cyl.height = 2.5
			cs.shape = cyl
			cs.position = xf.origin + Vector3(0, 1.2, 0)
			tree_body.add_child(cs)
	for kind: StringName in trees.keys():
		var list: Array = trees[kind]
		if list.is_empty():
			continue
		_add_multimesh(PropMeshes.get_mesh(kind), list, [], 260.0, true)
	if with_details:
		_add_ground_details(terrain, origin, rng)


func _pick_kind(zone: StringName, h: float, rng: RandomNumberGenerator) -> StringName:
	var r: float = rng.randf()
	if h < 0.4:
		return &"reed" if r < 0.25 and zone == &"lake" else &""
	match zone:
		&"forest":
			if r < 0.55:
				return &"tree_round" if rng.randf() < 0.6 else &"tree_pine"
			return &"bush" if r < 0.7 else &""
		&"mountain":
			if h > 90.0:
				return &"rock" if r < 0.15 else &""
			return &"tree_pine" if r < 0.25 else (&"rock" if r < 0.35 else &"")
		&"village":
			return &"bush" if r < 0.05 else &""
		&"countryside":
			if r < 0.04:
				return &"tree_round_light"
			return &"bush" if r < 0.08 else &""
		&"lake":
			return &"tree_round" if r < 0.12 else (&"bush" if r < 0.2 else &"")
		_:
			if r < 0.08:
				return &"tree_round_light" if rng.randf() < 0.5 else &"tree_round"
			return &"bush" if r < 0.14 else (&"rock" if r < 0.16 else &"")


func _add_ground_details(terrain: TerrainModel, origin: Vector2, rng: RandomNumberGenerator) -> void:
	var grass: Array = []
	var grass_colors: Array = []
	var flowers: Array = []
	var flower_colors: Array = []
	var flower_palette: Array[Color] = [Palette.FLOWER_PINK, Palette.FLOWER_YELLOW, Palette.FLOWER_WHITE, Palette.FLOWER_BLUE]
	for n: int in 420:
		var x: float = origin.x + rng.randf() * CHUNK_SIZE
		var z: float = origin.y + rng.randf() * CHUNK_SIZE
		var h: float = terrain.height_at(x, z)
		if h < 1.8 or h > 60.0 or (_near_path and IslandLayout.distance_to_path(Vector2(x, z)) < 2.6):
			continue
		var xf: Transform3D = Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.7, 1.4)), Vector3(x - origin.x, h, z - origin.y))
		var zone: StringName = IslandLayout.zone_at(Vector2(x, z))
		var flower_chance: float = 0.35 if zone == &"meadows" else 0.12
		if rng.randf() < flower_chance:
			flowers.append(xf)
			flower_colors.append(flower_palette[rng.randi() % flower_palette.size()])
		else:
			grass.append(xf)
			grass_colors.append(Palette.GRASS_DARK.lerp(Palette.LEAF_LIGHT, rng.randf()))
	if not grass.is_empty():
		_add_multimesh(PropMeshes.get_mesh(&"grass"), grass, grass_colors, 55.0, false)
	if not flowers.is_empty():
		_add_multimesh(PropMeshes.get_mesh(&"flower"), flowers, flower_colors, 70.0, false)
	_add_collectibles(terrain, origin)


## Oggetti da raccogliere (GDD § 7.8), con ID stabili per blocco: ricompaiono ogni giorno.
func _add_collectibles(terrain: TerrainModel, origin: Vector2) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(coord) + 77
	for n: int in 6:
		var x: float = origin.x + rng.randf_range(2.0, CHUNK_SIZE - 2.0)
		var z: float = origin.y + rng.randf_range(2.0, CHUNK_SIZE - 2.0)
		var h: float = terrain.height_at(x, z)
		var p2: Vector2 = Vector2(x, z)
		if h < 0.3 or _in_flat_area(p2):
			continue
		var item: StringName = _collectible_for(IslandLayout.zone_at(p2), h, p2, rng)
		if item == &"":
			continue
		var id: String = "c_%d_%d_%d" % [coord.x, coord.y, n]
		add_child(Collectible.create(item, id, Vector3(x - origin.x, h, z - origin.y)))


func _collectible_for(zone: StringName, h: float, p: Vector2, rng: RandomNumberGenerator) -> StringName:
	if h < 2.0 and p.length() > IslandLayout.ISLAND_RADIUS * 0.7:
		return &"seashell"
	match zone:
		&"forest":
			return &"mushroom" if rng.randf() < 0.6 else &"berries"
		&"lake", &"mountain":
			return &"herb" if rng.randf() < 0.7 else &""
		&"meadows", &"countryside", &"village":
			return &"flower" if rng.randf() < 0.7 else (&"herb" if rng.randf() < 0.3 else &"")
	return &"flower" if rng.randf() < 0.4 else &""


func _add_multimesh(mesh: Mesh, transforms: Array, colors: Array, visible_range: float, shadows: bool) -> void:
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	# Le istanze sono relative al centro del blocco: la distanza di visibilità
	# si misura dall'origine del nodo, che così è al centro e non in un angolo.
	var half: Vector3 = Vector3(CHUNK_SIZE * 0.5, 0.0, CHUNK_SIZE * 0.5)
	for i: int in transforms.size():
		var xf: Transform3D = transforms[i] as Transform3D
		xf.origin -= half
		mm.set_instance_transform(i, xf)
		if mm.use_colors:
			mm.set_instance_color(i, colors[i] as Color)
	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.position = half
	mmi.material_override = ToonMaterials.get_vertex_color_material()
	mmi.visibility_range_end = visible_range
	mmi.visibility_range_end_margin = 10.0
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func _in_flat_area(p: Vector2) -> bool:
	for area: Dictionary in IslandLayout.FLAT_AREAS:
		if p.distance_to(area["center"] as Vector2) < float(area["radius"]) * 0.8:
			return true
	return false
