extends Node

const PROTOTYPE_SCENE := "res://levels/prototype/prototype_room_front.tscn"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load(PROTOTYPE_SCENE).instantiate()
	add_child(scene)
	await get_tree().process_frame

	var object: Node = scene.get_node("ObjectLayer/TestObject")
	var interaction_manager: Node = get_tree().root.get_node("InteractionManager")
	await interaction_manager.request_interaction({
		"object": object,
		"object_id": "prototype.room_front.test_object",
		"display_name": "Test Object"
	})
	await get_tree().process_frame

	var game_state: Node = get_tree().root.get_node("GameState")
	var inventory: Node = get_tree().root.get_node("InventoryManager")

	if game_state.get_flag("prototype_clicked", false) != true:
		push_error("Expected prototype_clicked flag to be true.")
		get_tree().quit(1)
		return

	if not inventory.has_item("prototype_token"):
		push_error("Expected inventory to contain prototype_token.")
		get_tree().quit(1)
		return

	var object_state: Dictionary = game_state.get_object_state("prototype.room_front.test_object")
	if not bool(object_state.get("picked", false)):
		push_error("Expected test object picked state to be saved.")
		get_tree().quit(1)
		return

	if not FileAccess.file_exists("user://autosave.json"):
		push_error("Expected autosave file to be created.")
		get_tree().quit(1)
		return

	print("interaction_smoke_runner passed")
	get_tree().quit(0)

