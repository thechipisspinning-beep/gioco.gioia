class_name MeshCache
extends RefCounted
## Mesh primitive condivise: due animali della stessa specie usano le stesse
## sfere, capsule e cilindri invece di crearne di nuovi (meno memoria, meno
## lavoro per la GPU). Le mesh non vanno modificate dopo averle ottenute.

static var _cache: Dictionary = {}


static func sphere(radius: float, height: float, segments: int = 16, rings: int = 8) -> SphereMesh:
	var key: String = "s%.4f_%.4f_%d_%d" % [radius, height, segments, rings]
	if not _cache.has(key):
		var m: SphereMesh = SphereMesh.new()
		m.radius = radius
		m.height = height
		m.radial_segments = segments
		m.rings = rings
		_cache[key] = m
	return _cache[key] as SphereMesh


static func capsule(radius: float, height: float, segments: int = 12, rings: int = 4) -> CapsuleMesh:
	var key: String = "c%.4f_%.4f_%d_%d" % [radius, height, segments, rings]
	if not _cache.has(key):
		var m: CapsuleMesh = CapsuleMesh.new()
		m.radius = radius
		m.height = maxf(height, radius * 2.0)
		m.radial_segments = segments
		m.rings = rings
		_cache[key] = m
	return _cache[key] as CapsuleMesh


static func cylinder(top: float, bottom: float, height: float, segments: int = 12) -> CylinderMesh:
	var key: String = "y%.4f_%.4f_%.4f_%d" % [top, bottom, height, segments]
	if not _cache.has(key):
		var m: CylinderMesh = CylinderMesh.new()
		m.top_radius = top
		m.bottom_radius = bottom
		m.height = height
		m.radial_segments = segments
		_cache[key] = m
	return _cache[key] as CylinderMesh


static func box(size: Vector3) -> BoxMesh:
	var key: String = "b%.4f_%.4f_%.4f" % [size.x, size.y, size.z]
	if not _cache.has(key):
		var m: BoxMesh = BoxMesh.new()
		m.size = size
		_cache[key] = m
	return _cache[key] as BoxMesh


static func size() -> int:
	return _cache.size()
