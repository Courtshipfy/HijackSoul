extends Node

const FRONT_SCENE := "res://levels/prototype/prototype_room_front.tscn"
const LEFT_SCENE := "res://levels/prototype/prototype_room_left.tscn"
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

	_assert_hotspot(front, "ObjectLayer/ExitToLeftView", Vector2(112, 280))
	_assert_hotspot(front, "ObjectLayer/TestObject", Vector2(160, 120))
	_assert_hotspot(front, "ObjectLayer/PrototypeKey", Vector2(120, 72))
	_assert_interaction_kind(front, "ObjectLayer/ExitToLeftView", 3)
	_assert_interaction_kind(front, "ObjectLayer/TestObject", 2)
	_assert_interaction_kind(front, "ObjectLayer/PrototypeKey", 2)

	var left: Node = load(LEFT_SCENE).instantiate()
	add_child(left)
	await get_tree().process_frame

	_assert_hotspot(left, "ObjectLayer/ExitToFrontView", Vector2(112, 280))
	_assert_hotspot(left, "ObjectLayer/WallNote", Vector2(180, 100))
	_assert_hotspot(left, "ObjectLayer/LockedBox", Vector2(160, 120))
	_assert_interaction_kind(left, "ObjectLayer/ExitToFrontView", 3)
	_assert_interaction_kind(left, "ObjectLayer/WallNote", 4)
	_assert_interaction_kind(left, "ObjectLayer/LockedBox", 6)

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

		instance.queue_free()
