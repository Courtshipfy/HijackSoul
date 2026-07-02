extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_flow := root.get_node("SceneFlowManager")
	var game_state := root.get_node("GameState")
	var runner := root.get_node("ActionRunner")
	var story_bridge := root.get_node("StoryBridge")
	var subscene_flow := root.get_node("SubSceneFlowManager")
	var scene_manager := root.get_node_or_null("SceneManager")
	if scene_manager != null:
		scene_manager.queue_free()
		await process_frame

	scene_flow.register_view("house.bedroom", "res://levels/house/bedroom.tscn")
	scene_flow.register_view("train", "res://scenes/train.tscn")
	game_state.set_current_view("house.bedroom")

	var ok: bool = await runner.run_actions([{
		"type": "start_subscene_story",
		"scene_id": "train",
		"scene_path": "res://scenes/train.tscn",
		"story_id": "train_story",
		"return_view_id": "house.bedroom",
		"return_scene_path": "res://levels/house/bedroom.tscn",
		"once_flag": "test.subscene.train_done"
	}], {"object_id": "test.spring_pen", "save_reason": "test_subscene"})

	if not ok:
		push_error("Expected start_subscene_story action to succeed.")
		quit(1)
		return
	if not subscene_flow.is_subscene_story_active():
		push_error("Expected SubSceneFlowManager to track an active flow.")
		quit(1)
		return
	if game_state.current_view_id != "train":
		push_error("Expected current view to be train. Got: %s" % game_state.current_view_id)
		quit(1)
		return

	story_bridge.dialogue_ended.emit()
	await process_frame
	await process_frame

	if game_state.current_view_id != "house.bedroom":
		push_error("Expected current view to return to house.bedroom. Got: %s" % game_state.current_view_id)
		quit(1)
		return
	if game_state.get_flag("test.subscene.train_done", false) != true:
		push_error("Expected once_flag to be set after returning from subscene.")
		quit(1)
		return
	if subscene_flow.is_subscene_story_active():
		push_error("Expected active subscene flow to clear after return.")
		quit(1)
		return

	print("subscene_flow_runner passed")
	quit(0)
