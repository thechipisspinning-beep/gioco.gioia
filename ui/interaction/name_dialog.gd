class_name NameDialog
extends PanelContainer
## Finestra per dare il nome a un animale adottato (GDD § 6.3).
## Il pulsante "Suggerisci" propone un nome: comodo su telefono e con il controller.

signal confirmed(chosen_name: String)
signal cancelled

const SUGGESTIONS_IT: PackedStringArray = ["Biscotto", "Nuvola", "Briciola", "Pepe", "Luna", "Fiocco", "Ciambella", "Stella", "Tobia", "Zucchero", "Pallino", "Margherita", "Ginger", "Oliva", "Bruno", "Mirtillo"]
const SUGGESTIONS_EN: PackedStringArray = ["Biscuit", "Cloud", "Crumble", "Pepper", "Luna", "Flake", "Donut", "Star", "Toby", "Sugar", "Button", "Daisy", "Ginger", "Olive", "Bruno", "Blueberry"]

var _title: Label
var _edit: LineEdit
var _confirm: Button


func _ready() -> void:
	custom_minimum_size = Vector2(460, 0)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_font_size_override("font_size", 24)
	box.add_child(_title)
	_edit = LineEdit.new()
	_edit.max_length = Adoption.MAX_NAME_LENGTH
	_edit.custom_minimum_size = Vector2(0, 52)
	_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edit.add_theme_font_size_override("font_size", 24)
	_edit.text_changed.connect(func(_t: String) -> void: _update_confirm())
	_edit.text_submitted.connect(func(_t: String) -> void: _try_confirm())
	box.add_child(_edit)
	var suggest: Button = _button(tr("NAME_SUGGEST"))
	suggest.pressed.connect(_suggest)
	box.add_child(suggest)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var cancel: Button = _button(tr("ACTION_CANCEL"))
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(func() -> void:
		visible = false
		cancelled.emit())
	row.add_child(cancel)
	_confirm = _button(tr("NAME_CONFIRM"))
	_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm.pressed.connect(_try_confirm)
	row.add_child(_confirm)
	visible = false


func open(species_name: String) -> void:
	_title.text = tr("NAME_TITLE") % species_name
	_edit.text = ""
	_update_confirm()
	visible = true
	_edit.grab_focus.call_deferred()


func _process(_delta: float) -> void:
	if visible:
		var area: Vector2 = get_parent_area_size()
		size = get_combined_minimum_size()
		# Nella metà alta dello schermo: su telefono la tastiera virtuale occupa la metà bassa.
		position = Vector2((area.x - size.x) * 0.5, maxf(10.0, area.y * 0.3 - size.y * 0.5))


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		visible = false
		cancelled.emit()


func _suggest() -> void:
	var list: PackedStringArray = SUGGESTIONS_IT if TranslationServer.get_locale().begins_with("it") else SUGGESTIONS_EN
	var pick: String = list[randi() % list.size()]
	if pick == _edit.text and list.size() > 1:
		pick = list[(list.find(pick) + 1) % list.size()]
	_edit.text = pick
	_update_confirm()
	_confirm.grab_focus()


func _update_confirm() -> void:
	_confirm.disabled = Adoption.sanitize_name(_edit.text).is_empty()


func _try_confirm() -> void:
	var n: String = Adoption.sanitize_name(_edit.text)
	if n.is_empty():
		return
	visible = false
	confirmed.emit(n)


func _button(text: String) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	return b
