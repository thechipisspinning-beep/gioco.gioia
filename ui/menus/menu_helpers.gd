class_name MenuHelpers
extends RefCounted
## Piccole funzioni per costruire menu coerenti (pulsanti grandi, titoli, pannelli centrati).


static func button(text: String, min_width: float = 360.0) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 58)
	b.add_theme_font_size_override("font_size", 22)
	return b


static func title(text: String, size: int = 30) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	return l


static func body(text: String, size: int = 18, color: Color = UITheme.TEXT) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## Pannello centrato a tutto schermo con sfondo semitrasparente; restituisce il VBox interno.
static func centered_panel(parent: Control, min_width: float = 460.0, dim: bool = true) -> VBoxContainer:
	var holder: Control = Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(holder)
	if dim:
		var shade: ColorRect = ColorRect.new()
		shade.color = Color(0.2, 0.14, 0.25, 0.45)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(min_width, 0)
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	return box


## Rimuove il pannello creato da `centered_panel` partendo dal suo VBox.
static func close_panel(box: VBoxContainer) -> void:
	if box != null and is_instance_valid(box):
		box.get_parent().get_parent().get_parent().queue_free()


static func format_slot(summary: Dictionary) -> String:
	if summary.is_empty():
		return TranslationServer.translate("SLOT_EMPTY")
	var date: String = Time.get_datetime_string_from_unix_time(int(summary.get("saved_at", 0)), true).substr(0, 16)
	return TranslationServer.translate("SLOT_SUMMARY") % [int(summary.get("day", 1)), int(summary.get("adopted", 0)), int(summary.get("species_met", 0)), date]
