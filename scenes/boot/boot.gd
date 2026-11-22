extends Node
## Scena di avvio: inizializza ciò che serve e passa alla prima scena di gioco.
## Per ora porta direttamente alla sandbox di movimento (Fase 3); in seguito
## porterà al menu principale.

const FIRST_SCENE: String = "res://scenes/sandbox/movement_sandbox.tscn"


func _ready() -> void:
	_apply_locale()
	get_tree().change_scene_to_file.call_deferred(FIRST_SCENE)


func _apply_locale() -> void:
	var system_lang: String = OS.get_locale_language()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):
			system_lang = arg.trim_prefix("--lang=")
	TranslationServer.set_locale("it" if system_lang == "it" else "en")
