class_name QuestData
extends RefCounted
## Tutte le missioni del gioco (dati). Storia principale (D-12: il rifugio della
## nonna), missioni degli abitanti e missioni giornaliere.
##
## Campi: id, kind ("main" | "side" | "daily"), giver (abitante), title_key,
## requires (missioni da completare prima), objectives, rewards
## {coins, items {id: n}, furniture {id: n}, flags [..], room_tokens}.
## Un obiettivo "talk" può avere "line": la battuta speciale dell'abitante.

static var _all: Array[Dictionary] = []


static func all() -> Array[Dictionary]:
	if _all.is_empty():
		_all = _build()
	return _all


static func get_quest(id: StringName) -> Dictionary:
	for q: Dictionary in all():
		if q["id"] == id:
			return q
	return {}


static func _build() -> Array[Dictionary]:
	return [
		# --- Storia principale -------------------------------------------------
		{"id": &"m01_welcome", "kind": "main", "giver": &"sofia", "title_key": "Q_M01",
			"objectives": [{"type": "talk", "target": "sofia", "line": "DLG_SOFIA_WELCOME"}],
			"rewards": {"coins": 50}},
		{"id": &"m02_first_friend", "kind": "main", "giver": &"sofia", "title_key": "Q_M02", "requires": [&"m01_welcome"],
			"objectives": [{"type": "hearts", "target": "dog", "count": 2}],
			"rewards": {"coins": 30, "items": {&"kibble": 5}}},
		{"id": &"m03_adopt", "kind": "main", "giver": &"sofia", "title_key": "Q_M03", "requires": [&"m02_first_friend"],
			"objectives": [{"type": "adopt", "count": 1}],
			"rewards": {"coins": 50, "furniture": {&"pet_bowl": 1}}},
		{"id": &"m04_cozy_home", "kind": "main", "giver": &"paolo", "title_key": "Q_M04", "requires": [&"m03_adopt"],
			"objectives": [{"type": "place_furniture", "count": 2}],
			"rewards": {"coins": 40, "furniture": {&"lamp": 1}}},
		{"id": &"m05_carpenter", "kind": "main", "giver": &"paolo", "title_key": "Q_M05", "requires": [&"m04_cozy_home"],
			"objectives": [{"type": "talk", "target": "paolo", "line": "DLG_PAOLO_PERMIT"}],
			"rewards": {"coins": 30, "room_tokens": 1}},
		{"id": &"m06_feeder", "kind": "main", "giver": &"lia", "title_key": "Q_M06", "requires": [&"m03_adopt"],
			"objectives": [{"type": "refill_feeder", "count": 1}],
			"rewards": {"coins": 30, "items": {&"kibble": 10}}},
		{"id": &"m07_forest", "kind": "main", "giver": &"sofia", "title_key": "Q_M07", "requires": [&"m05_carpenter"],
			"objectives": [{"type": "visit_zone", "target": "forest", "count": 1}, {"type": "meet_species", "target": "fox", "count": 1}],
			"rewards": {"coins": 40, "items": {&"berries": 5}}},
		{"id": &"m08_fox_friend", "kind": "main", "giver": &"sofia", "title_key": "Q_M08", "requires": [&"m07_forest"],
			"objectives": [{"type": "hearts", "target": "fox", "count": 3}],
			"rewards": {"coins": 60, "flags": ["unlock_flower_crown"]}},
		{"id": &"m09_vet", "kind": "main", "giver": &"marta", "title_key": "Q_M09", "requires": [&"m07_forest"],
			"objectives": [{"type": "talk", "target": "marta", "line": "DLG_MARTA_MEDICINE"}],
			"rewards": {"items": {&"medicine": 2}}},
		{"id": &"m10_wild_family", "kind": "main", "giver": &"sofia", "title_key": "Q_M10", "requires": [&"m08_fox_friend"],
			"objectives": [{"type": "adopt", "target": "fox", "count": 1}],
			"rewards": {"coins": 150, "room_tokens": 1, "flags": ["unlock_backpack"]}},
		{"id": &"m11_first_dish", "kind": "main", "giver": &"lia", "title_key": "Q_M11", "requires": [&"m04_cozy_home"],
			"objectives": [{"type": "cook", "count": 1}],
			"rewards": {"coins": 40, "flags": ["recipe_herbal_medicine"]}},
		{"id": &"m12_garden", "kind": "main", "giver": &"elena", "title_key": "Q_M12", "requires": [&"m11_first_dish"],
			"objectives": [{"type": "plant", "count": 2}, {"type": "harvest", "count": 1}],
			"rewards": {"coins": 50, "items": {&"strawberry_seeds": 4}, "flags": ["recipe_mushroom_soup"]}},
		# --- Missioni degli abitanti ------------------------------------------
		{"id": &"s_bruno_shop", "kind": "side", "giver": &"bruno", "title_key": "Q_S_BRUNO", "requires": [&"m01_welcome"],
			"objectives": [{"type": "talk", "target": "bruno", "line": "DLG_BRUNO_HELLO"}],
			"rewards": {"coins": 20, "furniture": {&"rug": 1}}},
		{"id": &"s_elena_flowers", "kind": "side", "giver": &"elena", "title_key": "Q_S_ELENA", "requires": [&"m01_welcome"],
			"objectives": [{"type": "collect", "target": "flower", "count": 5}],
			"rewards": {"coins": 40, "furniture": {&"plant": 2}}},
		{"id": &"s_teo_shells", "kind": "side", "giver": &"teo", "title_key": "Q_S_TEO", "requires": [&"m01_welcome"],
			"objectives": [{"type": "collect", "target": "seashell", "count": 5}],
			"rewards": {"coins": 40, "flags": ["unlock_raincoat"]}},
		{"id": &"s_nino_ball", "kind": "side", "giver": &"nino", "title_key": "Q_S_NINO", "requires": [&"m02_first_friend"],
			"objectives": [{"type": "play", "count": 3}],
			"rewards": {"coins": 30, "furniture": {&"toy_box": 1}}},
		{"id": &"s_lia_caretaker", "kind": "side", "giver": &"lia", "title_key": "Q_S_LIA", "requires": [&"m06_feeder"],
			"objectives": [{"type": "feed", "count": 6}, {"type": "brush", "count": 3}],
			"rewards": {"coins": 60, "flags": ["caretaker"]}},
		{"id": &"s_marta_cure", "kind": "side", "giver": &"marta", "title_key": "Q_S_MARTA", "requires": [&"m09_vet"],
			"objectives": [{"type": "cure", "count": 1}],
			"rewards": {"coins": 80, "flags": ["unlock_boots"]}},
		{"id": &"s_paolo_mushrooms", "kind": "side", "giver": &"paolo", "title_key": "Q_S_PAOLO", "requires": [&"m07_forest"],
			"objectives": [{"type": "collect", "target": "mushroom", "count": 4}],
			"rewards": {"coins": 50, "furniture": {&"bookshelf": 1}}},
		# --- Giornaliere ---------------------------------------------------------
		{"id": &"d_pet", "kind": "daily", "title_key": "Q_D_PET", "objectives": [{"type": "pet", "count": 3}], "rewards": {"coins": 15}},
		{"id": &"d_feed", "kind": "daily", "title_key": "Q_D_FEED", "objectives": [{"type": "feed", "count": 2}], "rewards": {"coins": 15}},
		{"id": &"d_collect", "kind": "daily", "title_key": "Q_D_COLLECT", "objectives": [{"type": "collect", "count": 5}], "rewards": {"coins": 20}},
		{"id": &"d_play", "kind": "daily", "title_key": "Q_D_PLAY", "objectives": [{"type": "play", "count": 2}], "rewards": {"coins": 15}},
		{"id": &"d_brush", "kind": "daily", "title_key": "Q_D_BRUSH", "objectives": [{"type": "brush", "count": 2}], "rewards": {"coins": 15}},
		{"id": &"d_explore", "kind": "daily", "title_key": "Q_D_EXPLORE", "objectives": [{"type": "visit_zone", "count": 2}], "rewards": {"coins": 20}},
	]
