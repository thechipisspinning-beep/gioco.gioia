extends Node
## Scena di avvio: imposta la lingua e apre il menu principale.

const FIRST_SCENE: String = "res://scenes/main_menu/main_menu.tscn"


func _ready() -> void:
	_apply_locale()
	var scene: String = FIRST_SCENE
	# Strumenti di sviluppo: `-- --scene=res://...` apre direttamente una scena.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			scene = arg.trim_prefix("--scene=")
	get_tree().change_scene_to_file.call_deferred(scene)


func _apply_locale() -> void:
	var lang: String = Settings.get_language()
	if lang == "":
		lang = "it" if OS.get_locale_language() == "it" else "en"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):
			lang = arg.trim_prefix("--lang=")
	TranslationServer.set_locale(lang)
