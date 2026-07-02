extends Node

signal subscene_story_started(config: Dictionary, context: Dictionary)
signal subscene_story_finished(config: Dictionary, context: Dictionary)
signal subscene_story_failed(config: Dictionary, context: Dictionary, message: String)

var _active_flow: Dictionary = {}
var _active_context: Dictionary = {}
var _returning := false

func _ready() -> void:
	var story_bridge := _story_bridge()
	if story_bridge != null and story_bridge.has_signal("dialogue_ended"):
		story_bridge.dialogue_ended.connect(_on_story_ended)

func start_subscene_story(config: Dictionary, context: Dictionary = {}) -> bool:
	if not _active_flow.is_empty():
		return _fail(config, context, "A subscene story is already active.")

	var scene_id := String(config.get("scene_id", config.get("view_id", ""))).strip_edges()
	var scene_path := String(config.get("scene_path", "")).strip_edges()
	var story_id := String(config.get("story_id", config.get("event_id", ""))).strip_edges()
	if scene_id.is_empty():
		return _fail(config, context, "start_subscene_story requires scene_id.")
	if scene_path.is_empty():
		return _fail(config, context, "start_subscene_story requires scene_path.")
	if story_id.is_empty():
		return _fail(config, context, "start_subscene_story requires story_id.")

	var once_flag := String(config.get("once_flag", "")).strip_edges()
	var game_state := _game_state()
	if not once_flag.is_empty() and game_state != null and bool(game_state.get_flag(once_flag, false)):
		return true

	var return_view_id := String(config.get("return_view_id", context.get("return_view_id", ""))).strip_edges()
	if return_view_id.is_empty() and game_state != null:
		return_view_id = String(game_state.get("current_view_id")).strip_edges()
	if return_view_id.is_empty():
		return_view_id = String(context.get("view_id", "")).strip_edges()

	var return_scene_path := String(config.get("return_scene_path", context.get("return_scene_path", ""))).strip_edges()
	if return_scene_path.is_empty():
		return_scene_path = _registered_scene_path(return_view_id)
	if return_view_id.is_empty() or return_scene_path.is_empty():
		return _fail(config, context, "start_subscene_story requires a return view and scene path.")

	_active_flow = config.duplicate(true)
	_active_flow["scene_id"] = scene_id
	_active_flow["scene_path"] = scene_path
	_active_flow["story_id"] = story_id
	_active_flow["return_view_id"] = return_view_id
	_active_flow["return_scene_path"] = return_scene_path
	_active_context = context.duplicate(true)

	var scene_flow := _scene_flow()
	if scene_flow == null:
		_clear_active_flow()
		return _fail(config, context, "SceneFlowManager autoload is missing.")

	if scene_flow.has_method("register_view"):
		scene_flow.register_view(scene_id, scene_path)
	await scene_flow.change_view(scene_id, scene_path)

	var story_bridge := _story_bridge()
	if story_bridge == null:
		_clear_active_flow()
		return _fail(config, context, "StoryBridge autoload is missing.")

	var story_path := story_id
	if story_bridge.has_method("resolve_story_path"):
		story_path = String(story_bridge.resolve_story_path(story_id))
	if story_path.is_empty():
		_clear_active_flow()
		return _fail(config, context, "NarrRail story not found for subscene story: %s" % story_id)

	var started := bool(story_bridge.start_story(story_path))
	if not started:
		_clear_active_flow()
		return _fail(config, context, "Failed to start subscene story: %s" % story_id)

	subscene_story_started.emit(_active_flow.duplicate(true), _active_context.duplicate(true))
	return true

func is_subscene_story_active() -> bool:
	return not _active_flow.is_empty()

func active_flow() -> Dictionary:
	return _active_flow.duplicate(true)

func _on_story_ended() -> void:
	if _active_flow.is_empty() or _returning:
		return
	_returning = true
	await _return_to_main_scene()
	_returning = false

func _return_to_main_scene() -> void:
	var flow := _active_flow.duplicate(true)
	var context := _active_context.duplicate(true)
	var return_view_id := String(flow.get("return_view_id", "")).strip_edges()
	var return_scene_path := String(flow.get("return_scene_path", "")).strip_edges()
	var scene_flow := _scene_flow()
	if scene_flow == null:
		_fail(flow, context, "SceneFlowManager autoload is missing.")
		_clear_active_flow()
		return

	if scene_flow.has_method("register_view"):
		scene_flow.register_view(return_view_id, return_scene_path)
	await scene_flow.change_view(return_view_id, return_scene_path)

	var game_state := _game_state()
	var once_flag := String(flow.get("once_flag", "")).strip_edges()
	if not once_flag.is_empty() and game_state != null:
		game_state.set_flag(once_flag, true)

	var return_actions: Array = []
	var raw_return_actions: Variant = flow.get("return_actions", [])
	if typeof(raw_return_actions) == TYPE_ARRAY:
		return_actions = raw_return_actions
	if not return_actions.is_empty():
		var runner := _action_runner()
		if runner != null:
			context["save_reason"] = String(context.get("save_reason", "subscene_return"))
			await runner.run_actions(return_actions, context)

	subscene_story_finished.emit(flow, context)
	_clear_active_flow()

func _clear_active_flow() -> void:
	_active_flow.clear()
	_active_context.clear()

func _registered_scene_path(view_id: String) -> String:
	if view_id.is_empty():
		return ""
	var scene_flow := _scene_flow()
	if scene_flow == null:
		return ""
	var paths: Dictionary = scene_flow.get("view_paths")
	return String(paths.get(view_id, ""))

func _fail(config: Dictionary, context: Dictionary, message: String) -> bool:
	subscene_story_failed.emit(config.duplicate(true), context.duplicate(true), message)
	push_error(message)
	return false

func _scene_flow() -> Node:
	return get_tree().root.get_node_or_null("SceneFlowManager")

func _story_bridge() -> Node:
	return get_tree().root.get_node_or_null("StoryBridge")

func _game_state() -> Node:
	return get_tree().root.get_node_or_null("GameState")

func _action_runner() -> Node:
	return get_tree().root.get_node_or_null("ActionRunner")
