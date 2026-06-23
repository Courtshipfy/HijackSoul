extends Node

signal view_registered(view_id: String, scene_path: String)
signal view_change_requested(view_id: String)
signal view_change_failed(view_id: String, message: String)
signal view_change_finished(view_id: String)

var view_paths: Dictionary = {}

func register_view(view_id: String, scene_path: String) -> void:
	if view_id.is_empty() or scene_path.is_empty():
		push_warning("Ignored invalid view registration: %s -> %s" % [view_id, scene_path])
		return
	view_paths[view_id] = scene_path
	view_registered.emit(view_id, scene_path)

func change_view(view_id: String, scene_path: String = "") -> void:
	view_change_requested.emit(view_id)
	if not scene_path.is_empty():
		register_view(view_id, scene_path)
	if not view_paths.has(view_id):
		var message := "Unknown view_id: %s" % view_id
		view_change_failed.emit(view_id, message)
		push_error(message)
		return

	var target_scene_path := String(view_paths[view_id])
	var scene_manager := get_tree().root.get_node_or_null("SceneManager")
	if scene_manager != null and scene_manager.has_method("change_scene"):
		await scene_manager.change_scene(target_scene_path)
	else:
		var err := get_tree().change_scene_to_file(target_scene_path)
		if err != OK:
			var load_message := "Failed to change scene to %s: %s" % [target_scene_path, error_string(err)]
			view_change_failed.emit(view_id, load_message)
			push_error(load_message)
			return

	var game_state := get_tree().root.get_node_or_null("GameState")
	if game_state != null and game_state.has_method("set_current_view"):
		game_state.set_current_view(view_id)
	view_change_finished.emit(view_id)
