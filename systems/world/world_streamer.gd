class_name WorldStreamer
extends Node3D
## Carica i blocchi di terreno attorno a Gioia e scarica quelli lontani
## (Architettura § 5). La costruzione è distribuita su più frame per evitare
## scatti: al massimo `chunks_per_frame` blocchi per frame.

signal initial_area_ready

@export var target: Node3D
## Raggio di caricamento in blocchi (3 → area di 7 × 7 blocchi, ~450 m).
@export var load_radius: int = 3
## Raggio entro cui si aggiungono erba e fiori.
@export var detail_radius: int = 1
@export var chunks_per_frame: int = 1

var terrain: TerrainModel = TerrainModel.new()
var _chunks: Dictionary = {}  # Vector2i -> TerrainChunk
var _detailed: Dictionary = {}  # Vector2i -> bool
var _queue: Array[Vector2i] = []
var _center: Vector2i = Vector2i(999999, 999999)
var _initial_done: bool = false


func _ready() -> void:
	# Profilo qualità: su mobile e web un raggio più piccolo.
	if OS.has_feature("mobile") or OS.has_feature("web"):
		load_radius = mini(load_radius, 2)


func _process(_delta: float) -> void:
	if target == null:
		return
	var c: Vector2i = chunk_of(target.global_position)
	if c != _center:
		_center = c
		_plan()
	var built: int = 0
	while built < chunks_per_frame and not _queue.is_empty():
		var key: Vector2i = _queue.pop_front()
		_build(key)
		built += 1
	if not _initial_done and _queue.is_empty():
		_initial_done = true
		initial_area_ready.emit()


## Costruisce subito tutti i blocchi vicini (all'avvio, dietro la dissolvenza).
func build_all_now() -> void:
	if target == null:
		return
	_center = chunk_of(target.global_position)
	_plan()
	while not _queue.is_empty():
		_build(_queue.pop_front())
	_initial_done = true
	initial_area_ready.emit()


static func chunk_of(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / TerrainChunk.CHUNK_SIZE), floori(p.z / TerrainChunk.CHUNK_SIZE))


func loaded_count() -> int:
	return _chunks.size()


func is_loaded(c: Vector2i) -> bool:
	return _chunks.has(c)


func height_at(x: float, z: float) -> float:
	return terrain.height_at(x, z)


func _plan() -> void:
	# Scarica i blocchi fuori raggio (con un margine per evitare carica/scarica continui).
	for key: Vector2i in _chunks.keys():
		if _ring(key) > load_radius + 1:
			(_chunks[key] as Node).queue_free()
			_chunks.erase(key)
			_detailed.erase(key)
	# Coda dei blocchi mancanti o da ricostruire (dettagli aggiunti/tolti),
	# dal più vicino al più lontano.
	var wanted: Array[Vector2i] = []
	for dz: int in range(-load_radius, load_radius + 1):
		for dx: int in range(-load_radius, load_radius + 1):
			var key: Vector2i = _center + Vector2i(dx, dz)
			var needs_details: bool = _ring(key) <= detail_radius
			if not _chunks.has(key) or needs_details != bool(_detailed.get(key, false)):
				wanted.append(key)
	wanted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return _ring(a) < _ring(b))
	_queue = wanted


func _build(key: Vector2i) -> void:
	var with_details: bool = _ring(key) <= detail_radius
	if _chunks.has(key):
		if bool(_detailed.get(key, false)) == with_details:
			return
		(_chunks[key] as Node).queue_free()
		_chunks.erase(key)
	if _ring(key) > load_radius:
		return
	var chunk: TerrainChunk = TerrainChunk.new()
	chunk.build(terrain, key, with_details)
	add_child(chunk)
	_chunks[key] = chunk
	_detailed[key] = with_details


func _ring(key: Vector2i) -> int:
	return maxi(absi(key.x - _center.x), absi(key.y - _center.y))
