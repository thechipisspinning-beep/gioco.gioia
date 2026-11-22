extends TestCase

const DAY: float = 1440.0


func _species() -> SpeciesDefinition:
	var s: SpeciesDefinition = SpeciesDefinition.new()
	s.id = &"dog"
	s.hunger_decay_per_hour = 0.05      # da pieno a vuoto in 20 ore
	s.happiness_decay_per_hour = 0.01
	s.cleanliness_decay_per_hour = 0.01
	s.hours_neglected_before_sickness = 12.0
	return s


func _adopted() -> AnimalState:
	var a: AnimalState = AnimalState.new(&"d1", &"dog")
	a.adopted = true
	a.location = AnimalState.Location.HOME
	a.last_update_minutes = 0.0
	return a


func test_needs_decay_over_time() -> void:
	var a: AnimalState = _adopted()
	AnimalHealth.update(a, _species(), 10.0 * 60.0, false)
	assert_almost_eq(a.hunger, 0.5, 0.001, "10 ore → fame a metà")


func test_wild_animals_are_not_affected() -> void:
	var a: AnimalState = _adopted()
	a.adopted = false
	AnimalHealth.update(a, _species(), 10.0 * DAY, false)
	assert_almost_eq(a.hunger, 1.0)
	assert_eq(a.health, AnimalState.Health.HEALTHY, "D-40: solo gli adottati si ammalano")


func test_neglect_causes_sickness() -> void:
	var a: AnimalState = _adopted()
	# ~20 ore per svuotare la fame + 12 ore di trascuratezza = malato dopo ~31-32 ore.
	var events: Array = AnimalHealth.update(a, _species(), 30.0 * 60.0, false)
	assert_eq(a.health, AnimalState.Health.HEALTHY, "non ancora")
	events = AnimalHealth.update(a, _species(), 33.0 * 60.0, false)
	assert_eq(a.health, AnimalState.Health.SICK, "malato dopo 12 ore di trascuratezza")
	assert_true(events.has(AnimalHealth.Event.FELL_SICK))
	assert_eq(AnimalHealth.sick_day(a, 33.0 * 60.0), 1)


func test_sick_animal_dies_after_three_days() -> void:
	var a: AnimalState = _adopted()
	a.health = AnimalState.Health.SICK
	a.sick_since_minutes = 0.0
	a.hunger = 0.0
	AnimalHealth.update(a, _species(), 2.9 * DAY, false)
	assert_true(a.is_alive(), "vivo prima dei 3 giorni")
	var events: Array = AnimalHealth.update(a, _species(), 3.05 * DAY, false)
	assert_eq(a.health, AnimalState.Health.DEAD, "D-17: muore dopo 3 giorni senza cure")
	assert_true(events.has(AnimalHealth.Event.DIED))


func test_serene_mode_prevents_death() -> void:
	var a: AnimalState = _adopted()
	a.health = AnimalState.Health.SICK
	a.sick_since_minutes = 0.0
	AnimalHealth.update(a, _species(), 10.0 * DAY, true)
	assert_eq(a.health, AnimalState.Health.SICK, "D-38: in modalità serena resta malato ma non muore")
	assert_true(AnimalHealth.cure(a, _species(), 10.0 * DAY, true), "e si può ancora curare")


func test_cure_then_recover() -> void:
	var a: AnimalState = _adopted()
	a.health = AnimalState.Health.SICK
	a.sick_since_minutes = 0.0
	a.hunger = 0.0
	assert_true(AnimalHealth.cure(a, _species(), DAY, false))
	assert_eq(a.health, AnimalState.Health.CONVALESCENT)
	assert_gt(a.hunger, 0.4, "la cura ristora l'animale")
	var events: Array = AnimalHealth.update(a, _species(), DAY + 13.0 * 60.0, false)
	assert_eq(a.health, AnimalState.Health.HEALTHY)
	assert_true(events.has(AnimalHealth.Event.RECOVERED))


func test_cure_only_works_on_sick_animals() -> void:
	var a: AnimalState = _adopted()
	assert_false(AnimalHealth.cure(a, _species(), 0.0, false))


func test_caring_resets_neglect() -> void:
	var a: AnimalState = _adopted()
	AnimalHealth.update(a, _species(), 28.0 * 60.0, false)  # 8 ore di trascuratezza
	assert_gt(a.neglected_hours, 5.0)
	a.hunger = 1.0
	AnimalHealth.update(a, _species(), 34.0 * 60.0, false)
	assert_almost_eq(a.neglected_hours, 0.0, 0.001, "nutrito, la trascuratezza si azzera")
	assert_eq(a.health, AnimalState.Health.HEALTHY)


func test_low_need_warning_emitted_once() -> void:
	var a: AnimalState = _adopted()
	var events: Array = AnimalHealth.update(a, _species(), 16.0 * 60.0, false)  # fame 0.2
	assert_true(events.has(AnimalHealth.Event.NEED_LOW), "avviso quando un bisogno è basso")
	events = AnimalHealth.update(a, _species(), 17.0 * 60.0, false)
	assert_false(events.has(AnimalHealth.Event.NEED_LOW), "l'avviso non si ripete ogni ora")


func test_large_time_jump_is_consistent() -> void:
	# Un salto di 5 giorni in un colpo solo dà lo stesso risultato di tanti piccoli passi.
	var a: AnimalState = _adopted()
	var b: AnimalState = _adopted()
	AnimalHealth.update(a, _species(), 5.0 * DAY, false)
	var t: float = 0.0
	while t < 5.0 * DAY:
		t += 37.0
		AnimalHealth.update(b, _species(), minf(t, 5.0 * DAY), false)
	assert_eq(a.health, b.health)
	assert_eq(a.health, AnimalState.Health.DEAD, "5 giorni senza cure: 32 ore + 3 giorni")


func test_companions_stay_happier() -> void:
	var home: AnimalState = _adopted()
	var walk: AnimalState = _adopted()
	walk.location = AnimalState.Location.COMPANION
	AnimalHealth.update(home, _species(), 20.0 * 60.0, false)
	AnimalHealth.update(walk, _species(), 20.0 * 60.0, false)
	assert_gt(walk.happiness, home.happiness)
