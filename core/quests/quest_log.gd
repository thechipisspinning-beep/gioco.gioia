class_name QuestLog
extends RefCounted
## Stato delle missioni (GDD § 10). Logica pura, guidata dai dati in
## `QuestData`. Le missioni si attivano quando i prerequisiti sono completati,
## avanzano con gli eventi di gioco e si completano automaticamente.
##
## Tipi di obiettivo (campo "type"): meet_species, adopt, hearts (target: specie,
## count: cuori), pet, feed, play, brush, collect (target: oggetto), place_furniture,
## visit_zone (target: zona), talk (target: abitante), cure, refill_feeder,
## cook (target: ricetta o ""), plant, harvest (target: pianta o "").

signal quest_activated(quest_id: StringName)
signal quest_completed(quest_id: StringName)
signal progress_changed(quest_id: StringName)

enum Status { LOCKED, ACTIVE, COMPLETED }

var _status: Dictionary = {}    # id -> Status
var _progress: Dictionary = {}  # id -> Array[int] (uno per obiettivo)
var _daily_day: int = 0


## Attiva le missioni i cui prerequisiti sono soddisfatti.
func refresh(defs: Array[Dictionary]) -> void:
	for q: Dictionary in defs:
		var id: StringName = q["id"]
		if status(id) != Status.LOCKED or q.get("kind", "main") == "daily":
			continue
		var ok: bool = true
		for req: StringName in q.get("requires", []) as Array:
			if status(req) != Status.COMPLETED:
				ok = false
				break
		if ok:
			_activate(q)


## Imposta le missioni giornaliere del giorno (scelta deterministica dal pool).
func set_daily(defs: Array[Dictionary], day: int, count: int = 3) -> void:
	if _daily_day == day:
		return
	_daily_day = day
	var pool: Array[Dictionary] = []
	for q: Dictionary in defs:
		if q.get("kind", "main") == "daily":
			pool.append(q)
			_status.erase(q["id"])
			_progress.erase(q["id"])
	if pool.is_empty():
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = day * 7919
	for i: int in mini(count, pool.size()):
		var pick: Dictionary = pool.pop_at(rng.randi() % pool.size())
		_activate(pick)


## Un evento di gioco: aggiorna gli obiettivi delle missioni attive.
## Restituisce gli id delle missioni completate da questo evento.
func on_event(defs: Array[Dictionary], type: String, target: StringName = &"", amount: int = 1) -> Array[StringName]:
	var done: Array[StringName] = []
	for q: Dictionary in defs:
		var id: StringName = q["id"]
		if status(id) != Status.ACTIVE:
			continue
		var objectives: Array = q["objectives"] as Array
		var prog: Array = _progress[id] as Array
		var changed: bool = false
		for i: int in objectives.size():
			var o: Dictionary = objectives[i]
			if str(o["type"]) != type:
				continue
			var want: StringName = StringName(str(o.get("target", "")))
			if want != &"" and want != target:
				continue
			var goal: int = int(o.get("count", 1))
			if int(prog[i]) >= goal:
				continue
			# "hearts" conta il valore raggiunto, non la somma.
			prog[i] = maxi(int(prog[i]), amount) if type == "hearts" else mini(goal, int(prog[i]) + amount)
			prog[i] = mini(goal, int(prog[i]))
			changed = true
		if changed:
			progress_changed.emit(id)
			if _all_done(q):
				_status[id] = Status.COMPLETED
				done.append(id)
				quest_completed.emit(id)
	return done


func status(id: StringName) -> Status:
	return _status.get(id, Status.LOCKED) as Status


func progress(id: StringName) -> Array:
	return (_progress.get(id, []) as Array).duplicate()


func active_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in _status.keys():
		if _status[id] == Status.ACTIVE:
			out.append(id)
	return out


func completed_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in _status.keys():
		if _status[id] == Status.COMPLETED:
			out.append(id)
	return out


func _activate(q: Dictionary) -> void:
	var id: StringName = q["id"]
	_status[id] = Status.ACTIVE
	var prog: Array = []
	for o: Variant in q["objectives"] as Array:
		prog.append(0)
	_progress[id] = prog
	quest_activated.emit(id)


func _all_done(q: Dictionary) -> bool:
	var prog: Array = _progress[q["id"]] as Array
	var objectives: Array = q["objectives"] as Array
	for i: int in objectives.size():
		if int(prog[i]) < int((objectives[i] as Dictionary).get("count", 1)):
			return false
	return true


func to_dict() -> Dictionary:
	var st: Dictionary = {}
	for k: StringName in _status.keys():
		st[String(k)] = _status[k]
	var pr: Dictionary = {}
	for k: StringName in _progress.keys():
		pr[String(k)] = _progress[k]
	return {"status": st, "progress": pr, "daily_day": _daily_day}


func from_dict(d: Dictionary) -> void:
	_status.clear()
	_progress.clear()
	for k: Variant in (d.get("status", {}) as Dictionary).keys():
		_status[StringName(str(k))] = int((d["status"] as Dictionary)[k]) as Status
	for k: Variant in (d.get("progress", {}) as Dictionary).keys():
		var arr: Array = []
		for v: Variant in (d["progress"] as Dictionary)[k] as Array:
			arr.append(int(v))
		_progress[StringName(str(k))] = arr
	_daily_day = int(d.get("daily_day", 0))
