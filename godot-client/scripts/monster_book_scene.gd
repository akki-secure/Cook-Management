extends Control
## モンスター図鑑(一覧)。全モンスターをNo.順に表示し、未所持はMonsterItem側で
## シルエット表示にする。タップされたモンスターの位置をMonsterBookStateに記録して
## 詳細シーンへ渡す。

@onready var counter_label: Label = $VBox/CounterLabel
@onready var monster_grid: GridContainer = $VBox/MonsterScroll/MonsterGrid
@onready var back_button: Button = $VBox/BackButton
@onready var book_request: HTTPRequest = $BookRequest

const MonsterItemScene := preload("res://scenes/MonsterItem.tscn")

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	book_request.request_completed.connect(_on_book_completed)
	fetch_book()

func fetch_book() -> void:
	book_request.request(Api.BASE_URL + "/monsters/book", Api.auth_headers(), HTTPClient.METHOD_GET)

func _on_book_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		return

	var monsters = JSON.parse_string(body.get_string_from_utf8())
	if not (monsters is Array):
		return

	MonsterBookState.monsters = monsters

	for child in monster_grid.get_children():
		child.queue_free()

	var owned_count := 0
	for i in monsters.size():
		var m = monsters[i]
		var owned: bool = m.get("owned", false)
		if owned:
			owned_count += 1

		var item := MonsterItemScene.instantiate()
		monster_grid.add_child(item)
		item.setup(m["name"], m["sprite_key"], owned)
		item.tapped.connect(_on_tile_tapped.bind(i))

	counter_label.text = "所持数 %d / 全%d体" % [owned_count, monsters.size()]

func _on_tile_tapped(index: int) -> void:
	MonsterBookState.selected_index = index
	get_tree().change_scene_to_file("res://scenes/MonsterDetailScene.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
