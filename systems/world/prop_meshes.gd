class_name PropMeshes
extends RefCounted
## Mesh degli oggetti naturali (alberi, cespugli, rocce, erba, fiori),
## ognuna fusa in un'unica mesh con colori per vertice: un solo materiale
## e un solo draw call per tipo (con MultiMesh), ideale per mobile e web.

static var _cache: Dictionary = {}


static func get_mesh(kind: StringName) -> ArrayMesh:
	if _cache.has(kind):
		return _cache[kind] as ArrayMesh
	var m: ArrayMesh
	match kind:
		&"tree_round":
			m = _tree_round(Palette.LEAF)
		&"tree_round_light":
			m = _tree_round(Palette.LEAF_LIGHT)
		&"tree_pine":
			m = _tree_pine()
		&"bush":
			m = _bush()
		&"rock":
			m = _rock()
		&"grass":
			m = _grass()
		&"flower":
			m = _flower()
		&"reed":
			m = _reed()
		_:
			push_error("Mesh sconosciuta: %s" % kind)
			m = ArrayMesh.new()
	_cache[kind] = m
	return m


static func _tree_round(leaf: Color) -> ArrayMesh:
	var b: _Builder = _Builder.new()
	b.add(_cyl(0.18, 0.26, 1.7, 8), Transform3D(Basis(), Vector3(0, 0.85, 0)), Palette.BARK)
	b.add(_sph(1.15, 10, 7), Transform3D(Basis(), Vector3(0, 2.4, 0)), leaf)
	b.add(_sph(0.85, 10, 7), Transform3D(Basis(), Vector3(0.65, 2.1, 0.2)), leaf.darkened(0.06))
	b.add(_sph(0.8, 10, 7), Transform3D(Basis(), Vector3(-0.55, 2.15, -0.3)), leaf.lightened(0.05))
	b.add(_sph(0.75, 10, 7), Transform3D(Basis(), Vector3(0.1, 2.95, -0.1)), leaf.lightened(0.1))
	return b.commit()


static func _tree_pine() -> ArrayMesh:
	var b: _Builder = _Builder.new()
	var green: Color = Color("4f9a6a")
	b.add(_cyl(0.14, 0.22, 1.2, 8), Transform3D(Basis(), Vector3(0, 0.6, 0)), Palette.BARK)
	for i: int in 3:
		var r: float = 1.25 - i * 0.32
		b.add(_cyl(0.0, r, 1.4, 9), Transform3D(Basis(), Vector3(0, 1.6 + i * 0.85, 0)), green.lightened(i * 0.05))
	return b.commit()


static func _bush() -> ArrayMesh:
	var b: _Builder = _Builder.new()
	b.add(_sph(0.55, 9, 6), Transform3D(Basis().scaled(Vector3(1, 0.8, 1)), Vector3(0, 0.38, 0)), Palette.LEAF)
	b.add(_sph(0.4, 9, 6), Transform3D(Basis(), Vector3(0.4, 0.3, 0.1)), Palette.LEAF.darkened(0.06))
	b.add(_sph(0.38, 9, 6), Transform3D(Basis(), Vector3(-0.35, 0.32, -0.15)), Palette.LEAF_LIGHT)
	return b.commit()


static func _rock() -> ArrayMesh:
	var b: _Builder = _Builder.new()
	b.add(_sph(0.6, 7, 5), Transform3D(Basis().scaled(Vector3(1.2, 0.7, 1.0)), Vector3(0, 0.2, 0)), Palette.STONE)
	b.add(_sph(0.35, 6, 4), Transform3D(Basis(), Vector3(0.5, 0.15, 0.2)), Palette.STONE_DARK)
	return b.commit()


static func _grass() -> ArrayMesh:
	var b: _Builder = _Builder.new()
	for i: int in 3:
		var basis: Basis = Basis(Vector3.UP, TAU * i / 3.0).rotated(Vector3.RIGHT, 0.25)
		b.add(_cyl(0.0, 0.05, 0.32, 3), Transform3D(basis, Vector3(0, 0.14, 0)), Color.WHITE)
	return b.commit()


static func _flower() -> ArrayMesh:
	var b: _Builder = _Builder.new()
	b.add(_cyl(0.012, 0.012, 0.22, 4), Transform3D(Basis(), Vector3(0, 0.11, 0)), Palette.GRASS_DARK)
	b.add(_sph(0.06, 6, 4), Transform3D(Basis().scaled(Vector3(1, 0.6, 1)), Vector3(0, 0.23, 0)), Color.WHITE)
	return b.commit()


static func _reed() -> ArrayMesh:
	var b: _Builder = _Builder.new()
	for i: int in 4:
		var a: float = TAU * i / 4.0
		b.add(_cyl(0.01, 0.025, 1.1, 4), Transform3D(Basis(Vector3.UP, a).rotated(Vector3.RIGHT, 0.08), Vector3(cos(a) * 0.08, 0.55, sin(a) * 0.08)), Color("7fae5c"))
		b.add(_cyl(0.035, 0.035, 0.2, 5), Transform3D(Basis(), Vector3(cos(a) * 0.1, 1.05, sin(a) * 0.1)), Palette.WOOD_DARK)
	return b.commit()


static func _cyl(top: float, bottom: float, h: float, seg: int) -> CylinderMesh:
	var m: CylinderMesh = CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	return m


static func _sph(r: float, seg: int, rings: int) -> SphereMesh:
	var m: SphereMesh = SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = seg
	m.rings = rings
	return m


## Accumula primitive trasformate in un'unica superficie con colori per vertice.
class _Builder:
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()

	func add(mesh: PrimitiveMesh, xf: Transform3D, color: Color) -> void:
		var arrays: Array = mesh.get_mesh_arrays()
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var base: int = verts.size()
		var nb: Basis = xf.basis.inverse().transposed()
		for i: int in v.size():
			verts.append(xf * v[i])
			normals.append((nb * n[i]).normalized())
			colors.append(color)
		for i: int in idx:
			indices.append(base + i)

	func commit() -> ArrayMesh:
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = indices
		var m: ArrayMesh = ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return m
