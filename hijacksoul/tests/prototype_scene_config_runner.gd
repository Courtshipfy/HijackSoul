extends Node

const FRONT_SCENE := "res://levels/prototype/prototype_room_front.tscn"
const LEFT_SCENE := "res://levels/prototype/prototype_room_left.tscn"
const TRAIN_SCENE := "res://scenes/train.tscn"
const INTERACTION_PREFABS := [
	"res://modules/interaction/prefabs/inspect_object.tscn",
	"res://modules/interaction/prefabs/pickup_object.tscn",
	"res://modules/interaction/prefabs/view_exit_object.tscn",
	"res://modules/interaction/prefabs/story_trigger_object.tscn",
	"res://modules/interaction/prefabs/puzzle_entry_object.tscn",
	"res://modules/interaction/prefabs/locked_object.tscn"
]

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var front: Node = load(FRONT_SCENE).instantiate()
	add_child(front)
	await get_tree().process_frame

	_assert_hotspot(front, "ObjectLayer/ExitToLeftView", Vector2(168, 420))
	_assert_hotspot(front, "ObjectLayer/TestObject", Vector2(240, 180))
	_assert_hotspot(front, "ObjectLayer/PrototypeKey", Vector2(180, 108))
	_assert_interaction_kind(front, "ObjectLayer/ExitToLeftView", 3)
	_assert_interaction_kind(front, "ObjectLayer/TestObject", 2)
	_assert_interaction_kind(front, "ObjectLayer/PrototypeKey", 2)

	var left: Node = load(LEFT_SCENE).instantiate()
	add_child(left)
	await get_tree().process_frame

	_assert_hotspot(left, "ObjectLayer/ExitToFrontView", Vector2(168, 420))
	_assert_hotspot(left, "ObjectLayer/WallNote", Vector2(270, 150))
	_assert_hotspot(left, "ObjectLayer/LockedBox", Vector2(240, 180))
	_assert_interaction_kind(left, "ObjectLayer/ExitToFrontView", 3)
	_assert_interaction_kind(left, "ObjectLayer/WallNote", 4)
	_assert_interaction_kind(left, "ObjectLayer/LockedBox", 6)

	var train: Node = load(TRAIN_SCENE).instantiate()
	train.set("enter_actions", [])
	add_child(train)
	await get_tree().process_frame

	_assert_hotspot(train, "ObjectLayer/girl", Vector2(393, 770))
	_assert_hotspot(train, "ObjectLayer/desk", Vector2(1320, 223))
	_assert_interaction_kind(train, "ObjectLayer/girl", 4)
	_assert_interaction_kind(train, "ObjectLayer/desk", 1)
	_assert_story_event(train, "ObjectLayer/girl", "train_story")
	_assert_scene_music_stopped(train)
	_assert_scene_manager_group_is_absent(train)
	if train.get_node_or_null("DialogueOverlay") == null:
		push_error("Train scene is missing DialogueOverlay.")
		get_tree().quit(1)
		return

	await _assert_interaction_prefabs()

	print("prototype_scene_config_runner passed")
	get_tree().quit(0)

func _assert_hotspot(root: Node, node_path: NodePath, expected_size: Vector2) -> void:
	var node := root.get_node(node_path)
	var collision := node.get_node("CollisionShape2D") as CollisionShape2D
	var shape := collision.shape as RectangleShape2D
	if shape == null or not shape.size.is_equal_approx(expected_size):
		push_error("Unexpected hotspot size on %s: expected %s got %s" % [
			str(node_path),
			str(expected_size),
			str(shape.size if shape != null else Vector2.ZERO)
		])
		get_tree().quit(1)

func _assert_interaction_kind(root: Node, node_path: NodePath, expected_kind: int) -> void:
	var node := root.get_node(node_path)
	if int(node.get("object_kind")) != expected_kind:
		push_error("Unexpected interaction kind on %s: expected %d got %d" % [
			str(node_path),
			expected_kind,
			int(node.get("object_kind"))
		])
		get_tree().quit(1)
		return

	var default_actions: Array = node.get("default_actions")
	var item_interactions: Array = node.get("item_interactions")
	if not default_actions.is_empty() or not item_interactions.is_empty():
		push_error("Prototype interaction still uses legacy Dictionary actions: %s" % str(node_path))
		get_tree().quit(1)

func _assert_story_event(root: Node, node_path: NodePath, expected_event: String) -> void:
	var node := root.get_node(node_path)
	if String(node.get("story_event_on_click")) != expected_event:
		push_error("Unexpected story event on %s: expected %s got %s" % [
			str(node_path),
			expected_event,
			String(node.get("story_event_on_click"))
		])
		get_tree().quit(1)

func _assert_scene_manager_group_is_absent(root: Node) -> void:
	if root.is_in_group("scene_manager_entity_nodes"):
		push_error("Train scene node should not be in scene_manager_entity_nodes: %s" % root.name)
		get_tree().quit(1)
		return
	for child in root.get_children():
		_assert_scene_manager_group_is_absent(child)

func _assert_scene_music_stopped(root: Node) -> void:
	var configured_stream := root.get("music_stream") as AudioStream
	if configured_stream != null:
		push_error("Train scene should not have a configured music_stream: %s" % configured_stream.resource_path)
		get_tree().quit(1)
		return

	var music_manager := get_tree().root.get_node_or_null("SceneMusicManager")
	if music_manager == null:
		push_error("Expected SceneMusicManager autoload.")
		get_tree().quit(1)
		return

	var player := music_manager.get_node_or_null("SceneMusic") as AudioStreamPlayer
	if player == null:
		push_error("Expected SceneMusicManager AudioStreamPlayer.")
		get_tree().quit(1)
		return
	if player.stream != null or player.playing:
		push_error("Expected train scene without music_stream to stop SceneMusic.")
		get_tree().quit(1)

func _assert_interaction_prefabs() -> void:
	for prefab_path in INTERACTION_PREFABS:
		var packed_scene := load(prefab_path) as PackedScene
		if packed_scene == null:
			push_error("Failed to load interaction prefab: %s" % prefab_path)
			get_tree().quit(1)
			return

		var instance := packed_scene.instantiate()
		add_child(instance)
		await get_tree().process_frame

		if not instance.has_method("get_actions_for_item"):
			push_error("Interaction prefab is missing get_actions_for_item: %s" % prefab_path)
			get_tree().quit(1)
			return

		var collision := instance.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or collision.shape == null:
			push_error("Interaction prefab is missing a collision shape: %s" % prefab_path)
			get_tree().quit(1)
			return

		var sprite := instance.get_node_or_null("Sprite2D") as Sprite2D
		if sprite == null:
			push_error("Interaction prefab is missing a Sprite2D: %s" % prefab_path)
			get_tree().quit(1)
			return
		sprite.modulate = Color(0.74, 0.62, 0.48, 1.0)
		instance.set("hotspot_size", Vector2(144, 96))
		await get_tree().process_frame
		if sprite.modulate != Color(0.74, 0.62, 0.48, 1.0):
			push_error("Interaction prefab overwrote Sprite2D modulate: %s" % prefab_path)
			get_tree().quit(1)
			return

		instance.queue_free()
