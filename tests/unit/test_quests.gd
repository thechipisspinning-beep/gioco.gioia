extends TestCase

const DEFS: Array[Dictionary] = [
	{"id": &"a", "kind": "main", "objectives": [{"type": "talk", "target": "sofia"}], "rewards": {}},
	{"id": &"b", "kind": "main", "requires": [&"a"], "objectives": [{"type": "collect", "target": "flower", "count": 3}, {"type": "pet", "count": 2}], "rewards": {}},
	{"id": &"h", "kind": "side", "requires": [&"a"], "objectives": [{"type": "hearts", "target": "dog", "count": 3}], "rewards": {}},
	{"id": &"d1", "kind": "daily", "objectives": [{"type": "pet", "count": 1}], "rewards": {}},
	{"id": &"d2", "kind": "daily", "objectives": [{"type": "feed", "count": 1}], "rewards": {}},
	{"id": &"d3", "kind": "daily", "objectives": [{"type": "play", "count": 1}], "rewards": {}},
	{"id": &"d4", "kind": "daily", "objectives": [{"type": "brush", "count": 1}], "rewards": {}},
]


func test_prerequisites_and_chain() -> void:
	var log: QuestLog = QuestLog.new()
	log.refresh(DEFS)
	assert_eq(log.status(&"a"), QuestLog.Status.ACTIVE)
	assert_eq(log.status(&"b"), QuestLog.Status.LOCKED, "bloccata finché a non è completata")
	var done: Array[StringName] = log.on_event(DEFS, "talk", &"sofia")
	assert_eq(done, [&"a"] as Array[StringName])
	log.refresh(DEFS)
	assert_eq(log.status(&"b"), QuestLog.Status.ACTIVE)


func test_targets_must_match() -> void:
	var log: QuestLog = QuestLog.new()
	log.refresh(DEFS)
	log.on_event(DEFS, "talk", &"bruno")
	assert_eq(log.status(&"a"), QuestLog.Status.ACTIVE, "parlare con un altro non conta")


func test_multi_objective_progress() -> void:
	var log: QuestLog = QuestLog.new()
	log.refresh(DEFS)
	log.on_event(DEFS, "talk", &"sofia")
	log.refresh(DEFS)
	log.on_event(DEFS, "collect", &"flower", 2)
	log.on_event(DEFS, "collect", &"seashell", 5)
	log.on_event(DEFS, "pet")
	assert_eq(log.progress(&"b"), [2, 1])
	log.on_event(DEFS, "collect", &"flower", 5)
	assert_eq(log.progress(&"b"), [3, 1], "il conteggio non supera l'obiettivo")
	var done: Array[StringName] = log.on_event(DEFS, "pet")
	assert_true(done.has(&"b"))


func test_hearts_use_reached_value() -> void:
	var log: QuestLog = QuestLog.new()
	log.refresh(DEFS)
	log.on_event(DEFS, "talk", &"sofia")
	log.refresh(DEFS)
	log.on_event(DEFS, "hearts", &"dog", 1)
	log.on_event(DEFS, "hearts", &"dog", 2)
	assert_eq(log.progress(&"h"), [2], "conta il valore raggiunto, non la somma")
	log.on_event(DEFS, "hearts", &"dog", 3)
	assert_eq(log.status(&"h"), QuestLog.Status.COMPLETED)


func test_daily_rotation_is_deterministic() -> void:
	var a: QuestLog = QuestLog.new()
	var b: QuestLog = QuestLog.new()
	a.set_daily(DEFS, 5)
	b.set_daily(DEFS, 5)
	assert_eq(a.active_ids().size(), 3)
	var ids_a: Array[StringName] = a.active_ids()
	var ids_b: Array[StringName] = b.active_ids()
	ids_a.sort()
	ids_b.sort()
	assert_eq(ids_a, ids_b, "stesso giorno, stesse missioni")
	a.on_event(DEFS, "pet")
	a.set_daily(DEFS, 6)
	assert_eq(a.active_ids().size(), 3, "il giorno dopo nuove giornaliere")


func test_roundtrip() -> void:
	var log: QuestLog = QuestLog.new()
	log.refresh(DEFS)
	log.on_event(DEFS, "talk", &"sofia")
	log.refresh(DEFS)
	log.on_event(DEFS, "collect", &"flower", 2)
	var c: QuestLog = QuestLog.new()
	c.from_dict(log.to_dict())
	assert_eq(c.status(&"a"), QuestLog.Status.COMPLETED)
	assert_eq(c.progress(&"b"), [2, 0])


func test_real_quest_data_is_consistent() -> void:
	var ids: Dictionary = {}
	for q: Dictionary in QuestData.all():
		assert_false(ids.has(q["id"]), "id duplicato %s" % q["id"])
		ids[q["id"]] = true
	for q: Dictionary in QuestData.all():
		for req: Variant in q.get("requires", []) as Array:
			assert_true(ids.has(req), "%s richiede %s che non esiste" % [q["id"], req])
		for f: Variant in (q.get("rewards", {}) as Dictionary).get("furniture", {}).keys():
			assert_true(FurnitureCatalog.has(StringName(str(f))), "mobile %s" % f)
		for it: Variant in (q.get("rewards", {}) as Dictionary).get("items", {}).keys():
			assert_true(Database.item(StringName(str(it))) != null, "oggetto %s" % it)
