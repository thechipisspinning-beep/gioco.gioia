class_name Cooking
extends RefCounted
## Regole della cucina (logica pura).


static func is_known(recipe: Dictionary, flags: Dictionary) -> bool:
	var unlock: String = str(recipe.get("unlock", ""))
	return unlock == "" or bool(flags.get(unlock, false))


static func can_cook(recipe: Dictionary, inventory: Inventory) -> bool:
	for item: Variant in (recipe["ingredients"] as Dictionary).keys():
		if not inventory.has(StringName(str(item)), int((recipe["ingredients"] as Dictionary)[item])):
			return false
	return true


## Consuma gli ingredienti e aggiunge il risultato. `bonus` = porzioni extra
## (dal mini-gioco). Restituisce le porzioni prodotte (0 se impossibile).
static func cook(recipe: Dictionary, inventory: Inventory, bonus: int = 0) -> int:
	if not can_cook(recipe, inventory):
		return 0
	for item: Variant in (recipe["ingredients"] as Dictionary).keys():
		inventory.try_remove(StringName(str(item)), int((recipe["ingredients"] as Dictionary)[item]))
	var n: int = int(recipe.get("count", 1)) + maxi(0, bonus)
	inventory.add(recipe["result"], n)
	return n
