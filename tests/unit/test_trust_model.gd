extends TestCase


func _dog() -> SpeciesDefinition:
	var s: SpeciesDefinition = SpeciesDefinition.new()
	s.id = &"dog"
	s.favorite_foods = PackedStringArray(["kibble"])
	s.accepted_foods = PackedStringArray(["apple"])
	s.friendship_to_adopt = 60
	s.adoption_visit_days = 1
	return s


func _fox() -> SpeciesDefinition:
	var s: SpeciesDefinition = _dog()
	s.id = &"fox"
	s.wild = true
	s.shyness = 0.85
	s.comfort_distance = 5.0
	s.friendship_to_adopt = 90
	s.adoption_visit_days = 3
	s.trust_gain_multiplier = 0.6
	return s


func test_petting_increases_friendship() -> void:
	var st: AnimalState = AnimalState.new(&"a", &"dog")
	var r: TrustModel.Result = TrustModel.interact(st, _dog(), TrustModel.Action.PET, 1)
	assert_gt(r.gain, 0.0)
	assert_almost_eq(st.friendship, TrustModel.BASE_GAIN[TrustModel.Action.PET] as float)


func test_repeating_same_action_gives_less() -> void:
	var st: AnimalState = AnimalState.new(&"a", &"dog")
	var g1: float = TrustModel.interact(st, _dog(), TrustModel.Action.PET, 1).gain
	var g2: float = TrustModel.interact(st, _dog(), TrustModel.Action.PET, 1).gain
	assert_lt(g2, g1, "rendimenti decrescenti")


func test_daily_limit_then_reset_next_day() -> void:
	var st: AnimalState = AnimalState.new(&"a", &"dog")
	for i: int in TrustModel.MAX_REPEATS_PER_DAY:
		TrustModel.interact(st, _dog(), TrustModel.Action.PET, 1)
	var tired: TrustModel.Result = TrustModel.interact(st, _dog(), TrustModel.Action.PET, 1)
	assert_eq(tired.reaction, TrustModel.Reaction.TIRED)
	assert_almost_eq(tired.gain, 0.0)
	var next_day: TrustModel.Result = TrustModel.interact(st, _dog(), TrustModel.Action.PET, 2)
	assert_gt(next_day.gain, 0.0, "il giorno dopo l'azione rende di nuovo")


func test_favorite_food_doubles_gain() -> void:
	var a: AnimalState = AnimalState.new(&"a", &"dog")
	var b: AnimalState = AnimalState.new(&"b", &"dog")
	var fav: float = TrustModel.interact(a, _dog(), TrustModel.Action.FEED, 1, 2).gain
	var ok: float = TrustModel.interact(b, _dog(), TrustModel.Action.FEED, 1, 1).gain
	assert_almost_eq(fav, ok * TrustModel.FAVORITE_FOOD_MULTIPLIER)


func test_refused_food_gives_nothing() -> void:
	var st: AnimalState = AnimalState.new(&"a", &"dog")
	var r: TrustModel.Result = TrustModel.interact(st, _dog(), TrustModel.Action.FEED, 1, 0)
	assert_eq(r.reaction, TrustModel.Reaction.REFUSED)
	assert_almost_eq(st.friendship, 0.0)


func test_feeding_fills_hunger() -> void:
	var st: AnimalState = AnimalState.new(&"a", &"dog")
	st.hunger = 0.2
	TrustModel.interact(st, _dog(), TrustModel.Action.FEED, 1, 1)
	assert_gt(st.hunger, 0.5)


func test_wild_animals_gain_slower() -> void:
	var d: AnimalState = AnimalState.new(&"d", &"dog")
	var f: AnimalState = AnimalState.new(&"f", &"fox")
	var gd: float = TrustModel.interact(d, _dog(), TrustModel.Action.PET, 1).gain
	var gf: float = TrustModel.interact(f, _fox(), TrustModel.Action.PET, 1).gain
	assert_lt(gf, gd, "D-16: i selvatici sono più difficili")


func test_dog_adoptable_after_enough_friendship() -> void:
	var st: AnimalState = AnimalState.new(&"a", &"dog")
	assert_false(TrustModel.can_adopt(st, _dog()))
	st.friendship = 60.0
	st.record_visit(1)
	assert_true(TrustModel.can_adopt(st, _dog()))


func test_fox_needs_three_different_days() -> void:
	var st: AnimalState = AnimalState.new(&"f", &"fox")
	st.friendship = 95.0
	st.record_visit(1)
	st.record_visit(1)
	st.record_visit(2)
	assert_false(TrustModel.can_adopt(st, _fox()), "solo 2 giorni")
	assert_eq(int(TrustModel.adoption_progress(st, _fox())["days_missing"]), 1)
	st.record_visit(5)
	assert_true(TrustModel.can_adopt(st, _fox()))


func test_shy_animal_keeps_distance_until_trusted() -> void:
	var st: AnimalState = AnimalState.new(&"f", &"fox")
	assert_false(TrustModel.tolerates_distance(st, _fox(), 2.0), "da sconosciuta tiene le distanze")
	assert_true(TrustModel.tolerates_distance(st, _fox(), 6.0))
	st.friendship = 45.0  # metà della soglia di adozione
	assert_true(TrustModel.tolerates_distance(st, _fox(), 0.5), "con la fiducia si lascia avvicinare")


func test_startle_reduces_friendship_of_shy_animals() -> void:
	var st: AnimalState = AnimalState.new(&"f", &"fox")
	st.friendship = 10.0
	TrustModel.startle(st, _fox())
	assert_lt(st.friendship, 10.0)


func test_friendship_is_capped() -> void:
	var st: AnimalState = AnimalState.new(&"a", &"dog")
	st.friendship = 99.0
	TrustModel.interact(st, _dog(), TrustModel.Action.PLAY, 1)
	assert_almost_eq(st.friendship, 100.0)
	assert_eq(st.hearts(), 5)
