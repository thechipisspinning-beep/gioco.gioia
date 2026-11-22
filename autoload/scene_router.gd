extends CanvasLayer
## Cambi di scena con dissolvenza (D-14: interni in scene separate) e punto
## di arrivo ("spawn") nella scena di destinazione.

const FADE_TIME: float = 0.35

var _rect: ColorRect
var _pending_spawn: StringName = &""
var _busy: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.16, 0.12, 0.2, 0.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)


func is_busy() -> bool:
	return _busy


## Va alla scena `path`; la scena di arrivo legge il punto con `take_spawn()`.
func go_to(path: String, spawn: StringName) -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var t: Tween = create_tween()
	t.tween_property(_rect, "color:a", 1.0, FADE_TIME)
	await t.finished
	_pending_spawn = spawn
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	SaveManager.autosave()
	var t2: Tween = create_tween()
	t2.tween_property(_rect, "color:a", 0.0, FADE_TIME)
	await t2.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func take_spawn() -> StringName:
	var s: StringName = _pending_spawn
	_pending_spawn = &""
	return s
