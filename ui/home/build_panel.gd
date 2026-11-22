class_name BuildPanel
extends Control
## Pannello della modalità arredamento: mobili posseduti, strumenti
## (ruota, colore, rimuovi, pareti, pavimento, esterno, tetto, amplia) e uscita.

var build_mode: BuildMode
var _furniture_row: HFlowContainer
var _status: Label
var _panel: PanelContainer
var _tools: HFlowContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func open() -> void:
	for c: Node in get_children():
		c.queue_free()
	_panel = PanelContainer.new()
	add_child(_panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_panel.add_child(box)
	_status = MenuHelpers.body("", 17, UITheme.TEXT_SOFT)
	box.add_child(_status)
	_furniture_row = HFlowContainer.new()
	_furniture_row.add_theme_constant_override("h_separation", 6)
	_furniture_row.add_theme_constant_override("v_separation", 6)
	box.add_child(_furniture_row)
	_tools = HFlowContainer.new()
	_tools.add_theme_constant_override("h_separation", 6)
	_tools.add_theme_constant_override("v_separation", 6)
	box.add_child(_tools)
	_tool("BUILD_ROTATE", build_mode.rotate_selected)
	_tool("BUILD_COLOR", build_mode.cycle_color)
	_tool("BUILD_REMOVE", build_mode.remove_at_cursor)
	_tool("BUILD_WALLS", func() -> void:
		var room: StringName = build_mode.current_room()
		GameState.home.set_wall_color(room, (int(GameState.home.wall_colors.get(room, 0)) + 1) % FurnitureCatalog.WALL_COLORS.size()))
	_tool("BUILD_FLOOR", func() -> void:
		var room: StringName = build_mode.current_room()
		GameState.home.set_floor_color(room, (int(GameState.home.floor_colors.get(room, 0)) + 1) % FurnitureCatalog.FLOOR_COLORS.size()))
	_tool("BUILD_EXTERIOR", func() -> void:
		GameState.home.exterior_wall = (GameState.home.exterior_wall + 1) % FurnitureCatalog.WALL_COLORS.size()
		EventBus.notification_requested.emit(tr("BUILD_EXTERIOR_DONE")))
	_tool("BUILD_ROOF", func() -> void:
		GameState.home.exterior_roof = (GameState.home.exterior_roof + 1) % FurnitureCatalog.ROOF_COLORS.size()
		EventBus.notification_requested.emit(tr("BUILD_EXTERIOR_DONE")))
	var tokens: int = int(GameState.flags.get("room_tokens", 0))
	var expand: Button = _tool("BUILD_EXPAND", func() -> void:
		if int(GameState.flags.get("room_tokens", 0)) > 0 and GameState.home.unlock_next_room() != &"":
			GameState.flags["room_tokens"] = int(GameState.flags["room_tokens"]) - 1
			EventBus.notification_requested.emit(tr("BUILD_EXPANDED"))
			EventBus.home_expanded.emit(GameState.home.room_count())
			open())
	expand.disabled = tokens <= 0 or GameState.home.room_count() >= HomeLayout.ROOM_ORDER.size()
	expand.tooltip_text = tr("BUILD_EXPAND_HINT")
	_tool("BUILD_DONE", build_mode.close)
	visible = true
	_refresh()
	if not build_mode.selection_changed.is_connected(_refresh):
		build_mode.selection_changed.connect(_refresh)


func close() -> void:
	visible = false


func _process(_delta: float) -> void:
	if visible and _panel != null:
		var area: Vector2 = get_parent_area_size()
		_panel.size = Vector2(area.x - 40.0, 0)
		_panel.size = Vector2(area.x - 40.0, _panel.get_combined_minimum_size().y)
		_panel.position = Vector2(20.0, area.y - _panel.size.y - 16.0)
		_status.text = _status_text()


func _refresh() -> void:
	if _furniture_row == null:
		return
	for c: Node in _furniture_row.get_children():
		c.queue_free()
	for id: StringName in build_mode.owned_furniture():
		var fid: StringName = id
		var n: int = GameState.inventory.count(GameState.furniture_item(id))
		var b: Button = MenuHelpers.button("%s ×%d" % [tr(str(FurnitureCatalog.DEFS[id]["name_key"])), n], 0)
		b.custom_minimum_size = Vector2(0, 48)
		b.add_theme_font_size_override("font_size", 18)
		b.focus_mode = Control.FOCUS_NONE
		b.toggle_mode = true
		b.button_pressed = build_mode.selected == id
		b.pressed.connect(func() -> void: build_mode.select(&"" if build_mode.selected == fid else fid))
		_furniture_row.add_child(b)
	if build_mode.owned_furniture().is_empty():
		_furniture_row.add_child(MenuHelpers.body(tr("BUILD_NO_FURNITURE"), 17))


func _status_text() -> String:
	var room: String = tr("ROOM_" + String(build_mode.current_room()).to_upper())
	if build_mode.selected == &"":
		return tr("BUILD_HINT_PICK") % room
	return tr("BUILD_HINT_PLACE") % [tr(str(FurnitureCatalog.DEFS[build_mode.selected]["name_key"])), room]


func _tool(key: String, action: Callable) -> Button:
	var b: Button = MenuHelpers.button(tr(key), 0)
	b.custom_minimum_size = Vector2(0, 46)
	b.add_theme_font_size_override("font_size", 17)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(action)
	_tools.add_child(b)
	return b
