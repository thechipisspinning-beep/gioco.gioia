extends Node
## Strumenti di sviluppo controllati da riga di comando (argomenti dopo `--`).
## Non fanno nulla se non vengono passati argomenti: nelle partite normali sono inerti.
##
##   --scene=res://percorso.tscn          apre direttamente una scena (gestito da Boot)
##   --hold=azione:inizio:fine,...        tiene premuta un'azione tra due istanti (secondi)
##   --look=yaw:pitch:inizio:fine         ruota la telecamera (gradi/secondo) in un intervallo
##   --shot=secondi:/percorso.png,...     salva screenshot agli istanti indicati
##   --quit-at=secondi                    chiude il gioco
##   --time=HH                            imposta l'ora di gioco all'avvio
##   --friendship=id_animale:valore       imposta l'amicizia (e una visita) di un animale
##   --adopt=id_animale:Nome:follow       adotta un animale (follow facoltativo: diventa compagno)
##   --teleport=x:z                       porta Gioia in (x, z) sull'isola
##   --signal=nome_segnale:secondi        emette un segnale dell'EventBus senza argomenti (es. build_mode_requested)
##
## Esempio (screenshot di Gioia che corre):
##   godot --path . -- --hold=move_forward:0.5:3,run:0.5:3 --shot=3:/tmp/run.png --quit-at=3.2

signal look_requested(yaw_degrees: float, pitch_degrees: float)

var _holds: Array[Dictionary] = []
var _looks: Array[Dictionary] = []
var _shots: Array[Dictionary] = []
var _quit_at: float = -1.0
var _signals: Array[Dictionary] = []
var _elapsed: float = 0.0
var active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		set_process(false)
		return
	active = true
	for arg: String in args:
		if arg.begins_with("--hold="):
			for part: String in arg.trim_prefix("--hold=").split(","):
				var p: PackedStringArray = part.split(":")
				if p.size() == 3:
					_holds.append({"action": StringName(p[0]), "from": p[1].to_float(), "to": p[2].to_float(), "phase": 0})
		elif arg.begins_with("--look="):
			var p: PackedStringArray = arg.trim_prefix("--look=").split(":")
			if p.size() == 4:
				_looks.append({"yaw": p[0].to_float(), "pitch": p[1].to_float(), "from": p[2].to_float(), "to": p[3].to_float()})
		elif arg.begins_with("--shot="):
			for part: String in arg.trim_prefix("--shot=").split(","):
				var idx: int = part.find(":")
				if idx > 0:
					_shots.append({"at": part.substr(0, idx).to_float(), "path": part.substr(idx + 1), "done": false})
		elif arg.begins_with("--teleport="):
			_teleport.call_deferred(arg.trim_prefix("--teleport="))
		elif arg.begins_with("--signal="):
			var p: PackedStringArray = arg.trim_prefix("--signal=").split(":")
			_signals.append({"name": StringName(p[0]), "at": p[1].to_float() if p.size() > 1 else 1.0, "done": false})
		elif arg.begins_with("--quit-at="):
			_quit_at = arg.trim_prefix("--quit-at=").to_float()
		elif arg.begins_with("--friendship=") or arg.begins_with("--adopt="):
			_apply_animal_arg.call_deferred(arg)
		elif arg.begins_with("--time="):
			var hour: int = arg.trim_prefix("--time=").to_int()
			GameClock.reset(GameTime.new(float(hour * GameTime.MINUTES_PER_HOUR)))


func _process(delta: float) -> void:
	_elapsed += delta
	# Ogni pressione dura almeno un frame anche se il gioco va lento (rendering software):
	# 0 = in attesa, 1 = premuto, 2 = finito.
	for h: Dictionary in _holds:
		var phase: int = int(h["phase"])
		if phase == 0 and _elapsed >= float(h["from"]):
			_send_action(h["action"], true)
			h["phase"] = 1
		elif phase == 1 and _elapsed >= float(h["to"]):
			_send_action(h["action"], false)
			h["phase"] = 2
	for sig: Dictionary in _signals:
		if not bool(sig["done"]) and _elapsed >= float(sig["at"]):
			sig["done"] = true
			EventBus.emit_signal(sig["name"])
	for l: Dictionary in _looks:
		if _elapsed >= float(l["from"]) and _elapsed < float(l["to"]):
			look_requested.emit(float(l["yaw"]) * delta, float(l["pitch"]) * delta)
	for s: Dictionary in _shots:
		if not bool(s["done"]) and _elapsed >= float(s["at"]):
			s["done"] = true
			_save_screenshot(String(s["path"]))
	if _quit_at > 0.0 and _elapsed >= _quit_at:
		get_tree().quit()


func _teleport(spec: String) -> void:
	for i: int in 6:
		await get_tree().process_frame
	var p: PackedStringArray = spec.split(":")
	var player: PlayerController = get_tree().get_first_node_in_group(&"player") as PlayerController
	if player == null or p.size() < 2:
		return
	var x: float = p[0].to_float()
	var z: float = p[1].to_float()
	var y: float = float(WorldQuery.ground_height.call(x, z)) if WorldQuery.ground_height.is_valid() else player.global_position.y
	player.teleport_to(Vector3(x, y + 0.3, z))


## Evento reale (non solo action_press): così lo ricevono anche
## _input/_unhandled_input e i pulsanti dell'interfaccia.
func _send_action(action: StringName, pressed: bool) -> void:
	var ev: InputEventAction = InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)


## Applicato dopo che la scena ha creato i suoi animali.
func _apply_animal_arg(arg: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var p: PackedStringArray = arg.split("=", true, 1)[1].split(":")
	var state: AnimalState = GameState.animals.get_animal(StringName(p[0]))
	if state == null:
		push_warning("[DevTools] animale sconosciuto: %s" % p[0])
		return
	if arg.begins_with("--friendship="):
		state.friendship = p[1].to_float()
		state.record_visit(GameState.current_day())
	else:
		state.friendship = maxf(state.friendship, 100.0)
		for d: int in 5:
			state.record_visit(d + 1)
		AnimalCare.adopt(state, p[1] if p.size() > 1 else "Amico")
		if p.size() > 2 and p[2] == "follow":
			AnimalCare.set_companion(state, true)


func _save_screenshot(path: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	var err: Error = image.save_png(path)
	print("[DevTools] screenshot %s → %s" % [path, error_string(err)])
