class_name AnimalHealth
extends RefCounted
## Bisogni e salute degli animali adottati (D-17, D-35, D-38, D-40). Logica pura.
##
## - I bisogni (fame, felicità, pulizia) calano con il tempo di gioco.
## - Se un bisogno resta a zero per troppe ore, l'animale si ammala.
## - Da malato, senza cure, muore dopo 3 giorni di gioco (in Modalità serena no).
## - Curato, passa un periodo di convalescenza e poi torna sano.
## Funziona anche con salti di tempo grandi (animali "virtuali" a casa,
## dormire), avanzando a passi di un'ora.

## Cosa è successo durante un aggiornamento (per notifiche e diario).
enum Event { NONE, NEED_LOW, FELL_SICK, SICK_WORSE, DIED, RECOVERED }

const NEGLECT_THRESHOLD: float = 0.02
const LOW_NEED_WARNING: float = 0.25
const DAYS_SICK_BEFORE_DEATH: float = 3.0
const CONVALESCENCE_HOURS: float = 12.0
const MINUTES_PER_DAY: float = 1440.0
## I compagni a passeggio con Gioia sono più felici.
const COMPANION_HAPPINESS_FACTOR: float = 0.4


## Avanza lo stato fino a `now_minutes`. Restituisce gli eventi accaduti.
static func update(state: AnimalState, species: SpeciesDefinition, now_minutes: float, serene_mode: bool) -> Array[Event]:
	var events: Array[Event] = []
	if not state.adopted or not state.is_alive():
		state.last_update_minutes = now_minutes
		return events
	if state.last_update_minutes < 0.0:
		state.last_update_minutes = now_minutes
		return events
	var was_low: bool = lowest_need(state) < LOW_NEED_WARNING
	while state.last_update_minutes < now_minutes and state.is_alive():
		var step_minutes: float = minf(60.0, now_minutes - state.last_update_minutes)
		state.last_update_minutes += step_minutes
		_step(state, species, step_minutes / 60.0, state.last_update_minutes, serene_mode, events)
	if not was_low and lowest_need(state) < LOW_NEED_WARNING and state.is_alive():
		events.append(Event.NEED_LOW)
	return events


## Cura l'animale malato (medicina o veterinario). Prima porta lo stato
## all'ora attuale, così il tempo trascorso non viene simulato dopo la cura.
static func cure(state: AnimalState, species: SpeciesDefinition, now_minutes: float, serene_mode: bool) -> bool:
	update(state, species, now_minutes, serene_mode)
	if state.health != AnimalState.Health.SICK:
		return false
	state.health = AnimalState.Health.CONVALESCENT
	state.convalescent_until_minutes = now_minutes + CONVALESCENCE_HOURS * 60.0
	state.sick_since_minutes = -1.0
	state.neglected_hours = 0.0
	state.hunger = maxf(state.hunger, 0.5)
	state.happiness = maxf(state.happiness, 0.5)
	state.cleanliness = maxf(state.cleanliness, 0.5)
	return true


## Giorno di malattia corrente (1, 2, 3) o 0 se sano.
static func sick_day(state: AnimalState, now_minutes: float) -> int:
	if state.health != AnimalState.Health.SICK:
		return 0
	return int(floor((now_minutes - state.sick_since_minutes) / MINUTES_PER_DAY)) + 1


static func lowest_need(state: AnimalState) -> float:
	return minf(state.hunger, minf(state.happiness, state.cleanliness))


static func _step(state: AnimalState, species: SpeciesDefinition, hours: float, now: float, serene: bool, events: Array[Event]) -> void:
	var happiness_decay: float = species.happiness_decay_per_hour
	if state.location == AnimalState.Location.COMPANION:
		happiness_decay *= COMPANION_HAPPINESS_FACTOR
	state.hunger = maxf(0.0, state.hunger - species.hunger_decay_per_hour * hours)
	state.happiness = maxf(0.0, state.happiness - happiness_decay * hours)
	state.cleanliness = maxf(0.0, state.cleanliness - species.cleanliness_decay_per_hour * hours)

	if lowest_need(state) <= NEGLECT_THRESHOLD:
		state.neglected_hours += hours
	else:
		state.neglected_hours = maxf(0.0, state.neglected_hours - hours * 2.0)

	match state.health:
		AnimalState.Health.HEALTHY:
			if state.neglected_hours >= species.hours_neglected_before_sickness:
				state.health = AnimalState.Health.SICK
				state.sick_since_minutes = now
				events.append(Event.FELL_SICK)
		AnimalState.Health.SICK:
			var days: float = (now - state.sick_since_minutes) / MINUTES_PER_DAY
			if days >= DAYS_SICK_BEFORE_DEATH:
				if serene:
					# Modalità serena (D-38): resta malato ma non muore.
					state.sick_since_minutes = now - (DAYS_SICK_BEFORE_DEATH - 0.01) * MINUTES_PER_DAY
				else:
					state.health = AnimalState.Health.DEAD
					events.append(Event.DIED)
			elif int(floor(days)) > int(floor((now - hours * 60.0 - state.sick_since_minutes) / MINUTES_PER_DAY)):
				events.append(Event.SICK_WORSE)
		AnimalState.Health.CONVALESCENT:
			if now >= state.convalescent_until_minutes:
				state.health = AnimalState.Health.HEALTHY
				state.convalescent_until_minutes = -1.0
				events.append(Event.RECOVERED)
