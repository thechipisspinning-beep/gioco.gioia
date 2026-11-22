extends Node
## Autoload che fa avanzare l'orologio di gioco con il tempo reale.
## La logica è in `GameTime` (core); qui c'è solo il collegamento al ciclo di Godot.

signal hour_changed(day: int, hour: int)
signal day_started(day: int)

var time: GameTime = GameTime.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_connect_time()


func _process(delta: float) -> void:
	time.advance_real_seconds(delta)


## Sostituisce l'orologio (nuova partita o caricamento di un salvataggio).
func reset(new_time: GameTime) -> void:
	time = new_time
	_connect_time()


func _connect_time() -> void:
	time.hour_changed.connect(func(day: int, hour: int) -> void: hour_changed.emit(day, hour))
	time.day_started.connect(func(day: int) -> void: day_started.emit(day))
