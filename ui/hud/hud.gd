extends CanvasLayer
## HUD minimo (GDD § 12.1): giorno e ora in alto a sinistra, suggerimento dei
## controlli in basso che si adatta al dispositivo usato per ultimo.

@onready var _clock_label: Label = %ClockLabel
@onready var _hint_label: Label = %HintLabel

var _last_device: String = ""


func _ready() -> void:
	GameClock.hour_changed.connect(func(_d: int, _h: int) -> void: _refresh_clock())
	_refresh_clock()
	_set_device("touch" if TouchControls.should_show() else "desktop")


func _process(_delta: float) -> void:
	# Aggiorna i minuti (il segnale arriva solo allo scoccare dell'ora).
	_refresh_clock()


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5):
		_set_device("pad")
	elif event is InputEventKey or (event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION):
		# I clic "emulati" generati da un tocco non contano come mouse.
		_set_device("desktop")
	elif event is InputEventScreenTouch:
		_set_device("touch")


func _refresh_clock() -> void:
	var t: GameTime = GameClock.time
	_clock_label.text = "%s · %s" % [tr("HUD_DAY") % t.get_day(), t.format_clock()]


func _set_device(device: String) -> void:
	if device == _last_device:
		return
	_last_device = device
	match device:
		"pad":
			_hint_label.text = tr("HINT_CONTROLS_PAD")
		"touch":
			_hint_label.text = tr("HINT_CONTROLS_TOUCH")
		_:
			_hint_label.text = tr("HINT_CONTROLS_DESKTOP")
