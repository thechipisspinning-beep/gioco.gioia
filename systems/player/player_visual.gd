class_name PlayerVisual
extends Node3D
## Aspetto PROVVISORIO di Gioia, costruito con forme semplici, e animazione
## procedurale (dondolio della camminata, inclinazione in corsa, schiacciamento
## all'atterraggio).
##
## Verrà sostituito in Fase 4 dal modello definitivo con scheletro e parti
## personalizzabili. Il controller non dipende da questa classe.
## Proporzioni "morbide": testa grande, corpo piccolo (altezza totale ~1,3 m).

@export var controller: PlayerController

var _body_root: Node3D
var _left_foot: Node3D
var _right_foot: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _head: Node3D
var _ponytail: Node3D
var _walk_phase: float = 0.0
var _squash: float = 0.0
var _lean: float = 0.0


func _ready() -> void:
	_build()
	if controller != null:
		controller.landed.connect(_on_landed)
		controller.jumped.connect(_on_jumped)


func _process(delta: float) -> void:
	if controller == null:
		return
	var speed: float = controller.get_horizontal_speed()
	var on_floor: bool = controller.is_on_floor()
	var speed_ratio: float = clampf(speed / controller.run_speed, 0.0, 1.0)

	# Fase del passo proporzionale alla velocità: i piedi non "pattinano".
	if on_floor and speed > 0.15:
		_walk_phase += delta * (4.0 + speed * 1.9)
	else:
		_walk_phase = lerpf(_walk_phase, roundf(_walk_phase / PI) * PI, 1.0 - exp(-10.0 * delta))

	var stride: float = clampf(speed / controller.walk_speed, 0.0, 1.0) * (0.22 + 0.1 * speed_ratio)
	var swing: float = sin(_walk_phase)
	var bob: float = absf(sin(_walk_phase)) * 0.06 * clampf(speed / controller.walk_speed, 0.0, 1.0)

	_left_foot.position.z = swing * stride
	_right_foot.position.z = -swing * stride
	_left_foot.position.y = 0.06 + maxf(0.0, -cos(_walk_phase)) * 0.06 * stride * 3.0
	_right_foot.position.y = 0.06 + maxf(0.0, cos(_walk_phase)) * 0.06 * stride * 3.0
	_left_arm.rotation.x = -swing * stride * 2.4
	_right_arm.rotation.x = swing * stride * 2.4

	# Inclinazione in avanti quando corre, all'indietro brevemente quando frena.
	var target_lean: float = speed_ratio * 0.18
	_lean = lerpf(_lean, target_lean, 1.0 - exp(-8.0 * delta))
	_body_root.rotation.x = _lean

	# Schiacciamento/allungamento elastico.
	_squash = lerpf(_squash, 0.0, 1.0 - exp(-9.0 * delta))
	var stretch: float = 0.0
	if not on_floor:
		stretch = clampf(controller.velocity.y * 0.02, -0.06, 0.08)
	var sy: float = 1.0 - _squash + stretch
	var sxz: float = 1.0 + _squash * 0.6 - stretch * 0.5
	_body_root.scale = Vector3(sxz, sy, sxz)
	_body_root.position.y = bob

	# La coda di cavallo ondeggia con il movimento.
	_ponytail.rotation.x = 0.25 + swing * 0.12 * speed_ratio + _lean * 1.5
	# Respiro leggero da ferma.
	_head.position.y = 0.92 + sin(Time.get_ticks_msec() * 0.002) * 0.006


func _on_landed(fall_speed: float) -> void:
	_squash = clampf(fall_speed * 0.035, 0.0, 0.22)


func _on_jumped() -> void:
	_squash = -0.08


func _build() -> void:
	_body_root = Node3D.new()
	_body_root.name = "BodyRoot"
	add_child(_body_root)

	# Corpo / vestito (a campana, leggermente svasato)
	var dress: MeshInstance3D = _part(_body_root, _cylinder(0.17, 0.27, 0.42), Palette.OUTFIT_CORAL, Vector3(0, 0.38, 0))
	dress.name = "Dress"
	_part(_body_root, _sphere(0.18, 0.2), Palette.OUTFIT_CORAL, Vector3(0, 0.62, 0))
	# Colletto
	_part(_body_root, _cylinder(0.11, 0.14, 0.05), Palette.FLOWER_WHITE, Vector3(0, 0.74, 0))

	# Braccia (perno alla spalla per farle oscillare)
	_left_arm = _pivot(_body_root, Vector3(0.21, 0.68, 0))
	_part(_left_arm, _capsule(0.055, 0.32), Palette.SKIN_LIGHT, Vector3(0, -0.14, 0))
	_part(_left_arm, _sphere(0.075, 0.08), Palette.OUTFIT_CORAL, Vector3(0, -0.02, 0))
	_left_arm.rotation.z = 0.18
	_right_arm = _pivot(_body_root, Vector3(-0.21, 0.68, 0))
	_part(_right_arm, _capsule(0.055, 0.32), Palette.SKIN_LIGHT, Vector3(0, -0.14, 0))
	_part(_right_arm, _sphere(0.075, 0.08), Palette.OUTFIT_CORAL, Vector3(0, -0.02, 0))
	_right_arm.rotation.z = -0.18

	# Gambe e scarpe
	_part(_body_root, _capsule(0.06, 0.28), Palette.SKIN_LIGHT, Vector3(0.08, 0.2, 0))
	_part(_body_root, _capsule(0.06, 0.28), Palette.SKIN_LIGHT, Vector3(-0.08, 0.2, 0))
	_left_foot = _pivot(self, Vector3(0.08, 0.06, 0))
	_part(_left_foot, _box(Vector3(0.12, 0.09, 0.19), 0.04), Palette.SHOE_WHITE, Vector3(0, 0, 0.02))
	_right_foot = _pivot(self, Vector3(-0.08, 0.06, 0))
	_part(_right_foot, _box(Vector3(0.12, 0.09, 0.19), 0.04), Palette.SHOE_WHITE, Vector3(0, 0, 0.02))

	# Testa (grande, stile morbido)
	_head = _pivot(_body_root, Vector3(0, 0.92, 0))
	_part(_head, _sphere(0.27, 0.26), Palette.SKIN_LIGHT, Vector3.ZERO)
	# Capelli: calotta + frangia + coda di cavallo
	_part(_head, _sphere(0.29, 0.27), Palette.HAIR_BROWN, Vector3(0, 0.045, -0.035))
	_part(_head, _sphere(0.16, 0.09), Palette.HAIR_BROWN, Vector3(0.09, 0.17, 0.19))
	_part(_head, _sphere(0.15, 0.08), Palette.HAIR_BROWN, Vector3(-0.1, 0.16, 0.2))
	_ponytail = _pivot(_head, Vector3(0, 0.12, -0.25))
	_part(_ponytail, _sphere(0.11, 0.17), Palette.HAIR_BROWN, Vector3(0, -0.14, -0.06))
	_part(_ponytail, _sphere(0.055, 0.055), Palette.FLOWER_YELLOW, Vector3(0, 0, 0))
	# Occhi, guance
	_part(_head, _sphere(0.035, 0.05), Palette.EYE_DARK, Vector3(0.09, -0.01, 0.245))
	_part(_head, _sphere(0.035, 0.05), Palette.EYE_DARK, Vector3(-0.09, -0.01, 0.245))
	_part(_head, _sphere(0.012, 0.012), Palette.FLOWER_WHITE, Vector3(0.1, 0.01, 0.275))
	_part(_head, _sphere(0.012, 0.012), Palette.FLOWER_WHITE, Vector3(-0.08, 0.01, 0.275))
	_part(_head, _sphere(0.04, 0.02), Palette.CHEEK_PINK, Vector3(0.155, -0.075, 0.2))
	_part(_head, _sphere(0.04, 0.02), Palette.CHEEK_PINK, Vector3(-0.155, -0.075, 0.2))


func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n: Node3D = Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


func _part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = ToonMaterials.get_material(color)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _sphere(radius: float, half_height: float) -> SphereMesh:
	var m: SphereMesh = SphereMesh.new()
	m.radius = radius
	m.height = half_height * 2.0
	m.radial_segments = 20
	m.rings = 12
	return m


func _capsule(radius: float, height: float) -> CapsuleMesh:
	var m: CapsuleMesh = CapsuleMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = 12
	m.rings = 4
	return m


func _cylinder(top: float, bottom: float, height: float) -> CylinderMesh:
	var m: CylinderMesh = CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = 20
	return m


func _box(size: Vector3, _bevel: float) -> BoxMesh:
	var m: BoxMesh = BoxMesh.new()
	m.size = size
	return m
