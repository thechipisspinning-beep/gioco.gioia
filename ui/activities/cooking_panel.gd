class_name CookingPanel
extends Control
## Finestra della cucina (GDD § 9): ricette conosciute con gli ingredienti
## (posseduti/necessari). Cucinando parte un mini-gioco leggero e facoltativo
## (D-23): un cucchiaio va avanti e indietro, premi "Mescola!" quando è nella
## zona verde. 2 centri su 3 = una porzione in più. "Salta" cucina subito.

signal closed

var _box: VBoxContainer
var _game: StirGame


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func open() -> void:
	for c: Node in get_children():
		c.queue_free()
	_game = null
	_box = MenuHelpers.centered_panel(self, 640)
	_box.add_child(MenuHelpers.title(tr("COOK_TITLE")))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_box.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	var first: Button = null
	for r: Dictionary in RecipeData.ALL:
		if not Cooking.is_known(r, GameState.flags):
			continue
		var recipe: Dictionary = r
		var row: HBoxContainer = HBoxContainer.new()
		list.add_child(row)
		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var result_def: ItemDefinition = Database.item(r["result"])
		info.add_child(MenuHelpers.body("%s  ·  %s" % [tr(str(r["name_key"])), tr("COOK_FOR_" + str(r["for"]).to_upper())], 19))
		var parts: PackedStringArray = PackedStringArray()
		for item: Variant in (r["ingredients"] as Dictionary).keys():
			var need: int = int((r["ingredients"] as Dictionary)[item])
			var have: int = GameState.inventory.count(StringName(str(item)))
			var def: ItemDefinition = Database.item(StringName(str(item)))
			parts.append("%s %d/%d" % [tr(def.name_key) if def != null else str(item), have, need])
		info.add_child(MenuHelpers.body(", ".join(parts) + "  →  " + (tr(result_def.name_key) if result_def != null else ""), 15, UITheme.TEXT_SOFT))
		var b: Button = MenuHelpers.button(tr("COOK_BUTTON"), 140)
		b.custom_minimum_size = Vector2(140, 50)
		b.disabled = not Cooking.can_cook(r, GameState.inventory)
		b.pressed.connect(func() -> void: _start_game(recipe))
		row.add_child(b)
		if first == null and not b.disabled:
			first = b
	var close_b: Button = MenuHelpers.button(tr("JOURNAL_CLOSE"), 600)
	close_b.pressed.connect(close)
	_box.add_child(close_b)
	visible = true
	(first if first != null else close_b).grab_focus.call_deferred()


func close() -> void:
	if not visible:
		return
	visible = false
	for c: Node in get_children():
		c.queue_free()
	closed.emit()


func _start_game(recipe: Dictionary) -> void:
	for c: Node in get_children():
		c.queue_free()
	var box: VBoxContainer = MenuHelpers.centered_panel(self, 560)
	box.add_child(MenuHelpers.title(tr(str(recipe["name_key"]))))
	box.add_child(MenuHelpers.body(tr("COOK_GAME_HINT"), 17, UITheme.TEXT_SOFT))
	_game = StirGame.new()
	_game.custom_minimum_size = Vector2(520, 70)
	box.add_child(_game)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var stir: Button = MenuHelpers.button(tr("COOK_STIR"), 250)
	row.add_child(stir)
	var skip: Button = MenuHelpers.button(tr("COOK_SKIP"), 250)
	row.add_child(skip)
	stir.pressed.connect(func() -> void:
		_game.press()
		if _game.done():
			_finish(recipe, 1 if _game.hits >= 2 else 0))
	skip.pressed.connect(func() -> void: _finish(recipe, 0))
	stir.grab_focus.call_deferred()


func _finish(recipe: Dictionary, bonus: int) -> void:
	var n: int = Cooking.cook(recipe, GameState.inventory, bonus)
	if n > 0:
		var def: ItemDefinition = Database.item(recipe["result"])
		EventBus.notification_requested.emit(tr("COOK_DONE") % [tr(def.name_key), n] + (" " + tr("COOK_BONUS") if bonus > 0 else ""))
		EventBus.gameplay_event.emit("cook", recipe["id"], 1)
	open()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()


## Barra del mini-gioco: un cucchiaio oscilla, la zona verde è al centro.
class StirGame:
	extends Control
	var hits: int = 0
	var presses: int = 0
	var _t: float = 0.0
	var _flash: float = 0.0
	var _last_hit: bool = false

	func _process(delta: float) -> void:
		_t += delta * (1.6 + presses * 0.35)
		_flash = maxf(0.0, _flash - delta * 3.0)
		queue_redraw()

	func marker() -> float:
		return 0.5 + 0.5 * sin(_t * 2.2)

	func press() -> void:
		presses += 1
		_last_hit = absf(marker() - 0.5) < 0.12
		if _last_hit:
			hits += 1
		_flash = 1.0

	func done() -> bool:
		return presses >= 3

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		draw_rect(Rect2(0, h * 0.3, w, h * 0.4), Color("efe3d6"))
		draw_rect(Rect2(w * 0.38, h * 0.3, w * 0.24, h * 0.4), Color("b7e3a0"))
		var x: float = marker() * w
		draw_circle(Vector2(x, h * 0.5), h * 0.28, UITheme.ACCENT)
		for i: int in 3:
			var c: Color = UITheme.HEART_EMPTY
			if i < presses:
				c = UITheme.HEART_FULL if i < hits else Color("c9bcc9")
			draw_circle(Vector2(w * 0.5 - 30 + i * 30, h * 0.12), 8, c)
		if _flash > 0.0:
			draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.25 * _flash) if _last_hit else Color(1, 0.6, 0.6, 0.2 * _flash))
