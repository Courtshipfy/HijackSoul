extends Node

signal saved(path: String, snapshot: Dictionary)
signal loaded(path: String, snapshot: Dictionary)
signal save_failed(path: String, message: String)
signal load_failed(path: String, message: String)

const SAVE_SCHEMA_VERSION := 1

@export var autosave_path: String = "user://autosave.json"

func _ready() -> void:
	var bus := _event_bus()
	if bus != null:
		bus.autosave_requested.connect(func(reason: String):
			save_game({"reason": reason})
		)

func save_game(extra: Dictionary = {}, path: String = autosave_path) -> bool:
	var snapshot := create_snapshot(extra)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var message := "Cannot open save file. Error: %s" % error_string(FileAccess.get_open_error())
		save_failed.emit(path, message)
		push_error(message)
		return false

	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	saved.emit(path, snapshot)
	return true

func load_game(path: String = autosave_path) -> Dictionary:
	if not FileAccess.file_exists(path):
		var missing := "Save file does not exist: %s" % path
		load_failed.emit(path, missing)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var message := "Cannot open save file. Error: %s" % error_string(FileAccess.get_open_error())
		load_failed.emit(path, message)
		push_error(message)
		return {}

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		var parse_message := "Save file is not a JSON object: %s" % path
		load_failed.emit(path, parse_message)
		push_error(parse_message)
		return {}

	var snapshot: Dictionary = parsed
	if not restore_snapshot(snapshot):
		load_failed.emit(path, "Save snapshot restore failed.")
		return {}

	loaded.emit(path, snapshot)
	return snapshot

func clear_save(path: String = autosave_path) -> bool:
	if not FileAccess.file_exists(path):
		return true
	var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("Failed to remove save file %s: %s" % [path, error_string(err)])
		return false
	return true

func create_snapshot(extra: Dictionary = {}) -> Dictionary:
	var snapshot := {
		"schema_version": SAVE_SCHEMA_VERSION,
		"game_state": {},
		"inventory": {},
		"story": {},
		"extra": extra.duplicate(true)
	}

	var game_state := _game_state()
	if game_state != null and game_state.has_method("create_snapshot"):
		snapshot["game_state"] = game_state.create_snapshot()

	var inventory := _inventory_manager()
	if inventory != null and inventory.has_method("create_snapshot"):
		snapshot["inventory"] = inventory.create_snapshot()

	return snapshot

func restore_snapshot(snapshot: Dictionary) -> bool:
	if int(snapshot.get("schema_version", 0)) != SAVE_SCHEMA_VERSION:
		push_error("Unsupported save schema: %s" % str(snapshot.get("schema_version", "")))
		return false

	var game_state := _game_state()
	if game_state != null and game_state.has_method("restore_snapshot"):
		if not game_state.restore_snapshot(snapshot.get("game_state", {})):
			return false

	var inventory := _inventory_manager()
	if inventory != null and inventory.has_method("restore_snapshot"):
		if not inventory.restore_snapshot(snapshot.get("inventory", {})):
			return false

	return true

func _event_bus() -> Node:
	return get_tree().root.get_node_or_null("EventBus")

func _game_state() -> Node:
	return get_tree().root.get_node_or_null("GameState")

func _inventory_manager() -> Node:
	return get_tree().root.get_node_or_null("InventoryManager")

