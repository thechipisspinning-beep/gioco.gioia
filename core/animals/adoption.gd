class_name Adoption
extends RefCounted
## Regole di adozione e dei compagni al seguito (D-04, D-16). Logica pura.

const MAX_COMPANIONS: int = 3
const MAX_NAME_LENGTH: int = 16

enum CompanionResult { OK, TOO_MANY, NOT_ADOPTED, SICK, DEAD }


## Pulisce il nome scelto dal giocatore: spazi, lunghezza, maiuscola iniziale.
static func sanitize_name(raw: String) -> String:
	var n: String = raw.strip_edges().replace("\n", " ").replace("\t", " ")
	while n.contains("  "):
		n = n.replace("  ", " ")
	if n.length() > MAX_NAME_LENGTH:
		n = n.substr(0, MAX_NAME_LENGTH).strip_edges()
	if n.length() > 0:
		n = n.substr(0, 1).to_upper() + n.substr(1)
	return n


## Adotta l'animale con il nome dato. Restituisce false se non è possibile.
static func adopt(state: AnimalState, species: SpeciesDefinition, raw_name: String, day: int) -> bool:
	var n: String = sanitize_name(raw_name)
	if n.is_empty() or not TrustModel.can_adopt(state, species):
		return false
	state.given_name = n
	state.adopted = true
	state.adopted_day = day
	state.location = AnimalState.Location.HOME
	state.last_update_minutes = -1.0
	return true


## Fa seguire Gioia all'animale (o lo rimanda a casa).
static func set_companion(registry: AnimalRegistry, state: AnimalState, follow: bool) -> CompanionResult:
	if not state.adopted:
		return CompanionResult.NOT_ADOPTED
	if not state.is_alive():
		return CompanionResult.DEAD
	if not follow:
		state.location = AnimalState.Location.HOME
		return CompanionResult.OK
	if state.location == AnimalState.Location.COMPANION:
		return CompanionResult.OK
	if state.health == AnimalState.Health.SICK:
		return CompanionResult.SICK
	if registry.companions().size() >= MAX_COMPANIONS:
		return CompanionResult.TOO_MANY
	state.location = AnimalState.Location.COMPANION
	return CompanionResult.OK
