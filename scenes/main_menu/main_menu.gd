extends Control
## Menu principale: Continua, Nuova partita (3 slot + Modalità serena),
## Carica partita, Lingua, Esci.

const WORLD_SCENE: String = "res://scenes/sandbox/movement_sandbox.tscn"

var _main_box: VBoxContainer
var _dialog: VBoxContainer


func _ready() -> void:
	theme = UITheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().paused = false
	SaveManager.current_slot = 0
	_build_background()
	_build_main()


func _build_background() -> void:
	var bg: TextureRect = TextureRect.new()
	var grad: Gradient = Gradient.new()
	grad.set_color(0, Color("9fd3f7"))
	grad.set_color(1, Color("c8ecb4"))
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	bg.texture = tex
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var deco: MenuDecor = MenuDecor.new()
	deco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(deco)


func _build_main() -> void:
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_main_box = VBoxContainer.new()
	_main_box.add_theme_constant_override("separation", 14)
	center.add_child(_main_box)
	var t: Label = MenuHelpers.title(tr("GAME_TITLE"), 64)
	t.add_theme_color_override("font_color", Color.WHITE)
	t.add_theme_color_override("font_outline_color", Color("6b4f7a"))
	t.add_theme_constant_override("outline_size", 14)
	_main_box.add_child(t)
	var sub: Label = MenuHelpers.title(tr("MENU_SUBTITLE"), 22)
	sub.add_theme_color_override("font_color", Color("4a3a55"))
	_main_box.add_child(sub)
	_main_box.add_child(_spacer(18))
	var first: Button = null
	if SaveManager.has_any_save():
		var cont: Button = MenuHelpers.button(tr("MENU_CONTINUE"))
		cont.pressed.connect(func() -> void: _load_and_play(SaveManager.most_recent_slot()))
		_main_box.add_child(cont)
		first = cont
	var new_b: Button = MenuHelpers.button(tr("MENU_NEW_GAME"))
	new_b.pressed.connect(_open_new_game)
	_main_box.add_child(new_b)
	if first == null:
		first = new_b
	if SaveManager.has_any_save():
		var load_b: Button = MenuHelpers.button(tr("MENU_LOAD_GAME"))
		load_b.pressed.connect(_open_load)
		_main_box.add_child(load_b)
	var lang: Button = MenuHelpers.button(tr("MENU_LANGUAGE"))
	lang.pressed.connect(_toggle_language)
	_main_box.add_child(lang)
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		var quit_b: Button = MenuHelpers.button(tr("MENU_QUIT"))
		quit_b.pressed.connect(func() -> void: get_tree().quit())
		_main_box.add_child(quit_b)
	first.grab_focus.call_deferred()


func _open_new_game() -> void:
	_dialog = MenuHelpers.centered_panel(self, 560)
	_dialog.add_child(MenuHelpers.title(tr("MENU_CHOOSE_SLOT")))
	var serene: CheckButton = CheckButton.new()
	serene.text = tr("MENU_SERENE_MODE")
	serene.add_theme_font_size_override("font_size", 19)
	_dialog.add_child(serene)
	_dialog.add_child(MenuHelpers.body(tr("MENU_SERENE_MODE_HINT"), 16, UITheme.TEXT_SOFT))
	var first: Button = null
	for i: int in range(1, SaveManager.SLOT_COUNT + 1):
		var slot: int = i
		var summary: Dictionary = SaveManager.slot_summary(slot)
		var b: Button = MenuHelpers.button("%s %d — %s" % [tr("SLOT"), slot, MenuHelpers.format_slot(summary)], 520)
		b.pressed.connect(func() -> void:
			if summary.is_empty():
				_start_new(slot, serene.button_pressed)
			else:
				_confirm_overwrite(slot, serene.button_pressed))
		_dialog.add_child(b)
		if first == null:
			first = b
	var back: Button = MenuHelpers.button(tr("ACTION_CANCEL"), 520)
	back.pressed.connect(_close_dialog)
	_dialog.add_child(back)
	first.grab_focus.call_deferred()


func _confirm_overwrite(slot: int, serene: bool) -> void:
	_close_dialog()
	_dialog = MenuHelpers.centered_panel(self, 480)
	_dialog.add_child(MenuHelpers.title(tr("MENU_OVERWRITE_TITLE")))
	_dialog.add_child(MenuHelpers.body(tr("MENU_OVERWRITE_TEXT") % slot))
	var yes: Button = MenuHelpers.button(tr("MENU_OVERWRITE_YES"), 440)
	yes.pressed.connect(func() -> void: _start_new(slot, serene))
	_dialog.add_child(yes)
	var no: Button = MenuHelpers.button(tr("ACTION_CANCEL"), 440)
	no.pressed.connect(_close_dialog)
	_dialog.add_child(no)
	no.grab_focus.call_deferred()


func _open_load() -> void:
	_dialog = MenuHelpers.centered_panel(self, 560)
	_dialog.add_child(MenuHelpers.title(tr("MENU_LOAD_GAME")))
	var first: Button = null
	for i: int in range(1, SaveManager.SLOT_COUNT + 1):
		var slot: int = i
		var summary: Dictionary = SaveManager.slot_summary(slot)
		var b: Button = MenuHelpers.button("%s %d — %s" % [tr("SLOT"), slot, MenuHelpers.format_slot(summary)], 520)
		b.disabled = summary.is_empty()
		b.pressed.connect(func() -> void: _load_and_play(slot))
		_dialog.add_child(b)
		if first == null and not b.disabled:
			first = b
	var back: Button = MenuHelpers.button(tr("ACTION_CANCEL"), 520)
	back.pressed.connect(_close_dialog)
	_dialog.add_child(back)
	(first if first != null else back).grab_focus.call_deferred()


func _close_dialog() -> void:
	MenuHelpers.close_panel(_dialog)
	_dialog = null
	if _main_box.get_child_count() > 3:
		(_main_box.get_child(3) as Control).grab_focus.call_deferred()


func _start_new(slot: int, serene: bool) -> void:
	SaveManager.new_game(slot, serene)
	get_tree().change_scene_to_file(WORLD_SCENE)


func _load_and_play(slot: int) -> void:
	if SaveManager.load_game(slot):
		get_tree().change_scene_to_file(SaveManager.saved_scene_path(WORLD_SCENE))


func _toggle_language() -> void:
	var next: String = "en" if TranslationServer.get_locale().begins_with("it") else "it"
	TranslationServer.set_locale(next)
	Settings.set_language(next)
	# Ricostruisce il menu con la nuova lingua.
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if _dialog != null and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_dialog()


func _spacer(h: float) -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
