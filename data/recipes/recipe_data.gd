class_name RecipeData
extends RefCounted
## Ricette (GDD § 9): per Gioia (bonus temporanei, D-22), per gli animali
## e medicine (D-36). "unlock" = flag che la sblocca ("" = nota dall'inizio).

const ALL: Array[Dictionary] = [
	{"id": &"pet_treats", "name_key": "RECIPE_PET_TREATS", "for": "animals",
		"ingredients": {&"kibble": 2, &"apple": 1}, "result": &"pet_treat", "count": 2, "unlock": ""},
	{"id": &"berry_mix", "name_key": "RECIPE_BERRY_MIX", "for": "animals",
		"ingredients": {&"berries": 2, &"apple": 1}, "result": &"berry_mix", "count": 2, "unlock": ""},
	{"id": &"carrot_snack", "name_key": "RECIPE_CARROT_SNACK", "for": "animals",
		"ingredients": {&"carrot": 2}, "result": &"carrot_snack", "count": 2, "unlock": ""},
	{"id": &"herbal_medicine", "name_key": "RECIPE_HERBAL_MEDICINE", "for": "medicine",
		"ingredients": {&"herb": 3}, "result": &"medicine", "count": 1, "unlock": "recipe_herbal_medicine"},
	{"id": &"fruit_salad", "name_key": "RECIPE_FRUIT_SALAD", "for": "gioia",
		"ingredients": {&"apple": 1, &"strawberry": 2}, "result": &"fruit_salad", "count": 1, "unlock": ""},
	{"id": &"mushroom_soup", "name_key": "RECIPE_MUSHROOM_SOUP", "for": "gioia",
		"ingredients": {&"mushroom": 2, &"herb": 1, &"carrot": 1}, "result": &"mushroom_soup", "count": 1, "unlock": "recipe_mushroom_soup"},
	{"id": &"pancakes", "name_key": "RECIPE_PANCAKES", "for": "gioia",
		"ingredients": {&"egg": 2, &"milk": 1, &"grain": 1}, "result": &"pancakes", "count": 2, "unlock": ""},
]

## Effetti dei cibi per Gioia: durata in minuti di gioco.
const MEAL_BUFFS: Dictionary = {
	&"fruit_salad": {"buff": &"good_mood", "minutes": 180},
	&"mushroom_soup": {"buff": &"energy", "minutes": 180},
	&"pancakes": {"buff": &"good_mood", "minutes": 240},
}


static func get_recipe(id: StringName) -> Dictionary:
	for r: Dictionary in ALL:
		if r["id"] == id:
			return r
	return {}
