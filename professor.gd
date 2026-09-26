extends Control


# ============================================================
# BACKEND
# ============================================================

# Your FastAPI backend.
# Change this only if your backend is running somewhere else.
const BACKEND_URL := "http://127.0.0.1:8000/chat"


# ============================================================
# UI REFERENCES
# ============================================================

@onready var chat_log: RichTextLabel = $PanelContainer/VBoxContainer/ScrollContainer/RichTextLabel
@onready var input_box: LineEdit = $PanelContainer/VBoxContainer/HBoxContainer/LineEdit
@onready var send_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/Button


# ============================================================
# HTTP
# ============================================================

var http_request: HTTPRequest


# ============================================================
# SESSION
# ============================================================

var session_id: String


# ============================================================
# STATE
# ============================================================

var waiting_for_response := false


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	# Create HTTPRequest automatically.
	http_request = HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(_on_request_completed)

	# Create a unique conversation ID.
	session_id = (
		str(Time.get_unix_time_from_system())
		+ "_"
		+ str(get_instance_id())
	)

	# Connect UI.
	send_button.pressed.connect(_on_send_pressed)
	input_box.text_submitted.connect(_on_text_submitted)

	# Initial Professor message.
	add_professor_message(
		"Welcome to Variant Zero.\n"
		+ "What would you like to know about the experiment?"
	)

	input_box.grab_focus()


# ============================================================
# SEND BUTTON
# ============================================================

func _on_send_pressed() -> void:
	send_message()


# ============================================================
# ENTER KEY
# ============================================================

func _on_text_submitted(_text: String) -> void:
	send_message()


# ============================================================
# SEND MESSAGE
# ============================================================

func send_message() -> void:

	if waiting_for_response:
		return

	var message := input_box.text.strip_edges()

	if message.is_empty():
		return

	# Show player's message.
	add_player_message(message)

	# Clear input.
	input_box.clear()

	# Disable input while waiting.
	set_chat_enabled(false)

	waiting_for_response = true

	# Build the data sent to FastAPI.
	var request_body := {
		"session_id": session_id,
		"message": message,
		"context": get_lab_context()
	}

	var json_body := JSON.stringify(request_body)

	var headers := PackedStringArray([
		"Content-Type: application/json"
	])

	var error := http_request.request(
		BACKEND_URL,
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)

	if error != OK:

		waiting_for_response = false
		set_chat_enabled(true)

		add_system_message(
			"Unable to connect to the Professor backend."
		)

		print("HTTPRequest error: ", error)


# ============================================================
# BACKEND RESPONSE
# ============================================================

func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:

	waiting_for_response = false
	set_chat_enabled(true)

	# Connection-level error.
	if result != HTTPRequest.RESULT_SUCCESS:

		add_system_message(
			"Connection to Professor failed."
		)

		print("HTTP connection error: ", result)

		input_box.grab_focus()

		return


	# HTTP error.
	if response_code < 200 or response_code >= 300:

		var error_text := body.get_string_from_utf8()

		add_system_message(
			"Professor backend returned an error."
		)

		print("HTTP status: ", response_code)
		print("Backend response: ", error_text)

		input_box.grab_focus()

		return


	# Convert response body into text.
	var response_text := body.get_string_from_utf8()

	var json = JSON.parse_string(response_text)

	if json == null:

		add_system_message(
			"Professor returned an invalid response."
		)

		print("Invalid JSON:")
		print(response_text)

		input_box.grab_focus()

		return


	# Make sure the backend returned "reply".
	if not json.has("reply"):

		add_system_message(
			"Professor did not return a reply."
		)

		print("Unexpected backend response:")
		print(json)

		input_box.grab_focus()

		return


	# Get Professor's response.
	var professor_reply: String = str(json["reply"])

	add_professor_message(professor_reply)

	input_box.grab_focus()


# ============================================================
# LAB STATE
# ============================================================

func get_lab_context() -> Dictionary:

	# --------------------------------------------------------
	# IMPORTANT:
	# Replace these values later with your actual game state.
	# --------------------------------------------------------

	var context := {
		"selected_traits": [],
		"genome": "Unknown",

		"trait_count": 0,

		"mobility": 0,
		"defense": 0,
		"endurance": 0,
		"fat_storage": 0,
		"thermoregulation": 0,

		"instability_level": 0
	}

	return context


# ============================================================
# DISPLAY PLAYER MESSAGE
# ============================================================

func add_player_message(message: String) -> void:

	chat_log.append_text(
		"\n\n"
		+ "[color=#66ccff][b]You:[/b][/color]\n"
		+ message
	)


# ============================================================
# DISPLAY PROFESSOR MESSAGE
# ============================================================

func add_professor_message(message: String) -> void:

	chat_log.append_text(
		"\n\n"
		+ "[color=#7cff6b][b]Professor:[/b][/color]\n"
		+ message
	)

	scroll_chat_to_bottom()


# ============================================================
# DISPLAY SYSTEM ERROR
# ============================================================

func add_system_message(message: String) -> void:

	chat_log.append_text(
		"\n\n"
		+ "[color=#ff6666][b]SYSTEM:[/b][/color]\n"
		+ message
	)

	scroll_chat_to_bottom()


# ============================================================
# SCROLL CHAT
# ============================================================

func scroll_chat_to_bottom() -> void:

	await get_tree().process_frame

	var scroll_container := (
		$PanelContainer/VBoxContainer/ScrollContainer
		as ScrollContainer
	)

	scroll_container.set_deferred(
		"scroll_vertical",
		scroll_container.get_v_scroll_bar().max_value
	)


# ============================================================
# ENABLE / DISABLE CHAT
# ============================================================

func set_chat_enabled(enabled: bool) -> void:

	input_box.editable = enabled
	send_button.disabled = not enabled
