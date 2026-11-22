class_name VillagerData
extends RefCounted
## Gli 8 abitanti del villaggio (D-11): ruolo, aspetto, posizione (offset dalla
## piazza), battute generiche. Le battute legate alle missioni sono in QuestData.

const ALL: Array[Dictionary] = [
	{"id": &"sofia", "name_key": "NPC_SOFIA", "role": "mayor", "offset": Vector2(-4, -5),
		"look": {"skin": 2, "hair_style": 4, "hair_color": 5, "outfit_style": 3, "outfit_color": 4, "accessory": 3, "height": 2},
		"lines": ["DLG_SOFIA_1", "DLG_SOFIA_2"]},
	{"id": &"marta", "name_key": "NPC_MARTA", "role": "vet", "offset": Vector2(10, -8),
		"look": {"skin": 0, "hair_style": 1, "hair_color": 4, "outfit_style": 1, "outfit_color": 5, "accessory": 0, "height": 1},
		"lines": ["DLG_MARTA_1", "DLG_MARTA_2"]},
	{"id": &"bruno", "name_key": "NPC_BRUNO", "role": "shop", "offset": Vector2(-12, 6),
		"look": {"skin": 3, "hair_style": 5, "hair_color": 1, "outfit_style": 2, "outfit_color": 1, "accessory": 2, "height": 2},
		"lines": ["DLG_BRUNO_1", "DLG_BRUNO_2"]},
	{"id": &"lia", "name_key": "NPC_LIA", "role": "farmer", "offset": Vector2(14, 8),
		"look": {"skin": 4, "hair_style": 2, "hair_color": 2, "outfit_style": 2, "outfit_color": 2, "accessory": 2, "height": 1},
		"lines": ["DLG_LIA_1", "DLG_LIA_2"]},
	{"id": &"teo", "name_key": "NPC_TEO", "role": "fisher", "offset": Vector2(4, 14),
		"look": {"skin": 1, "hair_style": 5, "hair_color": 3, "outfit_style": 1, "outfit_color": 1, "accessory": 0, "height": 2},
		"lines": ["DLG_TEO_1", "DLG_TEO_2"]},
	{"id": &"elena", "name_key": "NPC_ELENA", "role": "gardener", "offset": Vector2(-14, -10),
		"look": {"skin": 2, "hair_style": 3, "hair_color": 0, "outfit_style": 0, "outfit_color": 2, "accessory": 4, "height": 1},
		"lines": ["DLG_ELENA_1", "DLG_ELENA_2"]},
	{"id": &"paolo", "name_key": "NPC_PAOLO", "role": "carpenter", "offset": Vector2(6, -14),
		"look": {"skin": 5, "hair_style": 5, "hair_color": 1, "outfit_style": 2, "outfit_color": 6, "accessory": 0, "height": 2},
		"lines": ["DLG_PAOLO_1", "DLG_PAOLO_2"]},
	{"id": &"nino", "name_key": "NPC_NINO", "role": "kid", "offset": Vector2(-6, 10),
		"look": {"skin": 1, "hair_style": 5, "hair_color": 2, "outfit_style": 1, "outfit_color": 3, "accessory": 0, "height": 0},
		"lines": ["DLG_NINO_1", "DLG_NINO_2"]},
]

## Negozio di Bruno: oggetti e mobili in vendita (prezzo in monete).
const SHOP_ITEMS: Array[Dictionary] = [
	{"item": &"kibble", "price": 8}, {"item": &"apple", "price": 6}, {"item": &"berries", "price": 10},
	{"item": &"medicine", "price": 45}, {"item": &"ball", "price": 25}, {"item": &"brush", "price": 30},
]
const SHOP_FURNITURE: Array[Dictionary] = [
	{"furniture": &"chair", "price": 60}, {"furniture": &"table", "price": 90}, {"furniture": &"sofa", "price": 180},
	{"furniture": &"rug", "price": 80}, {"furniture": &"lamp", "price": 70}, {"furniture": &"plant", "price": 40},
	{"furniture": &"bookshelf", "price": 140}, {"furniture": &"pet_bed", "price": 100}, {"furniture": &"pet_bowl", "price": 35},
	{"furniture": &"toy_box", "price": 80}, {"furniture": &"scratching_post", "price": 70}, {"furniture": &"bed", "price": 200},
]
## Bruno compra gli oggetti raccolti sull'isola.
const SELL_PRICES: Dictionary = {&"flower": 4, &"seashell": 6, &"mushroom": 5, &"herb": 5, &"berries": 3, &"apple": 3}
## Costo della visita della veterinaria per ogni animale malato.
const VET_PRICE: int = 30
