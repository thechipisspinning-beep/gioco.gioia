extends Node
## Impostazioni del giocatore (non della partita): lingua e in futuro volumi,
## grafica, controlli. Salvate in `user://settings.cfg`.

const PATH: String = "user://settings.cfg"

var _cfg: ConfigFile = ConfigFile.new()


func _ready() -> void:
	_cfg.load(PATH)


## Lingua scelta dal giocatore, o "" se non l'ha mai scelta.
func get_language() -> String:
	return str(_cfg.get_value("general", "language", ""))


func set_language(lang: String) -> void:
	_cfg.set_value("general", "language", lang)
	_cfg.save(PATH)
