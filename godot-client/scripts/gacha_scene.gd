extends Control

const COIN_START_POS := Vector2(144, 0)
const COIN_DROP_Y := 140.0

const CAPSULE_COLORS := ["blue", "green", "pink", "purple", "red", "yellow"]
const KNOB_FRAME_COUNT := 4
const GACHA_ASSET_DIR := "res://assets/gacha/"
const CAPSULE_START_POS := Vector2(128, 190)
const CAPSULE_DROP_POS_Y := 290.0
const DOME_CAPSULE_RADIUS := 44.0

@onready var coin_count_label: Label = $VBox/CoinCountLabel
@onready var rainbow_coin_count_label: Label = $VBox/RainbowCoinCountLabel
@onready var machine_sprite: TextureRect = $VBox/MachineArea/MachineSprite
@onready var coin_sprite: TextureRect = $VBox/MachineArea/CoinSprite
@onready var knob_sprite: TextureRect = $VBox/MachineArea/KnobSprite
@onready var capsule_sprite: TextureRect = $VBox/MachineArea/CapsuleSprite
@onready var dome_swirl: Node2D = $VBox/MachineArea/DomeSwirl
@onready var reveal_holder: Control = $VBox/MachineArea/RevealHolder
@onready var seven_result_scroll: ScrollContainer = $VBox/SevenResultScroll
@onready var seven_result_row: HBoxContainer = $VBox/SevenResultScroll/SevenResultRow
@onready var result_label: Label = $VBox/ResultLabel
@onready var pull_button: Button = $VBox/PullButton
@onready var seven_pull_button: Button = $VBox/SevenPullButton
@onready var back_button: Button = $VBox/BackButton
@onready var status_request: HTTPRequest = $StatusRequest
@onready var gacha_request: HTTPRequest = $GachaRequest
@onready var seven_gacha_request: HTTPRequest = $SevenGachaRequest
@onready var coin_sound: AudioStreamPlayer = $CoinSound
@onready var spin_sound: AudioStreamPlayer = $SpinSound
@onready var hit_sound: AudioStreamPlayer = $HitSound
@onready var miss_sound: AudioStreamPlayer = $MissSound
@onready var knob_sound: AudioStreamPlayer = $KnobSound
@onready var capsule_drop_sound: AudioStreamPlayer = $CapsuleDropSound

const MonsterItemScene := preload("res://scenes/MonsterItem.tscn")

var current_coins: int = 0
var current_rainbow_coins: int = 0
var gacha_cost: int = 1
var seven_gacha_cost: int = 1
var is_pulling: bool = false

## コイン投入アニメーションとAPIリクエストが両方終わってから結果を見せるための
## 簡単な同期フラグ。片方だけ早く終わってもフラグが揃うまで結果表示を待つ。
var animation_done: bool = false
var response_done: bool = false
var pending_data = null
var pending_message: String = ""
var is_seven_pull: bool = false

func _ready() -> void:
	machine_sprite.pivot_offset = machine_sprite.size / 2
	coin_sprite.position = COIN_START_POS
	capsule_sprite.position = CAPSULE_START_POS
	_setup_dome_swirl()

	pull_button.pressed.connect(_on_pull_pressed)
	seven_pull_button.pressed.connect(_on_seven_pull_pressed)
	back_button.pressed.connect(_on_back_pressed)
	status_request.request_completed.connect(_on_status_completed)
	gacha_request.request_completed.connect(_on_gacha_completed)
	seven_gacha_request.request_completed.connect(_on_seven_gacha_completed)

	fetch_status()

func fetch_status() -> void:
	status_request.request(Api.BASE_URL + "/status", Api.auth_headers(), HTTPClient.METHOD_GET)

func _on_status_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if data is Dictionary:
		current_coins = data.get("coins", 0)
		current_rainbow_coins = data.get("rainbow_coins", 0)
		_update_coin_label()

func _update_coin_label() -> void:
	coin_count_label.text = "所持コイン: %d枚" % current_coins
	rainbow_coin_count_label.text = "所持レインボーコイン: %d枚" % current_rainbow_coins
	pull_button.disabled = is_pulling or current_coins < gacha_cost
	seven_pull_button.disabled = is_pulling or current_rainbow_coins < seven_gacha_cost

func _on_pull_pressed() -> void:
	if is_pulling:
		return

	is_pulling = true
	is_seven_pull = false
	pull_button.disabled = true
	seven_pull_button.disabled = true
	result_label.text = ""
	_clear_reveal()
	seven_result_scroll.visible = false

	animation_done = false
	response_done = false
	pending_data = null
	pending_message = ""

	_play_coin_drop_animation()
	gacha_request.request(Api.BASE_URL + "/gacha", Api.auth_headers(), HTTPClient.METHOD_POST)

func _on_seven_pull_pressed() -> void:
	if is_pulling:
		return

	is_pulling = true
	is_seven_pull = true
	pull_button.disabled = true
	seven_pull_button.disabled = true
	result_label.text = ""
	_clear_reveal()
	seven_result_scroll.visible = false

	animation_done = false
	response_done = false
	pending_data = null
	pending_message = ""

	_play_coin_drop_animation()
	seven_gacha_request.request(Api.BASE_URL + "/gacha/seven", Api.auth_headers(), HTTPClient.METHOD_POST)

## ドーム内に6色ぶんのカプセルを均等配置しておく(常時は静止していて、
## レバーを回している間だけ_play_knob_turn()がdome_swirlごと回転させる)。
func _setup_dome_swirl() -> void:
	for i in range(CAPSULE_COLORS.size()):
		var sprite: Sprite2D = dome_swirl.get_child(i)
		sprite.texture = load("%scapsule_%s.png" % [GACHA_ASSET_DIR, CAPSULE_COLORS[i]])
		sprite.scale = Vector2(0.1, 0.1)
		var angle := deg_to_rad(i * 360.0 / CAPSULE_COLORS.size())
		sprite.position = Vector2(DOME_CAPSULE_RADIUS, 0).rotated(angle)

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
	tween.tween_callback(_play_knob_turn)

## レバーを4コマ差し替えて回転を表現する。ドーム内のカプセルも
## レバーを回している間だけ連動してくるくる回す。
func _play_knob_turn() -> void:
	knob_sound.play()
	knob_sprite.visible = true

	var dome_tween := create_tween()
	dome_tween.tween_property(dome_swirl, "rotation_degrees", dome_swirl.rotation_degrees + 360.0, 0.6)

	var tween := create_tween()
	for i in range(1, KNOB_FRAME_COUNT + 1):
		var frame_path := "%sgacha_knob_turn_%d.png" % [GACHA_ASSET_DIR, i]
		tween.tween_callback(func(): knob_sprite.texture = load(frame_path))
		tween.tween_interval(0.12)
	tween.tween_callback(func(): knob_sprite.visible = false)
	tween.tween_callback(_play_capsule_stage)

## ランダムな色のカプセルが落ちてきて、少し止まってから開く。
## 色は結果モンスターのrarityとは無関係な、見た目だけのランダム演出。
func _play_capsule_stage() -> void:
	var color: String = CAPSULE_COLORS[randi() % CAPSULE_COLORS.size()]
	var closed_texture := load("%scapsule_%s.png" % [GACHA_ASSET_DIR, color])
	var open_texture := load("%scapsule_open_%s.png" % [GACHA_ASSET_DIR, color])

	capsule_sprite.texture = closed_texture
	capsule_sprite.position = CAPSULE_START_POS
	capsule_sprite.scale = Vector2(1.0, 1.0)
	capsule_sprite.visible = true
	capsule_drop_sound.play()

	var tween := create_tween()
	tween.tween_property(capsule_sprite, "position:y", CAPSULE_DROP_POS_Y, 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(0.15)
	tween.tween_callback(func(): capsule_sprite.texture = open_texture)
	tween.tween_property(capsule_sprite, "scale", Vector2(1.15, 1.15), 0.1) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(capsule_sprite, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_callback(func(): capsule_sprite.visible = false)
	tween.tween_callback(_on_animation_finished)

func _on_animation_finished() -> void:
	animation_done = true
	_try_finish()

func _on_gacha_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 201:
		pending_data = JSON.parse_string(body.get_string_from_utf8())
	elif response_code == 422:
		pending_message = _gacha_error_message(body, "コインが足りません。")
	else:
		pending_message = "通信エラーが発生しました。"

	response_done = true
	_try_finish()

func _on_seven_gacha_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 201:
		pending_data = JSON.parse_string(body.get_string_from_utf8())
	elif response_code == 422:
		pending_message = _gacha_error_message(body, "レインボーコインが足りません。")
	else:
		pending_message = "通信エラーが発生しました。"

	response_done = true
	_try_finish()

## 422応答のerrorフィールドを見て適切な文言を返す。想定外のerror値が来ても
## 呼び出し元が渡すデフォルトの文言(コイン/レインボーコイン不足)にフォールバックする。
func _gacha_error_message(body: PackedByteArray, default_message: String) -> String:
	var data = JSON.parse_string(body.get_string_from_utf8())
	var error: String = data.get("error", "") if data is Dictionary else ""
	if error == "monster_limit_reached":
		return "モンスターの所持数が上限(100体)に達しています。"
	return default_message

func _try_finish() -> void:
	if not (animation_done and response_done):
		return

	if pending_data is Dictionary:
		if is_seven_pull:
			_show_seven_result(pending_data)
		else:
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

## 7連ガチャの結果を、獲得数のサマリーテキスト+横並びのモンスターアイコン列で見せる。
func _show_seven_result(data: Dictionary) -> void:
	var pulls = data.get("pulls", [])
	var hit_count := 0

	for child in seven_result_row.get_children():
		child.queue_free()

	for pull in pulls:
		var monster = pull.get("monster")
		if pull.get("hit", false) and monster is Dictionary:
			hit_count += 1
			var item := MonsterItemScene.instantiate()
			seven_result_row.add_child(item)
			item.setup(monster["name"], monster["sprite_key"])
		# ハズレの回はタイルを作らず、獲得できた分だけ横並びで見せる。

	# 獲得できたのが1体だけのときは中央に表示した方がわかりやすい
	seven_result_row.alignment = BoxContainer.ALIGNMENT_CENTER if hit_count == 1 else BoxContainer.ALIGNMENT_BEGIN
	seven_result_scroll.visible = true

	if hit_count > 0:
		result_label.text = "🌈 7連ガチャで%d体獲得！" % hit_count
		hit_sound.play()
	else:
		result_label.text = "🌈 7連ガチャ…残念、今回は全てハズレでした。"
		miss_sound.play()

func _clear_reveal() -> void:
	for child in reveal_holder.get_children():
		child.queue_free()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
