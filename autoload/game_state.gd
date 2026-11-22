extends Node
## Stato della partita in corso: animali, inventario, scoperte, opzioni di partita.
## È ciò che il sistema di salvataggio salva e ripristina.

signal new_game_started

var animals: AnimalRegistry = AnimalRegistry.new()
var inventory: Inventory = Inventory.new()
var discoveries: DiscoveryLog = DiscoveryLog.new()
## Modalità serena (D-38): gli animali si ammalano ma non muoiono.
var serene_mode: bool = false
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


func current_day() -> int:
	return GameClock.time.get_day()


func current_hour() -> int:
	return GameClock.time.get_hour()
