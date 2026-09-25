extends Control


# ============================================================
# BACKEND
# ============================================================

const BACKEND_URL := "http://127.0.0.1:8000/chat"

var session_id := "player_001"

var lab_context: Dictionary = {}


# ============================================================
# NODES
# ============================================================

@onready var professor_button: TextureButton = $ProfessorButton

@onready var chat_panel: PanelContainer = $ChatPanel

@onready var chat_history: RichTextLabel = \
	$ChatPanel/MainVBox/ChatHistory

@onready var input_box: LineEdit = \
	$ChatPanel/MainVBox/InputRow/InputBox

@onready var send_button: Button = \
	$ChatPanel/MainVBox/InputRow/SendButton

@onready var close_button: Button = \
	$ChatPanel/MainVBox/Header/CloseButton

@onready var http: HTTPRequest = $HTTPRequest


# ============================================================
# START
# ============================================================

func _ready() -> void:

	# Chat starts closed.
	chat_panel.visible = false


	# Connect buttons.
	professor_button.pressed.connect(
		open_chat
	)

	send_button.pressed.connect(
		send_message
	)

	close_button.pressed.connect(
		close_chat
	)

	input_box.text_submitted.connect(
		_on_input_submitted
	)


	# HTTP response.
	http.request_completed.connect(
		_on_request_completed
	)


	# Professor greeting.
	_add_message(
		"Professor Doom",
		"Welcome, researcher. What troubles you about the experiment?"
	)


# ============================================================
# OPEN / CLOSE
# ============================================================

func open_chat() -> void:

	chat_panel.visible = true

	input_box.grab_focus()


func close_chat() -> void:

	chat_panel.visible = false


# ============================================================
# INPUT
# ============================================================

func _on_input_submitted(_text: String) -> void:

	send_message()


func send_message() -> void:

	var message := input_box.text.strip_edges()

	if message.is_empty():
		return


	# Show player message.
	_add_message(
		"You",
		message
	)


	input_box.clear()

	send_button.disabled = true
	input_box.editable = false


	# --------------------------------------------------------
	# REQUEST
	# --------------------------------------------------------

	var payload := {

		"session_id": session_id,

		"message": message,

		"context": lab_context

	}


	var headers := [

		"Content-Type: application/json"

	]


	var body := JSON.stringify(
		payload
	)


	var error := http.request(

		BACKEND_URL,

		headers,

		HTTPClient.METHOD_POST,

		body

	)


	if error != OK:

		_add_message(
			"Professor Doom",
			"Unable to contact the laboratory AI."
		)

		_reset_input()


# ============================================================
# RESPONSE
# ============================================================

func _on_request_completed(

	result: int,

	response_code: int,

	_headers: PackedStringArray,

	body: PackedByteArray

) -> void:


	_reset_input()


	if result != HTTPRequest.RESULT_SUCCESS:

		_add_message(
			"Professor Doom",
			"Laboratory network connection failed."
		)

		return


	if response_code != 200:

		print(
			"Backend error: ",
			response_code
		)

		print(
			body.get_string_from_utf8()
		)

		_add_message(
			"Professor Doom",
			"The laboratory AI returned an error."
		)

		return


	var data = JSON.parse_string(
		body.get_string_from_utf8()
	)


	if data == null:

		_add_message(
			"Professor Doom",
			"I received an invalid response."
		)

		return


	var reply: String = data.get(
		"reply",
		""
	)


	if reply.is_empty():

		reply = "Interesting. Let me reconsider that."


	_add_message(
		"Professor Doom",
		reply
	)


# ============================================================
# INPUT RESET
# ============================================================

func _reset_input() -> void:

	send_button.disabled = false

	input_box.editable = true

	input_box.grab_focus()


# ============================================================
# CHAT DISPLAY
# ============================================================

func _add_message(

	speaker: String,

	message: String

) -> void:

	chat_history.append_text(

		"\n[b]" +
		speaker +
		":[/b] " +
		escape_bbcode(message) +
		"\n"

	)

	chat_history.scroll_to_line(
		chat_history.get_line_count()
	)


func escape_bbcode(text: String) -> String:

	return text \
		.replace("[", "[lb]") \
		.replace("]", "[rb]")


# ============================================================
# LAB CONTEXT
# ============================================================

func set_lab_context(
	context: Dictionary
) -> void:

	lab_context = context
