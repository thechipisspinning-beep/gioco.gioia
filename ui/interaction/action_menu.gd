class_name ActionMenu
extends PanelContainer
## Menu delle azioni possibili su un oggetto/animale (accarezza, dai cibo…).
## Navigabile con mouse, touch, tastiera e controller.

signal closed
signal action_chosen(action_id: String)

var _box: VBoxContainer
var _title: Label


func _ready() -> void:
	custom_minimum_size = Vector2(380, 0)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	add_child(_box)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 24)
	visible = false


func open(title: String, actions: Array[Dictionary]) -> void:
	for c: Node in _box.get_children():
		_box.remove_child(c)
		if c != _title:
			c.queue_free()
	_title.text = title
	_box.add_child(_title)
	var first: Button = null
	for a: Dictionary in actions:
		var b: Button = _make_button(str(a["label"]))
		b.disabled = not bool(a.get("enabled", true))
		var id: String = str(a["id"])
		b.pressed.connect(func() -> void: _choose(id))
		_box.add_child(b)
		if first == null and not b.disabled:
			first = b
	var cancel: Button = _make_button(tr("ACTION_CANCEL"))
	cancel.pressed.connect(close)
	_box.add_child(cancel)
	visible = true
	_layout()
	(first if first != null else cancel).grab_focus.call_deferred()


func _process(_delta: float) -> void:
	if visible:
		_layout()


## Al centro dello schermo, spostato un po' a destra per non coprire Gioia.
func _layout() -> void:
	var area: Vector2 = get_parent_area_size()
	size = get_combined_minimum_size()
	position = Vector2(clampf(area.x * 0.62 - size.x * 0.5, 10.0, area.x - size.x - 10.0), (area.y - size.y) * 0.5)


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()


func _choose(id: String) -> void:
	visible = false
	action_chosen.emit(id)
	closed.emit()


func _make_button(text: String) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.focus_mode = Control.FOCUS_ALL
	return b
