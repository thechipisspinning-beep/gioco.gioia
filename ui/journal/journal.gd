class_name Journal
extends Control
## Diario di Gioia (GDD § 11): animali incontrati, famiglia (adottati e ricordi),
## progressi. È solo una vista sui dati di gioco: non ha uno stato proprio,
## quindi non può andare "fuori sincrono".

signal closed

enum Tab { ANIMALS, FAMILY, PROGRESS }

var _tab: Tab = Tab.ANIMALS
var _content: VBoxContainer
var _tab_buttons: Array[Button] = []
var _box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func open() -> void:
	for c: Node in get_children():
		c.queue_free()
	_tab_buttons.clear()
	_box = MenuHelpers.centered_panel(self, 760)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	_box.add_child(header)
	var title: Label = MenuHelpers.title(tr("JOURNAL_TITLE"), 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_child(title)
	var close_b: Button = MenuHelpers.button(tr("JOURNAL_CLOSE"), 120)
	close_b.pressed.connect(close)
	header.add_child(close_b)
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	_box.add_child(tabs)
	for t: int in [Tab.ANIMALS, Tab.FAMILY, Tab.PROGRESS]:
		var key: String = ["JOURNAL_TAB_ANIMALS", "JOURNAL_TAB_FAMILY", "JOURNAL_TAB_PROGRESS"][t]
		var b: Button = MenuHelpers.button(tr(key), 150)
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tab_id: Tab = t as Tab
		b.pressed.connect(func() -> void: _show_tab(tab_id))
		tabs.add_child(b)
		_tab_buttons.append(b)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(720, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_box.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)
	visible = true
	_show_tab(_tab)
	_tab_buttons[_tab].grab_focus.call_deferred()


func close() -> void:
	visible = false
	for c: Node in get_children():
		c.queue_free()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("journal") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func _show_tab(t: Tab) -> void:
	_tab = t
	for i: int in _tab_buttons.size():
		_tab_buttons[i].button_pressed = i == t
	for c: Node in _content.get_children():
		c.queue_free()
	match t:
		Tab.ANIMALS:
			_fill_animals()
		Tab.FAMILY:
			_fill_family()
		Tab.PROGRESS:
			_fill_progress()


func _fill_animals() -> void:
	var all: Array[SpeciesDefinition] = Database.all_species()
	_content.add_child(MenuHelpers.body(tr("JOURNAL_SPECIES_COUNT") % [GameState.discoveries.species_count(), all.size()], 18, UITheme.TEXT_SOFT))
	for s: SpeciesDefinition in all:
		var card: VBoxContainer = _card()
		if not GameState.discoveries.has_met(s.id):
			card.add_child(MenuHelpers.body("???", 22))
			card.add_child(MenuHelpers.body(tr("JOURNAL_NOT_MET"), 16, UITheme.TEXT_SOFT))
			continue
		var info: Dictionary = GameState.discoveries.species_met_info(s.id)
		card.add_child(MenuHelpers.body("%s  ·  %s" % [tr(s.name_key), tr("JOURNAL_WILD") if s.wild else tr("JOURNAL_DOMESTIC")], 22))
		card.add_child(MenuHelpers.body(tr("JOURNAL_MET_ON") % [int(info.get("day", 1)), int(info.get("hour", 0))], 16, UITheme.TEXT_SOFT))
		card.add_child(MenuHelpers.body(tr("JOURNAL_ACTIVE_HOURS") % [s.active_from_hour, s.active_to_hour % 24], 16))
		var favs: Array[StringName] = GameState.discoveries.known_favorite_foods(s.id)
		var fav_names: PackedStringArray = PackedStringArray()
		for f: StringName in favs:
			fav_names.append(tr(Database.item(f).name_key) if Database.item(f) != null else String(f))
		var fav_text: String = ", ".join(fav_names) if not favs.is_empty() else tr("JOURNAL_FAVORITE_UNKNOWN")
		card.add_child(MenuHelpers.body(tr("JOURNAL_FAVORITE_FOOD") % fav_text, 16))
		if s.fact_key != "":
			card.add_child(MenuHelpers.body(tr(s.fact_key), 16, UITheme.TEXT_SOFT))


func _fill_family() -> void:
	var adopted: Array[AnimalState] = GameState.animals.adopted()
	var alive: Array[AnimalState] = adopted.filter(func(a: AnimalState) -> bool: return a.is_alive())
	var memories: Array[AnimalState] = adopted.filter(func(a: AnimalState) -> bool: return not a.is_alive())
	if alive.is_empty():
		_content.add_child(MenuHelpers.body(tr("JOURNAL_NO_FAMILY"), 18, UITheme.TEXT_SOFT))
	var now: float = GameClock.time.get_total_minutes()
	for a: AnimalState in alive:
		var s: SpeciesDefinition = Database.species(a.species_id)
		var card: VBoxContainer = _card()
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var name_l: Label = MenuHelpers.body("%s  (%s)" % [a.given_name, tr(s.name_key) if s != null else ""], 22)
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_l)
		var hearts: HeartsView = HeartsView.new()
		hearts.hearts = a.hearts()
		row.add_child(hearts)
		var where: String = tr("JOURNAL_FOLLOWS_YOU") if a.location == AnimalState.Location.COMPANION else tr("JOURNAL_AT_HOME")
		var health: String = ""
		match a.health:
			AnimalState.Health.SICK:
				health = " · " + tr("JOURNAL_SICK") % mini(AnimalHealth.sick_day(a, now), 3)
			AnimalState.Health.CONVALESCENT:
				health = " · " + tr("ANIMAL_STATUS_CONVALESCENT")
		card.add_child(MenuHelpers.body(tr("JOURNAL_ADOPTED_ON") % a.adopted_day + " · " + where + health, 16, UITheme.TEXT_SOFT))
		card.add_child(_need_bar(tr("NEED_HUNGER"), a.hunger))
		card.add_child(_need_bar(tr("NEED_HAPPINESS"), a.happiness))
		card.add_child(_need_bar(tr("NEED_CLEANLINESS"), a.cleanliness))
	if not memories.is_empty():
		_content.add_child(MenuHelpers.title(tr("JOURNAL_MEMORIES"), 22))
		for a: AnimalState in memories:
			var s: SpeciesDefinition = Database.species(a.species_id)
			var card: VBoxContainer = _card()
			card.add_child(MenuHelpers.body("%s  (%s)" % [a.given_name, tr(s.name_key) if s != null else ""], 20))
			card.add_child(MenuHelpers.body(tr("JOURNAL_MEMORY_TEXT") % a.adopted_day, 16, UITheme.TEXT_SOFT))


func _fill_progress() -> void:
	var t: GameTime = GameClock.time
	var adopted: Array[AnimalState] = GameState.animals.adopted()
	var alive: int = adopted.filter(func(a: AnimalState) -> bool: return a.is_alive()).size()
	var card: VBoxContainer = _card()
	card.add_child(MenuHelpers.body(tr("JOURNAL_STAT_DAY") % t.get_day(), 20))
	card.add_child(MenuHelpers.body(tr("JOURNAL_STAT_SPECIES") % [GameState.discoveries.species_count(), Database.all_species().size()], 20))
	card.add_child(MenuHelpers.body(tr("JOURNAL_STAT_ADOPTED") % alive, 20))
	card.add_child(MenuHelpers.body(tr("JOURNAL_STAT_COMPANIONS") % [GameState.animals.companions().size(), Adoption.MAX_COMPANIONS], 20))
	if GameState.serene_mode:
		card.add_child(MenuHelpers.body(tr("JOURNAL_SERENE_ON"), 16, UITheme.TEXT_SOFT))


func _card() -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = UITheme._box(Color("fffdf8"), UITheme.PANEL_BORDER, 14, 2)
	sb.shadow_size = 0
	panel.add_theme_stylebox_override("panel", sb)
	_content.add_child(panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	return v


func _need_bar(label: String, value: float) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	var l: Label = MenuHelpers.body(label, 16)
	l.custom_minimum_size = Vector2(130, 0)
	row.add_child(l)
	var bar: ProgressBar = ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(300, 16)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color("8ccf6b") if value > 0.5 else (Color("ffd75e") if value > AnimalHealth.LOW_NEED_WARNING else Color("ff8a7a"))
	fill.set_corner_radius_all(8)
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color("efe3d6")
	bg.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	row.add_child(bar)
	return row
