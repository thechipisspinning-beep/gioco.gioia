class_name IslandLayout
extends RefCounted
## Disposizione dell'isola (D-05: circa 2 × 2 km): zone, aree pianeggianti,
## sentieri. Sono dati, non codice: spostare il villaggio o allargare il lago
## significa cambiare un numero qui.
##
## Coordinate in metri; il centro dell'isola è (0, 0); -Z è il nord.

const ISLAND_RADIUS: float = 950.0
const SEA_LEVEL: float = 0.0
## Sotto questa profondità l'acqua è "profonda": Gioia non ci entra (D-13).
const DEEP_WATER: float = -0.7

## Zone: id, centro (x, z), raggio, chiave del nome.
const ZONES: Array[Dictionary] = [
	{"id": &"village", "center": Vector2(0, 60), "radius": 120.0, "name_key": "ZONE_VILLAGE"},
	{"id": &"countryside", "center": Vector2(330, 120), "radius": 230.0, "name_key": "ZONE_COUNTRYSIDE"},
	{"id": &"forest", "center": Vector2(-360, -40), "radius": 280.0, "name_key": "ZONE_FOREST"},
	{"id": &"lake", "center": Vector2(260, -260), "radius": 150.0, "name_key": "ZONE_LAKE"},
	{"id": &"mountain", "center": Vector2(-40, -620), "radius": 300.0, "name_key": "ZONE_MOUNTAIN"},
	{"id": &"meadows", "center": Vector2(-120, 450), "radius": 260.0, "name_key": "ZONE_MEADOWS"},
	{"id": &"beach", "center": Vector2(0, 0), "radius": 0.0, "name_key": "ZONE_BEACH"},
]

## Aree spianate: centro, raggio, quota. (Villaggio, casa di Gioia, fattoria.)
const FLAT_AREAS: Array[Dictionary] = [
	{"center": Vector2(0, 60), "radius": 75.0, "height": 6.0},
	{"center": Vector2(-70, 135), "radius": 32.0, "height": 6.5},
	{"center": Vector2(300, 140), "radius": 55.0, "height": 7.0},
]

## Lago: conca scavata sotto il livello del mare.
const LAKE_CENTER: Vector2 = Vector2(260, -260)
const LAKE_RADIUS: float = 95.0

## Sentieri (polilinee) che collegano le zone.
static var PATHS: Array[PackedVector2Array] = [
	PackedVector2Array([Vector2(0, 60), Vector2(-40, 100), Vector2(-70, 135)]),
	PackedVector2Array([Vector2(0, 60), Vector2(120, 90), Vector2(220, 120), Vector2(300, 140)]),
	PackedVector2Array([Vector2(0, 60), Vector2(-120, 40), Vector2(-250, 0), Vector2(-360, -40)]),
	PackedVector2Array([Vector2(0, 60), Vector2(60, -60), Vector2(160, -180), Vector2(230, -230)]),
	PackedVector2Array([Vector2(0, 60), Vector2(-20, -150), Vector2(-40, -380)]),
	PackedVector2Array([Vector2(0, 60), Vector2(-40, 250), Vector2(-120, 450)]),
	PackedVector2Array([Vector2(0, 60), Vector2(80, 300), Vector2(120, 640), Vector2(130, 820)]),
]
const PATH_HALF_WIDTH: float = 2.2

## Casa di Gioia (il vecchio rifugio della nonna, D-12) e punto di partenza.
const HOME_POSITION: Vector2 = Vector2(-70, 135)
const PLAYER_START: Vector2 = Vector2(-62, 122)


static func zone_at(p: Vector2) -> StringName:
	var best: StringName = &"meadows"
	var best_score: float = INF
	for z: Dictionary in ZONES:
		var r: float = float(z["radius"])
		if r <= 0.0:
			continue
		var score: float = p.distance_to(z["center"] as Vector2) / r
		if score < best_score:
			best_score = score
			best = z["id"]
	return best


static func zone_name_key(zone_id: StringName) -> String:
	for z: Dictionary in ZONES:
		if z["id"] == zone_id:
			return str(z["name_key"])
	return ""


## Distanza dal sentiero più vicino.
static func distance_to_path(p: Vector2) -> float:
	var best: float = INF
	for line: PackedVector2Array in PATHS:
		for i: int in line.size() - 1:
			best = minf(best, _segment_distance(p, line[i], line[i + 1]))
	return best


static func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)
