extends "res://modules/interaction/actions/interaction_action.gd"
class_name SetObjectStateAction

@export var object_id: String = ""
@export var state_name: String = ""
@export var visible: bool = true
@export var enabled: bool = true
@export var include_visible: bool = false
@export var include_enabled: bool = false

func to_action(context: Dictionary = {}) -> Dictionary:
	var target_object_id := object_id
	if target_object_id.is_empty():
		target_object_id = String(context.get("object_id", ""))

	var state: Dictionary = {}
	if not state_name.is_empty():
		state["state"] = state_name
	if include_visible:
		state["visible"] = visible
	if include_enabled:
		state["enabled"] = enabled

	return {
		"type": "set_object_state",
		"object_id": target_object_id,
		"state": state
	}
