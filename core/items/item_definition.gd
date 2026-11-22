class_name ItemDefinition
extends Resource
## Definizione di un oggetto (cibo, giocattolo, medicina, materiale, seme…).
## Un file `.tres` per oggetto in `data/items/`.

## FOOD = cibo per animali; MEAL = piatto per Gioia (bonus temporanei, D-22).
enum Category { FOOD, TOY, CARE, MEDICINE, MATERIAL, SEED, COLLECTIBLE, MEAL }

@export var id: StringName
@export var name_key: String
@export var category: Category = Category.FOOD
@export var stackable: bool = true
## Si consuma quando viene usato (es. cibo) oppure no (es. pallina, spazzola).
@export var consumable: bool = true
@export var icon_color: Color = Color.WHITE
