class_name AnimalState
extends RefCounted
## Stato persistente di un singolo animale conosciuto (adottato o con cui
## esiste un rapporto). Logica pura, serializzabile in un dizionario.

enum Location { WILD, HOME, COMPANION }
enum Health { HEALTHY, SICK, CONVALESCENT, DEAD }

const MAX_FRIENDSHIP: float = 100.0

var id: StringName
var species_id: StringName
var variant: int = 0
## Nome dato da Gioia (vuoto finché non è adottato).
var given_name: String = ""
var traits: PackedStringArray = PackedStringArray()
var friendship: float = 0.0
var adopted: bool = false
var adopted_day: int = 0
var location: Location = Location.WILD
## Giorni di gioco in cui Gioia ha interagito con l'animale.
var visit_days: PackedInt32Array = PackedInt32Array()
## Conteggio interazioni per tipo nel giorno corrente (rendimenti decrescenti).
var interactions_today: Dictionary = {}
var interactions_day: int = 0

# Bisogni (0 = vuoto, 1 = pieno)
var hunger: float = 1.0
var happiness: float = 1.0
var cleanliness: float = 1.0
# Salute
var health: Health = Health.HEALTHY
var neglected_hours: float = 0.0
var sick_since_minutes: float = -1.0
var convalescent_until_minutes: float = -1.0
## Minuti di gioco dell'ultimo aggiornamento dei bisogni.
var last_update_minutes: float = -1.0


func _init(animal_id: StringName = &"", species: StringName = &"") -> void:
	id = animal_id
	species_id = species


func hearts() -> int:
	## Cuori mostrati in interfaccia: 0–5.
	return clampi(int(floor(friendship / 20.0)), 0, 5)


func record_visit(day: int) -> void:
	if not visit_days.has(day):
		visit_days.append(day)


func display_name(species_name: String) -> String:
	return given_name if given_name != "" else species_name


func is_alive() -> bool:
	return health != Health.DEAD


func to_dict() -> Dictionary:
	return {
		"id": String(id), "species_id": String(species_id), "variant": variant,
		"given_name": given_name, "traits": Array(traits), "friendship": friendship,
		"adopted": adopted, "adopted_day": adopted_day, "location": location,
		"visit_days": Array(visit_days),
		"hunger": hunger, "happiness": happiness, "cleanliness": cleanliness,
		"health": health, "neglected_hours": neglected_hours,
		"sick_since_minutes": sick_since_minutes,
		"convalescent_until_minutes": convalescent_until_minutes,
		"last_update_minutes": last_update_minutes,
	}


static func from_dict(d: Dictionary) -> AnimalState:
	var s: AnimalState = AnimalState.new(StringName(str(d.get("id", ""))), StringName(str(d.get("species_id", ""))))
	s.variant = int(d.get("variant", 0))
	s.given_name = str(d.get("given_name", ""))
	s.traits = PackedStringArray(d.get("traits", []) as Array)
	s.friendship = clampf(float(d.get("friendship", 0.0)), 0.0, MAX_FRIENDSHIP)
	s.adopted = bool(d.get("adopted", false))
	s.adopted_day = int(d.get("adopted_day", 0))
	s.location = int(d.get("location", Location.WILD)) as Location
	s.visit_days = PackedInt32Array(d.get("visit_days", []) as Array)
	s.hunger = clampf(float(d.get("hunger", 1.0)), 0.0, 1.0)
	s.happiness = clampf(float(d.get("happiness", 1.0)), 0.0, 1.0)
	s.cleanliness = clampf(float(d.get("cleanliness", 1.0)), 0.0, 1.0)
	s.health = int(d.get("health", Health.HEALTHY)) as Health
	s.neglected_hours = float(d.get("neglected_hours", 0.0))
	s.sick_since_minutes = float(d.get("sick_since_minutes", -1.0))
	s.convalescent_until_minutes = float(d.get("convalescent_until_minutes", -1.0))
	s.last_update_minutes = float(d.get("last_update_minutes", -1.0))
	return s
