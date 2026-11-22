extends Node
## Catalogo dei contenuti di gioco caricati da `data/`: specie e oggetti.
## Accesso per ID stabile: `Database.species(&"dog")`, `Database.item(&"kibble")`.

const SPECIES_DIR: String = "res://data/species"
const ITEMS_DIR: String = "res://data/items"

var _species: Dictionary = {}
var _items: Dictionary = {}


func _ready() -> void:
	for res: Resource in _load_all(SPECIES_DIR):
		var s: SpeciesDefinition = res as SpeciesDefinition
		if s != null:
			_species[s.id] = s
	for res: Resource in _load_all(ITEMS_DIR):
		var it: ItemDefinition = res as ItemDefinition
		if it != null:
			_items[it.id] = it


func species(id: StringName) -> SpeciesDefinition:
	return _species.get(id) as SpeciesDefinition


func item(id: StringName) -> ItemDefinition:
	return _items.get(id) as ItemDefinition


func all_species() -> Array[SpeciesDefinition]:
	var out: Array[SpeciesDefinition] = []
	for s: SpeciesDefinition in _species.values():
		out.append(s)
	out.sort_custom(func(a: SpeciesDefinition, b: SpeciesDefinition) -> bool: return String(a.id) < String(b.id))
	return out


func all_items() -> Array[ItemDefinition]:
	var out: Array[ItemDefinition] = []
	for it: ItemDefinition in _items.values():
		out.append(it)
	return out


func _load_all(dir: String) -> Array[Resource]:
	var out: Array[Resource] = []
	# list_directory gestisce anche i file rimappati nelle build esportate.
	for file: String in ResourceLoader.list_directory(dir):
		if file.ends_with(".tres") or file.ends_with(".res"):
			var res: Resource = load(dir.path_join(file))
			if res != null:
				out.append(res)
	return out
