extends "res://modules/interaction/actions/interaction_action.gd"
class_name SetEnvironmentStateAction

@export var environment_id: String = ""
@export var state_id: String = ""

func to_action(_context: Dictionary = {}) -> Dictionary:
	return {
		"type": "set_environment_state",
		"environment_id": environment_id,
		"state_id": state_id
	}
