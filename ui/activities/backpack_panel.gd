class_name BackpackPanel
extends Control
## Zaino di Gioia: tutti gli oggetti posseduti, divisi per tipo. I piatti per
## Gioia si possono mangiare (bonus temporanei, D-22).

signal closed

const ORDER: Array[int] = [ItemDefinition.Category.MEAL, ItemDefinition.Category.FOOD, ItemDefinition.Category.MEDICINE,
	ItemDefinition.Category.SEED, ItemDefinition.Category.COLLECTIBLE, ItemDefinition.Category.TOY, ItemDefinition.Category.CARE,
	ItemDefinition.Category.MATERIAL]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func open() -> void:
	for c: Node in get_children():
		c.queue_free()
	var box: VBoxContainer = MenuHelpers.centered_panel(self, 600)
	box.add_child(MenuHelpers.title(tr("BACKPACK_TITLE")))
	box.add_child(MenuHelpers.body(tr("HUD_COINS") % GameState.coins + _buff_text(), 18, UITheme.ACCENT))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	var first: Button = null
	for cat: int in ORDER:
		var any: bool = false
		for id: StringName in GameState.inventory.item_ids():
			var def: ItemDefinition = Database.item(id)
			if def == null or int(def.category) != cat:
				continue
			if not any:
				list.add_child(MenuHelpers.body(tr("ITEMCAT_%d" % cat), 17, UITheme.TEXT_SOFT))
				any = true
			var row: HBoxContainer = HBoxContainer.new()
			list.add_child(row)
			var dot: ColorRect = ColorRect.new()
			dot.color = def.icon_color
			dot.custom_minimum_size = Vector2(18, 18)
			dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(dot)
			var l: Label = MenuHelpers.body("  %s ×%d" % [tr(def.name_key), GameState.inventory.count(id)], 18)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(l)
			if cat == ItemDefinition.Category.MEAL:
				var item: StringName = id
				var eat: Button = MenuHelpers.button(tr("BACKPACK_EAT"), 130)
				eat.custom_minimum_size = Vector2(130, 44)
				eat.pressed.connect(func() -> void:
					if GameState.eat_meal(item):
						EventBus.notification_requested.emit(tr("BUFF_" + String(RecipeData.MEAL_BUFFS[item]["buff"]).to_upper()))
					open())
				row.add_child(eat)
				if first == null:
					first = eat
	var close_b: Button = MenuHelpers.button(tr("JOURNAL_CLOSE"), 560)
	close_b.pressed.connect(close)
	box.add_child(close_b)
	visible = true
	(first if first != null else close_b).grab_focus.call_deferred()


func close() -> void:
	if not visible:
		return
	visible = false
	for c: Node in get_children():
		c.queue_free()
	closed.emit()


func _buff_text() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for b: StringName in [&"good_mood", &"energy"]:
		if GameState.has_buff(b):
			parts.append(tr("BUFF_NAME_" + String(b).to_upper()))
	return "" if parts.is_empty() else "  ·  " + ", ".join(parts)


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()
