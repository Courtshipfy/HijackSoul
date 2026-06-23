extends Node2D
class_name RoomView

@export var view_id: String = ""
@export var scene_path: String = ""
@export var enter_actions: Array[Dictionary] = []

func _ready() -> void:
	if not view_id.is_empty():
		var game_state := get_tree().root.get_node_or_null("GameState")
		if game_state != null and game_state.has_method("set_current_view"):
			game_state.set_current_view(view_id)

	if not scene_path.is_empty():
		var scene_flow := get_tree().root.get_node_or_null("SceneFlowManager")
		if scene_flow != null and scene_flow.has_method("register_view"):
			scene_flow.register_view(view_id, scene_path)

	_restore_interactive_objects(self)
	if not enter_actions.is_empty():
		var runner := get_tree().root.get_node_or_null("ActionRunner")
		if runner != null and runner.has_method("run_actions"):
			await runner.run_actions(enter_actions, {"view_id": view_id, "save_reason": "view_enter"})

func _restore_interactive_objects(root: Node) -> void:
	for child in root.get_children():
		if child.has_method("restore_from_game_state"):
			child.restore_from_game_state()
		_restore_interactive_objects(child)
