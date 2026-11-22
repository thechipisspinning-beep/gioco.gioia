class_name AnimalPopulation
extends Node3D
## Popolazione animale dell'isola (Fase 12, Architettura § 6.4).
## Ogni specie ha punti di comparsa stabili nelle sue zone. Gli animali vicini
## a Gioia diventano nodi "attivi"; quelli lontani vengono rilasciati
## (i loro dati restano nel registro se c'è un rapporto). Un limite massimo
## di animali attivi protegge le prestazioni, più basso su mobile e web.

@export var active_radius: float = 70.0
@export var release_radius: float = 95.0
@export var max_active: int = 30
@export var check_interval: float = 0.5

var entries: Array[Dictionary] = []  # {id, species, pos: Vector2}
var _active: Dictionary = {}  # id -> AnimalAgent
var _timer: float = 0.0
var _player: Node3D


func _ready() -> void:
	if Settings.get_quality() == Settings.Quality.LOW:
		max_active = 14
		active_radius = 55.0
		release_radius = 75.0
	build_entries()


## Calcola i punti di comparsa (deterministici) di tutte le specie.
func build_entries() -> void:
	entries.clear()
	for species: SpeciesDefinition in Database.all_species():
		for zone: String in species.zones:
			var z: Dictionary = _zone(StringName(zone))
			if z.is_empty():
				continue
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.seed = hash(String(species.id) + zone)
			for i: int in species.population:
				var id: StringName = StringName("%s_%s_%d" % [species.id, zone, i])
				# ID storici per compatibilità con i salvataggi esistenti.
				if species.id == &"dog" and zone == "village" and i == 0:
					id = &"village_dog"
				elif species.id == &"fox" and zone == "forest" and i == 0:
					id = &"forest_fox"
				var pos: Vector2 = _pick_point(z, rng, species)
				if pos.x < 1e8:
					entries.append({"id": id, "species": species.id, "pos": pos})


func active_count() -> int:
	return _active.size()


func is_active(id: StringName) -> bool:
	return _active.has(id) and is_instance_valid(_active[id])


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = check_interval
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
		if _player == null:
			return
	var pp: Vector2 = Vector2(_player.global_position.x, _player.global_position.z)
	# Rilascia gli animali lontani (non adottati: quelli li gestisce CompanionManager).
	for id: StringName in _active.keys():
		var a: AnimalAgent = _active[id] as AnimalAgent
		if not is_instance_valid(a):
			_active.erase(id)
			continue
		if a.data.adopted:
			_active.erase(id)
			continue
		if Vector2(a.global_position.x, a.global_position.z).distance_to(pp) > release_radius and not a.is_busy():
			a.queue_free()
			_active.erase(id)
	# Attiva i più vicini, entro il limite.
	var candidates: Array[Dictionary] = []
	for e: Dictionary in entries:
		if _active.has(e["id"]):
			continue
		var d: float = (e["pos"] as Vector2).distance_to(pp)
		if d > active_radius:
			continue
		var known: AnimalState = GameState.animals.get_animal(e["id"])
		if known != null and (known.adopted or not known.is_alive()):
			continue
		candidates.append({"e": e, "d": d})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["d"]) < float(b["d"]))
	for c: Dictionary in candidates:
		if _active.size() >= max_active:
			break
		var e: Dictionary = c["e"]
		var p: Vector2 = e["pos"]
		var y: float = float(WorldQuery.ground_height.call(p.x, p.y)) if WorldQuery.ground_height.is_valid() else 0.0
		var agent: AnimalAgent = AnimalSpawner.spawn(get_parent_node_3d(), e["id"], e["species"], Vector3(p.x, y + 0.3, p.y), false)
		if agent != null:
			_active[e["id"]] = agent


func _zone(id: StringName) -> Dictionary:
	if id == &"beach":
		return {"id": &"beach", "center": Vector2.ZERO, "radius": 0.0}
	for z: Dictionary in IslandLayout.ZONES:
		if z["id"] == id:
			return z
	return {}


func _pick_point(z: Dictionary, rng: RandomNumberGenerator, species: SpeciesDefinition) -> Vector2:
	var height: Callable = WorldQuery.ground_height
	for attempt: int in 30:
		var p: Vector2
		if z["id"] == &"beach":
			var a: float = rng.randf() * TAU
			p = Vector2(cos(a), sin(a)) * IslandLayout.ISLAND_RADIUS * rng.randf_range(0.78, 0.9)
		elif z["id"] == &"countryside" and not species.wild:
			# Gli animali da fattoria vivono nel recinto della fattoria.
			var farm: Vector2 = IslandLayout.FLAT_AREAS[2]["center"]
			p = farm + Vector2(rng.randf_range(-18.0, 20.0), rng.randf_range(-2.0, 22.0))
		else:
			var a: float = rng.randf() * TAU
			p = (z["center"] as Vector2) + Vector2(cos(a), sin(a)) * float(z["radius"]) * sqrt(rng.randf()) * 0.75
		if not height.is_valid():
			return p
		var h: float = float(height.call(p.x, p.y))
		var on_beach: bool = z["id"] == &"beach"
		# Spiaggia: sabbia asciutta; altrove: terra ferma non troppo alta per chi non vive in montagna.
		if on_beach and h > 0.3 and h < 2.5:
			return p
		if not on_beach and h > 1.5 and (h < 60.0 or z["id"] == &"mountain"):
			if IslandLayout.distance_to_path(p) > 3.0 or species.id == &"dog":
				return p
	return Vector2(1e9, 1e9)
