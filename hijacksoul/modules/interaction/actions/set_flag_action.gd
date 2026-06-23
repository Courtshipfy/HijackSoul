extends "res://modules/interaction/actions/interaction_action.gd"
class_name SetFlagAction

@export var flag_id: String = ""
@export var value: bool = true

func to_action(_context: Dictionary = {}) -> Dictionary:
	return {
		"type": "set_flag",
		"flag_id": flag_id,
		"value": value
	}
