class_name PhotoMode
extends Control
## Modalità foto (D-25): nasconde l'interfaccia, si inquadra con la telecamera
## libera e si scatta. Le foto (al massimo MAX_PHOTOS) finiscono in
## `user://photos` e si rivedono nel diario.

signal closed

const DIR: String = "user://photos"
const MAX_PHOTOS: int = 30

var hud_root: Control
var _hint: Label
var _flash: ColorRect
var _shooting: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint = MenuHelpers.body("", 18, Color.WHITE)
	_hint.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.35))
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.position = Vector2(24, 20)
	add_child(_hint)
	var shoot: Button = MenuHelpers.button(tr("PHOTO_SHOOT"), 160)
	shoot.name = "Shoot"
	shoot.focus_mode = Control.FOCUS_NONE
	shoot.pressed.connect(shoot_photo)
	add_child(shoot)
	var exit: Button = MenuHelpers.button(tr("PHOTO_EXIT"), 160)
	exit.name = "Exit"
	exit.focus_mode = Control.FOCUS_NONE
	exit.pressed.connect(close)
	add_child(exit)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)
	visible = false


func open() -> void:
	_hint.text = tr("PHOTO_HINT")
	visible = true
	_set_hud_visible(false)


func close() -> void:
	if not visible:
		return
	visible = false
	_set_hud_visible(true)
	closed.emit()


func _process(_delta: float) -> void:
	if not visible:
		return
	var area: Vector2 = get_parent_area_size()
	var shoot: Button = get_node("Shoot") as Button
	var exit: Button = get_node("Exit") as Button
	shoot.position = Vector2(area.x - 360, area.y - 90)
	exit.position = Vector2(area.x - 185, area.y - 90)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		shoot_photo()
	elif event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## Scatta: nasconde anche i pulsanti per un frame, salva l'immagine, lampo bianco.
func shoot_photo() -> void:
	if _shooting:
		return
	_shooting = true
	for c: Node in get_children():
		(c as CanvasItem).visible = false
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	for c: Node in get_children():
		(c as CanvasItem).visible = true
	if img != null and not img.is_empty():
		save_photo(img)
		EventBus.notification_requested.emit(tr("PHOTO_SAVED"))
	_flash.color.a = 0.8
	var t: Tween = create_tween()
	t.tween_property(_flash, "color:a", 0.0, 0.35)
	_shooting = false


static func save_photo(img: Image) -> String:
	DirAccess.make_dir_recursive_absolute(DIR)
	var path: String = DIR.path_join("foto_%d_%d.png" % [Time.get_unix_time_from_system(), Time.get_ticks_msec() % 1000])
	# Foto più leggere: larghezza massima 960 px.
	if img.get_width() > 960:
		img.resize(960, int(img.get_height() * 960.0 / img.get_width()))
	img.save_png(path)
	var all: PackedStringArray = list_photos()
	while all.size() > MAX_PHOTOS:
		DirAccess.remove_absolute(all[0])
		all.remove_at(0)
	return path


## Foto salvate, dalla più vecchia alla più recente.
static func list_photos() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var dir: DirAccess = DirAccess.open(DIR)
	if dir == null:
		return out
	for f: String in dir.get_files():
		if f.ends_with(".png"):
			out.append(DIR.path_join(f))
	out.sort()
	return out


func _set_hud_visible(v: bool) -> void:
	if hud_root == null:
		return
	for c: Node in hud_root.get_children():
		if c != self and c is CanvasItem:
			(c as CanvasItem).visible = v if c.name in ["ClockLabel", "HintLabel"] or c is QuestTracker or c is ToastStack else (c as CanvasItem).visible and v
