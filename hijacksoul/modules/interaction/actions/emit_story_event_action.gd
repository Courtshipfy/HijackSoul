extends "res://modules/interaction/actions/interaction_action.gd"
class_name EmitStoryEventAction

@export var event_id: String = ""

func to_action(_context: Dictionary = {}) -> Dictionary:
	return {
		"type": "emit_story_event",
		"event_id": event_id
	}
