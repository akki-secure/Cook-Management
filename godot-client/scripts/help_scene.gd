extends Control
## 使い方(ヘルプ)画面。メイン画面のレプリカに矢印と説明を重ねて表示する静的な画面。

@onready var back_button: Button = $Scroll/VBox/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
