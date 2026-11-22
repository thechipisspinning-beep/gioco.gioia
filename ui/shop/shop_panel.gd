class_name ShopPanel
extends Control
## Negozio di Bruno (D-19): compra oggetti e mobili, vendi ciò che hai raccolto.

signal closed

var _box: VBoxContainer
var _coins: Label
var _sell: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func open(sell: bool) -> void:
	_sell = sell
	for c: Node in get_children():
		c.queue_free()
	_box = MenuHelpers.centered_panel(self, 620)
	_box.add_child(MenuHelpers.title(tr("SHOP_SELL_TITLE") if sell else tr("SHOP_TITLE")))
	_coins = MenuHelpers.body("", 19, UITheme.ACCENT)
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(_coins)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_box.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	var first: Button = null
	if sell:
		for item: StringName in VillagerData.SELL_PRICES.keys():
			var n: int = GameState.inventory.count(item)
			var def: ItemDefinition = Database.item(item)
			if n <= 0 or def == null:
				continue
			var price: int = int(VillagerData.SELL_PRICES[item])
			var b: Button = _row(list, "%s ×%d" % [tr(def.name_key), n], tr("SHOP_SELL_FOR") % price)
			b.pressed.connect(func() -> void:
				if GameState.inventory.try_remove(item):
					GameState.coins += price
					open(true))
			if first == null:
				first = b
		if list.get_child_count() == 0:
			list.add_child(MenuHelpers.body(tr("SHOP_NOTHING_TO_SELL"), 18, UITheme.TEXT_SOFT))
	else:
		for e: Dictionary in VillagerData.SHOP_ITEMS:
			var item: StringName = e["item"]
			var price: int = int(e["price"])
			var def: ItemDefinition = Database.item(item)
			var b: Button = _row(list, "%s (%d)" % [tr(def.name_key), GameState.inventory.count(item)], tr("SHOP_BUY_FOR") % price)
			b.disabled = GameState.coins < price
			b.pressed.connect(func() -> void: _buy(price, func() -> void: GameState.inventory.add(item)))
			if first == null and not b.disabled:
				first = b
		for e: Dictionary in VillagerData.SHOP_FURNITURE:
			var furn: StringName = e["furniture"]
			var price: int = int(e["price"])
			var b: Button = _row(list, tr(str(FurnitureCatalog.DEFS[furn]["name_key"])), tr("SHOP_BUY_FOR") % price)
			b.disabled = GameState.coins < price
			b.pressed.connect(func() -> void: _buy(price, func() -> void: GameState.inventory.add(GameState.furniture_item(furn))))
			if first == null and not b.disabled:
				first = b
	var close_b: Button = MenuHelpers.button(tr("JOURNAL_CLOSE"), 580)
	close_b.pressed.connect(close)
	_box.add_child(close_b)
	_coins.text = tr("HUD_COINS") % GameState.coins
	visible = true
	(first if first != null else close_b).grab_focus.call_deferred()


func close() -> void:
	if not visible:
		return
	visible = false
	for c: Node in get_children():
		c.queue_free()
	closed.emit()


func _buy(price: int, give: Callable) -> void:
	if GameState.coins < price:
		return
	GameState.coins -= price
	give.call()
	EventBus.notification_requested.emit(tr("SHOP_BOUGHT"))
	open(false)


func _row(list: VBoxContainer, label: String, button_text: String) -> Button:
	var row: HBoxContainer = HBoxContainer.new()
	list.add_child(row)
	var l: Label = MenuHelpers.body(label, 18)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var b: Button = MenuHelpers.button(button_text, 190)
	b.custom_minimum_size = Vector2(190, 46)
	b.add_theme_font_size_override("font_size", 18)
	row.add_child(b)
	return b


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()
