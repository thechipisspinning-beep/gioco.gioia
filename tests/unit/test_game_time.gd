extends TestCase


func test_new_game_starts_at_day_1_8am() -> void:
	var t: GameTime = GameTime.new()
	assert_eq(t.get_day(), 1, "giorno iniziale")
	assert_eq(t.get_hour(), 8, "ora iniziale")
	assert_eq(t.format_clock(), "08:00")


func test_one_real_minute_is_one_game_hour() -> void:
	var t: GameTime = GameTime.new(0.0)
	t.advance_real_seconds(60.0)
	assert_eq(t.get_hour(), 1)
	assert_eq(t.get_minute(), 0)


func test_full_day_lasts_24_real_minutes() -> void:
	var t: GameTime = GameTime.new(0.0)
	t.advance_real_seconds(24.0 * 60.0)
	assert_eq(t.get_day(), 2)
	assert_eq(t.get_hour(), 0)


func test_pause_stops_time() -> void:
	var t: GameTime = GameTime.new(0.0)
	t.paused = true
	t.advance_real_seconds(100.0)
	assert_almost_eq(t.get_total_minutes(), 0.0)


func test_signals_emitted_for_every_hour_crossed() -> void:
	var t: GameTime = GameTime.new(22.0 * 60.0)  # giorno 1, 22:00
	var hours: Array[int] = []
	var days: Array[int] = []
	t.hour_changed.connect(func(_d: int, h: int) -> void: hours.append(h))
	t.day_started.connect(func(d: int) -> void: days.append(d))
	t.advance_game_minutes(3.0 * 60.0 + 30.0)  # → giorno 2, 01:30
	assert_eq(hours, [23, 0, 1] as Array[int], "ore attraversate")
	assert_eq(days, [2] as Array[int], "giorni iniziati")
	assert_eq(t.get_day(), 2)
	assert_eq(t.format_clock(), "01:30")


func test_skip_to_next_morning() -> void:
	var t: GameTime = GameTime.new(23.0 * 60.0)
	t.skip_to_next_hour(7)
	assert_eq(t.get_day(), 2)
	assert_eq(t.get_hour(), 7)
	# Se l'ora è già passata nella giornata, va al giorno dopo.
	t.skip_to_next_hour(7)
	assert_eq(t.get_day(), 3)


func test_day_fraction() -> void:
	var t: GameTime = GameTime.new(12.0 * 60.0)
	assert_almost_eq(t.get_day_fraction(), 0.5)


func test_save_roundtrip() -> void:
	var t: GameTime = GameTime.new(1234.5)
	var copy: GameTime = GameTime.new()
	copy.from_dict(t.to_dict())
	assert_almost_eq(copy.get_total_minutes(), 1234.5)


func test_from_dict_rejects_negative_values() -> void:
	var t: GameTime = GameTime.new()
	t.from_dict({"total_minutes": -50.0})
	assert_almost_eq(t.get_total_minutes(), 0.0)
