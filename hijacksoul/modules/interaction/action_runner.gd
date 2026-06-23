extends Node

signal action_started(action: Dictionary, context: Dictionary)
signal action_completed(action: Dictionary, context: Dictionary)
signal action_failed(action: Dictionary, context: Dictionary, message: String)
signal action_chain_completed(context: Dictionary)

func run_actions(actions: Array, context: Dictionary = {}) -> bool:
	for raw_action in actions:
		if typeof(raw_action) != TYPE_DICTIONARY:
			_fail({}, context, "Action must be a Dictionary.")
			return false

		var action: Dictionary = raw_action
		action_started.emit(action, context)
		var ok := await _run_action(action, context)
		if not ok:
			return false
		action_completed.emit(action, context)
		var bus := _event_bus()
		if bus != null:
			bus.action_completed.emit(action, context)

	action_chain_completed.emit(context)
	var bus := _event_bus()
	if bus != null:
		bus.action_chain_completed.emit(context)
		bus.request_autosave(String(context.get("save_reason", "interaction")))
	return true

func _run_action(action: Dictionary, context: Dictionary) -> bool:
	var action_type := String(action.get("type", action.get("action_type", "")))
	match action_type:
		"show_dialogue":
			return _show_dialogue(action, context)
		"emit_story_event":
			return _emit_story_event(action, context)
		"set_flag":
			return _set_flag(action, context)
		"pickup_item":
			return _pickup_item(action, context)
		"remove_item":
			return _remove_item(action, context)
		"change_view":
			return await _change_view(action, context)
		"set_object_state":
			return _set_object_state(action, context)
		"open_puzzle":
			return _open_puzzle(action, context)
		"show_toast":
			return _show_toast(action, context)
		"":
			_fail(action, context, "Action type is empty.")
			return false
		_:
			_fail(action, context, "Unsupported action type: %s" % action_type)
			return false

func _show_dialogue(action: Dictionary, context: Dictionary) -> bool:
	var bus := _event_bus()
	if bus != null:
		var payload := action.duplicate(true)
		payload["context"] = context.duplicate(true)
		bus.dialogue_requested.emit(payload)
	return true

func _emit_story_event(action: Dictionary, context: Dictionary) -> bool:
	var event_id := String(action.get("event_id", action.get("event", "")))
	if event_id.is_empty():
		_fail(action, context, "emit_story_event requires event_id.")
		return false
	var bus := _event_bus()
	if bus != null:
		bus.story_event_requested.emit(event_id, {"action": action.duplicate(true), "context": context.duplicate(true)})
	return true

func _set_flag(action: Dictionary, context: Dictionary) -> bool:
	var flag_id := String(action.get("flag_id", action.get("flag", "")))
	if flag_id.is_empty():
		_fail(action, context, "set_flag requires flag_id.")
		return false
	var game_state := _game_state()
	if game_state != null:
		game_state.set_flag(flag_id, action.get("value", true))
	return true

func _pickup_item(action: Dictionary, context: Dictionary) -> bool:
	var item_id := String(action.get("item_id", ""))
	if item_id.is_empty():
		_fail(action, context, "pickup_item requires item_id.")
		return false
	var bus := _event_bus()
	if bus != null:
		bus.item_pickup_requested.emit(item_id, context)

	var object_id := String(context.get("object_id", action.get("object_id", "")))
	if not object_id.is_empty():
		var game_state := _game_state()
		if game_state != null:
			game_state.set_object_state(object_id, {"visible": false, "picked": true})
	return true

func _remove_item(action: Dictionary, context: Dictionary) -> bool:
	var item_id := String(action.get("item_id", ""))
	if item_id.is_empty():
		_fail(action, context, "remove_item requires item_id.")
		return false
	var bus := _event_bus()
	if bus != null:
		bus.item_remove_requested.emit(item_id, context)
	return true

func _change_view(action: Dictionary, context: Dictionary) -> bool:
	var view_id := String(action.get("view_id", action.get("target_view_id", "")))
	if view_id.is_empty():
		_fail(action, context, "change_view requires view_id.")
		return false
	var scene_path := String(action.get("scene_path", ""))
	var scene_flow := get_tree().root.get_node_or_null("SceneFlowManager")
	if scene_flow == null:
		_fail(action, context, "SceneFlowManager autoload is missing.")
		return false
	await scene_flow.change_view(view_id, scene_path)
	return true

func _set_object_state(action: Dictionary, context: Dictionary) -> bool:
	var object_id := String(action.get("object_id", context.get("object_id", "")))
	if object_id.is_empty():
		_fail(action, context, "set_object_state requires object_id.")
		return false
	var state: Dictionary = action.get("state", {})
	var game_state := _game_state()
	if game_state != null:
		game_state.set_object_state(object_id, state)
	return true

func _open_puzzle(action: Dictionary, context: Dictionary) -> bool:
	var puzzle_id := String(action.get("puzzle_id", ""))
	if puzzle_id.is_empty():
		_fail(action, context, "open_puzzle requires puzzle_id.")
		return false
	var bus := _event_bus()
	if bus != null:
		bus.puzzle_open_requested.emit(puzzle_id, context)
	return true

func _show_toast(action: Dictionary, context: Dictionary) -> bool:
	var message := String(action.get("message", ""))
	var bus := _event_bus()
	if bus != null:
		bus.toast_requested.emit(message, {"action": action.duplicate(true), "context": context.duplicate(true)})
	return true

func _fail(action: Dictionary, context: Dictionary, message: String) -> void:
	action_failed.emit(action, context, message)
	var bus := _event_bus()
	if bus != null:
		bus.action_failed.emit(action, context, message)
	push_error(message)

func _event_bus() -> Node:
	return get_tree().root.get_node_or_null("EventBus")

func _game_state() -> Node:
	return get_tree().root.get_node_or_null("GameState")
