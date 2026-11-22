class_name MenuDecor
extends Control
## Decorazioni morbide del menu principale: colline, nuvole e fiori disegnati in vettoriale.

var _t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	# Nuvole che scorrono lentamente
	for i: int in 4:
		var x: float = fmod(i * w * 0.31 + _t * (12.0 + i * 4.0), w + 300.0) - 150.0
		var y: float = h * (0.1 + 0.07 * i)
		for j: int in 3:
			draw_circle(Vector2(x + j * 38.0, y - (12.0 if j == 1 else 0.0)), 34.0 - absf(j - 1) * 8.0, Color(1, 1, 1, 0.85))
	# Colline
	_hill(Vector2(w * 0.2, h * 1.15), w * 0.55, Color("8ccf6b"))
	_hill(Vector2(w * 0.85, h * 1.2), w * 0.6, Color("7cc462"))
	_hill(Vector2(w * 0.5, h * 1.35), w * 0.7, Color("9ad970"))
	# Fiori
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	var colors: Array[Color] = [Palette.FLOWER_PINK, Palette.FLOWER_YELLOW, Palette.FLOWER_WHITE, Palette.FLOWER_BLUE]
	for i: int in 40:
		var p: Vector2 = Vector2(rng.randf() * w, h * rng.randf_range(0.82, 0.98))
		var sway: float = sin(_t * 1.5 + i) * 2.0
		draw_circle(p + Vector2(sway, 0), rng.randf_range(4.0, 7.0), colors[i % colors.size()])


func _hill(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius, color)
