extends "res://modules/interaction/actions/interaction_action.gd"
class_name StartSubsceneStoryAction

@export var scene_id: String = ""
@export_file("*.tscn") var scene_path: String = ""
@export var story_id: String = ""
@export var return_view_id: String = ""
@export_file("*.tscn") var return_scene_path: String = ""
@export var once_flag: String = ""
@export var return_actions: Array[Dictionary] = []

func to_action(_context: Dictionary = {}) -> Dictionary:
	return {
		"type": "start_subscene_story",
		"scene_id": scene_id,
		"scene_path": scene_path,
		"story_id": story_id,
		"return_view_id": return_view_id,
		"return_scene_path": return_scene_path,
		"once_flag": once_flag,
		"return_actions": return_actions
	}
