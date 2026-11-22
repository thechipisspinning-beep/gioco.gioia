class_name FurnitureCatalog
extends RefCounted
## Catalogo dei mobili (GDD § 8): ingombro in celle della griglia (0,5 m),
## chiave del nome, se è colorabile, se è per gli animali.

const DEFS: Dictionary = {
	&"bed": {"size": Vector2i(4, 5), "name_key": "FURN_BED", "colorable": true},
	&"table": {"size": Vector2i(3, 3), "name_key": "FURN_TABLE", "colorable": false},
	&"chair": {"size": Vector2i(2, 2), "name_key": "FURN_CHAIR", "colorable": true},
	&"sofa": {"size": Vector2i(5, 2), "name_key": "FURN_SOFA", "colorable": true},
	&"rug": {"size": Vector2i(5, 4), "name_key": "FURN_RUG", "colorable": true, "flat": true},
	&"lamp": {"size": Vector2i(1, 1), "name_key": "FURN_LAMP", "colorable": true},
	&"plant": {"size": Vector2i(1, 1), "name_key": "FURN_PLANT", "colorable": false},
	&"bookshelf": {"size": Vector2i(4, 1), "name_key": "FURN_BOOKSHELF", "colorable": false},
	&"pet_bed": {"size": Vector2i(2, 2), "name_key": "FURN_PET_BED", "colorable": true, "pets": true},
	&"pet_bowl": {"size": Vector2i(1, 1), "name_key": "FURN_PET_BOWL", "colorable": true, "pets": true},
	&"scratching_post": {"size": Vector2i(1, 1), "name_key": "FURN_SCRATCHING_POST", "colorable": false, "pets": true},
	&"toy_box": {"size": Vector2i(2, 1), "name_key": "FURN_TOY_BOX", "colorable": true, "pets": true},
	&"stove": {"size": Vector2i(2, 2), "name_key": "FURN_STOVE", "colorable": false},
	&"counter": {"size": Vector2i(3, 2), "name_key": "FURN_COUNTER", "colorable": true},
}

const COLORS: Array[Color] = [
	Color("ff8a7a"), Color("6aa8e8"), Color("8ccf6b"), Color("ffd75e"), Color("c79be8"), Color("fff8ee"), Color("c58f5e")]
const WALL_COLORS: Array[Color] = [
	Color("fbefd8"), Color("ffe1e1"), Color("e1f0ff"), Color("e6f7dc"), Color("fff6c9"), Color("efe2ff"), Color("f2f2f2")]
const FLOOR_COLORS: Array[Color] = [
	Color("c58f5e"), Color("e0b98a"), Color("9a6a48"), Color("d9d4cc"), Color("b7cfa0"), Color("e7c3c3")]
const ROOF_COLORS: Array[Color] = [
	Color("7fb36a"), Color("e0725f"), Color("6aa8e8"), Color("c79be8"), Color("ffb36b"), Color("8a7a92")]


static func has(id: StringName) -> bool:
	return DEFS.has(id)


static func footprint(id: StringName, rotation: int) -> Vector2i:
	var s: Vector2i = DEFS[id]["size"] if DEFS.has(id) else Vector2i.ONE
	return Vector2i(s.y, s.x) if rotation % 2 == 1 else s


static func is_flat(id: StringName) -> bool:
	return bool((DEFS.get(id, {}) as Dictionary).get("flat", false))
