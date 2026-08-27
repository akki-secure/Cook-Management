extends Control

@onready var title_label: Label = $VBox/TitleLabel
@onready var level_label: Label = $VBox/LevelLabel
@onready var exp_bar: ProgressBar = $VBox/ExpBar
@onready var exp_label: Label = $VBox/ExpLabel
@onready var streak_label: Label = $VBox/StreakLabel
@onready var coin_label: Label = $VBox/CoinLabel
@onready var monster_grid: GridContainer = $VBox/MonsterScroll/MonsterGrid
@onready var status_request: HTTPRequest = $StatusRequest
@onready var monsters_request: HTTPRequest = $MonstersRequest
@onready var poll_timer: Timer = $PollTimer

const MonsterItemScene := preload("res://scenes/MonsterItem.tscn")

func _ready() -> void:
	status_request.request_completed.connect(_on_status_completed)
	monsters_request.request_completed.connect(_on_monsters_completed)
	poll_timer.timeout.connect(refresh)
	refresh()

## 起動時と、Timer(30秒間隔)のたびに現在のレベル/EXP/モンスターを取得し直す。
## リアルタイム通知ではなく、ポーリングで十分という設計方針(WebSocketは将来拡張)。
func refresh() -> void:
	var headers := Api.auth_headers()
	status_request.request(Api.BASE_URL + "/status", headers, HTTPClient.METHOD_GET)
	monsters_request.request(Api.BASE_URL + "/monsters", headers, HTTPClient.METHOD_GET)

func _on_status_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if not (data is Dictionary):
		return

	title_label.text = data.get("current_title", "") if data.get("current_title") else "称号なし"
	level_label.text = "Lv. %d" % data["level"]

	var exp: int = data["exp"]
	var next_level_exp = data.get("next_level_exp")
	if next_level_exp:
		exp_bar.max_value = next_level_exp
		exp_bar.value = exp
		exp_label.text = "%d / %d EXP" % [exp, next_level_exp]
	else:
		exp_bar.max_value = 1
		exp_bar.value = 1
		exp_label.text = "%d EXP (最大レベル)" % exp

	streak_label.text = "連続記録: %d日（最長 %d日）" % [data["current_streak_days"], data["longest_streak_days"]]
	coin_label.text = "所持コイン: %d枚" % data.get("coins", 0)

func _on_monsters_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		return

	var monsters = JSON.parse_string(body.get_string_from_utf8())
	if not (monsters is Array):
		return

	for child in monster_grid.get_children():
		child.queue_free()

	for m in monsters:
		var item := MonsterItemScene.instantiate()
		monster_grid.add_child(item)
		item.setup(m["name"], m["sprite_key"])
