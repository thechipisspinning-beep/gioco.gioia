class_name QuadrupedVisual
extends AnimalVisual
## Modello procedurale di un quadrupede (cane, volpe, e in futuro gatto, pecora…)
## con animazioni procedurali espressive.
##
## Il fronte dell'animale è +Z. L'agente (`AnimalAgent`) imposta solo parametri
## di alto livello: velocità, posa, scodinzolio, punto da guardare, testa bassa.
## Le proporzioni arrivano da `SpeciesDefinition.model_params`.


var _p: Dictionary
var _main: Color
var _accent: Color
var _leg_color: Color

var _body: Node3D
var _head_pivot: Node3D
var _head: Node3D
var _tail_pivot: Node3D
var _legs: Array[Node3D] = []  # FL, FR, BL, BR
var _ears: Array[Node3D] = []
var _eyes: Array[MeshInstance3D] = []
var _mouth_anchor: Node3D

var _gait_phase: float = 0.0
var _wag_phase: float = 0.0
var _blink_timer: float = 2.0
var _blink: float = 0.0
var _hop: float = 0.0
var _hop_velocity: float = 0.0
var _pose_blend: Dictionary = {Pose.STAND: 1.0, Pose.SIT: 0.0, Pose.LIE: 0.0, Pose.SLEEP: 0.0}
var _shake: float = 0.0


## Costruisce il modello. `variant` sceglie il colore del mantello.
func setup(species: SpeciesDefinition, variant: int) -> void:  # override
	_p = species.model_params
	_main = species.fur_colors[variant % species.fur_colors.size()] if not species.fur_colors.is_empty() else Color.BURLYWOOD
	_accent = species.accent_color
	_leg_color = _p.get("leg_color", _main) as Color
	_build()


## Punto in cui l'animale tiene gli oggetti in bocca (es. la pallina).
func get_mouth_anchor() -> Node3D:  # override
	return _mouth_anchor


## Piccolo saltello di gioia.
func hop(strength: float = 1.0) -> void:
	if _hop <= 0.001:
		_hop_velocity = 2.2 * strength


## Scuote la testa ("no, grazie").
func shake_head() -> void:
	_shake = 1.0


func _process(delta: float) -> void:
	if _body == null:
		return
	_update_pose_blend(delta)
	_animate_gait(delta)
	_animate_body(delta)
	_animate_head(delta)
	_animate_tail(delta)
	_animate_eyes(delta)


func _update_pose_blend(delta: float) -> void:
	var k: float = 1.0 - exp(-5.0 * delta)
	for p: int in _pose_blend.keys():
		var target: float = 1.0 if p == pose else 0.0
		_pose_blend[p] = lerpf(float(_pose_blend[p]), target, k)


func _animate_gait(delta: float) -> void:
	var leg_len: float = float(_p.get("leg_length", 0.3))
	var moving: float = clampf(speed / 1.0, 0.0, 1.0) * float(_pose_blend[Pose.STAND])
	_gait_phase += delta * (2.0 + speed * 3.2 / maxf(leg_len * 3.0, 0.5))
	var amplitude: float = clampf(0.25 + speed * 0.09, 0.0, 0.75) * moving
	var swing: float = sin(_gait_phase)
	var sit: float = float(_pose_blend[Pose.SIT])
	var lie: float = maxf(float(_pose_blend[Pose.LIE]), float(_pose_blend[Pose.SLEEP]))
	# Coppie diagonali: anteriore sinistra + posteriore destra, e viceversa.
	var front_lie: float = 1.35 * lie
	var back_lie: float = -1.35 * lie
	_legs[0].rotation.x = swing * amplitude + front_lie
	_legs[3].rotation.x = swing * amplitude + back_lie - 1.3 * sit
	_legs[1].rotation.x = -swing * amplitude + front_lie
	_legs[2].rotation.x = -swing * amplitude + back_lie - 1.3 * sit
	if scratching and pose == Pose.SIT:
		_legs[3].rotation.x = -0.4 + sin(Time.get_ticks_msec() * 0.04) * 0.5
		_legs[3].rotation.z = -0.6
	else:
		_legs[3].rotation.z = 0.0


func _animate_body(delta: float) -> void:
	var leg_len: float = float(_p.get("leg_length", 0.3))
	var sit: float = float(_pose_blend[Pose.SIT])
	var lie: float = maxf(float(_pose_blend[Pose.LIE]), float(_pose_blend[Pose.SLEEP]))
	# Saltello
	if _hop > 0.0 or _hop_velocity > 0.0:
		_hop_velocity -= 9.8 * delta
		_hop = maxf(0.0, _hop + _hop_velocity * delta)
		if _hop == 0.0:
			_hop_velocity = 0.0
	var bob: float = absf(sin(_gait_phase)) * 0.025 * clampf(speed, 0.0, 1.5)
	var breathe: float = sin(Time.get_ticks_msec() * 0.0025) * (0.006 + 0.01 * float(_pose_blend[Pose.SLEEP]))
	_body.position.y = bob + _hop - leg_len * 0.78 * lie - leg_len * 0.25 * sit + breathe
	_body.rotation.x = -0.42 * sit
	_body.position.z = -0.08 * sit
	_body.scale = Vector3(1.0 + breathe, 1.0 + breathe, 1.0)


func _animate_head(delta: float) -> void:
	var k: float = 1.0 - exp(-6.0 * delta)
	var yaw: float = 0.0
	var pitch: float = 0.0
	if look_target != null:
		var local: Vector3 = _head_pivot.get_parent_node_3d().to_local(look_target as Vector3) - _head_pivot.position
		yaw = clampf(atan2(local.x, local.z), -1.0, 1.0)
		pitch = clampf(-atan2(local.y, Vector2(local.x, local.z).length()), -0.5, 0.6)
	var sleep: float = float(_pose_blend[Pose.SLEEP])
	pitch = lerpf(pitch, 0.9, clampf(head_down, 0.0, 1.0))
	pitch = lerpf(pitch, 0.55, sleep)
	yaw = lerpf(yaw, 0.0, sleep)
	# Annusare: piccolo movimento ritmico quando la testa è bassa.
	if head_down > 0.5:
		pitch += sin(Time.get_ticks_msec() * 0.02) * 0.05
	# Scuotere la testa.
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 1.6)
		yaw += sin(_shake * 30.0) * 0.4 * _shake
	_head_pivot.rotation.y = lerp_angle(_head_pivot.rotation.y, yaw, k)
	_head_pivot.rotation.x = lerpf(_head_pivot.rotation.x, pitch, k)
	# Orecchie che si muovono con il passo e con la felicità.
	for i: int in _ears.size():
		var side: float = 1.0 if i == 0 else -1.0
		_ears[i].rotation.z = side * (0.05 + sin(_gait_phase * 2.0) * 0.06 * clampf(speed, 0.0, 1.0)) + side * wag * 0.08
		_ears[i].rotation.x = -0.1 * wag


func _animate_tail(delta: float) -> void:
	var sleep: float = float(_pose_blend[Pose.SLEEP])
	_wag_phase += delta * (4.0 + 14.0 * wag)
	var wag_amount: float = (0.15 + 0.6 * wag) * (1.0 - sleep)
	_tail_pivot.rotation.y = sin(_wag_phase) * wag_amount
	var base_lift: float = -0.6 + 0.55 * wag
	if String(_p.get("tail", "thin")) == "bushy":
		base_lift = -0.25 + 0.2 * wag
	_tail_pivot.rotation.x = lerpf(base_lift, 0.3, sleep)


func _animate_eyes(delta: float) -> void:
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink = 1.0
		_blink_timer = randf_range(2.0, 5.0)
	_blink = maxf(0.0, _blink - delta * 8.0)
	var closed: bool = pose == Pose.SLEEP or happy_eyes
	var open_amount: float = 0.12 if closed else 1.0 - _blink * 0.9
	for e: MeshInstance3D in _eyes:
		e.scale.y = lerpf(e.scale.y, open_amount, 1.0 - exp(-20.0 * delta))


func _build() -> void:
	var body_len: float = float(_p.get("body_length", 0.6))
	var body_r: float = float(_p.get("body_radius", 0.18))
	var leg_len: float = float(_p.get("leg_length", 0.3))
	var head_r: float = float(_p.get("head_radius", 0.16))
	var snout_len: float = float(_p.get("snout_length", 0.14))
	var body_y: float = leg_len + body_r * 0.75

	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)

	# Tronco: capsula orizzontale lungo Z, con pancia chiara.
	var torso: MeshInstance3D = _mesh(_body, _capsule(body_r, body_len + body_r * 2.0), _main, Vector3(0, body_y, 0))
	torso.rotation.x = PI * 0.5
	var belly: MeshInstance3D = _mesh(_body, _sphere(body_r * 0.8, body_r * 0.7), _accent, Vector3(0, body_y - body_r * 0.35, body_len * 0.22))
	belly.scale = Vector3(1.0, 0.8, 1.6)

	# Zampe: perni alle spalle/anche, zampa che pende verso il basso.
	var leg_r: float = body_r * 0.3
	var hip_z: float = body_len * 0.5 - leg_r * 0.5
	var hip_x: float = body_r * 0.55
	var spots: Array[Vector3] = [
		Vector3(hip_x, body_y - body_r * 0.3, hip_z), Vector3(-hip_x, body_y - body_r * 0.3, hip_z),
		Vector3(hip_x, body_y - body_r * 0.3, -hip_z), Vector3(-hip_x, body_y - body_r * 0.3, -hip_z)]
	for spot: Vector3 in spots:
		var pivot: Node3D = _pivot(_body, spot)
		var leg_h: float = spot.y
		_mesh(pivot, _capsule(leg_r, leg_h + leg_r), _leg_color, Vector3(0, -leg_h * 0.5, 0))
		var paw: MeshInstance3D = _mesh(pivot, _sphere(leg_r * 1.25, leg_r), _leg_color.lerp(_accent, 0.25), Vector3(0, -leg_h + leg_r * 0.6, leg_r * 0.4))
		paw.scale = Vector3(1.0, 0.8, 1.3)
		_legs.append(pivot)

	_build_body_extras(body_len, body_r, body_y)

	# Collo e testa (collo più lungo per cavalli, cervi, capre…)
	var neck_len: float = float(_p.get("neck_length", 1.0))
	_head_pivot = _pivot(_body, Vector3(0, body_y + body_r * (0.55 + 0.6 * (neck_len - 1.0)), body_len * 0.5 + body_r * 0.4))
	var neck: MeshInstance3D = _mesh(_head_pivot, _capsule(body_r * 0.55, body_r * 1.4 * neck_len), _main, Vector3(0, -body_r * 0.2 * neck_len, -body_r * 0.1))
	neck.rotation.x = -0.5
	if bool(_p.get("mane", false)):
		var mane: MeshInstance3D = _mesh(_head_pivot, _capsule(body_r * 0.22, body_r * 1.6 * neck_len), _p.get("mane_color", _main.darkened(0.45)) as Color, Vector3(0, -body_r * 0.05 * neck_len, -body_r * 0.42))
		mane.rotation.x = -0.5
	_head = _pivot(_head_pivot, Vector3(0, head_r * 0.55, head_r * 0.55))
	_mesh(_head, _sphere(head_r, head_r), _p.get("face_color", _main) as Color, Vector3.ZERO)
	# Muso e naso
	var snout_type: String = String(_p.get("snout", "normal"))
	var nose_color: Color = _p.get("nose_color", Palette.EYE_DARK) as Color
	if snout_type == "flat":
		var disc: CylinderMesh = CylinderMesh.new()
		disc.top_radius = head_r * 0.4
		disc.bottom_radius = head_r * 0.42
		disc.height = head_r * 0.35
		var d: MeshInstance3D = _mesh(_head, disc, nose_color, Vector3(0, -head_r * 0.2, head_r * 0.95))
		d.rotation.x = PI * 0.5
		for side: float in [-1.0, 1.0]:
			_mesh(_head, _sphere(head_r * 0.07, head_r * 0.07), nose_color.darkened(0.4), Vector3(side * head_r * 0.13, -head_r * 0.2, head_r * 1.12))
	else:
		var snout: MeshInstance3D = _mesh(_head, _sphere(head_r * 0.55, head_r * 0.5), _accent, Vector3(0, -head_r * 0.25, head_r * 0.7 + snout_len * 0.3))
		snout.scale = Vector3(0.95, 0.8, 1.0 + snout_len * 4.0)
		_mesh(_head, _sphere(head_r * 0.17, head_r * 0.13), nose_color, Vector3(0, -head_r * 0.12, head_r * 0.85 + snout_len))
	_mouth_anchor = _pivot(_head, Vector3(0, -head_r * 0.55, head_r * 0.75 + snout_len * 0.6))
	# Occhi con riflesso
	for side: float in [1.0, -1.0]:
		var eye: MeshInstance3D = _mesh(_head, _sphere(head_r * 0.15, head_r * 0.17), Palette.EYE_DARK, Vector3(side * head_r * 0.42, head_r * 0.18, head_r * 0.78))
		_eyes.append(eye)
		# Riflesso: piccolo punto bianco davanti all'occhio (dimensioni relative alla testa).
		_mesh(eye, _sphere(head_r * 0.05, head_r * 0.05), Palette.FLOWER_WHITE, Vector3(side * head_r * 0.04, head_r * 0.07, head_r * 0.12))
	_build_ears(head_r)
	_build_horns(head_r)
	_build_tail(body_r)


## Lana (pecora), aculei (riccio), macchie (mucca).
func _build_body_extras(body_len: float, body_r: float, body_y: float) -> void:
	if bool(_p.get("wool", false)):
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 3
		for i: int in 14:
			var a: float = TAU * i / 7.0
			var z: float = (float(i % 7) / 6.0 - 0.5) * body_len
			_mesh(_body, _sphere(body_r * 0.45, body_r * 0.45), _main.lightened(rng.randf() * 0.08), Vector3(cos(a) * body_r * 0.7, body_y + absf(sin(a)) * body_r * 0.55, z))
	if bool(_p.get("spikes", false)):
		var spike: CylinderMesh = CylinderMesh.new()
		spike.top_radius = 0.0
		spike.bottom_radius = body_r * 0.16
		spike.height = body_r * 0.7
		spike.radial_segments = 4
		for i: int in 24:
			var a: float = -1.2 + (i % 6) * 0.48
			var z: float = (float(i / 6) / 3.0 - 0.5) * (body_len + body_r)
			var m: MeshInstance3D = _mesh(_body, spike, (_p.get("spike_color", _main.darkened(0.3)) as Color), Vector3(sin(a) * body_r * 0.95, body_y + cos(a) * body_r * 0.95, z))
			m.rotation = Vector3(-0.3, 0.0, -a)
	if _p.has("patches"):
		var c: Color = _p["patches"] as Color
		for o: Vector3 in [Vector3(0.6, 0.4, 0.2), Vector3(-0.6, 0.3, -0.25), Vector3(0.3, 0.7, -0.4), Vector3(-0.4, 0.6, 0.35)]:
			var spot: MeshInstance3D = _mesh(_body, _sphere(body_r * 0.42, body_r * 0.2), c, Vector3(o.x * body_r, body_y + o.y * body_r, o.z * body_len))
			spot.look_at_from_position(spot.position, spot.position + Vector3(o.x, o.y, 0.0), Vector3.UP if absf(o.x) > 0.01 else Vector3.FORWARD)


func _build_ears(head_r: float) -> void:
	var ear_type: String = String(_p.get("ears", "floppy"))
	if ear_type == "none":
		return
	for side: float in [1.0, -1.0]:
		var ear_pivot: Node3D = _pivot(_head, Vector3(side * head_r * 0.62, head_r * 0.62, -head_r * 0.05))
		match ear_type:
			"pointed":
				var cone: CylinderMesh = CylinderMesh.new()
				cone.top_radius = 0.0
				cone.bottom_radius = head_r * 0.42
				cone.height = head_r * 1.0
				cone.radial_segments = 4
				var ear: MeshInstance3D = _mesh(ear_pivot, cone, _main, Vector3(0, head_r * 0.42, 0))
				ear.scale = Vector3(1.0, 1.0, 0.45)
				ear.rotation.z = -side * 0.25
				var inner: MeshInstance3D = _mesh(ear_pivot, cone, (_p.get("ear_inner", Palette.EYE_DARK) as Color), Vector3(0, head_r * 0.62, 0))
				inner.scale = Vector3(0.45, 0.45, 0.3)
				inner.rotation.z = -side * 0.25
			"long":
				var long: MeshInstance3D = _mesh(ear_pivot, _capsule(head_r * 0.2, head_r * 1.7), _main, Vector3(side * head_r * 0.05, head_r * 0.7, -head_r * 0.05))
				long.scale = Vector3(1.0, 1.0, 0.55)
				long.rotation.z = -side * 0.15
				var inner_l: MeshInstance3D = _mesh(ear_pivot, _capsule(head_r * 0.11, head_r * 1.3), Palette.CHEEK_PINK, Vector3(side * head_r * 0.05, head_r * 0.7, head_r * 0.03))
				inner_l.scale = Vector3(1.0, 1.0, 0.4)
				inner_l.rotation.z = -side * 0.15
			"round":
				var r: MeshInstance3D = _mesh(ear_pivot, _sphere(head_r * 0.3, head_r * 0.3), _main.darkened(0.1), Vector3(0, head_r * 0.15, 0))
				r.scale = Vector3(1.0, 1.0, 0.45)
			"small":
				var sm: MeshInstance3D = _mesh(ear_pivot, _sphere(head_r * 0.26, head_r * 0.15), _main.darkened(0.08), Vector3(side * head_r * 0.25, 0, 0))
				sm.rotation.z = side * 0.5
			_:
				var flap: MeshInstance3D = _mesh(ear_pivot, _sphere(head_r * 0.36, head_r * 0.62), _main.darkened(0.25), Vector3(side * head_r * 0.12, -head_r * 0.45, 0))
				flap.scale = Vector3(0.45, 1.0, 0.8)
				flap.rotation.z = side * 0.2
		_ears.append(ear_pivot)


## Corna (capra, stambecco, mucca) e palchi (cervo).
func _build_horns(head_r: float) -> void:
	var horns: String = String(_p.get("horns", "none"))
	if horns == "none":
		return
	var c: Color = _p.get("horn_color", Color("e8dcc4")) as Color
	for side: float in [1.0, -1.0]:
		var base: Node3D = _pivot(_head, Vector3(side * head_r * 0.35, head_r * 0.8, -head_r * 0.15))
		match horns:
			"small":
				var h: MeshInstance3D = _mesh(base, _capsule(head_r * 0.08, head_r * 0.45), c, Vector3(side * head_r * 0.08, head_r * 0.15, 0))
				h.rotation.z = -side * 0.6
			"curved":
				for i: int in 4:
					var seg: MeshInstance3D = _mesh(base, _capsule(head_r * (0.13 - i * 0.02), head_r * 0.45), c, Vector3(side * head_r * 0.05 * i, head_r * (0.2 + i * 0.22), -head_r * 0.18 * i * i * 0.4))
					seg.rotation.x = -0.4 - i * 0.35
			"antlers":
				var trunk: MeshInstance3D = _mesh(base, _capsule(head_r * 0.07, head_r * 1.3), c, Vector3(side * head_r * 0.2, head_r * 0.6, -head_r * 0.1))
				trunk.rotation.z = -side * 0.35
				for i: int in 3:
					var tine: MeshInstance3D = _mesh(base, _capsule(head_r * 0.05, head_r * 0.6), c, Vector3(side * head_r * (0.3 + i * 0.12), head_r * (0.6 + i * 0.3), head_r * 0.1))
					tine.rotation = Vector3(0.5, 0.0, -side * (0.2 - i * 0.2))


func _build_tail(body_r: float) -> void:
	var body_len: float = float(_p.get("body_length", 0.6))
	var body_y: float = float(_p.get("leg_length", 0.3)) + body_r * 0.75
	var tail_len: float = float(_p.get("tail_length", 0.3))
	_tail_pivot = _pivot(_body, Vector3(0, body_y + body_r * 0.45, -body_len * 0.5 - body_r * 0.7))
	match String(_p.get("tail", "thin")):
		"bushy":
			var brush: MeshInstance3D = _mesh(_tail_pivot, _sphere(body_r * 0.6, tail_len * 0.5), _main, Vector3(0, 0, -tail_len * 0.5))
			brush.rotation.x = PI * 0.5
			var tip: MeshInstance3D = _mesh(_tail_pivot, _sphere(body_r * 0.42, body_r * 0.45), _accent, Vector3(0, 0, -tail_len * 0.95))
			tip.scale = Vector3(1.0, 1.0, 1.2)
		"short":
			_mesh(_tail_pivot, _sphere(body_r * 0.32, body_r * 0.32), _p.get("tail_color", _accent) as Color, Vector3(0, 0, -body_r * 0.1))
		"curly":
			var torus: TorusMesh = TorusMesh.new()
			torus.inner_radius = body_r * 0.12
			torus.outer_radius = body_r * 0.25
			var t: MeshInstance3D = _mesh(_tail_pivot, torus, _main, Vector3(0, body_r * 0.1, -body_r * 0.2))
			t.rotation.z = PI * 0.5
		"tuft":
			var rope: MeshInstance3D = _mesh(_tail_pivot, _capsule(body_r * 0.1, tail_len), _main, Vector3(0, 0, -tail_len * 0.45))
			rope.rotation.x = PI * 0.5
			_mesh(_tail_pivot, _sphere(body_r * 0.22, body_r * 0.32), _p.get("mane_color", _main.darkened(0.4)) as Color, Vector3(0, 0, -tail_len * 0.95))
		"none":
			pass
		_:
			var thin: MeshInstance3D = _mesh(_tail_pivot, _capsule(body_r * 0.16, tail_len), _main, Vector3(0, 0, -tail_len * 0.45))
			thin.rotation.x = PI * 0.5


func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n: Node3D = Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


func _mesh(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.layers = RENDER_LAYER
	mi.mesh = mesh
	mi.material_override = ToonMaterials.get_material(color)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _sphere(radius: float, half_height: float) -> SphereMesh:
	var m: SphereMesh = SphereMesh.new()
	m.radius = radius
	m.height = half_height * 2.0
	m.radial_segments = 16
	m.rings = 8
	return m


func _capsule(radius: float, height: float) -> CapsuleMesh:
	var m: CapsuleMesh = CapsuleMesh.new()
	m.radius = radius
	m.height = maxf(height, radius * 2.0)
	m.radial_segments = 12
	m.rings = 4
	return m
