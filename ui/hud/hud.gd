extends CanvasLayer
# Nota: l'HUD continua a funzionare durante la pausa (menu e diario).
## HUD (GDD § 12.1): giorno e ora, suggerimento dei controlli, scheda
## dell'oggetto/animale puntato, menu delle azioni, notifiche.
## Collegato a Gioia tramite `setup()`.

@onready var _root: Control = %UIRoot
@onready var _clock_label: Label = %ClockLabel
@onready var _hint_label: Label = %HintLabel
@onready var _touch: TouchControls = %TouchControls

var _player: PlayerController
var _interactor: Interactor
var _card: InteractionCard
var _menu: ActionMenu
var _menu_target: Node3D
var _name_dialog: NameDialog
var _adopting: AnimalAgent
var _pause: PauseMenu
var _journal: Journal
var _top_buttons: HBoxContainer
var _creator: CharacterCreator
var _camera_rig: CameraRig
var _mouse_was_captured: bool = false
var _device: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.theme = UITheme.get_theme()
	_card = InteractionCard.new()
	_root.add_child(_card)
	_root.add_child(ToastStack.new())
	_menu = ActionMenu.new()
	_root.add_child(_menu)
	_menu.action_chosen.connect(_on_action_chosen)
	_menu.closed.connect(_on_menu_closed)
	_name_dialog = NameDialog.new()
	_root.add_child(_name_dialog)
	_name_dialog.confirmed.connect(_on_name_confirmed)
	_name_dialog.cancelled.connect(func() -> void: _set_ui_locked(false))
	EventBus.adoption_requested.connect(_on_adoption_requested)
	_journal = Journal.new()
	_root.add_child(_journal)
	_journal.closed.connect(_on_overlay_closed)
	_pause = PauseMenu.new()
	_root.add_child(_pause)
	_pause.closed.connect(_on_overlay_closed)
	_pause.journal_requested.connect(_open_journal)
	_build_top_buttons()
	_creator = CharacterCreator.new()
	_root.add_child(_creator)
	_creator.closed.connect(func() -> void: _set_ui_locked(false))
	EventBus.customization_requested.connect(open_customization)
	_touch.interact_pressed.connect(_on_touch_interact)
	GameClock.hour_changed.connect(func(_d: int, _h: int) -> void: _refresh_clock())
	_refresh_clock()
	_set_device("touch" if TouchControls.should_show() else "desktop")


## Collega l'HUD a Gioia e alla telecamera.
func setup(player: PlayerController, camera_rig: CameraRig) -> void:
	_player = player
	_camera_rig = camera_rig
	_touch.camera_rig = camera_rig
	_creator.camera_rig = camera_rig
	_creator.player = player
	_interactor = player.get_node("Interactor") as Interactor
	_interactor.focus_changed.connect(_on_focus_changed)
	_interactor.interact_requested.connect(_open_menu)


func _process(_delta: float) -> void:
	_refresh_clock()
	# Pulsanti in alto a destra (le notifiche compaiono sotto).
	var area: Vector2 = _root.size
	_top_buttons.size = _top_buttons.get_combined_minimum_size()
	_top_buttons.position = Vector2(area.x - _top_buttons.size.x - 20.0, 20.0)
	_top_buttons.visible = not (_pause.visible or _journal.visible or _creator.visible)


func _unhandled_input(event: InputEvent) -> void:
	if _pause.visible or _journal.visible or _menu.visible or _name_dialog.visible or _creator.visible:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			# Primo Esc: libera il mouse; secondo Esc: pausa.
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			_open_pause()
	elif event.is_action_pressed("journal"):
		get_viewport().set_input_as_handled()
		_open_journal()


## Apre la personalizzazione di Gioia (inizio partita o specchio).
func open_customization() -> void:
	_set_ui_locked(true)
	_card.visible = false
	_creator.open()


func _open_pause() -> void:
	_set_ui_locked(true)
	_pause.open()


func _open_journal() -> void:
	_set_ui_locked(true)
	get_tree().paused = true
	_journal.open()


func _on_overlay_closed() -> void:
	if _journal.visible or _pause.visible:
		return
	get_tree().paused = false
	_set_ui_locked(false)


## Pulsanti in alto a destra (Diario, Pausa): indispensabili su telefono, comodi col mouse.
func _build_top_buttons() -> void:
	_top_buttons = HBoxContainer.new()
	_top_buttons.add_theme_constant_override("separation", 10)
	_root.add_child(_top_buttons)
	var j: Button = MenuHelpers.button(tr("HUD_JOURNAL"), 110)
	j.focus_mode = Control.FOCUS_NONE
	j.pressed.connect(_open_journal)
	_top_buttons.add_child(j)
	var p: Button = MenuHelpers.button(tr("HUD_PAUSE"), 110)
	p.focus_mode = Control.FOCUS_NONE
	p.pressed.connect(_open_pause)
	_top_buttons.add_child(p)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5):
		_set_device("pad")
	elif event is InputEventKey or (event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION):
		# I clic "emulati" generati da un tocco non contano come mouse.
		_set_device("desktop")
	elif event is InputEventScreenTouch:
		_set_device("touch")


func _on_focus_changed(target: Node3D) -> void:
	_card.show_target(target)
	_touch.interact_available = target != null


func _on_touch_interact() -> void:
	if _interactor != null and _interactor.focus != null and not _menu.visible:
		_open_menu(_interactor.focus)


func _open_menu(target: Node3D) -> void:
	var actions: Array[Dictionary] = []
	actions.assign(target.call("get_interaction_actions") as Array)
	if actions.is_empty():
		return
	_menu_target = target
	_set_ui_locked(true)
	_menu.open(str(target.call("get_interaction_title")), actions)


func _on_action_chosen(action_id: String) -> void:
	if _menu_target != null and is_instance_valid(_menu_target):
		_player.face_towards(_menu_target.global_position)
		_menu_target.call("perform_interaction", action_id)


func _on_menu_closed() -> void:
	_menu_target = null
	# Se l'azione scelta ha aperto un'altra finestra (es. il nome), resta bloccato.
	if not _name_dialog.visible and not _creator.visible:
		_set_ui_locked(false)


func _on_adoption_requested(agent: Node) -> void:
	_adopting = agent as AnimalAgent
	if _adopting == null:
		return
	_set_ui_locked(true)
	_name_dialog.open(tr(_adopting.species.name_key))


func _on_name_confirmed(chosen_name: String) -> void:
	if _adopting != null and is_instance_valid(_adopting):
		if AnimalCare.adopt(_adopting.data, chosen_name):
			Emote.spawn(_adopting, _adopting.global_position + Vector3.UP * 0.95, Emote.Kind.BIG_HEARTS)
	_adopting = null
	_set_ui_locked(false)


## Blocca/sblocca Gioia, la telecamera e i controlli touch mentre una finestra è aperta.
func _set_ui_locked(locked: bool) -> void:
	_player.input_locked = locked
	_interactor.enabled = not locked
	_touch.set_active(not locked)
	if locked:
		_card.visible = false
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_mouse_was_captured = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		if _mouse_was_captured:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_mouse_was_captured = false
		_card.show_target(_interactor.focus)


func _refresh_clock() -> void:
	var t: GameTime = GameClock.time
	_clock_label.text = "%s · %s" % [tr("HUD_DAY") % t.get_day(), t.format_clock()]


func _set_device(device: String) -> void:
	if device == _device:
		return
	_device = device
	match device:
		"pad":
			_hint_label.text = tr("HINT_CONTROLS_PAD")
			_card.set_prompt_text(tr("PROMPT_INTERACT_PAD"))
		"touch":
			_hint_label.text = tr("HINT_CONTROLS_TOUCH")
			_card.set_prompt_text(tr("PROMPT_INTERACT_TOUCH"))
		_:
			_hint_label.text = tr("HINT_CONTROLS_DESKTOP")
			_card.set_prompt_text(tr("PROMPT_INTERACT_KEY"))
