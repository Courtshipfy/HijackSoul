extends SceneTree

const TRAIN_SCENE := "res://levels/train/train.tscn"

var _orange_event_seen := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var bus := root.get_node("EventBus")
	bus.environment_state_change_requested.connect(func(environment_id: String, state_id: String, payload: Dictionary):
		if environment_id == "train.OrangeVisual" and state_id == "orange":
			_orange_event_seen = true
	)

	var train: Node = load(TRAIN_SCENE).instantiate()
	root.add_child(train)
	await process_frame

	var story_bridge := root.get_node("StoryBridge")
	for index in range(80):
		story_bridge.next()
		await process_frame
		var orange := train.get_node_or_null("ObjectLayer/OrangeVisual") as Sprite2D
		if orange != null and orange.visible:
			if not _orange_event_seen:
				push_error("Orange became visible before the story event was observed.")
				quit(1)
				return
			print("train_story_orange_runner passed at step %d" % index)
			quit(0)
			return

	push_error("OrangeVisual did not become visible after advancing the story.")
	quit(1)
