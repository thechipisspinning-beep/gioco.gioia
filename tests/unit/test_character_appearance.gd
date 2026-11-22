extends TestCase


func test_defaults_are_valid() -> void:
	var a: CharacterAppearance = CharacterAppearance.new()
	assert_eq(a.style_id(&"hair"), &"ponytail")
	assert_eq(a.style_id(&"outfit"), &"dress")
	assert_almost_eq(a.height_scale(), 1.0)


func test_cycle_wraps_around() -> void:
	var a: CharacterAppearance = CharacterAppearance.new()
	a.cycle_style(&"hair", -1, {})
	assert_eq(a.style_id(&"hair"), CharacterCatalog.HAIR_STYLES[-1])
	a.cycle_style(&"hair", 1, {})
	assert_eq(a.style_id(&"hair"), &"ponytail")


func test_locked_styles_are_skipped_until_unlocked() -> void:
	var a: CharacterAppearance = CharacterAppearance.new()
	var seen: Dictionary = {}
	for i: int in 12:
		a.cycle_style(&"outfit", 1, {})
		seen[a.style_id(&"outfit")] = true
	assert_false(seen.has(&"raincoat"), "impermeabile bloccato")
	var flags: Dictionary = {"unlock_raincoat": true}
	seen.clear()
	for i: int in 12:
		a.cycle_style(&"outfit", 1, flags)
		seen[a.style_id(&"outfit")] = true
	assert_true(seen.has(&"raincoat"), "sbloccato con la missione")


func test_colors_clamped() -> void:
	var a: CharacterAppearance = CharacterAppearance.new()
	a.set_color(&"hair", 999)
	assert_eq(a.hair_color, CharacterCatalog.HAIR_COLORS.size() - 1)
	a.set_color(&"skin", -5)
	assert_eq(a.skin, 0)


func test_roundtrip_and_sanitize() -> void:
	var a: CharacterAppearance = CharacterAppearance.new()
	a.cycle_style(&"hair", 2, {})
	a.set_color(&"outfit", 3)
	a.cycle_style(&"height", 1, {})
	var b: CharacterAppearance = CharacterAppearance.new()
	b.from_dict(a.to_dict())
	assert_eq(b.to_dict(), a.to_dict())
	b.from_dict({"hair_style": 999, "skin": -3})
	assert_eq(b.hair_style, CharacterCatalog.HAIR_STYLES.size() - 1, "valori fuori scala corretti")
	assert_eq(b.skin, 0)


func test_randomize_never_picks_locked() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1
	var a: CharacterAppearance = CharacterAppearance.new()
	for i: int in 50:
		a.randomize_look(rng, {})
		for slot: StringName in [&"outfit", &"shoes", &"accessory"]:
			assert_true(CharacterCatalog.is_unlocked(a.style_id(slot), {}), "%s bloccato scelto" % a.style_id(slot))
