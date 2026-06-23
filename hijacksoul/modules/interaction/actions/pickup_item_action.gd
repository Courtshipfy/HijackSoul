extends "res://modules/interaction/actions/interaction_action.gd"
class_name PickupItemAction

@export var item_id: String = ""

func to_action(_context: Dictionary = {}) -> Dictionary:
	return {
		"type": "pickup_item",
		"item_id": item_id
	}
