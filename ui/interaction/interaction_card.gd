class_name InteractionCard
extends PanelContainer
## Scheda in basso al centro che mostra cosa Gioia sta guardando:
## nome, cuori dell'amicizia, stato ("Dorme", "È timida") e il tasto da premere.

var _title: Label
var _hearts: HeartsView
var _status: Label
var _prompt: Label
var _target: Node3D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 24)
	box.add_child(_title)
	_hearts = HeartsView.new()
	_hearts.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_hearts)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_color_override("font_color", UITheme.TEXT_SOFT)
	box.add_child(_status)
	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 17)
	_prompt.add_theme_color_override("font_color", UITheme.ACCENT)
	box.add_child(_prompt)
	visible = false


func show_target(target: Node3D) -> void:
	_target = target
	visible = target != null
	_refresh()


func set_prompt_text(text: String) -> void:
	_prompt.text = text


func _process(_delta: float) -> void:
	if visible:
		_refresh()
		# In basso al centro, sopra al suggerimento dei controlli.
		var area: Vector2 = get_parent_area_size()
		size = get_combined_minimum_size()
		position = Vector2((area.x - size.x) * 0.5, area.y - size.y - 70.0)


func _refresh() -> void:
	if _target == null or not is_instance_valid(_target):
		visible = false
		return
	_title.text = str(_target.call("get_interaction_title"))
	var has_hearts: bool = _target.has_method("get_hearts")
	_hearts.visible = has_hearts
	if has_hearts:
		_hearts.hearts = int(_target.call("get_hearts"))
	var status: String = str(_target.call("get_status_text")) if _target.has_method("get_status_text") else ""
	_status.text = status
	_status.visible = status != ""
	var actions: Array = _target.call("get_interaction_actions") as Array
	_prompt.visible = not actions.is_empty()
