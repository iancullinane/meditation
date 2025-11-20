extends CenterContainer

@onready var user_controls = %UserControls
@onready var debug_controls = %DebugControls
@onready var email_input = %Email/LineEdit
@onready var user_id_label = %UserID
@onready var get_user_button = user_controls.get_node("GetUser")
@onready var create_user_button = user_controls.get_node("CreateUser")
@onready var search_user_button = debug_controls.get_node("SearchUser")
@onready var delete_user_button = debug_controls.get_node("DeleteUser")


@export var base_url: String = "https://test.stytch.com/v1"
@export var project_id: String = ""
@export var secret: String = ""
@export var external_id: String = ""
@export var user_id: String = ""
@export var requester: HTTPRequest

func _ready():
	requester.request_completed.connect(_on_request_completed)
	get_user_button.pressed.connect(_on_get_user_pressed)
	create_user_button.pressed.connect(_on_create_user_pressed)
	search_user_button.pressed.connect(_on_search_user_pressed)
	delete_user_button.pressed.connect(_on_delete_user_pressed)

const HEADER_CONTENT_TYPE: String = "Content-Type: application/json"
const HEADER_AUTHORIZATION: String = "Authorization"

func create_user(email: String):
	var url := base_url + "/users"

	# The curl -u flag is equivalent to "Authorization: Basic base64(username:password)"
	var credentials := "%s:%s" % [project_id, secret]
	var auth_header := "Basic " + Marshalls.utf8_to_base64(credentials)
	var headers := [
		HEADER_CONTENT_TYPE,
		HEADER_AUTHORIZATION + ": " + auth_header
	]

	var body := JSON.stringify({
		"email": email,
		"external_id": external_id
	})

	requester.request(url, headers, HTTPClient.METHOD_POST, body)

func get_user(user_id_param: String):
	var url := base_url + "/users/" + user_id_param

	var credentials := "%s:%s" % [project_id, secret]
	var auth_header := "Basic " + Marshalls.utf8_to_base64(credentials)
	var headers := [
	HEADER_CONTENT_TYPE,
	HEADER_AUTHORIZATION + ": " + auth_header
	]

	requester.request(url, headers, HTTPClient.METHOD_GET)

func search_user(email: String):
	var url := base_url + "/users/search"
		
	var credentials := "%s:%s" % [project_id, secret]
	var auth_header := "Basic " + Marshalls.utf8_to_base64(credentials)
	var headers := [
		HEADER_CONTENT_TYPE,
		HEADER_AUTHORIZATION + ": " + auth_header
	]

	var body := JSON.stringify({
	"query": {
		"operator": "AND",
		"operands": [
		{
			"filter_name": "email_address",
			"filter_value": [email]
		}
		]
	}
	})

	requester.request(url, headers, HTTPClient.METHOD_POST, body)

func delete_user(user_id_param: String):
	var url := base_url + "/users/" + user_id_param

	var credentials := "%s:%s" % [project_id, secret]
	var auth_header := "Basic " + Marshalls.utf8_to_base64(credentials)
	var headers := [
		HEADER_CONTENT_TYPE,
		HEADER_AUTHORIZATION + ": " + auth_header
	]

	requester.request(url, headers, HTTPClient.METHOD_DELETE)

func _on_create_user_pressed():
	print("=== CREATE USER BUTTON PRESSED ===")
	var email: String = email_input.text
	if email.is_empty():
		print("Email is required")
		return
	create_user(email)

func _on_get_user_pressed():
	print("=== GET USER BUTTON PRESSED ===")
	if user_id.is_empty():
		print("User ID is required")
		return
	get_user(user_id)

func _on_search_user_pressed():
	print("=== SEARCH USER BUTTON PRESSED ===")
	var email: String = email_input.text
	if email.is_empty():
		print("Email is required for search")
		return
	search_user(email)

func _on_delete_user_pressed():
	print("=== DELETE USER BUTTON PRESSED ===")
	if user_id.is_empty():
		print("User ID is required for deletion")
		return
	delete_user(user_id)

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200 or response_code == 201:
		var json = JSON.parse_string(body.get_string_from_utf8())
		print("Response: ", json)
		
		if json.has("results") and json.results.size() > 0:
			user_id = json.results[0].user_id
			user_id_label.text = user_id
			print("User ID saved: ", user_id)
		elif json.has("user_id"):
			user_id = json.user_id
			user_id_label.text = user_id
			print("User ID saved: ", user_id)
	else:
		print("Error: ", response_code, " - ", body.get_string_from_utf8())
	print(response_code)
