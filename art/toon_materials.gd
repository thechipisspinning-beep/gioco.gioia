class_name ToonMaterials
extends RefCounted
## Fornisce materiali toon condivisi, uno per colore.
##
## Riutilizzare lo stesso materiale per tutti gli oggetti dello stesso colore
## riduce i cambi di stato della GPU (importante su mobile) e mantiene la palette coerente.

const TOON_SHADER: Shader = preload("res://art/shaders/toon.gdshader")

static var _cache: Dictionary = {}


## Restituisce il materiale toon condiviso per `color`.
static func get_material(color: Color) -> ShaderMaterial:
	var key: String = color.to_html(false)
	if _cache.has(key):
		return _cache[key] as ShaderMaterial
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = TOON_SHADER
	mat.set_shader_parameter("albedo", color)
	_cache[key] = mat
	return mat


## Materiale toon bianco che prende il colore da ogni istanza di un MultiMesh.
static func get_vertex_color_material() -> ShaderMaterial:
	const KEY: String = "__vertex_color__"
	if _cache.has(KEY):
		return _cache[KEY] as ShaderMaterial
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = TOON_SHADER
	mat.set_shader_parameter("albedo", Color.WHITE)
	mat.set_shader_parameter("use_vertex_color", true)
	_cache[KEY] = mat
	return mat
