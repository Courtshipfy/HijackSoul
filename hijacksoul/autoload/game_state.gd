extends Node

signal current_view_changed(view_id: String)
signal flag_changed(flag_id: String, value: Variant)
signal object_state_changed(object_id: String, state: Dictionary)
signal puzzle_state_changed(puzzle_id: String, state: Dictionary)
signal state_reset

const SNAPSHOT_SCHEMA_VERSION := 1

var current_view_id: String = ""
var flags: Dictionary = {}
var object_states: Dictionary = {}
var puzzle_states: Dictionary = {}

func reset() -> void:
	current_view_id = ""
	flags.clear()
	object_states.clear()
	puzzle_states.clear()
	state_reset.emit()

func set_current_view(view_id: String) -> void:
	if current_view_id == view_id:
		return
	current_view_id = view_id
	current_view_changed.emit(view_id)
	var bus := _event_bus()
	if bus != null:
		bus.current_view_changed.emit(view_id)

func set_flag(flag_id: String, value: Variant) -> void:
	if flag_id.is_empty():
		push_warning("Ignored empty flag_id.")
		return
	flags[flag_id] = value
	flag_changed.emit(flag_id, value)

func get_flag(flag_id: String, default_value: Variant = false) -> Variant:
	return flags.get(flag_id, default_value)

func has_flag(flag_id: String) -> bool:
	return flags.has(flag_id)

func set_object_state(object_id: String, state: Dictionary) -> void:
	if object_id.is_empty():
		push_warning("Ignored empty object_id.")
		return
	var current: Dictionary = object_states.get(object_id, {})
	for key in state.keys():
		current[key] = state[key]
	object_states[object_id] = current
	object_state_changed.emit(object_id, current.duplicate(true))

func get_object_state(object_id: String) -> Dictionary:
	return object_states.get(object_id, {}).duplicate(true)

func set_puzzle_state(puzzle_id: String, state: Dictionary) -> void:
	if puzzle_id.is_empty():
		push_warning("Ignored empty puzzle_id.")
		return
	var current: Dictionary = puzzle_states.get(puzzle_id, {})
	for key in state.keys():
		current[key] = state[key]
	puzzle_states[puzzle_id] = current
	puzzle_state_changed.emit(puzzle_id, current.duplicate(true))

func get_puzzle_state(puzzle_id: String) -> Dictionary:
	return puzzle_states.get(puzzle_id, {}).duplicate(true)

func create_snapshot() -> Dictionary:
	return {
		"schema_version": SNAPSHOT_SCHEMA_VERSION,
		"current_view_id": current_view_id,
		"flags": flags.duplicate(true),
		"object_states": object_states.duplicate(true),
		"puzzle_states": puzzle_states.duplicate(true)
	}

func restore_snapshot(snapshot: Dictionary) -> bool:
	if int(snapshot.get("schema_version", 0)) != SNAPSHOT_SCHEMA_VERSION:
		push_error("Unsupported GameState snapshot schema: %s" % str(snapshot.get("schema_version", "")))
		return false

	current_view_id = String(snapshot.get("current_view_id", ""))
	flags = (snapshot.get("flags", {}) as Dictionary).duplicate(true)
	object_states = (snapshot.get("object_states", {}) as Dictionary).duplicate(true)
	puzzle_states = (snapshot.get("puzzle_states", {}) as Dictionary).duplicate(true)
	current_view_changed.emit(current_view_id)
	return true

func _event_bus() -> Node:
	return get_tree().root.get_node_or_null("EventBus")

