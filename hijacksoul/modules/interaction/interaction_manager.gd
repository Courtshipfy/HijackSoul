extends Node

signal interaction_started(payload: Dictionary)
signal interaction_ignored(payload: Dictionary, message: String)
signal interaction_finished(payload: Dictionary)

func _ready() -> void:
	var bus := _event_bus()
	if bus != null:
		bus.interaction_requested.connect(func(payload: Dictionary):
			request_interaction(payload)
		)

func request_interaction(payload: Dictionary) -> void:
	interaction_started.emit(payload)
	var object = payload.get("object")
	if object == null or not is_instance_valid(object):
		_ignore(payload, "Interaction payload has no valid object.")
		return

	if object.has_method("is_interaction_enabled") and not object.is_interaction_enabled():
		_ignore(payload, "Interactive object is disabled.")
		return

	var selected_item_id := _selected_item_id()
	var actions: Array = []
	if object.has_method("get_actions_for_item"):
		actions = object.get_actions_for_item(selected_item_id)

	if actions.is_empty():
		_ignore(payload, "Interactive object has no matching actions.")
		return

	var context := payload.duplicate(true)
	context.erase("object")
	context["selected_item_id"] = selected_item_id
	context["save_reason"] = "interaction"

	var runner := get_tree().root.get_node_or_null("ActionRunner")
	if runner == null:
		_ignore(payload, "ActionRunner autoload is missing.")
		return

	await runner.run_actions(actions, context)
	interaction_finished.emit(payload)

func _selected_item_id() -> String:
	var inventory := get_tree().root.get_node_or_null("InventoryManager")
	if inventory != null and inventory.has_method("get_selected_item_id"):
		return String(inventory.get_selected_item_id())
	return ""

func _ignore(payload: Dictionary, message: String) -> void:
	interaction_ignored.emit(payload, message)
	push_warning(message)

func _event_bus() -> Node:
	return get_tree().root.get_node_or_null("EventBus")

