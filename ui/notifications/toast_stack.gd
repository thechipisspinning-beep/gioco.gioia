class_name ToastStack
extends VBoxContainer
## Notifiche brevi in alto a destra ("Nuovo animale nel diario!", ecc.).
## Ascolta `EventBus.notification_requested`.

const DURATION: float = 3.2
const MAX_VISIBLE: int = 4


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_BEGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 8)
	EventBus.notification_requested.connect(show_toast)


func _process(_delta: float) -> void:
	# In alto a destra, sotto i pulsanti Diario e Pausa.
	var area: Vector2 = get_parent_area_size()
	size = Vector2(420.0, get_combined_minimum_size().y)
	position = Vector2(area.x - size.x - 20.0, 94.0)


func show_toast(text: String) -> void:
	if get_child_count() >= MAX_VISIBLE:
		get_child(0).queue_free()
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 380.0
	label.add_theme_font_size_override("font_size", 18)
	panel.add_child(label)
	add_child(panel)
	panel.modulate.a = 0.0
	var t: Tween = panel.create_tween()
	t.tween_property(panel, "modulate:a", 1.0, 0.2)
	t.tween_interval(DURATION)
	t.tween_property(panel, "modulate:a", 0.0, 0.4)
	t.tween_callback(panel.queue_free)
