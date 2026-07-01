extends SceneTree

const TRAIN_SCENE := "res://scenes/train.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var train: Node = load(TRAIN_SCENE).instantiate()
	train.set("enter_actions", [])
	root.add_child(train)
	await process_frame

	var overlay := train.get_node_or_null("LightingOverlay") as TextureRect
	if overlay == null:
		push_error("Expected LightingOverlay in train scene.")
		quit(1)
		return

	var bus := root.get_node("EventBus")
	bus.environment_state_change_requested.emit("train.lighting", "dark_tunnel", {
		"params": {"transition_seconds": 0}
	})
	await process_frame

	if not overlay.visible or not is_equal_approx(overlay.modulate.a, 1.0):
		push_error("Expected LightingOverlay to be visible at full alpha for dark_tunnel.")
		quit(1)
		return

	bus.environment_state_change_requested.emit("train.lighting", "day", {
		"params": {"transition_seconds": 0}
	})
	await process_frame

	if overlay.visible or not is_equal_approx(overlay.modulate.a, 0.0):
		push_error("Expected LightingOverlay to be hidden at zero alpha for day.")
		quit(1)
		return

	print("train_lighting_runner passed")
	quit(0)
