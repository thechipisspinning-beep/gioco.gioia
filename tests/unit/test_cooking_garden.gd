extends TestCase


func test_cook_consumes_and_produces() -> void:
	var inv: Inventory = Inventory.new()
	inv.add(&"kibble", 3)
	inv.add(&"apple", 1)
	var r: Dictionary = RecipeData.get_recipe(&"pet_treats")
	assert_true(Cooking.can_cook(r, inv))
	assert_eq(Cooking.cook(r, inv, 1), 3, "2 porzioni + 1 bonus dal mini-gioco")
	assert_eq(inv.count(&"pet_treat"), 3)
	assert_eq(inv.count(&"kibble"), 1)
	assert_eq(inv.count(&"apple"), 0)
	assert_false(Cooking.can_cook(r, inv))
	assert_eq(Cooking.cook(r, inv), 0, "senza ingredienti non si cucina")


func test_locked_recipes() -> void:
	var r: Dictionary = RecipeData.get_recipe(&"herbal_medicine")
	assert_false(Cooking.is_known(r, {}))
	assert_true(Cooking.is_known(r, {"recipe_herbal_medicine": true}))
	assert_true(Cooking.is_known(RecipeData.get_recipe(&"pet_treats"), {}))


func test_recipes_reference_real_items() -> void:
	for r: Dictionary in RecipeData.ALL:
		assert_true(Database.item(r["result"]) != null, "risultato %s" % r["result"])
		for it: Variant in (r["ingredients"] as Dictionary).keys():
			assert_true(Database.item(StringName(str(it))) != null, "ingrediente %s" % it)
	for p: StringName in Garden.PLANTS.keys():
		assert_true(Database.item(Garden.PLANTS[p]["seed"]) != null, "seme di %s" % p)


func test_plant_grows_only_when_watered() -> void:
	var g: Garden = Garden.new()
	assert_true(g.plant(0, &"carrot", 0.0))
	assert_false(g.plant(0, &"herb", 0.0), "parcella occupata")
	g.update(48.0 * 60.0)
	assert_eq(g.stage(0), 0, "senza acqua non cresce (ma non muore)")
	g.water(0, 48.0 * 60.0)
	g.update(48.0 * 60.0 + 16.0 * 60.0)
	assert_eq(g.stage(0), 1, "12 ore di acqua = 1 fase (8 ore per fase)")
	g.water(0, 64.0 * 60.0)
	g.update(76.0 * 60.0)
	assert_eq(g.stage(0), 3, "24 ore annaffiate = pronta")
	assert_true(g.is_ready(0))
	assert_false(g.water(0, 76.0 * 60.0), "pronta: non serve annaffiare")


func test_harvest_empties_plot() -> void:
	var g: Garden = Garden.new()
	g.plant(2, &"herb", 0.0)
	assert_true(g.harvest(2).is_empty(), "non ancora pronta")
	g.water(2, 0.0)
	g.update(12.0 * 60.0)
	g.water(2, 12.0 * 60.0)
	g.update(24.0 * 60.0)
	var got: Dictionary = g.harvest(2)
	assert_eq(int(got[&"herb"]), 3)
	assert_true(g.is_empty(2))


func test_seed_lookup_and_roundtrip() -> void:
	assert_eq(Garden.plant_for_seed(&"strawberry_seeds"), &"strawberry")
	var g: Garden = Garden.new()
	g.plant(1, &"strawberry", 10.0)
	g.water(1, 10.0)
	var c: Garden = Garden.new()
	c.from_dict(g.to_dict())
	assert_eq(c.plots[1]["plant"], &"strawberry")
	assert_true(c.is_watered(1, 20.0))
