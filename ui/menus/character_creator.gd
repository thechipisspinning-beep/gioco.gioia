class_name CharacterCreator
extends Control
## Schermata di personalizzazione di Gioia (GDD § 4.2): acconciatura, colori,
## vestito, scarpe, accessorio, pelle, statura. Anteprima dal vivo sul modello
## nel mondo (la telecamera passa in modalità ritratto).

signal closed

const SLOT_ROWS: Array[StringName] = [&"hair", &"outfit", &"shoes", &"accessory", &"skin", &"height"]

var camera_rig: CameraRig
var player: PlayerController
var _appearance: CharacterAppearance
var _style_labels: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _panel: PanelContainer
var _content: VBoxContainer
var _first_focus: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func open() -> void:
	_appearance = GameState.appearance
	for c: Node in get_children():
		c.queue_free()
	_style_labels.clear()
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(500, 0)
	add_child(_panel)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)
	_content = box
	box.add_child(MenuHelpers.title(tr("CREATOR_TITLE"), 26))
	_first_focus = null
	for slot: StringName in SLOT_ROWS:
		_add_slot_row(box, slot)
	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	box.add_child(bottom)
	var rotate_b: Button = MenuHelpers.button(tr("CREATOR_ROTATE"), 140)
	rotate_b.pressed.connect(func() -> void:
		if player != null:
			player.rotation.y += PI * 0.5)
	bottom.add_child(rotate_b)
	var random_b: Button = MenuHelpers.button(tr("CREATOR_RANDOM"), 150)
	random_b.pressed.connect(func() -> void:
		_appearance.randomize_look(_rng, GameState.flags)
		_refresh_labels())
	bottom.add_child(random_b)
	var done: Button = MenuHelpers.button(tr("CREATOR_DONE"), 150)
	done.pressed.connect(close)
	bottom.add_child(done)
	visible = true
	_rng.randomize()
	if camera_rig != null:
		camera_rig.set_portrait(true)
	_refresh_labels()
	if _first_focus != null:
		_first_focus.grab_focus.call_deferred()


func close() -> void:
	if not visible:
		return
	visible = false
	GameState.flags["appearance_done"] = true
	if camera_rig != null:
		camera_rig.set_portrait(false)
	closed.emit()


func _process(_delta: float) -> void:
	if visible and _panel != null:
		var area: Vector2 = get_parent_area_size()
		var w: float = minf(520.0, area.x * 0.55)
		# Lo ScrollContainer non trasmette l'altezza del contenuto: la si calcola dal contenuto.
		var wanted: float = _content.get_combined_minimum_size().y + 28.0
		_panel.size = Vector2(w, minf(wanted, area.y - 40.0))
		_panel.position = Vector2(area.x - w - 20.0, (area.y - _panel.size.y) * 0.5)


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()


func _add_slot_row(box: VBoxContainer, slot: StringName) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	var name_l: Label = MenuHelpers.body(tr("CREATOR_SLOT_" + String(slot).to_upper()), 18)
	name_l.custom_minimum_size = Vector2(130, 0)
	row.add_child(name_l)
	var has_styles: bool = not CharacterCatalog.styles_for(slot).is_empty() or slot == &"height"
	if has_styles:
		var prev: Button = _small_button("<")
		prev.pressed.connect(func() -> void:
			_appearance.cycle_style(slot, -1, GameState.flags)
			_refresh_labels())
		row.add_child(prev)
		var style_l: Label = MenuHelpers.body("", 18)
		style_l.custom_minimum_size = Vector2(170, 0)
		style_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(style_l)
		_style_labels[slot] = style_l
		var next: Button = _small_button(">")
		next.pressed.connect(func() -> void:
			_appearance.cycle_style(slot, 1, GameState.flags)
			_refresh_labels())
		row.add_child(next)
		if _first_focus == null:
			_first_focus = next
	var colors: Array[Color] = CharacterCatalog.colors_for(slot)
	if colors.is_empty():
		return
	var swatches: HFlowContainer = HFlowContainer.new()
	swatches.add_theme_constant_override("h_separation", 6)
	swatches.add_theme_constant_override("v_separation", 6)
	box.add_child(swatches)
	for i: int in colors.size():
		var idx: int = i
		var b: Button = Button.new()
		b.custom_minimum_size = Vector2(40, 40)
		b.tooltip_text = tr("CREATOR_COLOR")
		for state: String in ["normal", "hover", "pressed"]:
			var sb: StyleBoxFlat = StyleBoxFlat.new()
			sb.bg_color = colors[i]
			sb.set_corner_radius_all(20)
			sb.border_color = UITheme.TEXT if state != "normal" else Color(0.3, 0.2, 0.3, 0.25)
			sb.set_border_width_all(3 if state != "normal" else 2)
			b.add_theme_stylebox_override(state, sb)
		b.pressed.connect(func() -> void:
			_appearance.set_color(slot, idx)
			_refresh_labels())
		swatches.add_child(b)
		if _first_focus == null:
			_first_focus = b


func _refresh_labels() -> void:
	for slot: StringName in _style_labels.keys():
		var l: Label = _style_labels[slot] as Label
		if slot == &"height":
			l.text = tr(["CREATOR_HEIGHT_SHORT", "CREATOR_HEIGHT_MEDIUM", "CREATOR_HEIGHT_TALL"][_appearance.height])
		else:
			l.text = tr("STYLE_" + String(_appearance.style_id(slot)).to_upper())


func _small_button(text: String) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(52, 46)
	b.add_theme_font_size_override("font_size", 22)
	return b
