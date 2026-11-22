extends CanvasLayer
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
var _mouse_was_captured: bool = false
var _device: String = ""


func _ready() -> void:
	_root.theme = UITheme.get_theme()
	_card = InteractionCard.new()
	_root.add_child(_card)
	_root.add_child(ToastStack.new())
	_menu = ActionMenu.new()
	_root.add_child(_menu)
	_menu.action_chosen.connect(_on_action_chosen)
	_menu.closed.connect(_on_menu_closed)
	_touch.interact_pressed.connect(_on_touch_interact)
	GameClock.hour_changed.connect(func(_d: int, _h: int) -> void: _refresh_clock())
	_refresh_clock()
	_set_device("touch" if TouchControls.should_show() else "desktop")


## Collega l'HUD a Gioia e alla telecamera.
func setup(player: PlayerController, camera_rig: CameraRig) -> void:
	_player = player
	_touch.camera_rig = camera_rig
	_interactor = player.get_node("Interactor") as Interactor
	_interactor.focus_changed.connect(_on_focus_changed)
	_interactor.interact_requested.connect(_open_menu)


func _process(_delta: float) -> void:
	_refresh_clock()


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
	_player.input_locked = true
	_interactor.enabled = false
	_touch.set_active(false)
	_card.visible = false
	_mouse_was_captured = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_menu.open(str(target.call("get_interaction_title")), actions)


func _on_action_chosen(action_id: String) -> void:
	if _menu_target != null and is_instance_valid(_menu_target):
		_menu_target.call("perform_interaction", action_id)


func _on_menu_closed() -> void:
	_player.input_locked = false
	_interactor.enabled = true
	_touch.set_active(true)
	if _mouse_was_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_menu_target = null


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
