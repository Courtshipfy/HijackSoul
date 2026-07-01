extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var bus := root.get_node("EventBus")
	var runner := root.get_node("ActionRunner")
	var state := {"seen": false}

	bus.environment_state_change_requested.connect(func(environment_id: String, state_id: String, payload: Dictionary):
		if environment_id == "train.OrangeVisual" and state_id == "orange_half":
			state["seen"] = true
	)

	var ok: bool = await runner.run_actions([{
		"type": "set_environment_state",
		"environment_id": "train.OrangeVisual",
		"state_id": "orange_half"
	}], {"object_id": "train.orange"})

	if not ok:
		push_error("Expected set_environment_state action chain to succeed.")
		quit(1)
		return

	if not bool(state["seen"]):
		push_error("Expected set_environment_state action to emit environment_state_change_requested.")
		quit(1)
		return

	print("environment_action_runner passed")
	quit(0)
