extends Control

@onready var email_input: LineEdit = $VBox/EmailInput
@onready var password_input: LineEdit = $VBox/PasswordInput
@onready var login_button: Button = $VBox/LoginButton
@onready var error_label: Label = $VBox/ErrorLabel
@onready var http_request: HTTPRequest = $HTTPRequest

func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)
	http_request.request_completed.connect(_on_request_completed)
	error_label.text = ""

	# 前回保存したトークンが残っていれば、ログイン画面を飛ばして直接ステータス画面へ
	if Api.has_token():
		_go_to_main()

func _on_login_pressed() -> void:
	var email := email_input.text.strip_edges()
	var password := password_input.text

	if email.is_empty() or password.is_empty():
		error_label.text = "メールアドレスとパスワードを入力してください。"
		return

	login_button.disabled = true
	error_label.text = "ログイン中..."

	var url := Api.BASE_URL + "/auth"
	var headers := PackedStringArray(["Content-Type: application/x-www-form-urlencoded"])
	var body := "email=%s&password=%s" % [email.uri_encode(), password.uri_encode()]
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	login_button.disabled = false

	if response_code != 201:
		error_label.text = "メールアドレスまたはパスワードが違います。"
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if data is Dictionary and data.has("token"):
		Api.save_token(data["token"])
		_go_to_main()
	else:
		error_label.text = "予期しないエラーが発生しました。"

func _go_to_main() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
