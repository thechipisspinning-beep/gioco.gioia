class_name CameraRig
extends Node3D
## Telecamera in terza persona libera (D-02).
##
## - Segue Gioia con smorzamento (nessuno scatto).
## - Orbita con mouse (quando catturato), stick destro o trascinamento touch.
## - Zoom con rotella, dorsali del controller o `add_zoom()`.
## - Uno SpringArm3D accorcia la distanza quando c'è un muro tra Gioia e la telecamera.
## - Quando Gioia si muove e il giocatore non tocca la telecamera, questa si
##   riallinea dolcemente dietro di lei.
##
## Il nodo è "top level": non eredita la rotazione di Gioia.

@export var target: Node3D
@export_group("Inquadratura")
@export var focus_height: float = 1.0
@export var follow_smoothing: float = 9.0
@export var distance: float = 5.0
@export var min_distance: float = 2.2
@export var max_distance: float = 9.0
@export var zoom_step: float = 0.6
@export var zoom_smoothing: float = 8.0
@export_group("Rotazione")
@export var initial_pitch_degrees: float = -16.0
@export var min_pitch_degrees: float = -65.0
@export var max_pitch_degrees: float = 20.0
@export var mouse_sensitivity: float = 0.22
@export var stick_speed_degrees: float = 150.0
@export var invert_y: bool = false
@export_group("Riallineamento automatico")
@export var auto_align_enabled: bool = true
@export var auto_align_delay: float = 1.4
@export var auto_align_speed: float = 1.6

@onready var _spring_arm: SpringArm3D = $SpringArm3D
@onready var _camera: Camera3D = $SpringArm3D/Camera3D

var _yaw: float = 0.0
var _pitch: float = 0.0
## Modalità ritratto (personalizzazione): Gioia inquadrata di fronte, a sinistra dello schermo.
var _portrait: bool = false
var _saved_view: Vector4 = Vector4.ZERO  # yaw, pitch, distanza, altezza
## Modalità arredamento: vista dall'alto che segue il cursore invece di Gioia.
var _build_view: bool = false
var _build_focus: Vector3 = Vector3.ZERO
var _target_distance: float = 5.0
var _time_since_manual_look: float = 100.0


func _ready() -> void:
	top_level = true
	_pitch = deg_to_rad(initial_pitch_degrees)
	_target_distance = distance
	if target != null:
		_yaw = target.global_rotation.y + PI
		global_position = target.global_position + Vector3.UP * focus_height
		if target is CollisionObject3D:
			_spring_arm.add_excluded_object((target as CollisionObject3D).get_rid())
	_spring_arm.spring_length = distance
	get_viewport().size_changed.connect(_update_aspect)
	_update_aspect()
	if DevTools.active:
		DevTools.look_requested.connect(add_look)
	_apply_rotation()


## Attiva/disattiva la modalità ritratto.
func set_portrait(enabled: bool) -> void:
	if enabled == _portrait:
		return
	_portrait = enabled
	# Nel ritratto gli animali non coprono Gioia.
	_camera.set_cull_mask_value(AnimalVisual.RENDER_LAYER, not enabled)
	if enabled:
		_saved_view = Vector4(_yaw, _pitch, _target_distance, focus_height)
		_yaw = target.global_rotation.y if target != null else _yaw
		_pitch = deg_to_rad(-6.0)
		_target_distance = 2.4
		focus_height = 0.72
	else:
		_yaw = _saved_view.x
		_pitch = _saved_view.y
		_target_distance = _saved_view.z
		focus_height = _saved_view.w
	_time_since_manual_look = 0.0


## Vista dall'alto per arredare (segue `set_build_focus`).
func set_build_view(enabled: bool, focus: Vector3) -> void:
	if enabled == _build_view:
		return
	_build_view = enabled
	_build_focus = focus
	if enabled:
		_saved_view = Vector4(_yaw, _pitch, _target_distance, focus_height)
		_yaw = 0.0
		_pitch = deg_to_rad(-58.0)
		_target_distance = minf(9.0, max_distance + 3.0)
		focus_height = 0.0
	else:
		_yaw = _saved_view.x
		_pitch = _saved_view.y
		_target_distance = _saved_view.z
		focus_height = _saved_view.w


func set_build_focus(focus: Vector3) -> void:
	_build_focus = focus


func _unhandled_input(event: InputEvent) -> void:
	if _portrait or _build_view:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		add_look(-motion.relative.x * mouse_sensitivity, -motion.relative.y * mouse_sensitivity)
	elif event is InputEventMouseButton:
		var button: InputEventMouseButton = event as InputEventMouseButton
		# Solo un vero clic cattura il mouse (non quelli emulati dai tocchi).
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT and button.device != InputEvent.DEVICE_ID_EMULATION:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("camera_zoom_in"):
		add_zoom(-zoom_step)
	elif event.is_action_pressed("camera_zoom_out"):
		add_zoom(zoom_step)


func _process(delta: float) -> void:
	var stick: Vector2 = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if _portrait or _build_view:
		stick = Vector2.ZERO
	if stick.length_squared() > 0.0:
		add_look(-stick.x * stick_speed_degrees * delta, -stick.y * stick_speed_degrees * delta * 0.7)

	_time_since_manual_look += delta
	_follow_target(delta)
	_auto_align(delta)
	_apply_rotation()
	_spring_arm.spring_length = lerpf(_spring_arm.spring_length, _target_distance, 1.0 - exp(-zoom_smoothing * delta))
	_spring_arm.collision_mask = 0 if _build_view else 1


## Ruota la telecamera di `yaw_degrees` (orizzontale) e `pitch_degrees` (verticale).
## Usato da mouse, stick, controlli touch e strumenti di test.
func add_look(yaw_degrees: float, pitch_degrees: float) -> void:
	if invert_y:
		pitch_degrees = -pitch_degrees
	_yaw += deg_to_rad(yaw_degrees)
	_pitch = clampf(_pitch + deg_to_rad(pitch_degrees), deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
	_time_since_manual_look = 0.0


## Avvicina (valore negativo) o allontana la telecamera.
func add_zoom(amount: float) -> void:
	_target_distance = clampf(_target_distance + amount, min_distance, max_distance)


func get_camera() -> Camera3D:
	return _camera


## Su schermi verticali (telefono in verticale nel browser) si mantiene
## l'ampiezza orizzontale dell'inquadratura, altrimenti si vedrebbe pochissimo ai lati.
func _update_aspect() -> void:
	var size: Vector2 = get_viewport().get_visible_rect().size
	_camera.keep_aspect = Camera3D.KEEP_WIDTH if size.y > size.x else Camera3D.KEEP_HEIGHT
	if size.y > size.x:
		_camera.fov = 80.0
	else:
		_camera.fov = 55.0


func _follow_target(delta: float) -> void:
	if target == null:
		return
	var focus: Vector3 = target.global_position + Vector3.UP * focus_height
	if _build_view:
		focus = _build_focus
	if _portrait:
		# Sposta l'inquadratura così Gioia sta a sinistra e il pannello a destra.
		focus += global_transform.basis.x * 0.55
	global_position = global_position.lerp(focus, 1.0 - exp(-follow_smoothing * delta))


func _auto_align(delta: float) -> void:
	if _portrait or _build_view or not auto_align_enabled or target == null or _time_since_manual_look < auto_align_delay:
		return
	var body: CharacterBody3D = target as CharacterBody3D
	if body == null:
		return
	var horizontal: Vector2 = Vector2(body.velocity.x, body.velocity.z)
	if horizontal.length() < 1.0:
		return
	# Yaw della telecamera che guarda nella direzione di movimento (alle spalle di Gioia).
	var behind_yaw: float = atan2(-body.velocity.x, -body.velocity.z)
	var strength: float = clampf(horizontal.length() / 6.0, 0.0, 1.0) * auto_align_speed
	_yaw = lerp_angle(_yaw, behind_yaw, 1.0 - exp(-strength * delta))


func _apply_rotation() -> void:
	rotation = Vector3(_pitch, _yaw, 0.0)
