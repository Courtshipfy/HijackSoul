extends "res://modules/interaction/actions/interaction_action.gd"
class_name OpenItemInspectAction

@export var inspect_id: String = ""
@export var title: String = ""
@export_multiline var body: String = ""
@export var detail_label: String = ""
@export var detail_required_clicks: int = 0

func to_action(_context: Dictionary = {}) -> Dictionary:
	return {
		"type": "open_item_inspect",
		"inspect_id": inspect_id,
		"title": title,
		"body": body,
		"detail_label": detail_label,
		"detail_required_clicks": detail_required_clicks
	}
