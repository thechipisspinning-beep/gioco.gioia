class_name PlayerController
extends CharacterBody3D
## Movimento di Gioia: camminata e corsa analogiche relative alla telecamera,
## piccolo salto (D-13), pendenze e gradini.
##
## Il controller legge solo azioni di input (tastiera, controller e touch
## si comportano allo stesso modo). Non conosce la grafica: la parte visiva
## (`PlayerVisual`) legge velocità e stato da qui.

signal jumped
signal landed(fall_speed: float)

@export_group("Velocità")
## Velocità di camminata (m/s) con input pieno.
@export var walk_speed: float = 3.2
## Velocità di corsa (m/s).
@export var run_speed: float = 6.6
## Accelerazione a terra (m/s²).
@export var ground_acceleration: float = 22.0
## Decelerazione a terra quando non si preme nulla (m/s²).
@export var ground_deceleration: float = 26.0
## Frazione del controllo disponibile in aria.
@export_range(0.0, 1.0) var air_control: float = 0.45
## Velocità di rotazione verso la direzione di movimento (rad/s, smorzata).
@export var turn_speed: float = 12.0

@export_group("Salto")
@export var jump_velocity: float = 5.2
## Moltiplicatore della gravità: un valore > 1 rende il salto meno "fluttuante".
@export var gravity_multiplier: float = 1.7
## Tempo dopo aver lasciato un bordo in cui si può ancora saltare (s).
@export var coyote_time: float = 0.12
## Tempo in cui una pressione di salto anticipata viene ricordata (s).
@export var jump_buffer_time: float = 0.12

@export_group("Sicurezza")
## Sotto questa quota Gioia viene riportata all'ultimo punto sicuro.
@export var kill_height: float = -25.0

## Telecamera usata per orientare il movimento. Se nulla, si usa l'asse globale.
@export var camera_rig: Node3D

var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = true
var _last_safe_position: Vector3
var _safe_position_timer: float = 0.0
var _is_running: bool = false
var _move_input: Vector2 = Vector2.ZERO


## Quando è vero (menu aperti, dialoghi) Gioia ignora l'input di movimento.
var input_locked: bool = false


func _ready() -> void:
	add_to_group(&"player")
	floor_max_angle = deg_to_rad(46.0)
	floor_snap_length = 0.35
	floor_constant_speed = true
	_last_safe_position = global_position


func _physics_process(delta: float) -> void:
	_move_input = Vector2.ZERO if input_locked else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_is_running = not input_locked and Input.is_action_pressed("run") and _move_input.length() > 0.1

	_update_timers(delta)
	_apply_gravity(delta)
	_apply_horizontal_movement(delta)
	_try_jump()

	var vertical_speed_before: float = velocity.y
	move_and_slide()
	_handle_landing(vertical_speed_before)
	_update_facing(delta)
	_update_safety(delta)


## Velocità orizzontale attuale (m/s), usata dalle animazioni.
func get_horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func is_running() -> bool:
	return _is_running


## Riporta Gioia in un punto (teletrasporto, uscita da un interno, caricamento).
func teleport_to(position_global: Vector3) -> void:
	global_position = position_global
	velocity = Vector3.ZERO
	_last_safe_position = position_global


func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	if Input.is_action_just_pressed("jump") and not input_locked:
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * gravity_multiplier * delta


func _apply_horizontal_movement(delta: float) -> void:
	var direction: Vector3 = _camera_relative_direction(_move_input)
	var strength: float = minf(_move_input.length(), 1.0)
	var target_speed: float = (run_speed if _is_running else walk_speed) * strength
	var target: Vector3 = direction * target_speed

	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var rate: float = ground_acceleration if strength > 0.01 else ground_deceleration
	if not is_on_floor():
		rate *= air_control
	horizontal = horizontal.move_toward(target, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _try_jump() -> void:
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		jumped.emit()


func _handle_landing(vertical_speed_before: float) -> void:
	var on_floor: bool = is_on_floor()
	if on_floor and not _was_on_floor:
		landed.emit(-vertical_speed_before)
	_was_on_floor = on_floor


func _update_facing(delta: float) -> void:
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length() < 0.2:
		return
	var target_yaw: float = atan2(horizontal.x, horizontal.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))


func _update_safety(delta: float) -> void:
	if global_position.y < kill_height:
		teleport_to(_last_safe_position)
		return
	# Memorizza periodicamente un punto sicuro quando si è fermi a terra su un piano.
	_safe_position_timer += delta
	if _safe_position_timer > 0.5 and is_on_floor() and get_floor_normal().y > 0.9:
		_safe_position_timer = 0.0
		_last_safe_position = global_position


func _camera_relative_direction(input: Vector2) -> Vector3:
	if input.length_squared() < 0.0001:
		return Vector3.ZERO
	var forward: Vector3 = Vector3.FORWARD
	var right: Vector3 = Vector3.RIGHT
	if camera_rig != null:
		forward = -camera_rig.global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		right = Vector3(-forward.z, 0.0, forward.x)
	# Solo la direzione: l'intensità dell'input è applicata a parte alla velocità.
	return (right * input.x - forward * input.y).normalized()
