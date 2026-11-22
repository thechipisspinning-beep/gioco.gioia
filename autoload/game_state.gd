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


func current_day() -> int:
	return GameClock.time.get_day()


func current_hour() -> int:
	return GameClock.time.get_hour()
