extends SceneTree
## Genera la sezione [input] di project.godot con tutte le azioni di gioco.
##
## Uso: godot --headless --path . -s res://tools/setup_input_map.gd
##
## Definire le azioni qui (invece che a mano nel file di progetto) le rende
## leggibili, revisionabili e rigenerabili. Il gameplay legge solo le azioni,
## mai i tasti: così tastiera, controller e touch funzionano allo stesso modo.

const DEADZONE: float = 0.2


func _initialize() -> void:
	# Movimento (WASD, frecce, stick sinistro)
	_action("move_forward", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action("move_back", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_action("move_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_action("move_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	# Telecamera (stick destro; il mouse è gestito direttamente dalla telecamera)
	_action("look_left", [_axis(JOY_AXIS_RIGHT_X, -1.0)])
	_action("look_right", [_axis(JOY_AXIS_RIGHT_X, 1.0)])
	_action("look_up", [_axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_action("look_down", [_axis(JOY_AXIS_RIGHT_Y, 1.0)])
	_action("camera_zoom_in", [_mouse(MOUSE_BUTTON_WHEEL_UP), _button(JOY_BUTTON_RIGHT_SHOULDER)])
	_action("camera_zoom_out", [_mouse(MOUSE_BUTTON_WHEEL_DOWN), _button(JOY_BUTTON_LEFT_SHOULDER)])
	# Azioni
	_action("run", [_key(KEY_SHIFT), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0), _button(JOY_BUTTON_LEFT_STICK)])
	_action("jump", [_key(KEY_SPACE), _button(JOY_BUTTON_X)])
	_action("interact", [_key(KEY_E), _button(JOY_BUTTON_A)])
	_action("pause", [_key(KEY_ESCAPE), _button(JOY_BUTTON_START)])

	var err: Error = ProjectSettings.save()
	if err != OK:
		push_error("Impossibile salvare project.godot: %s" % error_string(err))
		quit(1)
		return
	print("Mappa degli input salvata in project.godot")
	quit(0)


func _action(action_name: String, events: Array[InputEvent]) -> void:
	ProjectSettings.set_setting("input/" + action_name, {"deadzone": DEADZONE, "events": events})


func _key(keycode: Key) -> InputEventKey:
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = keycode
	return e


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var e: InputEventMouseButton = InputEventMouseButton.new()
	e.button_index = button
	return e


func _button(button: JoyButton) -> InputEventJoypadButton:
	var e: InputEventJoypadButton = InputEventJoypadButton.new()
	e.button_index = button
	return e


func _axis(axis: JoyAxis, direction: float) -> InputEventJoypadMotion:
	var e: InputEventJoypadMotion = InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = direction
	return e
