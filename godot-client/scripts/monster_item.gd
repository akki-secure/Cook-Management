extends Control
## モンスターの画像素材がまだ無いため、sprite_key(例: "color:red;shape:circle")を
## 解析して図形を自前で描画するプレースホルダー表示。素材が用意できたら
## _draw()の中身をTextureRect表示に差し替えるだけで済むようにしてある。

@onready var name_label: Label = $NameLabel

var shape_color: Color = Color.GRAY
var shape_type: String = "circle"

const COLOR_TABLE := {
	"red": Color.RED,
	"orange": Color.ORANGE,
	"yellow": Color.YELLOW,
	"green": Color.GREEN,
	"blue": Color.BLUE,
	"purple": Color.PURPLE,
	"gold": Color(0.85, 0.65, 0.13),
	"silver": Color(0.75, 0.75, 0.75),
	"rainbow": Color.MAGENTA,
	"diamond": Color(0.6, 0.9, 1.0),
}

func setup(monster_name: String, sprite_key: String) -> void:
	name_label.text = monster_name

	var parts := {}
	for pair in sprite_key.split(";"):
		var kv := pair.split(":")
		if kv.size() == 2:
			parts[kv[0]] = kv[1]

	shape_color = COLOR_TABLE.get(parts.get("color", ""), Color.GRAY)
	shape_type = parts.get("shape", "circle")
	queue_redraw()

func _draw() -> void:
	var center := Vector2(32, 32)
	var radius := 24.0

	match shape_type:
		"circle":
			draw_circle(center, radius, shape_color)
		"triangle":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, -radius),
				center + Vector2(radius, radius),
				center + Vector2(-radius, radius),
			]), shape_color)
		"square":
			draw_rect(Rect2(center - Vector2(radius, radius), Vector2(radius * 2, radius * 2)), shape_color)
		"star", "crown":
			draw_colored_polygon(_star_points(center, radius), shape_color)
		_:
			draw_circle(center, radius, shape_color)

func _star_points(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var inner := radius * 0.5
	for i in range(10):
		var angle := i * PI / 5.0 - PI / 2.0
		var r := radius if i % 2 == 0 else inner
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	return points
