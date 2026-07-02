extends Node2D
class_name RoomView

@export var view_id: String = ""
@export var scene_path: String = ""
@export var enter_actions: Array[Dictionary] = []
@export_group("Music")
@export var music_stream: AudioStream
@export var music_autoplay := true
@export var music_bus := "Master"

const LOCAL_SCENE_MUSIC_NODE_NAME := "SceneMusic"

func _ready() -> void:
	if not view_id.is_empty():
		var game_state := get_tree().root.get_node_or_null("GameState")
		if game_state != null and game_state.has_method("set_current_view"):
			game_state.set_current_view(view_id)

	if not scene_path.is_empty():
		var scene_flow := get_tree().root.get_node_or_null("SceneFlowManager")
		if scene_flow != null and scene_flow.has_method("register_view"):
			scene_flow.register_view(view_id, scene_path)

	_configure_scene_music()
	_restore_interactive_objects(self)
	if not enter_actions.is_empty():
		var runner := get_tree().root.get_node_or_null("ActionRunner")
		if runner != null and runner.has_method("run_actions"):
			await runner.run_actions(enter_actions, {"view_id": view_id, "save_reason": "view_enter"})

func _configure_scene_music() -> void:
	if music_stream == null:
		return

	var music_manager := get_tree().root.get_node_or_null("SceneMusicManager")
	if music_manager != null and music_manager.has_method("play_scene_music"):
		music_manager.play_scene_music(music_stream, music_autoplay, music_bus)
		return

	var player := get_node_or_null(LOCAL_SCENE_MUSIC_NODE_NAME) as AudioStreamPlayer
	if player == null:
		player = AudioStreamPlayer.new()
		player.name = LOCAL_SCENE_MUSIC_NODE_NAME
		add_child(player)

	player.stream = music_stream
	player.bus = music_bus
	player.autoplay = music_autoplay
	if music_autoplay and not player.playing:
		player.play()

func _restore_interactive_objects(root: Node) -> void:
	for child in root.get_children():
		if child.has_method("restore_from_game_state"):
			child.restore_from_game_state()
		_restore_interactive_objects(child)
