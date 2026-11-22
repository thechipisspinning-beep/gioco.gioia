class_name TurtleVisual
extends AnimalVisual
## Tartaruga: guscio a cupola con piastre, zampe che remano lente, testa che
## si ritira nel guscio quando dorme o si spaventa.

var _p: Dictionary
var _main: Color
var _accent: Color
var _shell: Node3D
var _head: Node3D
var _legs: Array[Node3D] = []
var _eyes: Array[MeshInstance3D] = []
var _phase: float = 0.0
var _shake: float = 0.0


func setup(species: SpeciesDefinition, variant: int) -> void:
	_p = species.model_params
	_main = species.fur_colors[variant % species.fur_colors.size()] if not species.fur_colors.is_empty() else Color("6b8f5a")
	_accent = species.accent_color
	_build()


func get_mouth_anchor() -> Node3D:
	return _head


func shake_head() -> void:
	_shake = 1.0


func _process(delta: float) -> void:
	if _shell == null:
		return
	_phase += delta * (1.5 + speed * 6.0)
	var moving: float = clampf(speed * 2.0, 0.0, 1.0)
	for i: int in _legs.size():
		_legs[i].rotation.y = sin(_phase + (i % 2) * PI) * 0.5 * moving
	var hide: float = 1.0 if pose == Pose.SLEEP else 0.0
	var s: float = float(_p.get("size", 0.35))
	var target_z: float = lerpf(s * 0.95, s * 0.55, hide)
	_head.position.z = lerpf(_head.position.z, target_z, 1.0 - exp(-4.0 * delta))
	_head.rotation.x = head_down * 0.5
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 1.5)
		_head.rotation.y = sin(_shake * 25.0) * 0.4 * _shake
	elif look_target != null:
		var local: Vector3 = _shell.to_local(look_target as Vector3)
		_head.rotation.y = lerp_angle(_head.rotation.y, clampf(atan2(local.x, local.z), -0.8, 0.8), 1.0 - exp(-5.0 * delta))
	var open: float = 0.12 if (pose == Pose.SLEEP or happy_eyes) else 1.0
	for e: MeshInstance3D in _eyes:
		e.scale.y = lerpf(e.scale.y, open, 1.0 - exp(-12.0 * delta))
	_shell.position.y = absf(sin(_phase)) * 0.01 * moving


func _build() -> void:
	var s: float = float(_p.get("size", 0.35))
	_shell = Node3D.new()
	add_child(_shell)
	var dome: SphereMesh = SphereMesh.new()
	dome.radius = s
	dome.height = s * 1.1
	dome.radial_segments = 16
	dome.rings = 8
	_mesh(_shell, dome, _main, Vector3(0, s * 0.35, 0)).scale = Vector3(1.0, 1.0, 1.2)
	var plate: SphereMesh = SphereMesh.new()
	plate.radius = s * 0.25
	plate.height = s * 0.12
	for o: Vector3 in [Vector3(0, 0.8, 0), Vector3(0.45, 0.62, 0.3), Vector3(-0.45, 0.62, 0.3), Vector3(0.45, 0.62, -0.3), Vector3(-0.45, 0.62, -0.3)]:
		_mesh(_shell, plate, _main.darkened(0.2), Vector3(o.x * s, o.y * s, o.z * s * 1.2))
	var belly: CylinderMesh = CylinderMesh.new()
	belly.top_radius = s * 0.95
	belly.bottom_radius = s * 0.9
	belly.height = s * 0.12
	_mesh(_shell, belly, _accent, Vector3(0, s * 0.28, 0)).scale = Vector3(1.0, 1.0, 1.2)
	var skin: Color = _p.get("skin_color", Color("9cc46a")) as Color
	for o: Vector2 in [Vector2(0.65, 0.55), Vector2(-0.65, 0.55), Vector2(0.65, -0.55), Vector2(-0.65, -0.55)]:
		var leg: Node3D = Node3D.new()
		leg.position = Vector3(o.x * s, s * 0.2, o.y * s * 1.2)
		_shell.add_child(leg)
		var foot: SphereMesh = SphereMesh.new()
		foot.radius = s * 0.2
		foot.height = s * 0.3
		_mesh(leg, foot, skin, Vector3(o.x * s * 0.15, -s * 0.05, 0)).scale = Vector3(1.4, 0.7, 1.0)
		_legs.append(leg)
	_head = Node3D.new()
	_head.position = Vector3(0, s * 0.35, s * 0.95)
	_shell.add_child(_head)
	var h: SphereMesh = SphereMesh.new()
	h.radius = s * 0.26
	h.height = s * 0.5
	_mesh(_head, h, skin, Vector3.ZERO).scale = Vector3(1.0, 0.9, 1.25)
	for side: float in [1.0, -1.0]:
		var e: SphereMesh = SphereMesh.new()
		e.radius = s * 0.05
		e.height = s * 0.1
		_eyes.append(_mesh(_head, e, Palette.EYE_DARK, Vector3(side * s * 0.15, s * 0.07, s * 0.18)))


func _mesh(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.layers = RENDER_LAYER
	mi.mesh = mesh
	mi.material_override = ToonMaterials.get_material(color)
	mi.position = pos
	parent.add_child(mi)
	return mi
