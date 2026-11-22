extends TestCase


func test_inventory_add_remove() -> void:
	var inv: Inventory = Inventory.new()
	inv.add(&"kibble", 3)
	assert_eq(inv.count(&"kibble"), 3)
	assert_true(inv.try_remove(&"kibble", 2))
	assert_eq(inv.count(&"kibble"), 1)
	assert_false(inv.try_remove(&"kibble", 2), "non si può togliere più di quanto c'è")
	assert_eq(inv.count(&"kibble"), 1)
	assert_true(inv.try_remove(&"kibble"))
	assert_false(inv.item_ids().has(&"kibble"), "le voci a zero spariscono")


func test_inventory_ignores_invalid_amounts() -> void:
	var inv: Inventory = Inventory.new()
	inv.add(&"apple", -5)
	assert_eq(inv.count(&"apple"), 0)
	assert_false(inv.try_remove(&"apple", 0))


func test_inventory_roundtrip() -> void:
	var inv: Inventory = Inventory.new()
	inv.add(&"apple", 4)
	inv.add(&"ball")
	var copy: Inventory = Inventory.new()
	copy.from_dict(inv.to_dict())
	assert_eq(copy.count(&"apple"), 4)
	assert_eq(copy.count(&"ball"), 1)


func test_registry_ensure_is_idempotent() -> void:
	var reg: AnimalRegistry = AnimalRegistry.new()
	var a: AnimalState = reg.ensure(&"dog_1", &"dog", 2)
	a.friendship = 30.0
	var b: AnimalState = reg.ensure(&"dog_1", &"dog", 0)
	assert_true(a == b)
	assert_eq(b.variant, 2)


func test_registry_new_ids_are_unique() -> void:
	var reg: AnimalRegistry = AnimalRegistry.new()
	var ids: Dictionary = {}
	for i: int in 50:
		var id: StringName = reg.new_id(&"cat")
		reg.ensure(id, &"cat")
		ids[id] = true
	assert_eq(ids.size(), 50)


func test_registry_roundtrip_keeps_everything() -> void:
	var reg: AnimalRegistry = AnimalRegistry.new()
	var a: AnimalState = reg.ensure(&"dog_1", &"dog", 1)
	a.given_name = "Biscotto"
	a.friendship = 72.5
	a.adopted = true
	a.location = AnimalState.Location.COMPANION
	a.record_visit(1)
	a.record_visit(3)
	a.hunger = 0.4
	a.health = AnimalState.Health.SICK
	var copy: AnimalRegistry = AnimalRegistry.new()
	copy.from_dict(reg.to_dict())
	var b: AnimalState = copy.get_animal(&"dog_1")
	assert_eq(b.given_name, "Biscotto")
	assert_almost_eq(b.friendship, 72.5)
	assert_true(b.adopted)
	assert_eq(b.location, AnimalState.Location.COMPANION)
	assert_eq(b.visit_days.size(), 2)
	assert_almost_eq(b.hunger, 0.4)
	assert_eq(b.health, AnimalState.Health.SICK)
	assert_eq(copy.companions().size(), 1)


func test_discovery_first_time_only() -> void:
	var log: DiscoveryLog = DiscoveryLog.new()
	assert_true(log.mark_species_met(&"dog", 1, 9))
	assert_false(log.mark_species_met(&"dog", 2, 10))
	assert_eq(int(log.species_met_info(&"dog")["day"]), 1)
	var copy: DiscoveryLog = DiscoveryLog.new()
	copy.from_dict(log.to_dict())
	assert_true(copy.has_met(&"dog"))


func test_database_loads_species_and_items() -> void:
	var dog: SpeciesDefinition = Database.species(&"dog")
	assert_true(dog != null, "cane caricato")
	assert_eq(dog.food_preference(&"kibble"), 2)
	assert_true(Database.species(&"fox").wild, "la volpe è selvatica")
	assert_true(Database.item(&"kibble") != null, "crocchette caricate")
	for s: SpeciesDefinition in Database.all_species():
		assert_false(s.fur_colors.is_empty(), "%s ha colori" % s.id)
		for food: String in s.favorite_foods + s.accepted_foods:
			assert_true(Database.item(StringName(food)) != null, "%s: cibo %s esiste" % [s.id, food])
