extends Resource
class_name ItemInteraction

@export var item_id: String = ""
@export var actions: Array[Resource] = []

func to_actions(context: Dictionary = {}) -> Array:
	var result: Array = []
	for action in actions:
		if action == null:
			continue
		if not action.has_method("to_action"):
			continue
		var action_data: Dictionary = action.call("to_action", context)
		if not action_data.is_empty():
			result.append(action_data)
	return result
