extends Node
## Servizio che si occupa degli animali adottati: aggiorna bisogni e salute
## a ogni ora di gioco (anche per gli animali non presenti nella scena),
## gestisce adozioni, compagni e cure, e avvisa il giocatore.

const LOW_NEED_KEYS: Dictionary = {"hunger": "NOTIFY_NEED_HUNGER", "happiness": "NOTIFY_NEED_HAPPINESS", "cleanliness": "NOTIFY_NEED_CLEAN"}


func _ready() -> void:
	GameClock.hour_changed.connect(func(_d: int, _h: int) -> void: tick())
	GameClock.day_started.connect(func(_d: int) -> void: produce())


## Aggiorna tutti gli animali adottati fino all'ora attuale.
func tick() -> void:
	var now: float = GameClock.time.get_total_minutes()
	# Prima la mangiatoia automatica (D-37), poi l'aggiornamento di bisogni e salute.
	Feeder.feed_hungry_animals()
	_caretaker()
	_companion_finds()
	GameState.garden.update(now)
	# La pioggia annaffia l'orto (D-07).
	if WeatherModel.is_raining(GameClock.time.get_day(), GameClock.time.get_hour()):
		for i: int in GameState.garden.plots.size():
			if not GameState.garden.is_empty(i) and not GameState.garden.is_ready(i):
				GameState.garden.water(i, now)
	for state: AnimalState in GameState.animals.adopted():
		var species: SpeciesDefinition = Database.species(state.species_id)
		if species == null:
			continue
		var events: Array[AnimalHealth.Event] = AnimalHealth.update(state, species, now, GameState.serene_mode)
		for e: AnimalHealth.Event in events:
			_announce(state, e, now)


## Il custode (sbloccato con una missione, D-37) passa ogni ora a coccolare e
## spazzolare gli animali che vivono a casa: felicità e pulizia non scendono
## sotto la metà. La fame resta compito di Gioia (o della mangiatoia).
func _caretaker() -> void:
	if not bool(GameState.flags.get("caretaker", false)):
		return
	for state: AnimalState in GameState.animals.adopted():
		if state.is_alive() and state.location == AnimalState.Location.HOME:
			state.happiness = maxf(state.happiness, 0.5)
			state.cleanliness = maxf(state.cleanliness, 0.5)


## Ogni mattina gli animali da fattoria adottati, sani e a casa regalano
## uova, latte o lana (D-24). Restituisce quanti oggetti sono stati prodotti.
func produce() -> int:
	var n: int = 0
	for state: AnimalState in GameState.animals.adopted():
		var species: SpeciesDefinition = Database.species(state.species_id)
		if species == null or species.produce_item == &"" or not state.is_alive():
			continue
		if state.health != AnimalState.Health.HEALTHY or state.location != AnimalState.Location.HOME or state.hunger < 0.2:
			continue
		GameState.inventory.add(species.produce_item)
		var def: ItemDefinition = Database.item(species.produce_item)
		EventBus.notification_requested.emit(tr("NOTIFY_PRODUCE") % [state.given_name, tr(def.name_key) if def != null else ""])
		n += 1
	return n


## Abilità dei compagni (D-18): ogni ora, chi segue Gioia ha una possibilità
## su tre di trovare il suo oggetto preferito (fiori, bacche, noci, pesce…).
func _companion_finds(chance: float = 0.33) -> void:
	for state: AnimalState in GameState.animals.companions():
		var species: SpeciesDefinition = Database.species(state.species_id)
		if species == null or species.companion_item == &"" or randf() > chance:
			continue
		GameState.inventory.add(species.companion_item)
		var def: ItemDefinition = Database.item(species.companion_item)
		EventBus.notification_requested.emit(tr("NOTIFY_COMPANION_FOUND") % [state.given_name, tr(def.name_key) if def != null else ""])


func adopt(state: AnimalState, raw_name: String) -> bool:
	var species: SpeciesDefinition = Database.species(state.species_id)
	if species == null or not Adoption.adopt(state, species, raw_name, GameState.current_day()):
		return false
	state.last_update_minutes = GameClock.time.get_total_minutes()
	EventBus.animal_adopted.emit(state.id, state.species_id)
	EventBus.notification_requested.emit(tr("NOTIFY_ADOPTED") % state.given_name)
	EventBus.companions_changed.emit()
	return true


func set_companion(state: AnimalState, follow: bool) -> Adoption.CompanionResult:
	var result: Adoption.CompanionResult = Adoption.set_companion(GameState.animals, state, follow)
	match result:
		Adoption.CompanionResult.OK:
			var key: String = "NOTIFY_FOLLOWS" if follow else "NOTIFY_GOES_HOME"
			EventBus.notification_requested.emit(tr(key) % state.given_name)
			EventBus.companions_changed.emit()
		Adoption.CompanionResult.TOO_MANY:
			EventBus.notification_requested.emit(tr("NOTIFY_TOO_MANY_COMPANIONS") % Adoption.MAX_COMPANIONS)
		Adoption.CompanionResult.SICK:
			EventBus.notification_requested.emit(tr("NOTIFY_SICK_CANNOT_FOLLOW") % state.given_name)
	return result


## Usa una medicina sull'animale malato.
func give_medicine(state: AnimalState) -> bool:
	var species: SpeciesDefinition = Database.species(state.species_id)
	if species == null or state.health != AnimalState.Health.SICK or not GameState.inventory.has(&"medicine"):
		return false
	if not AnimalHealth.cure(state, species, GameClock.time.get_total_minutes(), GameState.serene_mode):
		return false
	GameState.inventory.try_remove(&"medicine")
	EventBus.notification_requested.emit(tr("NOTIFY_CURED") % state.given_name)
	EventBus.gameplay_event.emit("cure", state.species_id, 1)
	EventBus.animal_health_changed.emit(state.id, state.health)
	return true


func _announce(state: AnimalState, e: AnimalHealth.Event, now: float) -> void:
	match e:
		AnimalHealth.Event.NEED_LOW:
			var need: String = "hunger"
			if state.happiness <= state.hunger and state.happiness <= state.cleanliness:
				need = "happiness"
			elif state.cleanliness <= state.hunger:
				need = "cleanliness"
			EventBus.notification_requested.emit(tr(String(LOW_NEED_KEYS[need])) % state.given_name)
		AnimalHealth.Event.FELL_SICK:
			if state.location == AnimalState.Location.COMPANION:
				state.location = AnimalState.Location.HOME
				EventBus.companions_changed.emit()
			EventBus.notification_requested.emit(tr("NOTIFY_FELL_SICK") % state.given_name)
			EventBus.animal_health_changed.emit(state.id, state.health)
		AnimalHealth.Event.SICK_WORSE:
			EventBus.notification_requested.emit(tr("NOTIFY_SICK_DAY") % [state.given_name, AnimalHealth.sick_day(state, now)])
		AnimalHealth.Event.DIED:
			if state.location == AnimalState.Location.COMPANION:
				state.location = AnimalState.Location.HOME
				EventBus.companions_changed.emit()
			EventBus.notification_requested.emit(tr("NOTIFY_DIED") % state.given_name)
			EventBus.animal_health_changed.emit(state.id, state.health)
		AnimalHealth.Event.RECOVERED:
			EventBus.notification_requested.emit(tr("NOTIFY_RECOVERED") % state.given_name)
			EventBus.animal_health_changed.emit(state.id, state.health)
