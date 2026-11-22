class_name PlayerVisual
extends Node3D
## Modello di Gioia costruito dall'aspetto scelto (`CharacterAppearance`):
## pelle, acconciatura, vestito, scarpe, accessorio e statura.
##
## Animazione procedurale: passo e dondolio proporzionali alla velocità,
## inclinazione in corsa, schiacciamento all'atterraggio, respiro, e gesti
## (accarezzare, porgere il cibo, lanciare, spazzolare).
## Proporzioni morbide: testa grande, corpo piccolo (altezza ~1,3 m).
## Il fronte del personaggio è +Z. Il controller non dipende da questa classe.

@export var controller: PlayerController

var appearance: CharacterAppearance

var _scale_root: Node3D
var _body_root: Node3D
var _left_foot: Node3D
var _right_foot: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _head: Node3D
var _swing_parts: Array[Node3D] = []  # code/trecce che ondeggiano
var _walk_phase: float = 0.0
var _squash: float = 0.0
var _lean: float = 0.0
var _gesture: StringName = &""
var _gesture_time: float = 0.0
var _gesture_duration: float = 0.0


func _ready() -> void:
	if appearance == null:
		appearance = GameState.appearance
	appearance.changed.connect(rebuild)
	rebuild()
	if controller != null:
		controller.landed.connect(_on_landed)
		controller.jumped.connect(_on_jumped)
	if controller == null or controller.is_player:
		EventBus.player_gesture.connect(play_gesture)


## Cambia l'aspetto (es. dopo il caricamento o dallo specchio).
func set_appearance(a: CharacterAppearance) -> void:
	if appearance != null and appearance.changed.is_connected(rebuild):
		appearance.changed.disconnect(rebuild)
	appearance = a
	appearance.changed.connect(rebuild)
	rebuild()


## Esegue un gesto: &"pet", &"feed", &"throw", &"brush".
func play_gesture(gesture: StringName) -> void:
	_gesture = gesture
	_gesture_time = 0.0
	_gesture_duration = {&"pet": 1.6, &"feed": 1.3, &"throw": 0.8, &"brush": 1.6}.get(gesture, 1.0)


func _process(delta: float) -> void:
	if controller == null or _body_root == null:
		return
	var speed: float = controller.get_horizontal_speed()
	var on_floor: bool = controller.is_on_floor()
	var speed_ratio: float = clampf(speed / controller.run_speed, 0.0, 1.0)
	var walk_ratio: float = clampf(speed / controller.walk_speed, 0.0, 1.0)

	# Fase del passo proporzionale alla velocità: i piedi non "pattinano".
	if on_floor and speed > 0.15:
		_walk_phase += delta * (4.0 + speed * 1.9)
	else:
		_walk_phase = lerpf(_walk_phase, roundf(_walk_phase / PI) * PI, 1.0 - exp(-10.0 * delta))

	var stride: float = walk_ratio * (0.22 + 0.1 * speed_ratio)
	var swing: float = sin(_walk_phase)
	var bob: float = absf(sin(_walk_phase)) * 0.06 * walk_ratio

	_left_foot.position.z = swing * stride
	_right_foot.position.z = -swing * stride
	_left_foot.position.y = 0.06 + maxf(0.0, -cos(_walk_phase)) * 0.06 * stride * 3.0
	_right_foot.position.y = 0.06 + maxf(0.0, cos(_walk_phase)) * 0.06 * stride * 3.0
	_left_arm.rotation = Vector3(-swing * stride * 2.4, 0.0, 0.18)
	_right_arm.rotation = Vector3(swing * stride * 2.4, 0.0, -0.18)

	var target_lean: float = speed_ratio * 0.18
	_lean = lerpf(_lean, target_lean, 1.0 - exp(-8.0 * delta))
	_body_root.rotation.x = _lean

	_squash = lerpf(_squash, 0.0, 1.0 - exp(-9.0 * delta))
	var stretch: float = 0.0
	if not on_floor:
		stretch = clampf(controller.velocity.y * 0.02, -0.06, 0.08)
	var sy: float = 1.0 - _squash + stretch
	var sxz: float = 1.0 + _squash * 0.6 - stretch * 0.5
	_body_root.scale = Vector3(sxz, sy, sxz)
	_body_root.position.y = bob

	for part: Node3D in _swing_parts:
		part.rotation.x = 0.2 + swing * 0.12 * speed_ratio + _lean * 1.5
	_head.position.y = 0.92 + sin(Time.get_ticks_msec() * 0.002) * 0.006
	_head.rotation = Vector3.ZERO

	_apply_gesture(delta)


func _apply_gesture(delta: float) -> void:
	if _gesture == &"":
		return
	_gesture_time += delta
	var t: float = _gesture_time / _gesture_duration
	if t >= 1.0:
		_gesture = &""
		return
	# Curva morbida di entrata/uscita del gesto.
	var w: float = sin(t * PI)
	match _gesture:
		&"pet", &"brush":
			# Si accovaccia e allunga il braccio verso l'animale.
			_body_root.position.y -= 0.28 * w
			_body_root.rotation.x += 0.35 * w
			_head.rotation.x = 0.35 * w
			var stroke: float = sin(_gesture_time * (14.0 if _gesture == &"brush" else 8.0)) * 0.15
			_right_arm.rotation = Vector3(-1.3 * w + stroke * w, 0.0, -0.18)
			_left_arm.rotation = Vector3(-0.6 * w, 0.0, 0.18)
		&"feed":
			_body_root.position.y -= 0.18 * w
			_body_root.rotation.x += 0.2 * w
			_head.rotation.x = 0.25 * w
			_right_arm.rotation = Vector3(-1.45 * w, 0.0, -0.18)
			_left_arm.rotation = Vector3(-1.45 * w, 0.0, 0.18)
		&"throw":
			# Carica il braccio all'indietro, poi lancia in avanti.
			var arm: float = lerpf(1.2, -2.2, smoothstep(0.25, 0.6, t)) * w
			_right_arm.rotation = Vector3(-arm - 0.5 * w, 0.0, -0.18)
			_body_root.rotation.y = -0.3 * w


func _on_landed(fall_speed: float) -> void:
	_squash = clampf(fall_speed * 0.035, 0.0, 0.22)


func _on_jumped() -> void:
	_squash = -0.08


# ---------------------------------------------------------------------------
# Costruzione del modello
# ---------------------------------------------------------------------------

## Ricostruisce tutte le parti (chiamato quando cambia l'aspetto).
func rebuild() -> void:
	if _scale_root != null:
		remove_child(_scale_root)
		_scale_root.queue_free()
	_swing_parts.clear()
	_scale_root = Node3D.new()
	_scale_root.name = "ScaleRoot"
	_scale_root.scale = Vector3.ONE * appearance.height_scale()
	add_child(_scale_root)
	_body_root = _pivot(_scale_root, Vector3.ZERO)

	var skin: Color = appearance.color(&"skin")
	var outfit: Color = appearance.color(&"outfit")
	_build_outfit(appearance.style_id(&"outfit"), outfit, skin)
	_build_feet(appearance.style_id(&"shoes"), appearance.color(&"shoes"))

	_head = _pivot(_body_root, Vector3(0, 0.92, 0))
	_part(_head, _sphere(0.27, 0.26), skin, Vector3.ZERO)
	_build_face(skin)
	_build_hair(appearance.style_id(&"hair"), appearance.color(&"hair"))
	_build_accessory(appearance.style_id(&"accessory"), appearance.color(&"accessory"))


func _build_outfit(style: StringName, color: Color, skin: Color) -> void:
	var sleeve: Color = color
	var lower: Color = color
	match style:
		&"dress":
			_part(_body_root, _cylinder(0.17, 0.27, 0.42), color, Vector3(0, 0.38, 0))
			_part(_body_root, _sphere(0.18, 0.2), color, Vector3(0, 0.62, 0))
			_part(_body_root, _cylinder(0.11, 0.14, 0.05), Palette.FLOWER_WHITE, Vector3(0, 0.74, 0))
		&"tshirt_shorts":
			lower = Color("5d7fb8")
			_part(_body_root, _cylinder(0.16, 0.18, 0.3), color, Vector3(0, 0.56, 0))
			_part(_body_root, _sphere(0.165, 0.12), color, Vector3(0, 0.7, 0))
			_part(_body_root, _cylinder(0.18, 0.19, 0.16), lower, Vector3(0, 0.36, 0))
		&"overalls":
			sleeve = Palette.FLOWER_WHITE
			_part(_body_root, _cylinder(0.16, 0.17, 0.3), sleeve, Vector3(0, 0.56, 0))
			_part(_body_root, _sphere(0.165, 0.12), sleeve, Vector3(0, 0.7, 0))
			_part(_body_root, _cylinder(0.175, 0.19, 0.22), color, Vector3(0, 0.4, 0))
			var bib: MeshInstance3D = _part(_body_root, _box(Vector3(0.2, 0.17, 0.05)), color, Vector3(0, 0.57, 0.15))
			bib.rotation.x = -0.12
			for side: float in [-1.0, 1.0]:
				_part(_body_root, _box(Vector3(0.035, 0.2, 0.3)), color, Vector3(side * 0.08, 0.66, 0.0))
				_part(_body_root, _sphere(0.02, 0.02), Palette.FLOWER_YELLOW, Vector3(side * 0.07, 0.63, 0.175))
			lower = color
		&"sweater_skirt":
			lower = color.darkened(0.35)
			_part(_body_root, _cylinder(0.17, 0.18, 0.3), color, Vector3(0, 0.56, 0))
			_part(_body_root, _sphere(0.175, 0.13), color, Vector3(0, 0.7, 0))
			_part(_body_root, _cylinder(0.12, 0.12, 0.06), color.lightened(0.25), Vector3(0, 0.76, 0))
			_part(_body_root, _cylinder(0.18, 0.25, 0.16), lower, Vector3(0, 0.36, 0))
		&"raincoat":
			_part(_body_root, _cylinder(0.17, 0.25, 0.5), color, Vector3(0, 0.45, 0))
			_part(_body_root, _sphere(0.18, 0.18), color, Vector3(0, 0.66, 0))
			_part(_body_root, _sphere(0.2, 0.16), color.darkened(0.1), Vector3(0, 0.84, -0.17)).scale = Vector3(1.1, 0.8, 0.6)
			for i: int in 3:
				_part(_body_root, _sphere(0.022, 0.022), Palette.WOOD_DARK, Vector3(0, 0.62 - i * 0.12, 0.19 + i * 0.02))
	# Braccia (perno alla spalla per farle oscillare)
	_left_arm = _pivot(_body_root, Vector3(0.21, 0.68, 0))
	_right_arm = _pivot(_body_root, Vector3(-0.21, 0.68, 0))
	for arm: Node3D in [_left_arm, _right_arm]:
		_part(arm, _capsule(0.055, 0.32), skin, Vector3(0, -0.14, 0))
		_part(arm, _sphere(0.075, 0.08), sleeve, Vector3(0, -0.02, 0))
	_left_arm.rotation.z = 0.18
	_right_arm.rotation.z = -0.18
	# Gambe
	var leg_color: Color = skin
	if style == &"overalls":
		leg_color = lower
	for x: float in [0.08, -0.08]:
		_part(_body_root, _capsule(0.06, 0.28), leg_color, Vector3(x, 0.2, 0))


func _build_feet(style: StringName, color: Color) -> void:
	_left_foot = _pivot(_scale_root, Vector3(0.08, 0.06, 0))
	_right_foot = _pivot(_scale_root, Vector3(-0.08, 0.06, 0))
	for foot: Node3D in [_left_foot, _right_foot]:
		match style:
			&"boots":
				_part(foot, _box(Vector3(0.13, 0.1, 0.2)), color, Vector3(0, 0, 0.02))
				_part(foot, _cylinder(0.065, 0.07, 0.14), color, Vector3(0, 0.1, -0.01))
			&"sandals":
				_part(foot, _box(Vector3(0.12, 0.03, 0.19)), color, Vector3(0, -0.03, 0.02))
				_part(foot, _box(Vector3(0.1, 0.06, 0.13)), appearance.color(&"skin"), Vector3(0, 0.01, 0.02))
				_part(foot, _box(Vector3(0.125, 0.025, 0.03)), color, Vector3(0, 0.03, 0.05))
			_:
				_part(foot, _box(Vector3(0.12, 0.09, 0.19)), color, Vector3(0, 0, 0.02))
				_part(foot, _box(Vector3(0.125, 0.025, 0.195)), Palette.FLOWER_WHITE.darkened(0.08), Vector3(0, -0.035, 0.02))


func _build_face(skin: Color) -> void:
	for side: float in [1.0, -1.0]:
		_part(_head, _sphere(0.035, 0.05), Palette.EYE_DARK, Vector3(side * 0.09, -0.01, 0.245))
		_part(_head, _sphere(0.012, 0.012), Palette.FLOWER_WHITE, Vector3(side * 0.09 + 0.01, 0.01, 0.275))
		_part(_head, _sphere(0.04, 0.02), Palette.CHEEK_PINK, Vector3(side * 0.155, -0.075, 0.2))
	# Naso appena accennato e sorriso
	_part(_head, _sphere(0.02, 0.016), skin.darkened(0.08), Vector3(0, -0.05, 0.27))
	var smile: MeshInstance3D = _part(_head, _capsule(0.008, 0.06), Color("c0605a"), Vector3(0, -0.1, 0.245))
	smile.rotation.z = PI * 0.5


func _build_hair(style: StringName, color: Color) -> void:
	# Calotta comune a tutte le acconciature
	_part(_head, _sphere(0.29, 0.27), color, Vector3(0, 0.045, -0.035))
	match style:
		&"short":
			_part(_head, _sphere(0.15, 0.07), color, Vector3(0.0, 0.18, 0.18))
		&"bob":
			_part(_head, _sphere(0.31, 0.24), color, Vector3(0, -0.02, -0.04)).scale = Vector3(1.05, 1.0, 1.0)
			_part(_head, _box(Vector3(0.36, 0.08, 0.06)), color, Vector3(0, 0.17, 0.22))
		&"pigtails":
			_fringe(color)
			for side: float in [-1.0, 1.0]:
				var p: Node3D = _pivot(_head, Vector3(side * 0.27, 0.05, -0.08))
				_part(p, _sphere(0.09, 0.15), color, Vector3(side * 0.04, -0.14, 0))
				_part(p, _sphere(0.045, 0.045), appearance.color(&"accessory"), Vector3(0, 0, 0))
				_swing_parts.append(p)
		&"long":
			_fringe(color)
			var back: Node3D = _pivot(_head, Vector3(0, 0.05, -0.2))
			_part(back, _capsule(0.2, 0.6), color, Vector3(0, -0.25, -0.03)).scale = Vector3(1.2, 1.0, 0.6)
			_swing_parts.append(back)
		&"bun":
			_fringe(color)
			_part(_head, _sphere(0.12, 0.11), color, Vector3(0, 0.3, -0.08))
		_:  # ponytail
			_fringe(color)
			var tail: Node3D = _pivot(_head, Vector3(0, 0.12, -0.25))
			_part(tail, _sphere(0.11, 0.17), color, Vector3(0, -0.14, -0.06))
			_part(tail, _sphere(0.055, 0.055), appearance.color(&"accessory"), Vector3.ZERO)
			_swing_parts.append(tail)


func _fringe(color: Color) -> void:
	_part(_head, _sphere(0.16, 0.09), color, Vector3(0.09, 0.17, 0.19))
	_part(_head, _sphere(0.15, 0.08), color, Vector3(-0.1, 0.16, 0.2))


func _build_accessory(style: StringName, color: Color) -> void:
	match style:
		&"bow":
			var bow: Node3D = _pivot(_head, Vector3(0.17, 0.25, 0.05))
			bow.rotation.z = -0.4
			for side: float in [-1.0, 1.0]:
				_part(bow, _sphere(0.065, 0.045), color, Vector3(side * 0.06, 0, 0)).scale = Vector3(1.0, 1.0, 0.6)
			_part(bow, _sphere(0.03, 0.03), color.darkened(0.2), Vector3.ZERO)
		&"straw_hat":
			_part(_head, _cylinder(0.42, 0.42, 0.025), Color("f1d48a"), Vector3(0, 0.2, -0.02))
			_part(_head, _cylinder(0.2, 0.23, 0.14), Color("f1d48a"), Vector3(0, 0.28, -0.02))
			_part(_head, _cylinder(0.232, 0.232, 0.04), color, Vector3(0, 0.23, -0.02))
		&"glasses":
			for side: float in [-1.0, 1.0]:
				var ring: TorusMesh = TorusMesh.new()
				ring.inner_radius = 0.045
				ring.outer_radius = 0.06
				ring.rings = 16
				ring.ring_segments = 6
				var lens: MeshInstance3D = _part(_head, ring, color.darkened(0.3), Vector3(side * 0.09, -0.01, 0.265))
				lens.rotation.x = PI * 0.5
			_part(_head, _box(Vector3(0.06, 0.012, 0.012)), color.darkened(0.3), Vector3(0, 0.0, 0.27))
		&"flower_crown":
			for i: int in 10:
				var a: float = TAU * i / 10.0
				var c: Color = [Palette.FLOWER_PINK, Palette.FLOWER_YELLOW, Palette.FLOWER_WHITE, color][i % 4]
				_part(_head, _sphere(0.04, 0.035), c, Vector3(cos(a) * 0.255, 0.17, sin(a) * 0.255 - 0.03))
		&"backpack":
			_part(_body_root, _box(Vector3(0.28, 0.3, 0.14)), color, Vector3(0, 0.55, -0.22))
			_part(_body_root, _box(Vector3(0.22, 0.12, 0.05)), color.darkened(0.15), Vector3(0, 0.47, -0.3))


# ---------------------------------------------------------------------------
# Utilità
# ---------------------------------------------------------------------------

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
	return MeshCache.sphere(radius, half_height * 2.0, 20, 12)


func _capsule(radius: float, height: float) -> CapsuleMesh:
	return MeshCache.capsule(radius, height, 12, 4)


func _cylinder(top: float, bottom: float, height: float) -> CylinderMesh:
	return MeshCache.cylinder(top, bottom, height, 20)


func _box(size: Vector3) -> BoxMesh:
	return MeshCache.box(size)
