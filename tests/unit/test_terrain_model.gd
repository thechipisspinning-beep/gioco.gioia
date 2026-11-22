extends TestCase

var _t: TerrainModel


func before_each() -> void:
	_t = TerrainModel.new()


func test_deterministic() -> void:
	var other: TerrainModel = TerrainModel.new()
	for p: Vector2 in [Vector2(10, 20), Vector2(-300, 400), Vector2(500, -100)]:
		assert_almost_eq(_t.height_at(p.x, p.y), other.height_at(p.x, p.y), 0.0001)


func test_center_is_land_and_far_is_sea() -> void:
	assert_gt(_t.height_at(0, 60), 2.0, "villaggio sopra il mare")
	assert_lt(_t.height_at(1200, 0), IslandLayout.DEEP_WATER, "fuori dall'isola è mare profondo")
	assert_lt(_t.height_at(0, -1200), IslandLayout.DEEP_WATER)


func test_village_and_home_are_flat() -> void:
	for area: Dictionary in IslandLayout.FLAT_AREAS:
		var c: Vector2 = area["center"]
		var h: float = float(area["height"])
		for o: Vector2 in [Vector2.ZERO, Vector2(10, 0), Vector2(0, -12), Vector2(-15, 8)]:
			assert_almost_eq(_t.height_at(c.x + o.x, c.y + o.y), h, 0.05, "area piana in %s" % (c + o))


func test_mountain_is_high() -> void:
	assert_gt(_t.height_at(-40, -620), 60.0, "montagna a nord")


func test_lake_is_water() -> void:
	var c: Vector2 = IslandLayout.LAKE_CENTER
	assert_lt(_t.height_at(c.x, c.y), IslandLayout.DEEP_WATER, "centro del lago profondo")


func test_player_start_is_dry_land() -> void:
	var s: Vector2 = IslandLayout.PLAYER_START
	assert_gt(_t.height_at(s.x, s.y), 1.0)


func test_zone_lookup() -> void:
	assert_eq(IslandLayout.zone_at(Vector2(0, 60)), &"village")
	assert_eq(IslandLayout.zone_at(Vector2(-360, -40)), &"forest")
	assert_eq(IslandLayout.zone_at(Vector2(-40, -620)), &"mountain")


func test_paths_detected() -> void:
	assert_lt(IslandLayout.distance_to_path(Vector2(-40, 100)), 0.5)
	assert_gt(IslandLayout.distance_to_path(Vector2(600, 600)), 50.0)
