extends Control
## モンスターのイラストを表示する。sprite_keyには画像ファイル名(例: "egg_character.png")が
## 入っており、res://assets/monsters/ 以下から読み込んで表示する。
##
## 図鑑一覧(MonsterBookScene)でも同じシーンを使い回す。owned=falseのときは
## シルエット表示にし、名前を「？？？」にする。tappedシグナルは図鑑一覧でのみ
## 購読される(所持一覧・ガチャ演出での既存の使い方には影響しない)。

signal tapped

@onready var icon: TextureRect = $Icon
@onready var name_label: Label = $NameLabel

const MONSTER_ASSET_DIR := "res://assets/monsters/"
const LOCKED_TINT := Color(0.18, 0.18, 0.18, 1.0)

func setup(monster_name: String, sprite_key: String, owned: bool = true) -> void:
	var texture := load(MONSTER_ASSET_DIR + sprite_key)
	if texture is Texture2D:
		icon.texture = texture

	if owned:
		name_label.text = monster_name
		icon.modulate = Color.WHITE
	else:
		name_label.text = "？？？"
		icon.modulate = LOCKED_TINT

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		tapped.emit()
