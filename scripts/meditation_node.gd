extends MarginContainer


class_name MeditationNode

@onready var map_scene = %CozyMap
@onready var cozy_map: CozyMap = get_node("CozyMap")

func start_scene():
	visible = true
	map_scene.start_scene()

func get_map_camera_marker():
	return cozy_map.get_camera_marker()
