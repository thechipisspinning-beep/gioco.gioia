class_name Garden
extends RefCounted
## L'orto di Gioia (GDD § 7.6). Ogni parcella ha una pianta che cresce solo
## nelle ore in cui è annaffiata (un'annaffiatura dura 12 ore). Le piante non
## muoiono mai: senza acqua semplicemente non crescono. Logica pura.

signal changed

const WATER_HOURS: float = 12.0
const PLANTS: Dictionary = {
	&"carrot": {"seed": &"carrot_seeds", "hours_per_stage": 8.0, "harvest": {&"carrot": 3}},
	&"strawberry": {"seed": &"strawberry_seeds", "hours_per_stage": 10.0, "harvest": {&"strawberry": 4}},
	&"herb": {"seed": &"herb_seeds", "hours_per_stage": 6.0, "harvest": {&"herb": 3}},
	&"flower": {"seed": &"flower_seeds", "hours_per_stage": 6.0, "harvest": {&"flower": 3}},
}
const STAGES: int = 3  # 0 = seme, 1 = germoglio, 2 = pianta, 3 = pronta

var plots: Array[Dictionary] = []  # {plant, growth_hours, watered_until, last_minutes}


func _init(plot_count: int = 6) -> void:
	for i: int in plot_count:
		plots.append(_empty())


static func plant_for_seed(seed_item: StringName) -> StringName:
	for p: StringName in PLANTS.keys():
		if PLANTS[p]["seed"] == seed_item:
			return p
	return &""


func is_empty(i: int) -> bool:
	return plots[i]["plant"] == &""


func stage(i: int) -> int:
	var p: StringName = plots[i]["plant"]
	if p == &"":
		return -1
	return mini(STAGES, int(floor(float(plots[i]["growth_hours"]) / float(PLANTS[p]["hours_per_stage"]))))


func is_ready(i: int) -> bool:
	return stage(i) >= STAGES


func is_watered(i: int, now: float) -> bool:
	return float(plots[i]["watered_until"]) > now


func plant(i: int, plant_id: StringName, now: float) -> bool:
	if i < 0 or i >= plots.size() or not is_empty(i) or not PLANTS.has(plant_id):
		return false
	plots[i] = {"plant": plant_id, "growth_hours": 0.0, "watered_until": -1.0, "last_minutes": now}
	changed.emit()
	return true


func water(i: int, now: float) -> bool:
	if is_empty(i) or is_ready(i):
		return false
	update(now)
	plots[i]["watered_until"] = now + WATER_HOURS * 60.0
	changed.emit()
	return true


## Raccoglie: restituisce {oggetto: quantità} e svuota la parcella ({} se non pronta).
func harvest(i: int) -> Dictionary:
	if not is_ready(i):
		return {}
	var out: Dictionary = (PLANTS[plots[i]["plant"]]["harvest"] as Dictionary).duplicate()
	plots[i] = _empty()
	changed.emit()
	return out


## Fa crescere le piante fino a `now` (minuti di gioco), solo nelle ore annaffiate.
func update(now: float) -> void:
	var any: bool = false
	for p: Dictionary in plots:
		if p["plant"] == &"":
			continue
		var last: float = float(p["last_minutes"])
		var wet_end: float = minf(now, float(p["watered_until"]))
		if wet_end > last:
			p["growth_hours"] = float(p["growth_hours"]) + (wet_end - last) / 60.0
			any = true
		p["last_minutes"] = now
	if any:
		changed.emit()


func to_dict() -> Dictionary:
	var arr: Array = []
	for p: Dictionary in plots:
		arr.append({"plant": String(p["plant"]), "growth_hours": p["growth_hours"], "watered_until": p["watered_until"], "last_minutes": p["last_minutes"]})
	return {"plots": arr}


func from_dict(d: Dictionary) -> void:
	var arr: Array = d.get("plots", []) as Array
	for i: int in plots.size():
		if i < arr.size():
			var e: Dictionary = arr[i] as Dictionary
			var pid: StringName = StringName(str(e.get("plant", "")))
			plots[i] = {"plant": pid if PLANTS.has(pid) else &"", "growth_hours": float(e.get("growth_hours", 0.0)),
				"watered_until": float(e.get("watered_until", -1.0)), "last_minutes": float(e.get("last_minutes", 0.0))}
		else:
			plots[i] = _empty()
	changed.emit()


func _empty() -> Dictionary:
	return {"plant": &"", "growth_hours": 0.0, "watered_until": -1.0, "last_minutes": 0.0}
