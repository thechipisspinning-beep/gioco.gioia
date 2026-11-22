class_name PauseMenu
extends Control
## Menu di pausa: Riprendi, Diario, Salva, Menu principale. Il gioco è in pausa
## mentre è aperto (anche l'orologio di gioco).

signal closed
signal journal_requested

const MAIN_MENU: String = "res://scenes/main_menu/main_menu.tscn"

var _box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func open() -> void:
	for c: Node in get_children():
		c.queue_free()
	_box = MenuHelpers.centered_panel(self, 420)
	_box.add_child(MenuHelpers.title(tr("PAUSE_TITLE")))
	var resume: Button = MenuHelpers.button(tr("PAUSE_RESUME"))
	resume.pressed.connect(close)
	_box.add_child(resume)
	var journal: Button = MenuHelpers.button(tr("PAUSE_JOURNAL"))
	journal.pressed.connect(func() -> void:
		close()
		journal_requested.emit())
	_box.add_child(journal)
	var save: Button = MenuHelpers.button(tr("PAUSE_SAVE"))
	save.pressed.connect(func() -> void:
		var ok: bool = SaveManager.save_game(SaveManager.current_slot) if SaveManager.current_slot > 0 else false
		EventBus.notification_requested.emit(tr("NOTIFY_SAVED") if ok else tr("NOTIFY_SAVE_FAILED"))
		close())
	save.disabled = SaveManager.current_slot == 0
	_box.add_child(save)
	var quality: Button = MenuHelpers.button(tr("PAUSE_QUALITY") % tr(["QUALITY_LOW", "QUALITY_MEDIUM", "QUALITY_HIGH"][Settings.get_quality()]))
	quality.pressed.connect(func() -> void:
		Settings.set_quality((Settings.get_quality() + 1) % 3)
		quality.text = tr("PAUSE_QUALITY") % tr(["QUALITY_LOW", "QUALITY_MEDIUM", "QUALITY_HIGH"][Settings.get_quality()])
		EventBus.notification_requested.emit(tr("QUALITY_NOTE")))
	_box.add_child(quality)
	var menu: Button = MenuHelpers.button(tr("PAUSE_MAIN_MENU"))
	menu.pressed.connect(func() -> void:
		SaveManager.autosave()
		get_tree().paused = false
		get_tree().change_scene_to_file(MAIN_MENU))
	_box.add_child(menu)
	visible = true
	get_tree().paused = true
	resume.grab_focus.call_deferred()


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		close()
