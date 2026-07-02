extends Node

const PLAYER_NAME := "SceneMusic"

var current_music_path := ""
var stream_change_count := 0

func _ready() -> void:
	_ensure_player()

func play_scene_music(stream: AudioStream, autoplay: bool = true, bus: String = "Master") -> void:
	if stream == null:
		stop_scene_music()
		return

	var stream_path := stream.resource_path
	var player := _ensure_player()
	if player.stream != null and current_music_path == stream_path:
		player.bus = bus
		if autoplay and not player.playing:
			player.play()
		return

	current_music_path = stream_path
	stream_change_count += 1
	player.stream = stream
	player.bus = bus
	player.autoplay = autoplay
	if autoplay:
		player.play()
	else:
		player.stop()

func stop_scene_music() -> void:
	var player := _ensure_player()
	if player.playing:
		player.stop()
	player.stream = null
	player.autoplay = false
	current_music_path = ""

func _ensure_player() -> AudioStreamPlayer:
	var player := get_node_or_null(PLAYER_NAME) as AudioStreamPlayer
	if player == null:
		player = AudioStreamPlayer.new()
		player.name = PLAYER_NAME
		add_child(player)
	return player
