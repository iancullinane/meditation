extends Control

# @onready var label: Label = get_node("Margins/FgPanel/Label")
@onready var line_edit: LineEdit = get_node("Meditation/FgPanel/LineEdit")
@onready var fg_panel: Panel = get_node("Meditation/FgPanel")
@onready var http_request: HTTPRequest = get_node("HTTPRequest")

# Updated to a working endpoint - replace with your actual API
@export var url: String = "https://ajc2zv4pr0.execute-api.us-east-2.amazonaws.com/beta"

var is_requesting: bool = false

func _ready() -> void:
	line_edit.text_submitted.connect(_on_line_edit_text_submitted)
	http_request.request_completed.connect(_on_request_completed)
	# Don't make automatic request on startup
	# label.text = "Click 'Talk to Sheeta' to start a conversation"


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	is_requesting = false
	
	# Handle different types of errors
	match result:
		HTTPRequest.RESULT_SUCCESS:
			if response_code == 200:
				var response_text = body.get_string_from_utf8()
				if response_text.is_empty():
					_show_error("Empty response from server")
					return
				
				var json = JSON.new()
				var parse_result = json.parse(response_text)
				if parse_result != OK:
					_show_error("Invalid JSON response: " + response_text)
					return
				
				_handle_successful_response(json.data)
			else:
				_show_error("Server returned error code: " + str(response_code))
		
		HTTPRequest.RESULT_CANT_CONNECT:
			_show_error("Cannot connect to server. Check your internet connection.")
		
		HTTPRequest.RESULT_CANT_RESOLVE:
			_show_error("Cannot resolve server address. The endpoint may no longer exist.")
		
		HTTPRequest.RESULT_CONNECTION_ERROR:
			_show_error("Connection error occurred.")
		
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			_show_error("SSL/TLS handshake error.")
		
		HTTPRequest.RESULT_NO_RESPONSE:
			_show_error("No response from server.")
		
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
			_show_error("Response too large.")
		
		HTTPRequest.RESULT_REQUEST_FAILED:
			_show_error("Request failed.")
		
		HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN:
			_show_error("Cannot open download file.")
		
		HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
			_show_error("Download file write error.")
		
		HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
			_show_error("Too many redirects.")
		
		HTTPRequest.RESULT_TIMEOUT:
			_show_error("Request timed out.")
		
		_:
			_show_error("Unknown error occurred: " + str(result))

func _handle_successful_response(data):
	print("Successful response:", data)
	var response_text = ""
	if data.has("message"):
		response_text = "Response: " + str(data)
		# label.text = response_text
	else:
		response_text = "Response received: " + str(data)
		# label.text = response_text
	
	# Display the response as animated text (in green to distinguish from user input)
	display_animated_text(response_text, Color.GREEN, 0.5, 2.0, 6.0)

func _show_error(error_message: String):
	print("HTTP Error: ", error_message)
	# label.text = "Error: " + error_message
	
	# Display the error as animated text (in red to indicate error, positioned higher on screen)
	display_animated_text("Error: " + error_message, Color.RED, 0.3, 5.0, 2.0)


# Helper function to display animated text messages
func display_animated_text(text: String, color: Color = Color.WHITE, y_position_ratio: float = 0.75, delay_before_fade: float = 3.0, fade_duration: float = 8.0, drift_distance: float = -2000, drift_duration: float = 60.0) -> void:
	# Create a new temporary label
	var temp_label = Label.new()
	temp_label.text = text
	temp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	temp_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	temp_label.modulate = color
	temp_label.position.y = fg_panel.size.y * y_position_ratio
	temp_label.position.x = (fg_panel.size.x - temp_label.size.x) / 2
	fg_panel.add_child(temp_label)
	
	# Wait one frame for the label to be properly sized
	await get_tree().process_frame
	
	# Now center the label horizontally
	
	# Create a timer for the fade effect
	var timer = Timer.new()
	timer.wait_time = delay_before_fade
	timer.one_shot = true
	add_child(timer)
	
	# Create a tween for the fade and drift effect
	var tween = create_tween()
	# Move upward while fading out
	tween.parallel().tween_property(temp_label, "position:y", temp_label.position.y + drift_distance, drift_duration).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(temp_label, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(func(): temp_label.queue_free()) # Remove the label after fade
	
	timer.start()

func _on_line_edit_text_submitted(new_text: String) -> void:
	display_animated_text(new_text)
	line_edit.clear()
	# line_edit.call_deferred("grab_focus") # Return focus to the LineEdit after a frame

func _on_button_pressed() -> void:
	print("=== TALK TO SHEETA BUTTON PRESSED ===")
	if is_requesting:
		# label.text = "Request already in progress..."
		return
	
	if url.is_empty():
		_show_error("No URL configured for HTTP request")
		return
	
	# Add cache-busting parameter to ensure fresh requests
	var cache_bust_url = url
	if url.contains("?"):
		cache_bust_url += "&_t=" + str(Time.get_unix_time_from_system())
	else:
		cache_bust_url += "?_t=" + str(Time.get_unix_time_from_system())
	
	print("Making HTTP request to: ", cache_bust_url)
	# label.text = "Connecting to server..."
	is_requesting = true
	
	# Set headers to disable caching
	var headers = ["Cache-Control: no-cache", "Pragma: no-cache"]
	var request_result = http_request.request(cache_bust_url, headers)
	if request_result != OK:
		is_requesting = false
		_show_error("Failed to start HTTP request: " + str(request_result))
