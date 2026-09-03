extends Control
## モンスター図鑑の詳細ページ。MonsterBookState.monsters / selected_index を見て描画する。
## 所持済みは常時ループのTweenアニメーションで動き続け、未所持はシルエットのまま静止する。

@onready var prev_button: Button = $VBox/Row/PrevButton
@onready var next_button: Button = $VBox/Row/NextButton
@onready var no_label: Label = $VBox/Row/Card/TopRow/NoLabel
@onready var type_label: Label = $VBox/Row/Card/TopRow/TypeLabel
@onready var icon: TextureRect = $VBox/Row/Card/IconArea/Icon
@onready var name_label: Label = $VBox/Row/Card/NameLabel
@onready var desc_label: Label = $VBox/Row/Card/DescLabel
@onready var back_button: Button = $VBox/BackButton

const MONSTER_ASSET_DIR := "res://assets/monsters/"
const LOCKED_TINT := Color(0.18, 0.18, 0.18, 1.0)

var idle_tween: Tween = null

func _ready() -> void:
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	back_button.pressed.connect(_on_back_pressed)
	# TextureRectの中心を軸に回転させたいので、レイアウト確定後にピボットを設定する。
	# 足元(下端)を軸のままにすると、回転時にキャラクターが名前テキストへはみ出す
	# (Web版のCSS実装で実際に発生させたバグと同じ原因)。
	icon.pivot_offset = icon.size / 2.0
	_render()

func _render() -> void:
	var monsters: Array = MonsterBookState.monsters
	var index: int = MonsterBookState.selected_index
	if monsters.is_empty() or index < 0 or index >= monsters.size():
		get_tree().change_scene_to_file("res://scenes/MonsterBookScene.tscn")
		return

	var m = monsters[index]
	var owned: bool = m.get("owned", false)

	no_label.text = "No.%03d" % (index + 1)

	var texture := load(MONSTER_ASSET_DIR + String(m["sprite_key"]))
	if texture is Texture2D:
		icon.texture = texture

	if idle_tween:
		idle_tween.kill()
		idle_tween = null

	icon.position = Vector2.ZERO
	icon.rotation_degrees = 0.0
	icon.scale = Vector2.ONE

	if owned:
		type_label.text = String(m.get("type_label", "モンスター"))
		name_label.text = String(m["name"])
		desc_label.text = String(m.get("description", ""))
		icon.modulate = Color.WHITE
		idle_tween = _apply_idle_animation(icon, String(m.get("animation_class", "anim-bounce")))
	else:
		type_label.text = "未確認"
		name_label.text = "？？？"
		desc_label.text = "まだ出会っていないモンスターだ。ガチャで探してみよう。"
		icon.modulate = LOCKED_TINT

	prev_button.disabled = index <= 0
	next_button.disabled = index >= monsters.size() - 1

## Web版CSS(application.css)の6種のアニメーションをGodotのTweenで再現する。
## いずれも常時ループ(set_loops())。
func _apply_idle_animation(sprite: Control, anim_class: String) -> Tween:
	var tween := create_tween()
	tween.set_loops()

	match anim_class:
		"anim-sway":
			tween.tween_property(sprite, "rotation_degrees", 9.0, 1.3) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(sprite, "rotation_degrees", -9.0, 1.3) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		"anim-hop":
			tween.tween_property(sprite, "position:y", -26.0, 0.3) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(sprite, "position:y", 0.0, 0.3) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_interval(0.5)
			tween.tween_property(sprite, "position:y", -26.0, 0.3) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(sprite, "position:y", 0.0, 0.3) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_interval(0.5)
		"anim-jiggle":
			tween.tween_property(sprite, "rotation_degrees", 5.0, 0.2)
			tween.tween_property(sprite, "rotation_degrees", -5.0, 0.2)
			tween.tween_property(sprite, "rotation_degrees", 3.0, 0.2)
			tween.tween_property(sprite, "rotation_degrees", 0.0, 0.2)
			tween.tween_interval(0.8)
		"anim-spinhop":
			tween.tween_property(sprite, "position:y", -30.0, 0.5) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(sprite, "rotation_degrees", 360.0, 1.0) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(sprite, "position:y", 0.0, 0.5) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_callback(func(): sprite.rotation_degrees = 0.0)
			tween.tween_interval(0.4)
		"anim-float":
			tween.tween_property(sprite, "position:y", -16.0, 1.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(sprite, "position:y", 0.0, 1.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_: # "anim-bounce" をデフォルトとする
			tween.tween_property(sprite, "position:y", -38.0, 0.35) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(sprite, "position:y", 0.0, 0.35) \
				.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tween.tween_interval(0.6)

	return tween

func _on_prev_pressed() -> void:
	MonsterBookState.selected_index -= 1
	_render()

func _on_next_pressed() -> void:
	MonsterBookState.selected_index += 1
	_render()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MonsterBookScene.tscn")
