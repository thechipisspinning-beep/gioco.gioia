extends Node
## Strumenti di sviluppo controllati da riga di comando (argomenti dopo `--`).
## Non fanno nulla se non vengono passati argomenti: nelle partite normali sono inerti.
##
##   --scene=res://percorso.tscn          apre direttamente una scena
##   --hold=azione:inizio:fine,...        tiene premuta un'azione tra due istanti (secondi)
##   --look=yaw:pitch:inizio:fine         ruota la telecamera (gradi/secondo) in un intervallo
##   --shot=secondi:/percorso.png,...     salva screenshot agli istanti indicati
##   --quit-at=secondi                    chiude il gioco
##   --time=HH                            imposta l'ora di gioco all'avvio
##
## Esempio (screenshot di Gioia che corre):
##   godot --path . -- --hold=move_forward:0.5:3,run:0.5:3 --shot=3:/tmp/run.png --quit-at=3.2

signal look_requested(yaw_degrees: float, pitch_degrees: float)

var _holds: Array[Dictionary] = []
var _looks: Array[Dictionary] = []
var _shots: Array[Dictionary] = []
var _quit_at: float = -1.0
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
		if arg.begins_with("--scene="):
			var scene_path: String = arg.trim_prefix("--scene=")
			get_tree().change_scene_to_file.call_deferred(scene_path)
		elif arg.begins_with("--hold="):
			for part: String in arg.trim_prefix("--hold=").split(","):
				var p: PackedStringArray = part.split(":")
				if p.size() == 3:
					_holds.append({"action": StringName(p[0]), "from": p[1].to_float(), "to": p[2].to_float(), "down": false})
		elif arg.begins_with("--look="):
			var p: PackedStringArray = arg.trim_prefix("--look=").split(":")
			if p.size() == 4:
				_looks.append({"yaw": p[0].to_float(), "pitch": p[1].to_float(), "from": p[2].to_float(), "to": p[3].to_float()})
		elif arg.begins_with("--shot="):
			for part: String in arg.trim_prefix("--shot=").split(","):
				var idx: int = part.find(":")
				if idx > 0:
					_shots.append({"at": part.substr(0, idx).to_float(), "path": part.substr(idx + 1), "done": false})
		elif arg.begins_with("--quit-at="):
			_quit_at = arg.trim_prefix("--quit-at=").to_float()
		elif arg.begins_with("--time="):
			var hour: int = arg.trim_prefix("--time=").to_int()
			GameClock.reset(GameTime.new(float(hour * GameTime.MINUTES_PER_HOUR)))


func _process(delta: float) -> void:
	_elapsed += delta
	for h: Dictionary in _holds:
		var should_be_down: bool = _elapsed >= float(h["from"]) and _elapsed < float(h["to"])
		if should_be_down != bool(h["down"]):
			h["down"] = should_be_down
			if should_be_down:
				Input.action_press(h["action"])
			else:
				Input.action_release(h["action"])
	for l: Dictionary in _looks:
		if _elapsed >= float(l["from"]) and _elapsed < float(l["to"]):
			look_requested.emit(float(l["yaw"]) * delta, float(l["pitch"]) * delta)
	for s: Dictionary in _shots:
		if not bool(s["done"]) and _elapsed >= float(s["at"]):
			s["done"] = true
			_save_screenshot(String(s["path"]))
	if _quit_at > 0.0 and _elapsed >= _quit_at:
		get_tree().quit()


func _save_screenshot(path: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	var err: Error = image.save_png(path)
	print("[DevTools] screenshot %s → %s" % [path, error_string(err)])
