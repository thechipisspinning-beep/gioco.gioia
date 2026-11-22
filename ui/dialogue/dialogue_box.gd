class_name DialogueBox
extends PanelContainer
## Fumetto di dialogo in basso: nome di chi parla e battuta. Si chiude con
## Interagisci / conferma / tocco, o da solo dopo qualche secondo.

signal closed

var _name: Label
var _text: Label
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var box: VBoxContainer = VBoxContainer.new()
	add_child(box)
	_name = MenuHelpers.body("", 20, UITheme.ACCENT)
	box.add_child(_name)
	_text = MenuHelpers.body("", 21)
	_text.custom_minimum_size = Vector2(560, 0)
	box.add_child(_text)
	box.add_child(MenuHelpers.body(tr("DIALOGUE_CONTINUE"), 15, UITheme.TEXT_SOFT))
	visible = false
	EventBus.dialogue_requested.connect(show_line)


func show_line(speaker: String, text: String) -> void:
	_name.text = speaker
	_text.text = text
	_time = 0.0
	visible = true


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	var area: Vector2 = get_parent_area_size()
	size = Vector2(minf(720.0, area.x - 40.0), get_combined_minimum_size().y)
	position = Vector2((area.x - size.x) * 0.5, area.y - size.y - 60.0)
	if _time > 8.0:
		close()


func close() -> void:
	if visible:
		visible = false
		closed.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if visible and _time > 0.25 and (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		close()
