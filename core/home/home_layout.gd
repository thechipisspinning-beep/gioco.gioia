class_name HomeLayout
extends RefCounted
## La casa di Gioia (GDD § 8): stanze sbloccate, mobili posizionati su griglia,
## colori di pareti e pavimenti, colori dell'esterno. Logica pura.
##
## Le stanze sono affiancate lungo X; ogni stanza è ROOM_CELLS celle da 0,5 m.
## La porta d'ingresso è al centro del lato sud del soggiorno; tra stanze
## vicine c'è un passaggio al centro della parete.

signal changed

const CELL: float = 0.5
const ROOM_CELLS: Vector2i = Vector2i(16, 12)  # 8 × 6 m
const ROOM_ORDER: Array[StringName] = [&"living", &"bedroom", &"kitchen", &"pets"]
## Celle che devono restare libere (porte e passaggi), larghezza 3 celle.
const DOOR_HALF: int = 1

var rooms: Array[StringName] = [&"living"]
var placements: Array[Dictionary] = []  # {id, x, y, rot, color}
var wall_colors: Dictionary = {}  # room -> indice
var floor_colors: Dictionary = {}
var exterior_wall: int = 0
var exterior_roof: int = 0


func room_count() -> int:
	return rooms.size()


func grid_size() -> Vector2i:
	return Vector2i(ROOM_CELLS.x * rooms.size(), ROOM_CELLS.y)


func is_unlocked(room: StringName) -> bool:
	return rooms.has(room)


## Sblocca la stanza successiva nell'ordine; restituisce l'id o &"" se già tutte.
func unlock_next_room() -> StringName:
	for r: StringName in ROOM_ORDER:
		if not rooms.has(r):
			rooms.append(r)
			changed.emit()
			return r
	return &""


func room_at_cell(x: int) -> StringName:
	var i: int = floori(float(x) / ROOM_CELLS.x)
	return rooms[i] if i >= 0 and i < rooms.size() else &""


## Il mobile `id` può stare con l'angolo in (x, y) e rotazione `rot`?
func can_place(id: StringName, x: int, y: int, rot: int, ignore_index: int = -1) -> bool:
	if not FurnitureCatalog.has(id):
		return false
	var fp: Vector2i = FurnitureCatalog.footprint(id, rot)
	var size: Vector2i = grid_size()
	if x < 0 or y < 0 or x + fp.x > size.x or y + fp.y > size.y:
		return false
	var flat: bool = FurnitureCatalog.is_flat(id)
	for cy: int in range(y, y + fp.y):
		for cx: int in range(x, x + fp.x):
			if not flat and _is_door_cell(cx, cy):
				return false
	# I tappeti possono stare sotto gli altri mobili e viceversa.
	for i: int in placements.size():
		if i == ignore_index:
			continue
		var p: Dictionary = placements[i]
		if flat != FurnitureCatalog.is_flat(p["id"]):
			continue
		var pfp: Vector2i = FurnitureCatalog.footprint(p["id"], int(p["rot"]))
		if Rect2i(x, y, fp.x, fp.y).intersects(Rect2i(int(p["x"]), int(p["y"]), pfp.x, pfp.y)):
			return false
	return true


func place(id: StringName, x: int, y: int, rot: int, color: int = 0) -> bool:
	if not can_place(id, x, y, rot):
		return false
	placements.append({"id": id, "x": x, "y": y, "rot": rot % 4, "color": color})
	changed.emit()
	return true


## Indice del mobile che occupa la cella (preferendo quelli non piatti), o -1.
func index_at(x: int, y: int) -> int:
	var found: int = -1
	for i: int in placements.size():
		var p: Dictionary = placements[i]
		var fp: Vector2i = FurnitureCatalog.footprint(p["id"], int(p["rot"]))
		if Rect2i(int(p["x"]), int(p["y"]), fp.x, fp.y).has_point(Vector2i(x, y)):
			if not FurnitureCatalog.is_flat(p["id"]):
				return i
			found = i
	return found


## Rimuove il mobile alla cella; restituisce i suoi dati ({} se nessuno).
func remove_at(x: int, y: int) -> Dictionary:
	var i: int = index_at(x, y)
	if i < 0:
		return {}
	var p: Dictionary = placements[i]
	placements.remove_at(i)
	changed.emit()
	return p


func count_of(id: StringName) -> int:
	var n: int = 0
	for p: Dictionary in placements:
		if p["id"] == id:
			n += 1
	return n


func set_wall_color(room: StringName, index: int) -> void:
	wall_colors[room] = clampi(index, 0, FurnitureCatalog.WALL_COLORS.size() - 1)
	changed.emit()


func set_floor_color(room: StringName, index: int) -> void:
	floor_colors[room] = clampi(index, 0, FurnitureCatalog.FLOOR_COLORS.size() - 1)
	changed.emit()


func wall_color(room: StringName) -> Color:
	return FurnitureCatalog.WALL_COLORS[int(wall_colors.get(room, 0))]


func floor_color(room: StringName) -> Color:
	return FurnitureCatalog.FLOOR_COLORS[int(floor_colors.get(room, 0))]


func _is_door_cell(x: int, y: int) -> bool:
	# Ingresso: centro del lato sud (y alto) del soggiorno, profondità 2 celle.
	var entrance_x: int = ROOM_CELLS.x / 2
	if absi(x - entrance_x) <= DOOR_HALF and y >= ROOM_CELLS.y - 2:
		return true
	# Passaggi tra stanze: centro (in y) di ogni parete divisoria, 1 cella per lato.
	for i: int in range(1, rooms.size()):
		var wall_x: int = i * ROOM_CELLS.x
		if (x == wall_x - 1 or x == wall_x) and absi(y - ROOM_CELLS.y / 2) <= DOOR_HALF:
			return true
	return false


func to_dict() -> Dictionary:
	var pl: Array = []
	for p: Dictionary in placements:
		pl.append({"id": String(p["id"]), "x": p["x"], "y": p["y"], "rot": p["rot"], "color": p["color"]})
	var wc: Dictionary = {}
	for k: StringName in wall_colors.keys():
		wc[String(k)] = wall_colors[k]
	var fc: Dictionary = {}
	for k: StringName in floor_colors.keys():
		fc[String(k)] = floor_colors[k]
	var rs: Array = []
	for r: StringName in rooms:
		rs.append(String(r))
	return {"rooms": rs, "placements": pl, "wall_colors": wc, "floor_colors": fc,
		"exterior_wall": exterior_wall, "exterior_roof": exterior_roof}


func from_dict(d: Dictionary) -> void:
	rooms.clear()
	for r: Variant in d.get("rooms", ["living"]) as Array:
		if ROOM_ORDER.has(StringName(str(r))) and not rooms.has(StringName(str(r))):
			rooms.append(StringName(str(r)))
	if rooms.is_empty():
		rooms.append(&"living")
	placements.clear()
	for p: Variant in d.get("placements", []) as Array:
		var e: Dictionary = p as Dictionary
		var id: StringName = StringName(str(e.get("id", "")))
		if FurnitureCatalog.has(id):
			placements.append({"id": id, "x": int(e.get("x", 0)), "y": int(e.get("y", 0)), "rot": int(e.get("rot", 0)) % 4, "color": int(e.get("color", 0))})
	wall_colors.clear()
	for k: Variant in (d.get("wall_colors", {}) as Dictionary).keys():
		wall_colors[StringName(str(k))] = int((d["wall_colors"] as Dictionary)[k])
	floor_colors.clear()
	for k: Variant in (d.get("floor_colors", {}) as Dictionary).keys():
		floor_colors[StringName(str(k))] = int((d["floor_colors"] as Dictionary)[k])
	exterior_wall = clampi(int(d.get("exterior_wall", 0)), 0, FurnitureCatalog.WALL_COLORS.size() - 1)
	exterior_roof = clampi(int(d.get("exterior_roof", 0)), 0, FurnitureCatalog.ROOF_COLORS.size() - 1)
	changed.emit()
