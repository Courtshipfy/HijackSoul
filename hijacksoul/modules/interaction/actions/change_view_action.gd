extends "res://modules/interaction/actions/interaction_action.gd"
class_name ChangeViewAction

@export var view_id: String = ""
@export_file("*.tscn") var scene_path: String = ""

func to_action(_context: Dictionary = {}) -> Dictionary:
	return {
		"type": "change_view",
		"view_id": view_id,
		"scene_path": scene_path
	}
