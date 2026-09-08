extends Control
## 対戦ミニゲーム。「手持ち対戦」(自分の手持ちモンスター2体を戦わせる)と
## 「ボス戦」(手持ち1体で固定ボスに挑む)の2モードを持つ。
##
## 戦闘はターン制: 自分のターンは「こうげき」ボタン、相手のターンは
## 飛び道具(Polygon2D)が斜めに飛んでくる演出を再生し、その間に
## 「ジャンプ」(着弾タイミングに合わせて押すと完全回避)か
## 「ガード」(タイミング不問でダメージ半減)で対応する。

@onready var self_mode_button: Button = $VBox/ModeRow/SelfModeButton
@onready var boss_mode_button: Button = $VBox/ModeRow/BossModeButton

@onready var selection_panel: Control = $VBox/SelectionPanel
@onready var instruction_label: Label = $VBox/SelectionPanel/SelectionVBox/InstructionLabel
@onready var monster_grid: GridContainer = $VBox/SelectionPanel/SelectionVBox/MonsterScroll/MonsterGrid
@onready var start_battle_button: Button = $VBox/SelectionPanel/SelectionVBox/StartBattleButton
@onready var back_button: Button = $VBox/SelectionPanel/SelectionVBox/BackButton

@onready var battle_panel: Control = $VBox/BattlePanel
@onready var turn_label: Label = $VBox/BattlePanel/BattleVBox/TurnLabel
@onready var arena: Control = $VBox/BattlePanel/BattleVBox/Arena
@onready var player_platform: Control = $VBox/BattlePanel/BattleVBox/Arena/PlayerPlatform
@onready var enemy_platform: Control = $VBox/BattlePanel/BattleVBox/Arena/EnemyPlatform
@onready var player_item: Control = $VBox/BattlePanel/BattleVBox/Arena/PlayerPlatform/PlayerItem
@onready var enemy_item: Control = $VBox/BattlePanel/BattleVBox/Arena/EnemyPlatform/EnemyItem
@onready var projectile: Polygon2D = $VBox/BattlePanel/BattleVBox/Arena/Projectile

@onready var player_name_atk_label: Label = $VBox/BattlePanel/BattleVBox/HudRow/PlayerHud/NameAtkLabel
@onready var player_hp_bar: ProgressBar = $VBox/BattlePanel/BattleVBox/HudRow/PlayerHud/HpBar
@onready var player_hp_num_label: Label = $VBox/BattlePanel/BattleVBox/HudRow/PlayerHud/HpNumLabel
@onready var enemy_name_atk_label: Label = $VBox/BattlePanel/BattleVBox/HudRow/EnemyHud/NameAtkLabel
@onready var enemy_hp_bar: ProgressBar = $VBox/BattlePanel/BattleVBox/HudRow/EnemyHud/HpBar
@onready var enemy_hp_num_label: Label = $VBox/BattlePanel/BattleVBox/HudRow/EnemyHud/HpNumLabel

@onready var attack_button: Button = $VBox/BattlePanel/BattleVBox/ControlsRow/AttackButton
@onready var jump_button: Button = $VBox/BattlePanel/BattleVBox/ControlsRow/JumpButton
@onready var guard_button: Button = $VBox/BattlePanel/BattleVBox/ControlsRow/GuardButton
@onready var result_label: Label = $VBox/BattlePanel/BattleVBox/ResultLabel
@onready var battle_back_button: Button = $VBox/BattlePanel/BattleVBox/BattleBackButton

@onready var monsters_request: HTTPRequest = $MonstersRequest
@onready var battle_result_request: HTTPRequest = $BattleResultRequest
@onready var enemy_turn_timer: Timer = $EnemyTurnTimer
@onready var next_turn_timer: Timer = $NextTurnTimer

const MonsterItemScene := preload("res://scenes/MonsterItem.tscn")

const FIREBALL_TRAVEL_TIME := 1.0
const DODGE_WINDOW := 0.25
const MIN_HOP_HALF_TIME := 0.14
const TURN_PAUSE := 0.5

const BOSS_NAME := "クラウンハンバーグ"
const BOSS_SPRITE_KEY := "boss_crowned_hamburg.png"
const BOSS_BASE_HP := 150
const BOSS_BASE_ATTACK := 18
const BOSS_ATTACK_MULTIPLIER := 1.25
const BOSS_STAGE_SPRITES := [
	"boss_hamburg_dark.png",
	"boss_hamburg_fire.png",
	"boss_hamburg_ice.png",
	"boss_hamburg_poison.png",
]
const BOSS_STAGE_THRESHOLDS := [0.75, 0.50, 0.25]

## type_label(図鑑のタイプ表示)ごとの飛び道具の色と形。新規画像は使わず、
## Polygon2Dの頂点だけで区別する。
const TYPE_EFFECT_TABLE := {
	"たまご": { "color": Color(1.0, 0.85, 0.2), "shape": "circle" },
	"ドリンク": { "color": Color(0.4, 0.8, 0.9), "shape": "circle" },
	"スイーツ": { "color": Color(0.95, 0.6, 0.75), "shape": "circle" },
	"デザート": { "color": Color(0.75, 0.6, 0.9), "shape": "diamond" },
	"めん類": { "color": Color(0.95, 0.55, 0.2), "shape": "square" },
	"がっつり": { "color": Color(0.85, 0.25, 0.2), "shape": "square" },
	"やさい": { "color": Color(0.35, 0.75, 0.35), "shape": "triangle" },
	"なつのあじ": { "color": Color(0.3, 0.85, 0.85), "shape": "diamond" },
	"おつまみ": { "color": Color(0.6, 0.5, 0.3), "shape": "triangle" },
}
const DEFAULT_EFFECT := { "color": Color(0.8, 0.8, 0.8), "shape": "circle" }

var mode := "self" # "self" または "boss"
var owned_monsters: Array = []
var selected_player_index := -1
var selected_enemy_index := -1

var turn := "player" # "player" または "enemy"
var game_over := false

var player_stats := {}
var enemy_stats := {}
var is_boss_battle := false
var boss_stage_index := 0

var jump_pressed_at = null
var guarded := false
var impact_at := 0.0
var player_base_position := Vector2.ZERO


func _ready() -> void:
	self_mode_button.toggled.connect(_on_self_mode_toggled)
	boss_mode_button.toggled.connect(_on_boss_mode_toggled)
	start_battle_button.pressed.connect(_on_start_battle_pressed)
	back_button.pressed.connect(_on_back_pressed)
	battle_back_button.pressed.connect(_on_battle_back_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	jump_button.pressed.connect(_on_jump_pressed)
	guard_button.pressed.connect(_on_guard_pressed)
	monsters_request.request_completed.connect(_on_monsters_completed)
	battle_result_request.request_completed.connect(_on_battle_result_completed)
	enemy_turn_timer.timeout.connect(_resolve_enemy_attack)
	next_turn_timer.timeout.connect(_on_next_turn_timer_timeout)

	fetch_monsters()


func fetch_monsters() -> void:
	monsters_request.request(Api.BASE_URL + "/monsters", Api.auth_headers(), HTTPClient.METHOD_GET)


func _on_monsters_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		return

	var monsters = JSON.parse_string(body.get_string_from_utf8())
	if not (monsters is Array):
		return

	owned_monsters = monsters
	_render_grid()


func _render_grid() -> void:
	for child in monster_grid.get_children():
		child.queue_free()

	for i in owned_monsters.size():
		var m = owned_monsters[i]
		var item := MonsterItemScene.instantiate()
		monster_grid.add_child(item)
		item.setup(m["name"], m["sprite_key"])
		item.tapped.connect(_on_grid_tile_tapped.bind(i))

	_refresh_grid_highlights()


func _refresh_grid_highlights() -> void:
	for i in monster_grid.get_child_count():
		var item = monster_grid.get_child(i)
		if i == selected_player_index:
			item.modulate = Color(0.6, 1.0, 0.6)
		elif i == selected_enemy_index:
			item.modulate = Color(1.0, 0.6, 0.6)
		else:
			item.modulate = Color.WHITE


func _on_grid_tile_tapped(index: int) -> void:
	if index == selected_player_index:
		selected_player_index = -1
	elif index == selected_enemy_index:
		selected_enemy_index = -1
	elif selected_player_index == -1:
		selected_player_index = index
	elif mode == "self" and selected_enemy_index == -1:
		selected_enemy_index = index
	# ボス戦モードでは相手はボス固定なので2体目の選択は無視する。

	_refresh_grid_highlights()
	_update_start_button()


func _update_start_button() -> void:
	if mode == "boss":
		start_battle_button.disabled = selected_player_index == -1
	else:
		start_battle_button.disabled = selected_player_index == -1 or selected_enemy_index == -1


func _on_self_mode_toggled(pressed: bool) -> void:
	if not pressed:
		return
	boss_mode_button.button_pressed = false
	mode = "self"
	instruction_label.text = "対戦する自分のモンスターを2体選んでください（1体目=自分、2体目=相手）"
	selected_player_index = -1
	selected_enemy_index = -1
	_refresh_grid_highlights()
	_update_start_button()


func _on_boss_mode_toggled(pressed: bool) -> void:
	if not pressed:
		return
	self_mode_button.button_pressed = false
	mode = "boss"
	instruction_label.text = "ボスに挑戦する自分のモンスターを1体選んでください"
	selected_player_index = -1
	selected_enemy_index = -1
	_refresh_grid_highlights()
	_update_start_button()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


## 対戦結果画面から一覧(モンスター選択画面)に戻る。選択状態はリセットする。
func _on_battle_back_pressed() -> void:
	enemy_turn_timer.stop()
	next_turn_timer.stop()
	selected_player_index = -1
	selected_enemy_index = -1
	_refresh_grid_highlights()
	_update_start_button()
	battle_panel.visible = false
	selection_panel.visible = true


func _on_start_battle_pressed() -> void:
	var player_monster: Dictionary = owned_monsters[selected_player_index]
	player_stats = {
		"name": player_monster["name"],
		"sprite_key": player_monster["sprite_key"],
		"type_label": player_monster.get("type_label", ""),
		"hp": player_monster["hp"],
		"max_hp": player_monster["hp"],
		"attack": player_monster["attack"],
	}

	is_boss_battle = mode == "boss"
	boss_stage_index = 0

	if is_boss_battle:
		enemy_stats = {
			"name": BOSS_NAME,
			"sprite_key": BOSS_SPRITE_KEY,
			"type_label": "がっつり",
			"hp": BOSS_BASE_HP,
			"max_hp": BOSS_BASE_HP,
			"attack": BOSS_BASE_ATTACK,
		}
	else:
		var enemy_monster: Dictionary = owned_monsters[selected_enemy_index]
		enemy_stats = {
			"name": enemy_monster["name"],
			"sprite_key": enemy_monster["sprite_key"],
			"type_label": enemy_monster.get("type_label", ""),
			"hp": enemy_monster["hp"],
			"max_hp": enemy_monster["hp"],
			"attack": enemy_monster["attack"],
		}

	player_item.setup(player_stats["name"], player_stats["sprite_key"], true, false)
	enemy_item.setup(enemy_stats["name"], enemy_stats["sprite_key"], true, false)
	player_base_position = player_item.position

	game_over = false
	result_label.text = ""
	projectile.visible = false

	selection_panel.visible = false
	battle_panel.visible = true

	_update_hud()
	_start_player_turn()


func _update_hud() -> void:
	player_name_atk_label.text = "%s  ATK %d" % [player_stats["name"], player_stats["attack"]]
	player_hp_bar.max_value = player_stats["max_hp"]
	player_hp_bar.value = max(0, player_stats["hp"])
	player_hp_num_label.text = "%d / %d" % [max(0, player_stats["hp"]), player_stats["max_hp"]]

	enemy_name_atk_label.text = "ATK %d  %s" % [enemy_stats["attack"], enemy_stats["name"]]
	enemy_hp_bar.max_value = enemy_stats["max_hp"]
	enemy_hp_bar.value = max(0, enemy_stats["hp"])
	enemy_hp_num_label.text = "%d / %d" % [max(0, enemy_stats["hp"]), enemy_stats["max_hp"]]


func _start_player_turn() -> void:
	turn = "player"
	turn_label.text = "あなたのターン"
	attack_button.disabled = false
	jump_button.disabled = true
	guard_button.disabled = true


func _on_attack_pressed() -> void:
	if turn != "player" or game_over:
		return
	attack_button.disabled = true

	var dmg: int = player_stats["attack"]
	enemy_stats["hp"] = max(0, enemy_stats["hp"] - dmg)
	_shake(enemy_item)
	_update_hud()

	if enemy_stats["hp"] <= 0:
		_end_battle(true)
		return

	next_turn_timer.wait_time = TURN_PAUSE
	next_turn_timer.start()


func _on_next_turn_timer_timeout() -> void:
	if game_over:
		return
	if turn == "player":
		_start_enemy_turn()
	else:
		_start_player_turn()


func _start_enemy_turn() -> void:
	turn = "enemy"
	jump_pressed_at = null
	guarded = false
	jump_button.disabled = false
	guard_button.disabled = false
	turn_label.text = "%s のターン！" % enemy_stats["name"]

	var effect = TYPE_EFFECT_TABLE.get(enemy_stats.get("type_label", ""), DEFAULT_EFFECT)
	projectile.polygon = _shape_points(effect["shape"])
	projectile.color = effect["color"]
	projectile.modulate.a = 1.0
	projectile.visible = true
	projectile.position = enemy_platform.position + Vector2(enemy_platform.size.x * 0.5, enemy_platform.size.y * 0.2)

	var landing_position: Vector2 = player_platform.position + Vector2(player_platform.size.x * 0.6, player_platform.size.y * 0.95)

	var tw := create_tween()
	tw.tween_property(projectile, "position", landing_position, FIREBALL_TRAVEL_TIME)

	impact_at = Time.get_ticks_msec() / 1000.0 + FIREBALL_TRAVEL_TIME
	enemy_turn_timer.wait_time = FIREBALL_TRAVEL_TIME
	enemy_turn_timer.start()


func _on_jump_pressed() -> void:
	if turn != "enemy" or game_over or jump_pressed_at != null:
		return
	jump_pressed_at = Time.get_ticks_msec() / 1000.0
	jump_button.disabled = true

	# ジャンプは押した瞬間ではなく、必ず着弾の瞬間に頂点が来るよう
	# 長さを合わせて再生する(押すタイミングが早くても遅くても山が着弾と同期する)。
	var delay: float = max(0.0, impact_at - jump_pressed_at)
	var half: float = max(delay, MIN_HOP_HALF_TIME)

	var tw := create_tween()
	tw.tween_property(player_item, "position:y", player_base_position.y - 36, half)
	tw.tween_property(player_item, "position:y", player_base_position.y, half)


func _on_guard_pressed() -> void:
	if turn != "enemy" or game_over or guarded:
		return
	guarded = true
	guard_button.disabled = true


func _resolve_enemy_attack() -> void:
	jump_button.disabled = true
	guard_button.disabled = true

	var dodged: bool = jump_pressed_at != null and (impact_at - jump_pressed_at) <= DODGE_WINDOW

	var dmg: int
	if dodged:
		dmg = 0
	elif guarded:
		dmg = max(1, int(enemy_stats["attack"] / 2.0))
	else:
		dmg = enemy_stats["attack"]
		if jump_pressed_at == null:
			_shake(player_item)

	var settle_tw := create_tween()
	settle_tw.tween_interval(0.2)
	settle_tw.tween_property(projectile, "modulate:a", 0.0, 0.15)
	settle_tw.tween_callback(func(): projectile.visible = false)

	player_stats["hp"] = max(0, player_stats["hp"] - dmg)
	_update_hud()

	if is_boss_battle:
		_maybe_transform_boss()

	if player_stats["hp"] <= 0:
		_end_battle(false)
		return

	next_turn_timer.wait_time = TURN_PAUSE
	next_turn_timer.start()


func _maybe_transform_boss() -> void:
	while boss_stage_index < BOSS_STAGE_THRESHOLDS.size():
		var threshold: float = BOSS_STAGE_THRESHOLDS[boss_stage_index]
		var hp_ratio: float = float(enemy_stats["hp"]) / float(enemy_stats["max_hp"])
		if hp_ratio > threshold:
			break

		var sprite_key: String = BOSS_STAGE_SPRITES[randi() % BOSS_STAGE_SPRITES.size()]
		var texture := load("res://assets/monsters/" + sprite_key)
		if texture is Texture2D:
			enemy_item.get_node("Icon").texture = texture
		else:
			push_warning("battle_scene: boss stage sprite not found or not imported: " + sprite_key)

		enemy_stats["attack"] = int(round(enemy_stats["attack"] * BOSS_ATTACK_MULTIPLIER))
		boss_stage_index += 1
		_update_hud()


func _shake(node: Control) -> void:
	var original: Vector2 = node.position
	var tw := create_tween()
	tw.tween_property(node, "position:x", original.x - 6, 0.06)
	tw.tween_property(node, "position:x", original.x + 6, 0.06)
	tw.tween_property(node, "position:x", original.x, 0.06)


func _end_battle(player_won: bool) -> void:
	game_over = true
	attack_button.disabled = true
	jump_button.disabled = true
	guard_button.disabled = true

	if player_won:
		result_label.text = "🎉 勝利！ %s を たおした！" % enemy_stats["name"]
	else:
		result_label.text = "💀 敗北… %s は たおれた" % player_stats["name"]

	_report_battle_result(player_won)


## 対戦結果をサーバーに報告する。ボス戦勝利時のみレインボーコインが1枚付与される。
## レインボーコインという実質的な報酬が絡むため、通信結果を確認せず送りっぱなしに
## せず、成功/失敗どちらもプレイヤーにわかる形で表示する。
func _report_battle_result(player_won: bool) -> void:
	var body := JSON.stringify({
		"mode": mode,
		"result": "win" if player_won else "lose",
	})
	var headers := Api.auth_headers()
	headers.append("Content-Type: application/json")
	battle_result_request.request(Api.BASE_URL + "/battle_results", headers, HTTPClient.METHOD_POST, body)


func _on_battle_result_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200 and response_code != 201:
		result_label.text += "\n⚠ 報酬の受け取りに失敗しました。通信環境をご確認ください。"
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if data is Dictionary and data.get("rainbow_coins_awarded", 0) > 0:
		result_label.text += "\n🌈 レインボーコインを%d枚獲得！" % data["rainbow_coins_awarded"]


func _shape_points(shape: String) -> PackedVector2Array:
	match shape:
		"square":
			return PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
		"diamond":
			return PackedVector2Array([Vector2(0, -10), Vector2(10, 0), Vector2(0, 10), Vector2(-10, 0)])
		"triangle":
			return PackedVector2Array([Vector2(0, -10), Vector2(9, 8), Vector2(-9, 8)])
		_:
			var points := PackedVector2Array()
			var sides := 12
			for i in sides:
				var angle: float = TAU * i / sides
				points.append(Vector2(cos(angle), sin(angle)) * 9)
			return points
