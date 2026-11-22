class_name DiscoveryLog
extends RefCounted
## Cosa Gioia ha scoperto: specie incontrate (con giorno e ora), luoghi, collezionabili.

signal species_discovered(species_id: StringName)

var _species: Dictionary = {}  # StringName -> {day, hour}
var _places: Dictionary = {}
var _favorites: Dictionary = {}  # "specie:oggetto" -> true


## Registra l'incontro; restituisce true se è la prima volta.
func mark_species_met(species_id: StringName, day: int, hour: int) -> bool:
	if _species.has(species_id):
		return false
	_species[species_id] = {"day": day, "hour": hour}
	species_discovered.emit(species_id)
	return true


func has_met(species_id: StringName) -> bool:
	return _species.has(species_id)


func species_met_info(species_id: StringName) -> Dictionary:
	return _species.get(species_id, {}) as Dictionary


func species_count() -> int:
	return _species.size()


func mark_place(place_id: StringName, day: int) -> bool:
	if _places.has(place_id):
		return false
	_places[place_id] = {"day": day}
	return true


func has_place(place_id: StringName) -> bool:
	return _places.has(place_id)


func to_dict() -> Dictionary:
	var sp: Dictionary = {}
	for k: StringName in _species.keys():
		sp[String(k)] = _species[k]
	var pl: Dictionary = {}
	for k: StringName in _places.keys():
		pl[String(k)] = _places[k]
	return {"species": sp, "places": pl, "favorites": _favorites.keys()}


func from_dict(d: Dictionary) -> void:
	_species.clear()
	_places.clear()
	_favorites.clear()
	for k: Variant in d.get("favorites", []) as Array:
		_favorites[str(k)] = true
	var sp: Dictionary = d.get("species", {}) as Dictionary
	for k: Variant in sp.keys():
		_species[StringName(str(k))] = sp[k]
	var pl: Dictionary = d.get("places", {}) as Dictionary
	for k: Variant in pl.keys():
		_places[StringName(str(k))] = pl[k]


## Registra che `item_id` è un cibo preferito di `species_id` (scoperto dando da mangiare).
func mark_favorite_food(species_id: StringName, item_id: StringName) -> bool:
	var key: String = "%s:%s" % [species_id, item_id]
	if _favorites.has(key):
		return false
	_favorites[key] = true
	return true


func known_favorite_foods(species_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var prefix: String = String(species_id) + ":"
	for k: String in _favorites.keys():
		if k.begins_with(prefix):
			out.append(StringName(k.trim_prefix(prefix)))
	return out
