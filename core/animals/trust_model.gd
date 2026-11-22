class_name TrustModel
extends RefCounted
## Regole dell'amicizia tra Gioia e un animale (logica pura).
##
## - Ogni azione dà amicizia; ripeterla nello stesso giorno rende sempre meno
##   (così conviene tornare a trovare l'animale in giorni diversi).
## - Il cibo preferito vale il doppio, quello non gradito viene rifiutato.
## - Gli animali selvatici guadagnano amicizia più lentamente (D-16).
## - Spaventare un animale timido (correndogli addosso) fa perdere amicizia.

enum Action { PET, FEED, PLAY, BRUSH }
enum Reaction { HAPPY, VERY_HAPPY, REFUSED, TIRED }

const BASE_GAIN: Dictionary = {
	Action.PET: 4.0,
	Action.FEED: 6.0,
	Action.PLAY: 7.0,
	Action.BRUSH: 5.0,
}
const FAVORITE_FOOD_MULTIPLIER: float = 2.0
## Oltre questo numero di ripetizioni nello stesso giorno l'azione non dà più amicizia.
const MAX_REPEATS_PER_DAY: int = 4
const STARTLE_PENALTY: float = 3.0


## Risultato di un'interazione.
class Result:
	var gain: float = 0.0
	var reaction: Reaction = Reaction.HAPPY


## Applica un'interazione allo stato e restituisce il risultato.
## `food_preference`: 2 preferito, 1 accettato, 0 rifiutato (solo per FEED).
static func interact(state: AnimalState, species: SpeciesDefinition, action: Action, day: int, food_preference: int = 1, bonus: float = 1.0) -> Result:
	var result: Result = Result.new()
	if not state.is_alive():
		result.reaction = Reaction.TIRED
		return result
	_roll_day(state, day)
	state.record_visit(day)

	if action == Action.FEED and food_preference <= 0:
		result.reaction = Reaction.REFUSED
		return result

	var key: String = str(action)
	var repeats: int = int(state.interactions_today.get(key, 0))
	state.interactions_today[key] = repeats + 1
	if repeats >= MAX_REPEATS_PER_DAY:
		result.reaction = Reaction.TIRED
		return result

	var gain: float = float(BASE_GAIN[action]) / (1.0 + repeats)
	if action == Action.FEED and food_preference >= 2:
		gain *= FAVORITE_FOOD_MULTIPLIER
		result.reaction = Reaction.VERY_HAPPY
	gain *= species.trust_gain_multiplier * bonus
	state.friendship = clampf(state.friendship + gain, 0.0, AnimalState.MAX_FRIENDSHIP)
	result.gain = gain

	# Le cure soddisfano anche i bisogni.
	match action:
		Action.FEED:
			state.hunger = minf(1.0, state.hunger + (0.6 if food_preference >= 2 else 0.4))
		Action.PET:
			state.happiness = minf(1.0, state.happiness + 0.15)
		Action.PLAY:
			state.happiness = minf(1.0, state.happiness + 0.3)
		Action.BRUSH:
			state.cleanliness = minf(1.0, state.cleanliness + 0.5)
	return result


## Gioia ha spaventato l'animale (es. correndogli vicino).
static func startle(state: AnimalState, species: SpeciesDefinition) -> void:
	state.friendship = maxf(0.0, state.friendship - STARTLE_PENALTY * species.shyness)


## L'animale accetta di essere avvicinato a `distance` metri?
static func tolerates_distance(state: AnimalState, species: SpeciesDefinition, distance: float) -> bool:
	if species.comfort_distance <= 0.0 or state.adopted:
		return true
	# Con l'amicizia la distanza di sicurezza si riduce fino a zero (a metà della soglia di adozione).
	var trust_ratio: float = clampf(state.friendship / maxf(1.0, species.friendship_to_adopt * 0.5), 0.0, 1.0)
	return distance >= species.comfort_distance * (1.0 - trust_ratio)


## Condizioni di adozione (D-16).
static func can_adopt(state: AnimalState, species: SpeciesDefinition) -> bool:
	return state.is_alive() and not state.adopted \
		and state.friendship >= species.friendship_to_adopt \
		and state.visit_days.size() >= species.adoption_visit_days


## Spiega cosa manca per adottare (per l'interfaccia): {friendship_missing, days_missing}.
static func adoption_progress(state: AnimalState, species: SpeciesDefinition) -> Dictionary:
	return {
		"friendship_missing": maxf(0.0, species.friendship_to_adopt - state.friendship),
		"days_missing": maxi(0, species.adoption_visit_days - state.visit_days.size()),
	}


static func _roll_day(state: AnimalState, day: int) -> void:
	if state.interactions_day != day:
		state.interactions_day = day
		state.interactions_today.clear()
