class_name AnimalSpawner
extends RefCounted
## Crea gli animali nel mondo a partire dal registro (`GameState.animals`).
## Ogni punto di comparsa ha un ID stabile: lo stesso animale ricompare con
## la stessa amicizia e lo stesso aspetto dopo un caricamento.


## Crea (o ritrova) l'animale `animal_id` della specie data e lo aggiunge a `parent`.
## `register` = false: l'animale entra nel registro (e nei salvataggi) solo
## quando Gioia ci interagisce (simulazione a livelli, Architettura § 6.4).
static func spawn(parent: Node3D, animal_id: StringName, species_id: StringName, position: Vector3, register: bool = true) -> AnimalAgent:
	var species: SpeciesDefinition = Database.species(species_id)
	if species == null:
		push_error("Specie sconosciuta: %s" % species_id)
		return null
	var variant: int = absi(hash(String(animal_id))) % maxi(1, species.fur_colors.size())
	var state: AnimalState
	if register or GameState.animals.has(animal_id):
		state = GameState.animals.ensure(animal_id, species_id, variant)
	else:
		state = AnimalState.new(animal_id, species_id)
		state.variant = variant
	if not state.is_alive():
		return null
	var agent: AnimalAgent = AnimalAgent.new()
	agent.name = String(animal_id)
	agent.setup(species, state, position)
	agent.position = position
	parent.add_child(agent)
	return agent
