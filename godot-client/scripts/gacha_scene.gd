extends Control

const COIN_START_POS := Vector2(144, 0)
const COIN_DROP_Y := 140.0

@onready var coin_count_label: Label = $VBox/CoinCountLabel
@onready var machine_sprite: TextureRect = $VBox/MachineArea/MachineSprite
@onready var coin_sprite: TextureRect = $VBox/MachineArea/CoinSprite
@onready var reveal_holder: Control = $VBox/MachineArea/RevealHolder
@onready var result_label: Label = $VBox/ResultLabel
@onready var pull_button: Button = $VBox/PullButton
@onready var back_button: Button = $VBox/BackButton
@onready var status_request: HTTPRequest = $StatusRequest
@onready var gacha_request: HTTPRequest = $GachaRequest
@onready var coin_sound: AudioStreamPlayer = $CoinSound
@onready var spin_sound: AudioStreamPlayer = $SpinSound
@onready var hit_sound: AudioStreamPlayer = $HitSound
@onready var miss_sound: AudioStreamPlayer = $MissSound

const MonsterItemScene := preload("res://scenes/MonsterItem.tscn")

var current_coins: int = 0
var gacha_cost: int = 1
var is_pulling: bool = false

## コイン投入アニメーションとAPIリクエストが両方終わってから結果を見せるための
## 簡単な同期フラグ。片方だけ早く終わってもフラグが揃うまで結果表示を待つ。
var animation_done: bool = false
var response_done: bool = false
var pending_data = null
var pending_message: String = ""

func _ready() -> void:
	machine_sprite.pivot_offset = machine_sprite.size / 2
	coin_sprite.position = COIN_START_POS

	pull_button.pressed.connect(_on_pull_pressed)
	back_button.pressed.connect(_on_back_pressed)
	status_request.request_completed.connect(_on_status_completed)
	gacha_request.request_completed.connect(_on_gacha_completed)

	fetch_status()

func fetch_status() -> void:
	status_request.request(Api.BASE_URL + "/status", Api.auth_headers(), HTTPClient.METHOD_GET)

func _on_status_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if data is Dictionary:
		current_coins = data.get("coins", 0)
		_update_coin_label()

func _update_coin_label() -> void:
	coin_count_label.text = "所持コイン: %d枚" % current_coins
	pull_button.disabled = is_pulling or current_coins < gacha_cost

func _on_pull_pressed() -> void:
	if is_pulling:
		return

	is_pulling = true
	pull_button.disabled = true
	result_label.text = ""
	_clear_reveal()

	animation_done = false
	response_done = false
	pending_data = null
	pending_message = ""

	_play_coin_drop_animation()
	gacha_request.request(Api.BASE_URL + "/gacha", Api.auth_headers(), HTTPClient.METHOD_POST)

## コインが落ちる → ガチャマシンが揺れる、の順にアニメーションさせる。
## この絵はあくまで「回した」ことを伝える演出で、実際のコイン消費計算は
## サーバー側(Api::V1::GachaController)が担当している。
func _play_coin_drop_animation() -> void:
	coin_sprite.visible = true
	coin_sprite.position = COIN_START_POS
	coin_sound.play()

	var tween := create_tween()
	tween.tween_property(coin_sprite, "position:y", COIN_DROP_Y, 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): coin_sprite.visible = false)
	tween.tween_callback(_play_machine_shake)

func _play_machine_shake() -> void:
	spin_sound.play()
	var tween := create_tween()
	tween.tween_property(machine_sprite, "rotation_degrees", 4.0, 0.08)
	tween.tween_property(machine_sprite, "rotation_degrees", -4.0, 0.08)
	tween.tween_property(machine_sprite, "rotation_degrees", 4.0, 0.08)
	tween.tween_property(machine_sprite, "rotation_degrees", -4.0, 0.08)
	tween.tween_property(machine_sprite, "rotation_degrees", 0.0, 0.08)
	tween.tween_callback(_on_animation_finished)

func _on_animation_finished() -> void:
	animation_done = true
	_try_finish()

func _on_gacha_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 201:
		pending_data = JSON.parse_string(body.get_string_from_utf8())
	elif response_code == 422:
		pending_message = "コインが足りません。"
	else:
		pending_message = "通信エラーが発生しました。"

	response_done = true
	_try_finish()

func _try_finish() -> void:
	if not (animation_done and response_done):
		return

	if pending_data is Dictionary:
		_show_result(pending_data)
	else:
		result_label.text = pending_message

	is_pulling = false
	fetch_status()

## カプセルが開いてモンスターが飛び出すような演出でMonsterItemを表示する
func _show_result(data: Dictionary) -> void:
	var monster = data.get("monster")
	if data.get("hit", false) and monster is Dictionary:
		result_label.text = "🎉 %s を獲得しました！" % monster["name"]
		hit_sound.play()

		var item := MonsterItemScene.instantiate()
		reveal_holder.add_child(item)
		item.setup(monster["name"], monster["sprite_key"])
		item.scale = Vector2(0.2, 0.2)
		item.modulate.a = 0.0

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(item, "scale", Vector2(1.0, 1.0), 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(item, "modulate:a", 1.0, 0.25)
	else:
		result_label.text = "ハズレでした…また挑戦してください。"
		miss_sound.play()

func _clear_reveal() -> void:
	for child in reveal_holder.get_children():
		child.queue_free()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
