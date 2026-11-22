extends TestCase


func _dog() -> SpeciesDefinition:
	var s: SpeciesDefinition = SpeciesDefinition.new()
	s.id = &"dog"
	s.friendship_to_adopt = 60
	s.adoption_visit_days = 1
	return s


func _friend(reg: AnimalRegistry, id: String) -> AnimalState:
	var a: AnimalState = reg.ensure(StringName(id), &"dog")
	a.friendship = 80.0
	a.record_visit(1)
	return a


func test_sanitize_name() -> void:
	assert_eq(Adoption.sanitize_name("  biscotto  "), "Biscotto")
	assert_eq(Adoption.sanitize_name("a   b"), "A b")
	assert_eq(Adoption.sanitize_name("   "), "")
	assert_eq(Adoption.sanitize_name("x".repeat(40)).length(), Adoption.MAX_NAME_LENGTH)


func test_adopt_sets_name_and_home() -> void:
	var reg: AnimalRegistry = AnimalRegistry.new()
	var a: AnimalState = _friend(reg, "d1")
	assert_true(Adoption.adopt(a, _dog(), "biscotto", 2))
	assert_true(a.adopted)
	assert_eq(a.given_name, "Biscotto")
	assert_eq(a.adopted_day, 2)
	assert_eq(a.location, AnimalState.Location.HOME)
	assert_eq(reg.adopted().size(), 1)


func test_cannot_adopt_without_name_or_friendship() -> void:
	var reg: AnimalRegistry = AnimalRegistry.new()
	var a: AnimalState = _friend(reg, "d1")
	assert_false(Adoption.adopt(a, _dog(), "  ", 1), "serve un nome")
	a.friendship = 10.0
	assert_false(Adoption.adopt(a, _dog(), "Fido", 1), "serve amicizia")
	assert_false(a.adopted)


func test_cannot_adopt_twice() -> void:
	var reg: AnimalRegistry = AnimalRegistry.new()
	var a: AnimalState = _friend(reg, "d1")
	assert_true(Adoption.adopt(a, _dog(), "Fido", 1))
	assert_false(Adoption.adopt(a, _dog(), "Rex", 1))
	assert_eq(a.given_name, "Fido")


func test_max_three_companions() -> void:
	var reg: AnimalRegistry = AnimalRegistry.new()
	var animals: Array[AnimalState] = []
	for i: int in 5:
		var a: AnimalState = _friend(reg, "d%d" % i)
		Adoption.adopt(a, _dog(), "Cane %d" % i, 1)
		animals.append(a)
	for i: int in 3:
		assert_eq(Adoption.set_companion(reg, animals[i], true), Adoption.CompanionResult.OK)
	assert_eq(Adoption.set_companion(reg, animals[3], true), Adoption.CompanionResult.TOO_MANY, "D-04: massimo 3")
	assert_eq(reg.companions().size(), 3)
	assert_eq(Adoption.set_companion(reg, animals[0], false), Adoption.CompanionResult.OK)
	assert_eq(Adoption.set_companion(reg, animals[3], true), Adoption.CompanionResult.OK, "liberato un posto")


func test_adoption_is_unlimited() -> void:
	var reg: AnimalRegistry = AnimalRegistry.new()
	for i: int in 150:
		Adoption.adopt(_friend(reg, "d%d" % i), _dog(), "Cane", 1)
	assert_eq(reg.adopted().size(), 150, "nessun limite rigido alle adozioni")


func test_sick_or_wild_cannot_follow() -> void:
	var reg: AnimalRegistry = AnimalRegistry.new()
	var wild: AnimalState = _friend(reg, "w")
	assert_eq(Adoption.set_companion(reg, wild, true), Adoption.CompanionResult.NOT_ADOPTED)
	var sick: AnimalState = _friend(reg, "s")
	Adoption.adopt(sick, _dog(), "Malato", 1)
	sick.health = AnimalState.Health.SICK
	assert_eq(Adoption.set_companion(reg, sick, true), Adoption.CompanionResult.SICK)
