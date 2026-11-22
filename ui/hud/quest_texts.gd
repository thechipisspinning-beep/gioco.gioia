class_name QuestTexts
extends RefCounted
## Testi leggibili degli obiettivi delle missioni (HUD e diario).


static func objectives_text(q: Dictionary, progress: Array) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var objectives: Array = q.get("objectives", []) as Array
	for i: int in objectives.size():
		var o: Dictionary = objectives[i]
		var goal: int = int(o.get("count", 1))
		var done: int = int(progress[i]) if i < progress.size() else 0
		var text: String = objective_text(o)
		# Solo caratteri presenti nel font predefinito (anche sul web non ci sono font di sistema).
		var line: String = "• " + (text if goal <= 1 else "%s (%d/%d)" % [text, done, goal])
		if done >= goal:
			line += " — " + TranslationServer.translate("OBJ_DONE")
		lines.append(line)
	return "\n".join(lines)


static func objective_text(o: Dictionary) -> String:
	var t: String = str(o.get("target", ""))
	var tr_t: Callable = func(k: String) -> String: return TranslationServer.translate(k)
	match str(o["type"]):
		"talk":
			return tr_t.call("OBJ_TALK") % tr_t.call("NPC_" + t.to_upper())
		"hearts":
			return tr_t.call("OBJ_HEARTS") % [int(o.get("count", 1)), tr_t.call("SPECIES_" + t.to_upper())]
		"adopt":
			return tr_t.call("OBJ_ADOPT_SPECIES") % tr_t.call("SPECIES_" + t.to_upper()) if t != "" else tr_t.call("OBJ_ADOPT")
		"place_furniture":
			return tr_t.call("OBJ_PLACE_FURNITURE")
		"refill_feeder":
			return tr_t.call("OBJ_REFILL_FEEDER")
		"visit_zone":
			return tr_t.call("OBJ_VISIT_ZONE") % tr_t.call("ZONE_" + t.to_upper()) if t != "" else tr_t.call("OBJ_VISIT_ANY")
		"discover_species":
			return tr_t.call("OBJ_MEET_ANY")
		"meet_species":
			return tr_t.call("OBJ_MEET") % tr_t.call("SPECIES_" + t.to_upper()) if t != "" else tr_t.call("OBJ_MEET_ANY")
		"collect":
			return tr_t.call("OBJ_COLLECT") % tr_t.call("ITEM_" + t.to_upper()) if t != "" else tr_t.call("OBJ_COLLECT_ANY")
	return tr_t.call("OBJ_" + str(o["type"]).to_upper())
