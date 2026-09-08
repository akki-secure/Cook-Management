extends Control
## アプリ起動後、ログインを終えたら最初に表示されるタイトル画面。
## 「スタート」を押すとマイページ(Main.tscn)へ進む。

@onready var start_button: Button = $VBox/StartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
