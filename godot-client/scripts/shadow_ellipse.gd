extends Control
## キャラクターの足元に敷く、楕円形の落ち影。ColorRectだと四角形にしかならないため、
## 自分の矩形いっぱいに楕円ポリゴンを描画する。

@export var shadow_color: Color = Color(0.15, 0.25, 0.12, 0.45)

func _draw() -> void:
	var points := PackedVector2Array()
	var sides := 24
	var rx: float = size.x / 2.0
	var ry: float = size.y / 2.0
	var center := Vector2(rx, ry)
	for i in sides:
		var angle: float = TAU * i / sides
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, shadow_color)
