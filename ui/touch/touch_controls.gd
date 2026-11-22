class_name TouchControls
extends Control
## Controlli touch per mobile (e per browser su dispositivi touch).
##
## - Metà sinistra: joystick "fluttuante" che compare dove si appoggia il dito.
##   Spingerlo fino al bordo fa correre Gioia.
## - Metà destra: trascinare ruota la telecamera.
## - Pulsante in basso a destra: salto.
##
## I controlli premono le stesse azioni di input di tastiera e controller,
## quindi il gameplay non sa da dove arriva l'input.
## Si mostrano solo su dispositivi touch (o con l'argomento `--touch`).

## Premuto il pulsante "interagisci" (compare solo quando c'è qualcosa vicino).
signal interact_pressed

@export var camera_rig: CameraRig
@export var joystick_radius: float = 90.0
@export_range(0.5, 1.0) var run_threshold: float = 0.92
@export var look_sensitivity: float = 0.28
@export var jump_button_radius: float = 62.0

var _move_touch: int = -1
var _move_origin: Vector2 = Vector2.ZERO
var _move_vector: Vector2 = Vector2.ZERO
var _look_touch: int = -1
var _jump_touch: int = -1
var _active: bool = true
## Mostra il pulsante "interagisci" (impostato dall'HUD).
var interact_available: bool = false:
	set(value):
		interact_available = value
		queue_redraw()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Senza touch il nodo resta nascosto e non intercetta nulla.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = should_show()
	set_process_input(visible)


## True se il dispositivo ha uno schermo touch o se è stato richiesto `--touch`.
static func should_show() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.get_cmdline_user_args().has("--touch")


## Disattiva i controlli (es. mentre un menu è aperto, così i tocchi arrivano ai pulsanti).
func set_active(active: bool) -> void:
	_active = active
	if not active:
		_move_touch = -1
		_look_touch = -1
		_jump_touch = -1
		_set_move(Vector2.ZERO)
		Input.action_release("jump")
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or not _active:
		return
	if event is InputEventScreenTouch:
		_on_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_on_drag(event as InputEventScreenDrag)


func _on_touch(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		# La fascia in alto è riservata ai pulsanti dell'interfaccia (Diario, Pausa).
		if touch.position.y < 96.0:
			return
		if interact_available and touch.position.distance_to(_interact_button_center()) <= jump_button_radius * 1.1:
			interact_pressed.emit()
			get_viewport().set_input_as_handled()
			return
		if _jump_touch == -1 and touch.position.distance_to(_jump_button_center()) <= jump_button_radius * 1.15:
			_jump_touch = touch.index
			Input.action_press("jump")
		elif _move_touch == -1 and touch.position.x < size.x * 0.5:
			_move_touch = touch.index
			_move_origin = touch.position
			_set_move(Vector2.ZERO)
		elif _look_touch == -1:
			_look_touch = touch.index
		get_viewport().set_input_as_handled()
	else:
		if touch.index == _move_touch:
			_move_touch = -1
			_set_move(Vector2.ZERO)
		elif touch.index == _look_touch:
			_look_touch = -1
		elif touch.index == _jump_touch:
			_jump_touch = -1
			Input.action_release("jump")
	queue_redraw()


func _on_drag(drag: InputEventScreenDrag) -> void:
	if drag.index == _move_touch:
		var offset: Vector2 = drag.position - _move_origin
		# Se il dito va oltre il bordo, il joystick lo "insegue" (più comodo sui telefoni).
		if offset.length() > joystick_radius:
			_move_origin = drag.position - offset.normalized() * joystick_radius
			offset = drag.position - _move_origin
		_set_move(offset / joystick_radius)
		get_viewport().set_input_as_handled()
	elif drag.index == _look_touch and camera_rig != null:
		camera_rig.add_look(-drag.relative.x * look_sensitivity, -drag.relative.y * look_sensitivity)
		get_viewport().set_input_as_handled()
	queue_redraw()


func _set_move(v: Vector2) -> void:
	_move_vector = v.limit_length(1.0)
	_press_axis("move_left", "move_right", _move_vector.x)
	_press_axis("move_forward", "move_back", _move_vector.y)
	if _move_vector.length() >= run_threshold:
		Input.action_press("run")
	else:
		Input.action_release("run")


func _press_axis(negative: StringName, positive: StringName, value: float) -> void:
	if value < 0.0:
		Input.action_press(negative, -value)
		Input.action_release(positive)
	elif value > 0.0:
		Input.action_press(positive, value)
		Input.action_release(negative)
	else:
		Input.action_release(negative)
		Input.action_release(positive)


func _interact_button_center() -> Vector2:
	return _jump_button_center() + Vector2(-20.0, -150.0)


func _jump_button_center() -> Vector2:
	return Vector2(size.x - 120.0, size.y - 130.0)


func _draw() -> void:
	# Riempimento bianco + bordo viola scuro: leggibili sia su prati chiari sia su sfondi scuri.
	var outline: Color = Color(0.36, 0.27, 0.42, 0.55)
	if _move_touch != -1:
		draw_circle(_move_origin, joystick_radius, Color(1, 1, 1, 0.25))
		draw_arc(_move_origin, joystick_radius, 0.0, TAU, 48, outline, 4.0, true)
		var knob: Vector2 = _move_origin + _move_vector * joystick_radius
		draw_circle(knob, 40.0, Color(1, 1, 1, 0.85))
		draw_arc(knob, 40.0, 0.0, TAU, 32, outline, 3.0, true)
	else:
		# Suggerimento della posizione del joystick.
		var hint: Vector2 = Vector2(150.0, size.y - 150.0)
		draw_circle(hint, joystick_radius * 0.8, Color(1, 1, 1, 0.18))
		draw_arc(hint, joystick_radius * 0.8, 0.0, TAU, 48, outline, 4.0, true)
		draw_circle(hint, 30.0, Color(1, 1, 1, 0.55))
	var jump_center: Vector2 = _jump_button_center()
	var pressed: bool = _jump_touch != -1
	draw_circle(jump_center, jump_button_radius, Color(1, 1, 1, 0.75 if pressed else 0.45))
	draw_arc(jump_center, jump_button_radius, 0.0, TAU, 48, outline, 4.0, true)
	var p: PackedVector2Array = PackedVector2Array([
		jump_center + Vector2(0, -24), jump_center + Vector2(22, 10), jump_center + Vector2(-22, 10)])
	draw_colored_polygon(p, Color(0.36, 0.27, 0.42, 0.8))
	if interact_available and _active:
		# Pulsante "interagisci": cerchio corallo con una mano stilizzata (palmo + dita).
		var ic: Vector2 = _interact_button_center()
		draw_circle(ic, jump_button_radius, Color(1.0, 0.54, 0.48, 0.85))
		draw_arc(ic, jump_button_radius, 0.0, TAU, 48, outline, 4.0, true)
		draw_circle(ic + Vector2(0, 8), 16.0, Color.WHITE)
		for i: int in 4:
			draw_circle(ic + Vector2(-13.0 + i * 8.7, -12.0 - absf(1.5 - i) * -2.0), 5.0, Color.WHITE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
