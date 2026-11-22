extends Node
## Stato della partita in corso: animali, inventario, scoperte, opzioni di partita.
## È ciò che il sistema di salvataggio salva e ripristina.

signal new_game_started

var animals: AnimalRegistry = AnimalRegistry.new()
var inventory: Inventory = Inventory.new()
var discoveries: DiscoveryLog = DiscoveryLog.new()
## Modalità serena (D-38): gli animali si ammalano ma non muoiono.
var serene_mode: bool = false
## Aspetto di Gioia (personalizzazione, Fase 4).
var appearance: CharacterAppearance = CharacterAppearance.new()
## Casa di Gioia: stanze, mobili, colori (Fase 8).
var home: HomeLayout = HomeLayout.new()
## Missioni (Fase 9).
var quests: QuestLog = QuestLog.new()
## Monete (D-19).
var coins: int = 0
## Orto (Fase 11).
var garden: Garden = Garden.new()
## Bonus temporanei dei piatti di Gioia: id → minuto di gioco di scadenza (D-22).
var buffs: Dictionary = {}
## Piccoli valori di progressione (es. ultimo giorno in cui si è presa la medicina).
var flags: Dictionary = {}


func _ready() -> void:
	start_new_game()


func start_new_game(serene: bool = false) -> void:
	animals = AnimalRegistry.new()
	inventory = Inventory.new()
	discoveries = DiscoveryLog.new()
	serene_mode = serene
	flags = {}
	appearance.from_dict(CharacterAppearance.new().to_dict())
	quests = QuestLog.new()
	coins = 50
	garden = Garden.new()
	buffs = {}
	inventory.add(&"carrot_seeds", 3)
	inventory.add(&"flower_seeds", 2)
	home = HomeLayout.new()
	# Arredamento iniziale già posizionato e qualche mobile da sistemare.
	home.place(&"bed", 1, 1, 0, 0)
	home.place(&"rug", 6, 5, 0, 4)
	home.place(&"table", 7, 5, 0)
	home.place(&"pet_bed", 12, 1, 0, 1)
	home.place(&"plant", 14, 9, 0)
	home.place(&"stove", 13, 5, 3)
	for f: StringName in [&"chair", &"chair", &"lamp", &"bookshelf", &"pet_bowl", &"plant", &"sofa"]:
		inventory.add(furniture_item(f))
	flags["feeder_portions"] = 10
	# Dotazione iniziale di Gioia.
	inventory.add(&"kibble", 10)
	inventory.add(&"apple", 5)
	inventory.add(&"berries", 5)
	inventory.add(&"ball", 1)
	inventory.add(&"brush", 1)
	new_game_started.emit()


## Tutto lo stato della partita, pronto per il salvataggio.
func to_dict() -> Dictionary:
	return {
		"animals": animals.to_dict(),
		"inventory": inventory.to_dict(),
		"discoveries": discoveries.to_dict(),
		"serene_mode": serene_mode,
		"flags": flags.duplicate(true),
		"appearance": appearance.to_dict(),
		"home": home.to_dict(),
		"quests": quests.to_dict(),
		"coins": coins,
		"garden": garden.to_dict(),
		"buffs": buffs.duplicate(),
	}


func from_dict(d: Dictionary) -> void:
	animals = AnimalRegistry.new()
	animals.from_dict(d.get("animals", {}) as Dictionary)
	inventory = Inventory.new()
	inventory.from_dict(d.get("inventory", {}) as Dictionary)
	discoveries = DiscoveryLog.new()
	discoveries.from_dict(d.get("discoveries", {}) as Dictionary)
	serene_mode = bool(d.get("serene_mode", false))
	flags = (d.get("flags", {}) as Dictionary).duplicate(true)
	# Lo stesso oggetto viene aggiornato (non sostituito): il modello di Gioia lo osserva.
	appearance.from_dict(d.get("appearance", {}) as Dictionary)
	home = HomeLayout.new()
	home.from_dict(d.get("home", {}) as Dictionary)
	quests = QuestLog.new()
	quests.from_dict(d.get("quests", {}) as Dictionary)
	coins = maxi(0, int(d.get("coins", 0)))
	garden = Garden.new()
	garden.from_dict(d.get("garden", {}) as Dictionary)
	buffs = {}
	for k: Variant in (d.get("buffs", {}) as Dictionary).keys():
		buffs[StringName(str(k))] = float((d["buffs"] as Dictionary)[k])


## Il bonus temporaneo `buff` è attivo?
func has_buff(buff: StringName) -> bool:
	return float(buffs.get(buff, -1.0)) > GameClock.time.get_total_minutes()


## Gioia mangia un piatto: attiva il bonus. Restituisce false se non è un piatto.
func eat_meal(item: StringName) -> bool:
	if not RecipeData.MEAL_BUFFS.has(item) or not inventory.try_remove(item):
		return false
	var b: Dictionary = RecipeData.MEAL_BUFFS[item]
	buffs[b["buff"]] = GameClock.time.get_total_minutes() + float(b["minutes"])
	return true


## Chiave d'inventario di un mobile (i mobili da posizionare stanno nell'inventario).
static func furniture_item(id: StringName) -> StringName:
	return StringName("furn_" + String(id))


func current_day() -> int:
	return GameClock.time.get_day()


func current_hour() -> int:
	return GameClock.time.get_hour()
