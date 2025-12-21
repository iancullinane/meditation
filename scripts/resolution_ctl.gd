@tool
extends VBoxContainer

signal resolution_changed(new_resolution: Vector2i)

var resolutions = {
	"3840x2160": Vector2i(3840, 2160),
	"2560x1440": Vector2i(2560, 1440),
	"1920x1080": Vector2i(1920, 1080),
	"1366x768": Vector2i(1366, 768),
	"1280x720": Vector2i(1280, 720),
	"1440x900": Vector2i(1440, 900),
	"1600x900": Vector2i(1600, 900),
	"1024x600": Vector2i(1024, 600),
	"800x600": Vector2i(800, 600)
}

func _ready():
	var current_resolution = str(get_viewport().size.x, "x", get_viewport().size.x)

	print(current_resolution)

	var selected_idx = resolutions.keys().find(current_resolution)
	var option_button = get_node_or_null("OptionsBtn")
	if option_button:
		if option_button.item_count == 0:
			for resolution in resolutions:
				option_button.add_item(resolution)
		if selected_idx != -1:
			option_button.select(selected_idx)
		option_button.item_selected.connect(_on_resolution_selected)

func _on_resolution_selected(index: int):
	var option_button = get_node("OptionsBtn")
	var selected_text = option_button.get_item_text(index)
	var new_resolution = resolutions[selected_text]
	# get_viewport().size = new_resolution
	# get_window().set_size(new_resolution)
	resolution_changed.emit(new_resolution)
