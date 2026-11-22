class_name SpeciesDefinition
extends Resource
## Definizione di una specie animale (dati di contenuto, D-09).
## Ogni specie è un file `.tres` in `data/species/`. Nessun codice dedicato per specie:
## comportamento, adozione, cibi e aspetto sono tutti descritti qui.

enum Size { SMALL, MEDIUM, LARGE }

@export_group("Identità")
@export var id: StringName
## Chiave di traduzione del nome della specie (es. SPECIES_DOG).
@export var name_key: String
## Chiave di traduzione della curiosità mostrata nel diario.
@export var fact_key: String
## Selvatico: adozione più difficile (D-16).
@export var wild: bool = false
@export var size: Size = Size.MEDIUM

@export_group("Movimento")
@export var walk_speed: float = 1.4
@export var run_speed: float = 4.5
## Raggio entro cui l'animale si sposta attorno al suo punto di casa.
@export var roam_radius: float = 10.0

@export_group("Carattere")
## 0 = per nulla timido, 1 = molto timido (scappa facilmente).
@export_range(0.0, 1.0) var shyness: float = 0.1
## Distanza a cui l'animale nota Gioia.
@export var notice_distance: float = 7.0
## Distanza minima che un animale timido mantiene finché la fiducia è bassa.
@export var comfort_distance: float = 0.0
## Ore di attività (gli animali dormono fuori da questa fascia).
@export_range(0, 23) var active_from_hour: int = 6
@export_range(0, 24) var active_to_hour: int = 22

@export_group("Cibo e gioco")
@export var favorite_foods: PackedStringArray = PackedStringArray()
@export var accepted_foods: PackedStringArray = PackedStringArray()
@export var likes_fetch: bool = true

@export_group("Adozione")
## Amicizia (0–100) necessaria per adottare.
@export_range(0, 100) var friendship_to_adopt: int = 60
## Giorni diversi in cui Gioia deve aver fatto visita all'animale.
@export var adoption_visit_days: int = 1
## Moltiplicatore del guadagno di amicizia (i selvatici < 1).
@export var trust_gain_multiplier: float = 1.0

@export_group("Bisogni e salute (per ora di gioco)")
@export var hunger_decay_per_hour: float = 0.02
@export var happiness_decay_per_hour: float = 0.015
@export var cleanliness_decay_per_hour: float = 0.01
## Ore di gioco consecutive con un bisogno a zero prima di ammalarsi.
@export var hours_neglected_before_sickness: float = 12.0

@export_group("Aspetto")
@export var model: StringName = &"quadruped"
## Colori del mantello possibili (variante scelta alla nascita dell'animale).
@export var fur_colors: Array[Color] = []
## Colore secondario (pancia, muso, punta della coda).
@export var accent_color: Color = Color.WHITE
## Parametri del modello procedurale (proporzioni, orecchie, coda...).
@export var model_params: Dictionary = {}


func is_active_at(hour: int) -> bool:
	if active_from_hour <= active_to_hour:
		return hour >= active_from_hour and hour < active_to_hour
	return hour >= active_from_hour or hour < active_to_hour


func food_preference(item_id: StringName) -> int:
	## 2 = preferito, 1 = accettato, 0 = rifiutato.
	if favorite_foods.has(String(item_id)):
		return 2
	if accepted_foods.has(String(item_id)):
		return 1
	return 0
