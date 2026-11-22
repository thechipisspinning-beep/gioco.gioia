class_name BirdVisual
extends AnimalVisual
## Uccelli (gallina, anatra, gufo, gabbiano): corpo tondo, ali che sbattono,
## testa che becca, zampette che si muovono veloci.
## Parametri da `model_params`: size, beak ("cone" | "flat" | "hook"), crest
## (cresta rossa), eye_size, tail ("fan" | "short"), legs_color, beak_color.

var _p: Dictionary
var _main: Color
var _accent: Color
var _body: Node3D
var _head: Node3D
var _wings: Array[Node3D] = []
var _feet: Array[Node3D] = []
var _eyes: Array[MeshInstance3D] = []
var _mouth: Node3D
var _phase: float = 0.0
var _flap: float = 0.0
var _hop_y: float = 0.0
var _hop_v: float = 0.0
var _blink: float = 0.0
var _blink_t: float = 3.0
var _shake: float = 0.0


func setup(species: SpeciesDefinition, variant: int) -> void:
	_p = species.model_params
	_main = species.fur_colors[variant % species.fur_colors.size()] if not species.fur_colors.is_empty() else Color.WHITE
	_accent = species.accent_color
	_build()


func get_mouth_anchor() -> Node3D:
	return _mouth


func hop(strength: float = 1.0) -> void:
	if _hop_y <= 0.001:
		_hop_v = 1.8 * strength
	_flap = 1.0


func shake_head() -> void:
	_shake = 1.0


func _process(delta: float) -> void:
	if _body == null:
		return
	var s: float = float(_p.get("size", 0.3))
	_phase += delta * (3.0 + speed * 9.0)
	var moving: float = clampf(speed, 0.0, 1.0)
	for i: int in _feet.size():
		var side: float = 1.0 if i == 0 else -1.0
		_feet[i].position.z = sin(_phase + i * PI) * 0.08 * s * 3.0 * moving
		_feet[i].position.y = maxf(0.0, side * sin(_phase)) * 0.04 * moving
	# Ali: sbattono quando è felice o salta.
	_flap = maxf(_flap - delta * 1.5, wag - 0.6)
	for i: int in _wings.size():
		var side: float = 1.0 if i == 0 else -1.0
		_wings[i].rotation.z = side * (0.1 + absf(sin(Time.get_ticks_msec() * 0.03)) * 0.9 * maxf(_flap, 0.0))
	if _hop_y > 0.0 or _hop_v > 0.0:
		_hop_v -= 9.8 * delta
		_hop_y = maxf(0.0, _hop_y + _hop_v * delta)
	var sleep: float = 1.0 if pose == Pose.SLEEP else 0.0
	var sit: float = 1.0 if pose in [Pose.SIT, Pose.LIE, Pose.SLEEP] else 0.0
	_body.position.y = _hop_y + absf(sin(_phase)) * 0.02 * moving - sit * s * 0.25
	_body.rotation.z = sin(_phase) * 0.08 * moving
	# Testa: becca il terreno, guarda Gioia, si nasconde sotto l'ala dormendo.
	var pitch: float = lerpf(0.0, 1.0, head_down) + sin(Time.get_ticks_msec() * 0.025) * 0.15 * head_down
	var yaw: float = 0.0
	if look_target != null:
		var local: Vector3 = _body.to_local(look_target as Vector3)
		yaw = clampf(atan2(local.x, local.z), -1.2, 1.2)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 1.8)
		yaw += sin(_shake * 35.0) * 0.5 * _shake
	_head.rotation.x = lerpf(_head.rotation.x, lerpf(pitch, 0.6, sleep), 1.0 - exp(-10.0 * delta))
	_head.rotation.y = lerp_angle(_head.rotation.y, lerpf(yaw, 1.2, sleep), 1.0 - exp(-8.0 * delta))
	# Occhi
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink = 1.0
		_blink_t = randf_range(2.0, 5.0)
	_blink = maxf(0.0, _blink - delta * 8.0)
	var open: float = 0.12 if (pose == Pose.SLEEP or happy_eyes) else 1.0 - _blink * 0.9
	for e: MeshInstance3D in _eyes:
		e.scale.y = lerpf(e.scale.y, open, 1.0 - exp(-20.0 * delta))


func _build() -> void:
	var s: float = float(_p.get("size", 0.3))
	var legs_color: Color = _p.get("legs_color", Color("f2a33a")) as Color
	var beak_color: Color = _p.get("beak_color", Color("f2a33a")) as Color
	_body = Node3D.new()
	add_child(_body)
	var leg_h: float = s * 0.55
	for side: float in [1.0, -1.0]:
		var foot: Node3D = Node3D.new()
		foot.position = Vector3(side * s * 0.3, 0, 0)
		add_child(foot)
		_mesh(foot, _cyl(s * 0.04, s * 0.04, leg_h), legs_color, Vector3(0, leg_h * 0.5, 0))
		var toe: MeshInstance3D = _mesh(foot, _box(Vector3(s * 0.22, s * 0.04, s * 0.26)), legs_color, Vector3(0, s * 0.02, s * 0.06))
		toe.scale = Vector3.ONE
		_feet.append(foot)
	var body_y: float = leg_h + s * 0.45
	var torso: MeshInstance3D = _mesh(_body, _sph(s * 0.6), _main, Vector3(0, body_y, 0))
	torso.scale = Vector3(0.9, 0.85, 1.15)
	_mesh(_body, _sph(s * 0.42), _accent, Vector3(0, body_y - s * 0.12, s * 0.22)).scale = Vector3(0.9, 0.8, 0.9)
	for side: float in [1.0, -1.0]:
		var wing: Node3D = Node3D.new()
		wing.position = Vector3(side * s * 0.5, body_y + s * 0.15, -s * 0.05)
		_body.add_child(wing)
		var w: MeshInstance3D = _mesh(wing, _sph(s * 0.38), _main.darkened(0.12), Vector3(side * s * 0.05, -s * 0.12, -s * 0.05))
		w.scale = Vector3(0.35, 0.8, 1.2)
		_wings.append(wing)
	# Coda
	if String(_p.get("tail", "fan")) == "fan":
		for i: int in 3:
			var f: MeshInstance3D = _mesh(_body, _sph(s * 0.2), _main.darkened(0.08 * i), Vector3((i - 1) * s * 0.15, body_y + s * 0.3, -s * 0.7))
			f.scale = Vector3(0.5, 1.4, 0.5)
			f.rotation.x = -0.5
	else:
		_mesh(_body, _sph(s * 0.22), _main.darkened(0.1), Vector3(0, body_y + s * 0.05, -s * 0.68)).scale = Vector3(1.2, 0.5, 1.0)
	# Testa
	_head = Node3D.new()
	_head.position = Vector3(0, body_y + s * 0.55, s * 0.42)
	_body.add_child(_head)
	var head_r: float = s * float(_p.get("head_ratio", 0.38))
	_mesh(_head, _sph(head_r), _p.get("head_color", _main) as Color, Vector3.ZERO)
	match String(_p.get("beak", "cone")):
		"flat":
			var beak: MeshInstance3D = _mesh(_head, _sph(head_r * 0.6), beak_color, Vector3(0, -head_r * 0.2, head_r * 0.95))
			beak.scale = Vector3(1.0, 0.35, 1.3)
		"hook":
			var hook: MeshInstance3D = _mesh(_head, _cyl(0.0, head_r * 0.25, head_r * 0.5), beak_color, Vector3(0, -head_r * 0.15, head_r * 0.95))
			hook.rotation.x = PI * 0.6
		_:
			var cone: MeshInstance3D = _mesh(_head, _cyl(0.0, head_r * 0.28, head_r * 0.55), beak_color, Vector3(0, -head_r * 0.05, head_r * 1.05))
			cone.rotation.x = PI * 0.5
	_mouth = Node3D.new()
	_mouth.position = Vector3(0, -head_r * 0.1, head_r * 1.2)
	_head.add_child(_mouth)
	if bool(_p.get("crest", false)):
		for i: int in 3:
			_mesh(_head, _sph(head_r * 0.22), Color("e84a3c"), Vector3(0, head_r * (0.9 + 0.05 * (1 - absi(i - 1))), head_r * (0.3 - i * 0.25)))
		_mesh(_head, _sph(head_r * 0.18), Color("e84a3c"), Vector3(0, -head_r * 0.55, head_r * 0.85)).scale = Vector3(0.7, 1.3, 0.7)
	var eye_size: float = float(_p.get("eye_size", 0.2))
	for side: float in [1.0, -1.0]:
		if eye_size > 0.3:
			_mesh(_head, _sph(head_r * eye_size * 1.25), Color("fff2c0"), Vector3(side * head_r * 0.42, head_r * 0.15, head_r * 0.72))
		var eye: MeshInstance3D = _mesh(_head, _sph(head_r * eye_size * 0.75), Palette.EYE_DARK, Vector3(side * head_r * 0.45, head_r * 0.18, head_r * 0.8))
		_eyes.append(eye)
	if bool(_p.get("ear_tufts", false)):
		for side: float in [1.0, -1.0]:
			var tuft: MeshInstance3D = _mesh(_head, _cyl(0.0, head_r * 0.25, head_r * 0.6), _main.darkened(0.2), Vector3(side * head_r * 0.55, head_r * 0.85, 0))
			tuft.rotation.z = -side * 0.4


func _mesh(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.layers = RENDER_LAYER
	mi.mesh = mesh
	mi.material_override = ToonMaterials.get_material(color)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _sph(r: float) -> SphereMesh:
	return MeshCache.sphere(r, r * 2.0, 14, 7)


func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	return MeshCache.cylinder(top, bottom, h, 8)


func _box(size: Vector3) -> BoxMesh:
	return MeshCache.box(size)
