extends "res://modules/interaction/actions/interaction_action.gd"
class_name ShowDialogueAction

@export var speaker: String = ""
@export_multiline var text: String = ""
@export var text_key: String = ""

func to_action(_context: Dictionary = {}) -> Dictionary:
	return {
		"type": "show_dialogue",
		"speaker": speaker,
		"text": text,
		"textKey": text_key
	}
