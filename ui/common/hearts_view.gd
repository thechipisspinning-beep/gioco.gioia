class_name HeartsView
extends Control
## Mostra l'amicizia come 5 cuori (pieni/vuoti), disegnati in vettoriale.

@export var hearts: int = 0:
	set(value):
		hearts = clampi(value, 0, max_hearts)
		queue_redraw()
@export var max_hearts: int = 5
@export var heart_size: float = 22.0
@export var spacing: float = 6.0


func _ready() -> void:
	custom_minimum_size = Vector2(max_hearts * (heart_size + spacing) - spacing, heart_size)


func _draw() -> void:
	for i: int in max_hearts:
		var center: Vector2 = Vector2(i * (heart_size + spacing) + heart_size * 0.5, heart_size * 0.5)
		var color: Color = UITheme.HEART_FULL if i < hearts else UITheme.HEART_EMPTY
		_draw_heart(center, heart_size * 0.5, color)


func _draw_heart(c: Vector2, r: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in 32:
		var t: float = TAU * i / 32.0
		# Curva del cuore (forma classica), scalata e capovolta per lo schermo.
		var x: float = 16.0 * pow(sin(t), 3)
		var y: float = 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		pts.append(c + Vector2(x, -y - 2.0) * (r / 17.0))
	draw_colored_polygon(pts, color)
