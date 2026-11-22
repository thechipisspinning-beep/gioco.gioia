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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		add_look(-motion.relative.x * mouse_sensitivity, -motion.relative.y * mouse_sensitivity)
	elif event is InputEventMouseButton:
		var button: InputEventMouseButton = event as InputEventMouseButton
		# Solo un vero clic cattura il mouse (non quelli emulati dai tocchi).
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT and button.device != InputEvent.DEVICE_ID_EMULATION:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("pause") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("camera_zoom_in"):
		add_zoom(-zoom_step)
	elif event.is_action_pressed("camera_zoom_out"):
		add_zoom(zoom_step)


func _process(delta: float) -> void:
	var stick: Vector2 = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if stick.length_squared() > 0.0:
		add_look(-stick.x * stick_speed_degrees * delta, -stick.y * stick_speed_degrees * delta * 0.7)

	_time_since_manual_look += delta
	_follow_target(delta)
	_auto_align(delta)
	_apply_rotation()
	_spring_arm.spring_length = lerpf(_spring_arm.spring_length, _target_distance, 1.0 - exp(-zoom_smoothing * delta))


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
	global_position = global_position.lerp(focus, 1.0 - exp(-follow_smoothing * delta))


func _auto_align(delta: float) -> void:
	if not auto_align_enabled or target == null or _time_since_manual_look < auto_align_delay:
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
