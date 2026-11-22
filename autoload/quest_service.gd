extends Node
## Collega le missioni (`QuestLog`, dati in `QuestData`) agli eventi di gioco,
## consegna le ricompense e attiva le missioni successive.

signal quests_changed


func _ready() -> void:
	EventBus.animal_met.connect(func(species: StringName, _id: StringName) -> void: _event("meet_species", species))
	EventBus.animal_adopted.connect(func(_id: StringName, species: StringName) -> void: _event("adopt", species))
	EventBus.animal_interacted.connect(_on_interacted)
	EventBus.friendship_changed.connect(_on_friendship)
	EventBus.furniture_placed.connect(func(id: StringName) -> void: _event("place_furniture", id))
	EventBus.zone_entered.connect(func(zone: StringName) -> void: _event("visit_zone", zone))
	EventBus.npc_talked.connect(func(npc: StringName) -> void: _event("talk", npc))
	EventBus.item_collected.connect(func(item: StringName, n: int) -> void: _event("collect", item, n))
	EventBus.gameplay_event.connect(func(type: String, target: StringName, n: int) -> void: _event(type, target, n))
	GameClock.day_started.connect(func(_d: int) -> void: start_day())
	GameState.new_game_started.connect(start_day)
	start_day.call_deferred()


## All'inizio della partita e di ogni giorno: missioni giornaliere e sblocchi.
func start_day() -> void:
	GameState.quests.set_daily(QuestData.all(), GameState.current_day())
	GameState.quests.refresh(QuestData.all())
	quests_changed.emit()


## Battuta speciale di un abitante se una missione attiva richiede di parlargli.
func talk_line_for(npc: StringName) -> String:
	for id: StringName in GameState.quests.active_ids():
		for o: Variant in QuestData.get_quest(id).get("objectives", []) as Array:
			var obj: Dictionary = o as Dictionary
			if str(obj["type"]) == "talk" and StringName(str(obj.get("target", ""))) == npc:
				return str(obj.get("line", ""))
	return ""


## Missioni attive assegnate da un abitante (per il fumetto "!").
func has_quest_from(npc: StringName) -> bool:
	for id: StringName in GameState.quests.active_ids():
		var q: Dictionary = QuestData.get_quest(id)
		if q.get("giver", &"") == npc:
			return true
	return false


## Titolo e avanzamento della missione principale attiva (per l'HUD).
func tracked_quest() -> Dictionary:
	var best: Dictionary = {}
	for id: StringName in GameState.quests.active_ids():
		var q: Dictionary = QuestData.get_quest(id)
		if q.get("kind", "") == "main":
			best = q
			break
	return best


func _on_interacted(_animal: StringName, _species: StringName, action: int, _gain: float) -> void:
	match action:
		TrustModel.Action.PET:
			_event("pet")
		TrustModel.Action.FEED:
			_event("feed")
		TrustModel.Action.PLAY:
			_event("play")
		TrustModel.Action.BRUSH:
			_event("brush")


func _on_friendship(animal_id: StringName, _friendship: float) -> void:
	var s: AnimalState = GameState.animals.get_animal(animal_id)
	if s != null:
		_event("hearts", s.species_id, s.hearts())


func _event(type: String, target: StringName = &"", amount: int = 1) -> void:
	var done: Array[StringName] = GameState.quests.on_event(QuestData.all(), type, target, amount)
	for id: StringName in done:
		_reward(QuestData.get_quest(id))
	if not done.is_empty():
		GameState.quests.refresh(QuestData.all())
		SaveManager.autosave()
	quests_changed.emit()


func _reward(q: Dictionary) -> void:
	var r: Dictionary = q.get("rewards", {}) as Dictionary
	var parts: PackedStringArray = PackedStringArray()
	var coins: int = int(r.get("coins", 0))
	if coins > 0:
		GameState.coins += coins
		parts.append(tr("REWARD_COINS") % coins)
	for item: Variant in (r.get("items", {}) as Dictionary).keys():
		var n: int = int((r["items"] as Dictionary)[item])
		GameState.inventory.add(StringName(str(item)), n)
		var def: ItemDefinition = Database.item(StringName(str(item)))
		parts.append("%s ×%d" % [tr(def.name_key) if def != null else str(item), n])
	for f: Variant in (r.get("furniture", {}) as Dictionary).keys():
		var n: int = int((r["furniture"] as Dictionary)[f])
		GameState.inventory.add(GameState.furniture_item(StringName(str(f))), n)
		parts.append("%s ×%d" % [tr(str(FurnitureCatalog.DEFS[StringName(str(f))]["name_key"])), n])
	for flag: Variant in r.get("flags", []) as Array:
		GameState.flags[str(flag)] = true
		parts.append(tr("REWARD_" + str(flag).to_upper()))
	var tokens: int = int(r.get("room_tokens", 0))
	if tokens > 0:
		GameState.flags["room_tokens"] = int(GameState.flags.get("room_tokens", 0)) + tokens
		parts.append(tr("REWARD_ROOM_PERMIT"))
	EventBus.notification_requested.emit(tr("NOTIFY_QUEST_DONE") % tr(str(q["title_key"])))
	if not parts.is_empty():
		EventBus.notification_requested.emit(tr("NOTIFY_REWARD") % ", ".join(parts))
