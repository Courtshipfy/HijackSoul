extends Node

const PROTOTYPE_SCENE := "res://levels/prototype/prototype_room_front.tscn"
const LEFT_SCENE := "res://levels/prototype/prototype_room_left.tscn"

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

	var resource_object_script: Script = load("res://modules/interaction/interactive_object.gd")
	var set_flag_action_script: Script = load("res://modules/interaction/actions/set_flag_action.gd")
	var resource_object: Node = resource_object_script.new()
	var resource_action: Resource = set_flag_action_script.new()
	resource_object.object_id = "prototype.room_front.resource_action_object"
	resource_object.display_name = "Resource Action Object"
	resource_action.flag_id = "prototype_resource_action_clicked"
	resource_action.value = true
	var resource_actions: Array[Resource] = [resource_action]
	resource_object.default_action_resources = resource_actions
	scene.get_node("ObjectLayer").add_child(resource_object)
	await get_tree().process_frame

	await interaction_manager.request_interaction({
		"object": resource_object,
		"object_id": "prototype.room_front.resource_action_object",
		"display_name": "Resource Action Object"
	})
	await get_tree().process_frame

	if game_state.get_flag("prototype_resource_action_clicked", false) != true:
		push_error("Expected Resource action to set prototype_resource_action_clicked.")
		get_tree().quit(1)
		return

	var key_object: Node = scene.get_node("ObjectLayer/PrototypeKey")
	await interaction_manager.request_interaction({
		"object": key_object,
		"object_id": "prototype.room_front.prototype_key",
		"display_name": "Prototype Key"
	})
	await get_tree().process_frame

	if not inventory.has_item("prototype_key"):
		push_error("Expected inventory to contain prototype_key.")
		get_tree().quit(1)
		return

	inventory.select_item("prototype_key")
	var left_scene: Node = load(LEFT_SCENE).instantiate()
	add_child(left_scene)
	await get_tree().process_frame

	var box_object: Node = left_scene.get_node("ObjectLayer/LockedBox")
	await interaction_manager.request_interaction({
		"object": box_object,
		"object_id": "prototype.room_left.locked_box",
		"display_name": "Locked Box"
	})
	await get_tree().process_frame

	if inventory.has_item("prototype_key"):
		push_error("Expected prototype_key to be consumed by locked box.")
		get_tree().quit(1)
		return

	if game_state.get_flag("prototype_box_opened", false) != true:
		push_error("Expected prototype_box_opened flag to be true.")
		get_tree().quit(1)
		return

	var story_bridge: Node = get_tree().root.get_node("StoryBridge")
	if story_bridge.resolve_story_path("test_story") != "res://narrrail_stories/HijackSoul_Stories/Stories/test_story.tres":
		push_error("Expected StoryBridge to resolve test_story to synced .tres resource.")
		get_tree().quit(1)
		return
	if story_bridge.resolve_story_path("train_draft") != "res://narrrail_stories/HijackSoul_Stories/Stories/train_draft.tres":
		push_error("Expected StoryBridge to resolve train_draft to synced .tres resource.")
		get_tree().quit(1)
		return

	var dialogue_lines: Array[String] = []
	story_bridge.dialogue_line_requested.connect(func(payload: Dictionary):
		dialogue_lines.append(String(payload.get("textKey", "")))
	)

	var note_object: Node = left_scene.get_node("ObjectLayer/WallNote")
	await interaction_manager.request_interaction({
		"object": note_object,
		"object_id": "prototype.room_left.wall_note",
		"display_name": "Wall Note"
	})
	await get_tree().process_frame

	if dialogue_lines.is_empty() or dialogue_lines[0] != "The paper is brittle.":
		push_error("Expected NarrRail dialogue line from WallNote.")
		get_tree().quit(1)
		return

	story_bridge.next()
	await get_tree().process_frame
	story_bridge.next()
	await get_tree().process_frame

	if game_state.get_flag("prototype_note_story_seen", false) != true:
		push_error("Expected NarrRail emitted event to set prototype_note_story_seen.")
		get_tree().quit(1)
		return

	print("interaction_smoke_runner passed")
	get_tree().quit(0)
