extends Node

signal dialogue_line_requested(payload: Dictionary)
signal dialogue_choices_requested(choices: Array)
signal dialogue_ended
signal dialogue_npc_bubble_position_requested(payload: Dictionary)
signal story_error(message: String)

const DEFAULT_STORY_PATH := "res://levels/prototype/prototype_story.nrstory"
const STORY_LOADER_SCRIPT := "res://addons/narrrail/runtime/story_resource_loader.gd"
const DIRECT_STORY_LOADER_SCRIPT := "res://addons/narrrail/importer/nrstory_loader.gd"
const SESSION_SCRIPT := "res://addons/narrrail/runtime/narrrail_session.gd"
const SETTING_STORY_RESOURCE_ROOT := "narrrail/story_resource_root"
const DEFAULT_STORY_RESOURCE_ROOT := "res://narrrail_stories"
const STORY_EVENT_ROUTER_NODE := "StoryEventRouter"

@export var story_event_map: Dictionary = {
	"inspect_wall_note": DEFAULT_STORY_PATH
}
@export var story_resource_root: String = DEFAULT_STORY_RESOURCE_ROOT

var _session: RefCounted
var _active_story_path: String = ""
var _active_story_data: Dictionary = {}

func _ready() -> void:
	var bus := _event_bus()
	if bus != null:
		bus.story_event_requested.connect(_on_story_event_requested)
		bus.dialogue_npc_bubble_position_requested.connect(func(payload: Dictionary):
			dialogue_npc_bubble_position_requested.emit(payload)
		)

func start_story(story_path: String, initial_variables: Dictionary = {}) -> bool:
	var load_result := _load_story_data(story_path)
	if not load_result.get("ok", false):
		_raise_error(String(load_result.get("error", "Failed to load story.")))
		return false

	var session_script: Script = load(SESSION_SCRIPT)
	if session_script == null:
		_raise_error("NarrRail session missing: %s" % SESSION_SCRIPT)
		return false

	_session = session_script.new()
	_active_story_path = story_path
	_active_story_data = load_result.get("story", {})
	_connect_session(_session)
	_session.start(_active_story_data, initial_variables)
	return true

func next() -> void:
	if _session == null:
		return
	_session.next()

func choose(index: int) -> void:
	if _session == null:
		return
	_session.choose(index)

func create_snapshot() -> Dictionary:
	if _session == null:
		return {}
	return {
		"story_path": _active_story_path,
		"snapshot": _session.create_save_snapshot()
	}

func restore_snapshot(snapshot: Dictionary) -> bool:
	var story_path := String(snapshot.get("story_path", ""))
	var session_snapshot: Dictionary = snapshot.get("snapshot", {})
	if story_path.is_empty() or session_snapshot.is_empty():
		return true

	var session_script: Script = load(SESSION_SCRIPT)
	if session_script == null:
		return false

	var load_result := _load_story_data(story_path)
	if not load_result.get("ok", false):
		_raise_error(String(load_result.get("error", "Failed to restore story.")))
		return false

	_session = session_script.new()
	_active_story_path = story_path
	_active_story_data = load_result.get("story", {})
	_connect_session(_session)
	return _session.restore_save_snapshot(_active_story_data, session_snapshot)

func resolve_story_path(story_name_or_event_id: String) -> String:
	var key := story_name_or_event_id.strip_edges()
	if key.is_empty():
		return ""

	var mapped_path := String(story_event_map.get(key, ""))
	if not mapped_path.is_empty():
		return mapped_path

	if key.begins_with("res://"):
		if ResourceLoader.exists(key) or FileAccess.file_exists(key):
			return key
		return ""

	var normalized_name := key
	if normalized_name.ends_with(".tres") or normalized_name.ends_with(".res") or normalized_name.ends_with(".nrstory"):
		normalized_name = normalized_name.get_basename()

	var root := _story_resource_root()
	var matches := _find_story_resources_by_name(root, normalized_name)
	if matches.size() == 1:
		return String(matches[0])
	if matches.size() > 1:
		_raise_error("Multiple NarrRail stories match '%s': %s" % [key, ", ".join(matches)])
	return ""

func _connect_session(session: RefCounted) -> void:
	session.line_changed.connect(func(payload: Dictionary):
		dialogue_line_requested.emit(payload)
	)
	session.choices_changed.connect(func(choices: Array):
		dialogue_choices_requested.emit(choices)
	)
	session.ended.connect(func():
		dialogue_ended.emit()
	)
	session.error_raised.connect(func(message: String):
		_raise_error(message)
	)
	session.event_emitted.connect(_on_narrrail_event_emitted)

func _load_story_data(story_path: String) -> Dictionary:
	var loader_path := DIRECT_STORY_LOADER_SCRIPT if story_path.ends_with(".nrstory") else STORY_LOADER_SCRIPT
	var loader_script: Script = load(loader_path)
	if loader_script == null:
		return {"ok": false, "story": {}, "error": "NarrRail story loader missing: %s" % loader_path}
	return loader_script.call("load_story", story_path)

func _on_story_event_requested(event_id: String, _payload: Dictionary) -> void:
	var story_path := resolve_story_path(event_id)
	if story_path.is_empty():
		_raise_error("NarrRail story not found for event/story name: %s" % event_id)
		return
	start_story(story_path)

func _on_narrrail_event_emitted(payload: Dictionary) -> void:
	var router := get_tree().root.get_node_or_null(STORY_EVENT_ROUTER_NODE)
	if router == null:
		_raise_error("StoryEventRouter autoload is missing.")
		return

	var handled: bool = await router.handle_event(payload)
	if not handled:
		var event_type := String(payload.get("eventType", payload.get("eventId", ""))).strip_edges()
		_raise_error("NarrRail story event failed: %s" % event_type)

func _raise_error(message: String) -> void:
	story_error.emit(message)
	push_error(message)

func _event_bus() -> Node:
	return get_tree().root.get_node_or_null("EventBus")

func _story_resource_root() -> String:
	var root := story_resource_root
	if ProjectSettings.has_setting(SETTING_STORY_RESOURCE_ROOT):
		root = String(ProjectSettings.get_setting(SETTING_STORY_RESOURCE_ROOT, root))
	if root.strip_edges().is_empty():
		root = DEFAULT_STORY_RESOURCE_ROOT
	return root.trim_suffix("/")

func _find_story_resources_by_name(root: String, story_name: String) -> Array:
	var matches: Array = []
	var dir := DirAccess.open(root)
	if dir == null:
		return matches

	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		var path := "%s/%s" % [root, name]
		if dir.current_is_dir():
			matches.append_array(_find_story_resources_by_name(path, story_name))
		elif _is_story_resource_name_match(path, story_name):
			var resource := ResourceLoader.load(path)
			if resource != null and _has_resource_property(resource, "story_data"):
				matches.append(path)
		name = dir.get_next()
	dir.list_dir_end()
	return matches

func _is_story_resource_name_match(path: String, story_name: String) -> bool:
	if not (path.ends_with(".tres") or path.ends_with(".res")):
		return false
	return path.get_file().get_basename() == story_name

func _has_resource_property(resource: Resource, property_name: String) -> bool:
	for property in resource.get_property_list():
		if String((property as Dictionary).get("name", "")) == property_name:
			return true
	return false
