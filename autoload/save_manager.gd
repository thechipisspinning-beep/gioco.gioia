extends Node
## Salvataggi su 3 slot (D-31) con scrittura sicura:
## 1. si scrive un file temporaneo;
## 2. il salvataggio precedente diventa la copia di riserva (.bak);
## 3. il temporaneo prende il posto del salvataggio.
## Se il gioco si chiude a metà, resta sempre un salvataggio valido.
## In caricamento, se il file principale è rovinato si usa la copia di riserva.
##
## Salvataggio automatico: ogni pochi minuti, dopo un'adozione, quando si
## dorme e quando l'app va in background o viene chiusa.

signal saved(slot: int)
signal loaded(slot: int)

const SLOT_COUNT: int = 3
const SAVE_DIR: String = "user://saves"
const AUTOSAVE_INTERVAL_SECONDS: float = 180.0

## Slot della partita in corso (0 = nessuna partita attiva, es. nel menu).
var current_slot: int = 0
## Scena e posizione di Gioia da ripristinare dopo un caricamento.
var _pending_player: Dictionary = {}
var _autosave_timer: float = 0.0
## Percorso della cartella dei salvataggi (modificabile dai test).
var save_dir: String = SAVE_DIR


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.animal_adopted.connect(func(_id: StringName, _sp: StringName) -> void: autosave())
	get_tree().auto_accept_quit = false


func _process(delta: float) -> void:
	if current_slot == 0:
		return
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL_SECONDS:
		autosave()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT and OS.has_feature("mobile"):
		autosave()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		autosave()
		get_tree().quit()


## Salva la partita in corso nel suo slot (se c'è).
func autosave() -> void:
	if current_slot > 0:
		save_game(current_slot)


func save_game(slot: int) -> bool:
	if slot < 1 or slot > SLOT_COUNT:
		return false
	DirAccess.make_dir_recursive_absolute(save_dir)
	var path: String = _slot_path(slot)
	var tmp: String = path + ".tmp"
	var text: String = SaveCodec.encode(_capture_game(), _summary(), int(Time.get_unix_time_from_system()))
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Impossibile scrivere il salvataggio: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(text)
	f.close()
	# Verifica che il file temporaneo sia leggibile prima di sostituire il salvataggio.
	if SaveCodec.decode(FileAccess.get_file_as_string(tmp)).is_empty():
		push_error("Salvataggio temporaneo non valido, salvataggio annullato")
		DirAccess.remove_absolute(tmp)
		return false
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(path + ".bak")
		DirAccess.rename_absolute(path, path + ".bak")
	var err: Error = DirAccess.rename_absolute(tmp, path)
	if err != OK:
		push_error("Impossibile completare il salvataggio: %s" % error_string(err))
		return false
	_autosave_timer = 0.0
	current_slot = slot
	saved.emit(slot)
	return true


## Carica lo slot e ripristina lo stato. La scena va cambiata dal chiamante
## (`change_to_saved_scene()`), che poi posiziona Gioia con `take_pending_player()`.
func load_game(slot: int) -> bool:
	var doc: Dictionary = read_slot(slot)
	if doc.is_empty():
		return false
	var game: Dictionary = doc["game"] as Dictionary
	GameState.from_dict(game.get("state", {}) as Dictionary)
	var t: GameTime = GameTime.new()
	t.from_dict(game.get("time", {}) as Dictionary)
	GameClock.reset(t)
	_pending_player = (game.get("player", {}) as Dictionary).duplicate()
	current_slot = slot
	_autosave_timer = 0.0
	QuestService.start_day()
	loaded.emit(slot)
	return true


## Avvia una nuova partita nello slot (sovrascrive quella vecchia al primo salvataggio).
func new_game(slot: int, serene: bool) -> void:
	GameState.start_new_game(serene)
	GameClock.reset(GameTime.new())
	_pending_player = {}
	current_slot = slot
	save_game(slot)


## Legge e valida uno slot (principale o copia di riserva). {} se vuoto o rovinato.
func read_slot(slot: int) -> Dictionary:
	var path: String = _slot_path(slot)
	for candidate: String in [path, path + ".bak"]:
		if FileAccess.file_exists(candidate):
			var doc: Dictionary = SaveCodec.decode(FileAccess.get_file_as_string(candidate))
			if not doc.is_empty():
				return doc
	return {}


## Riassunto per il menu (giorno, animali adottati, data del salvataggio). {} se vuoto.
func slot_summary(slot: int) -> Dictionary:
	var doc: Dictionary = read_slot(slot)
	if doc.is_empty():
		return {}
	var s: Dictionary = (doc.get("summary", {}) as Dictionary).duplicate()
	s["saved_at"] = doc.get("saved_at", 0)
	return s


func has_any_save() -> bool:
	for i: int in range(1, SLOT_COUNT + 1):
		if not read_slot(i).is_empty():
			return true
	return false


func most_recent_slot() -> int:
	var best: int = 0
	var best_time: int = -1
	for i: int in range(1, SLOT_COUNT + 1):
		var doc: Dictionary = read_slot(i)
		if not doc.is_empty() and int(doc.get("saved_at", 0)) > best_time:
			best_time = int(doc.get("saved_at", 0))
			best = i
	return best


func delete_slot(slot: int) -> void:
	var path: String = _slot_path(slot)
	for p: String in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


## Scena in cui si trovava Gioia al salvataggio (o quella iniziale).
func saved_scene_path(default_scene: String) -> String:
	var scene: String = str(_pending_player.get("scene", ""))
	return scene if scene != "" and ResourceLoader.exists(scene) else default_scene


## La scena di gioco chiama questa funzione per sapere dove mettere Gioia.
## Restituisce {} se non c'è una posizione salvata per questa scena.
func take_pending_player(scene_path: String) -> Dictionary:
	if str(_pending_player.get("scene", "")) != scene_path:
		return {}
	var p: Dictionary = _pending_player
	_pending_player = {}
	return p


func _capture_game() -> Dictionary:
	var game: Dictionary = {
		"state": GameState.to_dict(),
		"time": GameClock.time.to_dict(),
	}
	var player: Node3D = get_tree().get_first_node_in_group(&"player") as Node3D
	var scene: Node = get_tree().current_scene
	if player != null and scene != null and scene.scene_file_path != "":
		game["player"] = {
			"scene": scene.scene_file_path,
			"x": player.global_position.x, "y": player.global_position.y, "z": player.global_position.z,
			"yaw": player.global_rotation.y,
		}
	elif not _pending_player.is_empty():
		game["player"] = _pending_player
	return game


func _summary() -> Dictionary:
	return {
		"day": GameClock.time.get_day(),
		"clock": GameClock.time.format_clock(),
		"adopted": GameState.animals.adopted().size(),
		"species_met": GameState.discoveries.species_count(),
		"serene": GameState.serene_mode,
	}


func _slot_path(slot: int) -> String:
	return save_dir.path_join("slot_%d.json" % slot)
