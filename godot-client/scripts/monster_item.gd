extends Control
## モンスターのイラストを表示する。sprite_keyには画像ファイル名(例: "egg_character.png")が
## 入っており、res://assets/monsters/ 以下から読み込んで表示する。

@onready var icon: TextureRect = $Icon
@onready var name_label: Label = $NameLabel

const MONSTER_ASSET_DIR := "res://assets/monsters/"

func setup(monster_name: String, sprite_key: String) -> void:
	name_label.text = monster_name

	var texture := load(MONSTER_ASSET_DIR + sprite_key)
	if texture is Texture2D:
		icon.texture = texture
