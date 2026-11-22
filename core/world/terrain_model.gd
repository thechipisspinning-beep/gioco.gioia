class_name TerrainModel
extends RefCounted
## Altezza e colore del terreno in ogni punto dell'isola. Deterministico:
## dato lo stesso seme, l'isola è sempre identica (nessun file enorme da
## salvare o scaricare: perfetto per web e mobile).

const SEED: int = 20261122

var _hills: FastNoiseLite
var _detail: FastNoiseLite
var _coast: FastNoiseLite
var _ridge: FastNoiseLite
var _tint: FastNoiseLite


func _init() -> void:
	_hills = _noise(SEED, 1.0 / 260.0, 3)
	_detail = _noise(SEED + 1, 1.0 / 45.0, 2)
	_coast = _noise(SEED + 2, 1.0 / 300.0, 2)
	_ridge = _noise(SEED + 3, 1.0 / 160.0, 4)
	_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_tint = _noise(SEED + 4, 1.0 / 30.0, 1)


## Quota del terreno (m) nel punto (x, z).
func height_at(x: float, z: float) -> float:
	var p: Vector2 = Vector2(x, z)
	# Forma dell'isola: costa irregolare.
	var r: float = p.length() / IslandLayout.ISLAND_RADIUS + _coast.get_noise_2d(x, z) * 0.09
	var land: float = smoothstep(1.0, 0.78, r)
	var base: float = 5.0 + _hills.get_noise_2d(x, z) * 9.0 + _detail.get_noise_2d(x, z) * 1.2
	# Montagna a nord.
	var m_dist: float = p.distance_to(Vector2(-40, -620)) / 320.0
	var mountain: float = smoothstep(1.0, 0.1, m_dist)
	base += mountain * (55.0 + (_ridge.get_noise_2d(x, z) * 0.5 + 0.5) * 95.0)
	var h: float = lerpf(-9.0, base, land)
	# Spiaggia: dolce discesa vicino alla costa.
	var beach: float = smoothstep(0.86, 0.95, r) * (1.0 - smoothstep(0.95, 1.02, r))
	h = lerpf(h, minf(h, 1.2), beach * 0.8)
	# Lago.
	var l_dist: float = p.distance_to(IslandLayout.LAKE_CENTER) / IslandLayout.LAKE_RADIUS
	h = lerpf(h, -2.5, smoothstep(1.25, 0.6, l_dist))
	# Aree spianate (villaggio, casa, fattoria).
	for area: Dictionary in IslandLayout.FLAT_AREAS:
		var d: float = p.distance_to(area["center"] as Vector2)
		var rad: float = float(area["radius"])
		h = lerpf(h, float(area["height"]), smoothstep(rad, rad * 0.65, d))
	return h


## Colore del terreno (vertex color) data quota e pendenza (0 = piano, 1 = verticale).
## `check_paths` = false salta il calcolo dei sentieri (blocchi lontani da ogni sentiero).
func color_at(x: float, z: float, h: float, slope: float, check_paths: bool = true) -> Color:
	var tint: float = _tint.get_noise_2d(x, z) * 0.5 + 0.5
	var c: Color = Palette.GRASS.lerp(Palette.GRASS_DARK, tint * 0.6)
	var zone: StringName = IslandLayout.zone_at(Vector2(x, z))
	if zone == &"forest":
		c = c.lerp(Palette.LEAF, 0.35)
	elif zone == &"meadows":
		c = c.lerp(Palette.LEAF_LIGHT, 0.3)
	if h < 1.6:
		c = c.lerp(Palette.SAND, smoothstep(1.6, 0.6, h))
	if h < -0.2:
		c = Palette.SAND.darkened(0.12)
	if slope > 0.45 or h > 45.0:
		c = c.lerp(Palette.STONE, clampf(maxf((slope - 0.45) * 3.0, (h - 45.0) / 20.0), 0.0, 1.0))
	if h > 115.0:
		c = c.lerp(Color("f4f6fb"), clampf((h - 115.0) / 15.0, 0.0, 1.0))
	if not check_paths:
		return c
	var path_d: float = IslandLayout.distance_to_path(Vector2(x, z))
	if path_d < IslandLayout.PATH_HALF_WIDTH and h > 0.8:
		c = c.lerp(Palette.PATH, smoothstep(IslandLayout.PATH_HALF_WIDTH, IslandLayout.PATH_HALF_WIDTH * 0.5, path_d))
	return c


## Normale del terreno (per l'illuminazione e la pendenza).
func normal_at(x: float, z: float, step: float = 1.0) -> Vector3:
	var hx: float = height_at(x + step, z) - height_at(x - step, z)
	var hz: float = height_at(x, z + step) - height_at(x, z - step)
	return Vector3(-hx, 2.0 * step, -hz).normalized()


func _noise(s: int, freq: float, octaves: int) -> FastNoiseLite:
	var n: FastNoiseLite = FastNoiseLite.new()
	n.seed = s
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = freq
	n.fractal_octaves = octaves
	return n
