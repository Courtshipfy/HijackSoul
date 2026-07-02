extends SceneTree

const BEDROOM_SCENE := "res://levels/house/bedroom.tscn"
const TRAIN_SCENE := "res://levels/train/train.tscn"
const EXPECTED_MAIN_SCENE_MUSIC := "res://music/Sink into the Daylight.ogg"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var bedroom: Node = load(BEDROOM_SCENE).instantiate()
	bedroom.set("enter_actions", [])
	root.add_child(bedroom)
	await process_frame

	var music_manager := root.get_node_or_null("SceneMusicManager")
	if music_manager == null:
		push_error("Expected SceneMusicManager autoload.")
		quit(1)
		return

	var player := music_manager.get_node_or_null("SceneMusic") as AudioStreamPlayer
	if player == null:
		push_error("Expected SceneMusicManager to create SceneMusic.")
		quit(1)
		return
	if player.stream == null or player.stream.resource_path != EXPECTED_MAIN_SCENE_MUSIC:
		push_error("Expected main scene music stream to be %s, got %s" % [
			EXPECTED_MAIN_SCENE_MUSIC,
			player.stream.resource_path if player.stream != null else ""
		])
		quit(1)
		return
	if not player.playing:
		push_error("Expected main scene music to play before entering train.")
		quit(1)
		return

	var train: Node = load(TRAIN_SCENE).instantiate()
	train.set("enter_actions", [])
	root.add_child(train)
	await process_frame

	var configured_stream := train.get("music_stream") as AudioStream
	if configured_stream != null:
		push_error("Expected train music_stream to be empty, got %s" % configured_stream.resource_path)
		quit(1)
		return

	if train.get_node_or_null("TrainMusic") != null:
		push_error("Train scene should not use the legacy TrainMusic node.")
		quit(1)
		return
	if train.get_node_or_null("SceneMusic") != null:
		push_error("Train scene should not create a local SceneMusic node when SceneMusicManager is available.")
		quit(1)
		return

	if player.stream != null or player.playing:
		push_error("Expected train scene without music_stream to stop SceneMusic.")
		quit(1)
		return

	var second_train: Node = load(TRAIN_SCENE).instantiate()
	second_train.set("enter_actions", [])
	root.add_child(second_train)
	await process_frame

	if player.stream != null or player.playing:
		push_error("Expected repeated train scene entry to keep SceneMusic stopped.")
		quit(1)
		return

	print("room_view_music_runner passed")
	quit(0)
