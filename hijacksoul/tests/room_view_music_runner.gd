extends SceneTree

const TRAIN_SCENE := "res://scenes/train.tscn"
const EXPECTED_TRAIN_MUSIC := "res://music/Sink into the Daylight.ogg"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var train: Node = load(TRAIN_SCENE).instantiate()
	train.set("enter_actions", [])
	root.add_child(train)
	await process_frame

	var configured_stream := train.get("music_stream") as AudioStream
	if configured_stream == null or configured_stream.resource_path != EXPECTED_TRAIN_MUSIC:
		push_error("Expected train music_stream to be %s, got %s" % [
			EXPECTED_TRAIN_MUSIC,
			configured_stream.resource_path if configured_stream != null else ""
		])
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
	if player.stream == null or player.stream.resource_path != EXPECTED_TRAIN_MUSIC:
		push_error("Expected SceneMusic stream to be %s, got %s" % [
			EXPECTED_TRAIN_MUSIC,
			player.stream.resource_path if player.stream != null else ""
		])
		quit(1)
		return
	if not player.autoplay:
		push_error("Expected SceneMusic to autoplay.")
		quit(1)
		return
	if int(music_manager.get("stream_change_count")) != 1:
		push_error("Expected first train entry to start one music stream.")
		quit(1)
		return

	var second_train: Node = load(TRAIN_SCENE).instantiate()
	second_train.set("enter_actions", [])
	root.add_child(second_train)
	await process_frame

	if int(music_manager.get("stream_change_count")) != 1:
		push_error("Expected same scene music to continue without restarting.")
		quit(1)
		return

	print("room_view_music_runner passed")
	quit(0)
