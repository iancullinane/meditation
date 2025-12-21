extends Node2D
class_name CozyMap


@onready var audio_player: AudioStreamPlayer = get_node("AudioStreamPlayer")
@onready var camera_marker: Marker2D = get_node("CameraMarker")


func start_scene():
	audio_player.play()

func get_camera_marker() -> Node2D:
	return camera_marker
