extends Node
## Impostazioni del giocatore (non della partita): lingua e in futuro volumi,
## grafica, controlli. Salvate in `user://settings.cfg`.

const PATH: String = "user://settings.cfg"

var _cfg: ConfigFile = ConfigFile.new()


## Qualità grafica: 0 = bassa (telefoni, web), 1 = media, 2 = alta.
signal quality_changed(level: int)

enum Quality { LOW, MEDIUM, HIGH }


func _ready() -> void:
	_cfg.load(PATH)


## Qualità scelta o, se mai scelta, predefinita per il dispositivo.
func get_quality() -> int:
	var default: int = Quality.LOW if OS.has_feature("mobile") or OS.has_feature("web") else Quality.HIGH
	return int(_cfg.get_value("graphics", "quality", default))


func set_quality(level: int) -> void:
	_cfg.set_value("graphics", "quality", clampi(level, 0, 2))
	_cfg.save(PATH)
	apply_quality()
	quality_changed.emit(get_quality())


## Applica le impostazioni globali (risoluzione 3D) alla finestra.
func apply_quality() -> void:
	var vp: Viewport = get_tree().root
	vp.scaling_3d_scale = [0.7, 0.85, 1.0][get_quality()]
	vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_2X][get_quality()]


## Lingua scelta dal giocatore, o "" se non l'ha mai scelta.
func get_language() -> String:
	return str(_cfg.get_value("general", "language", ""))


func set_language(lang: String) -> void:
	_cfg.set_value("general", "language", lang)
	_cfg.save(PATH)
