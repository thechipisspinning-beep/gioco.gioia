class_name LevelBuilder
extends RefCounted
## Funzioni per costruire geometria di livello da codice (greybox e ambienti
## generati). Ogni oggetto solido usa il layer di collisione 1 ("mondo").
##
## Tutte le mesh usano materiali toon condivisi da `ToonMaterials`.

const WORLD_LAYER: int = 1

var root: Node3D


func _init(parent: Node3D) -> void:
	root = parent


## Blocco solido (con collisione).
func solid_box(size: Vector3, position: Vector3, color: Color, rotation_degrees: Vector3 = Vector3.ZERO, parent: Node3D = null) -> StaticBody3D:
	var body: StaticBody3D = _static_body(position, rotation_degrees, parent)
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	_add_mesh(body, mesh, color)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	_add_shape(body, shape)
	return body


## Mesh solo visiva (nessuna collisione).
func decor(mesh: Mesh, position: Vector3, color: Color, rotation_degrees: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE, parent: Node3D = null) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = ToonMaterials.get_material(color)
	mi.position = position
	mi.rotation_degrees = rotation_degrees
	mi.scale = scale
	(parent if parent != null else root).add_child(mi)
	return mi


## Collisione invisibile (es. limite dell'acqua profonda, rampa sotto le scale).
func invisible_wall(shape: Shape3D, position: Vector3, rotation_degrees: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body: StaticBody3D = _static_body(position, rotation_degrees, null)
	_add_shape(body, shape)
	return body


## Rampa inclinata di `angle_degrees` che sale verso -Z, con base al centro `base_position`.
## Restituisce l'altezza raggiunta in cima.
func ramp(width: float, length: float, angle_degrees: float, base_position: Vector3, color: Color) -> float:
	var thickness: float = 0.4
	var a: float = deg_to_rad(angle_degrees)
	var rise: float = sin(a) * length
	var run: float = cos(a) * length
	# Il centro del blocco inclinato: metà percorso, metà salita, abbassato dello spessore.
	var center: Vector3 = base_position + Vector3(0.0, rise * 0.5 - cos(a) * thickness * 0.5, -run * 0.5)
	solid_box(Vector3(width, thickness, length), center, color, Vector3(angle_degrees, 0.0, 0.0))
	return rise


## Scala: gradini visivi, ma collisione a rampa (così Gioia sale in modo fluido
## senza incastrarsi sugli spigoli). Sale verso -Z.
func stairs(width: float, steps: int, step_height: float, step_depth: float, base_position: Vector3, color: Color) -> void:
	for i: int in steps:
		var h: float = step_height * (i + 1)
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(width, h, step_depth)
		decor(mesh, base_position + Vector3(0.0, h * 0.5, -step_depth * (i + 0.5)), color)
	var total_rise: float = step_height * steps
	var total_run: float = step_depth * steps
	var length: float = sqrt(total_rise * total_rise + total_run * total_run)
	var angle: float = atan2(total_rise, total_run)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(width, 0.1, length)
	invisible_wall(shape, base_position + Vector3(0.0, total_rise * 0.5, -total_run * 0.5), Vector3(rad_to_deg(angle), 0.0, 0.0))


## Albero stilizzato: tronco con collisione + chioma di sfere morbide.
func tree(position: Vector3, height: float = 3.0, foliage_color: Color = Palette.LEAF) -> void:
	var body: StaticBody3D = _static_body(position, Vector3.ZERO, null)
	var trunk: CylinderMesh = CylinderMesh.new()
	trunk.top_radius = 0.16 * height / 3.0
	trunk.bottom_radius = 0.24 * height / 3.0
	trunk.height = height * 0.55
	trunk.radial_segments = 10
	var trunk_mi: MeshInstance3D = _add_mesh(body, trunk, Palette.BARK)
	trunk_mi.position.y = height * 0.275
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = trunk.bottom_radius
	shape.height = trunk.height
	var cs: CollisionShape3D = _add_shape(body, shape)
	cs.position.y = height * 0.275
	var r: float = height * 0.3
	var blobs: Array[Vector4] = [
		Vector4(0.0, height * 0.72, 0.0, r),
		Vector4(r * 0.55, height * 0.62, r * 0.2, r * 0.72),
		Vector4(-r * 0.5, height * 0.64, -r * 0.25, r * 0.7),
		Vector4(0.1 * r, height * 0.88, -0.1 * r, r * 0.65),
	]
	for b: Vector4 in blobs:
		var s: SphereMesh = SphereMesh.new()
		s.radius = b.w
		s.height = b.w * 1.8
		s.radial_segments = 14
		s.rings = 8
		_add_mesh(body, s, foliage_color).position = Vector3(b.x, b.y, b.z)


## Prato decorativo: MultiMesh di ciuffi/fiori sparsi in un rettangolo.
## Un solo draw call per migliaia di elementi.
func scatter(mesh: Mesh, count: int, center: Vector3, extents: Vector2, colors: Array[Color], min_scale: float, max_scale: float, rng_seed: int, avoid: Array[Rect2] = []) -> MultiMeshInstance3D:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = rng_seed
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	var transforms: Array[Transform3D] = []
	var tints: Array[Color] = []
	var attempts: int = 0
	while transforms.size() < count and attempts < count * 4:
		attempts += 1
		var p: Vector3 = center + Vector3(rng.randf_range(-extents.x, extents.x), 0.0, rng.randf_range(-extents.y, extents.y))
		var blocked: bool = false
		for rect: Rect2 in avoid:
			if rect.has_point(Vector2(p.x, p.z)):
				blocked = true
				break
		if blocked:
			continue
		var s: float = rng.randf_range(min_scale, max_scale)
		var basis: Basis = Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s))
		transforms.append(Transform3D(basis, p))
		tints.append(colors[rng.randi() % colors.size()])
	mm.instance_count = transforms.size()
	for i: int in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, tints[i])
	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = ToonMaterials.get_vertex_color_material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 70.0
	root.add_child(mmi)
	return mmi


func _static_body(position: Vector3, rotation_degrees: Vector3, parent: Node3D) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	body.position = position
	body.rotation_degrees = rotation_degrees
	(parent if parent != null else root).add_child(body)
	return body


func _add_mesh(parent: Node3D, mesh: Mesh, color: Color) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = ToonMaterials.get_material(color)
	parent.add_child(mi)
	return mi


func _add_shape(body: StaticBody3D, shape: Shape3D) -> CollisionShape3D:
	var cs: CollisionShape3D = CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	return cs
