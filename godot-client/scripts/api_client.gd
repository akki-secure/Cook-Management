extends Node
## Rails側の /api/v1 と通信するための共通処理をまとめたAutoload(シングルトン)。
## ログインで取得したトークンを保持し、他のシーンからは常に Api.xxx() の形で呼び出す。

const BASE_URL := "http://localhost:3000/api/v1"
const TOKEN_FILE_PATH := "user://token.json"

var token: String = ""

func _ready() -> void:
	_load_token()

func has_token() -> bool:
	return token != ""

func save_token(new_token: String) -> void:
	token = new_token
	var file := FileAccess.open(TOKEN_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({ "token": token }))
		file.close()

func clear_token() -> void:
	token = ""
	if FileAccess.file_exists(TOKEN_FILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TOKEN_FILE_PATH))

func auth_headers() -> PackedStringArray:
	return PackedStringArray(["Authorization: Bearer " + token])

func _load_token() -> void:
	if not FileAccess.file_exists(TOKEN_FILE_PATH):
		return

	var file := FileAccess.open(TOKEN_FILE_PATH, FileAccess.READ)
	if not file:
		return

	var content := file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)
	if data is Dictionary and data.has("token"):
		token = data["token"]
