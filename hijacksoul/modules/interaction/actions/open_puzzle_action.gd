extends "res://modules/interaction/actions/interaction_action.gd"
class_name OpenPuzzleAction

@export var puzzle_id: String = ""

func to_action(_context: Dictionary = {}) -> Dictionary:
	return {
		"type": "open_puzzle",
		"puzzle_id": puzzle_id
	}
