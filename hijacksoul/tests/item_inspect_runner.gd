extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var bus := root.get_node("EventBus")
	var runner := root.get_node("ActionRunner")
	var overlay := root.get_node("ItemInspectOverlay")
	var game_state := root.get_node("GameState")
	var sounds: Array[String] = []

	bus.sound_play_requested.connect(func(_object_id: String, sound_id: String, _payload: Dictionary):
		sounds.append(sound_id)
	)

	var ok: bool = await runner.run_actions([{
		"type": "open_item_inspect",
		"inspect_id": "test.inspect.spring_pen",
		"title": "Test Inspect",
		"pages": ["first page"],
		"detail_label": "Press",
		"detail_required_clicks": 2,
		"detail_sounds": ["stuck", "release"],
		"completion_actions": [{
			"type": "set_flag",
			"flag_id": "test.inspect.complete",
			"value": true
		}]
	}], {"object_id": "test.object"})

	if not ok:
		push_error("Expected open_item_inspect action to succeed.")
		quit(1)
		return

	await process_frame
	if not overlay.visible:
		push_error("Expected ItemInspectOverlay to become visible.")
		quit(1)
		return

	overlay.call("_on_target_pressed")
	await process_frame
	if game_state.get_flag("test.inspect.complete", false) == true:
		push_error("Expected completion flag to stay false before required clicks.")
		quit(1)
		return

	await overlay.call("_on_target_pressed")
	await process_frame
	if game_state.get_flag("test.inspect.complete", false) != true:
		push_error("Expected completion flag after required clicks.")
		quit(1)
		return

	if sounds != ["stuck", "release"]:
		push_error("Expected two inspect sounds. Got: %s" % str(sounds))
		quit(1)
		return

	await runner.run_actions([{
		"type": "open_item_inspect",
		"inspect_id": "test.inspect.note",
		"title": "Info",
		"pages": ["plain text"]
	}], {"object_id": "test.note"})
	await process_frame
	var target_button := overlay.get("_target_button") as Button
	if target_button == null or target_button.visible:
		push_error("Expected plain info inspect to hide the detail target button.")
		quit(1)
		return

	print("item_inspect_runner passed")
	quit(0)
