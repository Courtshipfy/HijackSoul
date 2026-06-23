extends "res://modules/interaction/actions/interaction_action.gd"
class_name ShowToastAction

@export_multiline var message: String = ""

func to_action(_context: Dictionary = {}) -> Dictionary:
	return {
		"type": "show_toast",
		"message": message
	}
