class_name AnimalRegistry
extends RefCounted
## Registro di tutti gli animali conosciuti: fonte unica di verità per
## adozioni, diario e salvataggi. Gli animali selvatici senza alcun rapporto
## non sono registrati (vengono generati e rilasciati dal mondo).

signal animal_added(state: AnimalState)

var _animals: Dictionary = {}  # StringName -> AnimalState
var _next_serial: int = 1


func has(animal_id: StringName) -> bool:
	return _animals.has(animal_id)


func get_animal(animal_id: StringName) -> AnimalState:
	return _animals.get(animal_id) as AnimalState


## Restituisce lo stato esistente oppure lo crea.
func ensure(animal_id: StringName, species_id: StringName, variant: int = 0) -> AnimalState:
	if _animals.has(animal_id):
		return _animals[animal_id] as AnimalState
	var s: AnimalState = AnimalState.new(animal_id, species_id)
	s.variant = variant
	_animals[animal_id] = s
	animal_added.emit(s)
	return s


## Registra uno stato creato altrove (animale selvatico con cui nasce un rapporto).
func add(state: AnimalState) -> void:
	if state.id == &"" or _animals.has(state.id):
		return
	_animals[state.id] = state
	animal_added.emit(state)


## Genera un nuovo ID univoco e stabile per un animale.
func new_id(species_id: StringName) -> StringName:
	var id: StringName = StringName("%s_%04d" % [species_id, _next_serial])
	_next_serial += 1
	while _animals.has(id):
		id = StringName("%s_%04d" % [species_id, _next_serial])
		_next_serial += 1
	return id


func all() -> Array[AnimalState]:
	var out: Array[AnimalState] = []
	for s: AnimalState in _animals.values():
		out.append(s)
	return out


func adopted() -> Array[AnimalState]:
	var out: Array[AnimalState] = []
	for s: AnimalState in _animals.values():
		if s.adopted:
			out.append(s)
	return out


func companions() -> Array[AnimalState]:
	var out: Array[AnimalState] = []
	for s: AnimalState in _animals.values():
		if s.adopted and s.location == AnimalState.Location.COMPANION and s.is_alive():
			out.append(s)
	return out


func to_dict() -> Dictionary:
	var list: Array = []
	for s: AnimalState in _animals.values():
		list.append(s.to_dict())
	return {"next_serial": _next_serial, "animals": list}


func from_dict(d: Dictionary) -> void:
	_animals.clear()
	_next_serial = int(d.get("next_serial", 1))
	for entry: Variant in d.get("animals", []) as Array:
		var s: AnimalState = AnimalState.from_dict(entry as Dictionary)
		if s.id != &"":
			_animals[s.id] = s
