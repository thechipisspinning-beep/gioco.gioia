class_name UITheme
extends RefCounted
## Stile grafico comune dell'interfaccia (GDD § 12.1): pannelli color crema con
## angoli arrotondati, testo viola scuro, pulsanti grandi (adatti anche al touch).

const PANEL: Color = Color("fff8ec")
const PANEL_BORDER: Color = Color("e8c9a6")
const TEXT: Color = Color("4a3a55")
const TEXT_SOFT: Color = Color("8a7a92")
const ACCENT: Color = Color("ff8a7a")
const BUTTON: Color = Color("ffe9d2")
const BUTTON_HOVER: Color = Color("ffd7b0")
const BUTTON_PRESSED: Color = Color("ffc28f")
const HEART_FULL: Color = Color("ff6f91")
const HEART_EMPTY: Color = Color("e9d9df")

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t: Theme = Theme.new()
	t.default_font_size = 20
	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, PANEL_BORDER, 18, 3))
	t.set_stylebox("panel", "Panel", _box(PANEL, PANEL_BORDER, 18, 3))
	t.set_stylebox("normal", "Button", _box(BUTTON, PANEL_BORDER, 14, 2))
	t.set_stylebox("hover", "Button", _box(BUTTON_HOVER, PANEL_BORDER, 14, 2))
	t.set_stylebox("pressed", "Button", _box(BUTTON_PRESSED, PANEL_BORDER, 14, 2))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), ACCENT, 14, 4))
	t.set_stylebox("disabled", "Button", _box(Color("f3ece4"), PANEL_BORDER, 14, 2))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(state, "Button", TEXT)
	t.set_color("font_disabled_color", "Button", TEXT_SOFT)
	t.set_stylebox("normal", "LineEdit", _box(Color.WHITE, PANEL_BORDER, 12, 2))
	t.set_stylebox("focus", "LineEdit", _box(Color.WHITE, ACCENT, 12, 3))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("caret_color", "LineEdit", ACCENT)
	_theme = t
	return t


static func _box(bg: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0.29, 0.2, 0.33, 0.18)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	return sb
