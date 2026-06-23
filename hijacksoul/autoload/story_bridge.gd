extends Node

signal dialogue_line_requested(payload: Dictionary)
signal dialogue_choices_requested(choices: Array)
signal dialogue_ended
signal story_error(message: String)

const DEFAULT_STORY_PATH := "res://levels/prototype/prototype_story.nrstory"
const STORY_LOADER_SCRIPT := "res://addons/narrrail/runtime/story_resource_loader.gd"
const DIRECT_STORY_LOADER_SCRIPT := "res://addons/narrrail/importer/nrstory_loader.gd"
const SESSION_SCRIPT := "res://addons/narrrail/runtime/narrrail_session.gd"

@export var story_event_map: Dictionary = {
	"inspect_wall_note": DEFAULT_STORY_PATH
}

@export var narrrail_event_action_map: Dictionary = {
	"prototype_note_story_seen": [
		{"type": "set_flag", "flag_id": "prototype_note_story_seen", "value": true},
		{"type": "show_toast", "message": "Story event: prototype_note_story_seen"}
	]
}

var _session: RefCounted
var _active_story_path: String = ""
var _active_story_data: Dictionary = {}

func _ready() -> void:
	var bus := _event_bus()
	if bus != null:
		bus.story_event_requested.connect(_on_story_event_requested)

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
	var story_path := String(story_event_map.get(event_id, ""))
	if story_path.is_empty():
		return
	start_story(story_path)

func _on_narrrail_event_emitted(payload: Dictionary) -> void:
	var event_id := String(payload.get("eventId", ""))
	var actions: Array = narrrail_event_action_map.get(event_id, [])
	if actions.is_empty():
		return
	var runner := get_tree().root.get_node_or_null("ActionRunner")
	if runner != null:
		await runner.run_actions(actions, {"story_event_id": event_id, "save_reason": "story_event"})

func _raise_error(message: String) -> void:
	story_error.emit(message)
	push_error(message)

func _event_bus() -> Node:
	return get_tree().root.get_node_or_null("EventBus")
