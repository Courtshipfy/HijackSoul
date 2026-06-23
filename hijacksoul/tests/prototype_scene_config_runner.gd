extends Node

const FRONT_SCENE := "res://levels/prototype/prototype_room_front.tscn"
const LEFT_SCENE := "res://levels/prototype/prototype_room_left.tscn"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var front: Node = load(FRONT_SCENE).instantiate()
	add_child(front)
	await get_tree().process_frame

	_assert_hotspot(front, "ObjectLayer/ExitToLeftView", Vector2(112, 280))
	_assert_hotspot(front, "ObjectLayer/TestObject", Vector2(160, 120))
	_assert_hotspot(front, "ObjectLayer/PrototypeKey", Vector2(120, 72))

	var left: Node = load(LEFT_SCENE).instantiate()
	add_child(left)
	await get_tree().process_frame

	_assert_hotspot(left, "ObjectLayer/ExitToFrontView", Vector2(112, 280))
	_assert_hotspot(left, "ObjectLayer/WallNote", Vector2(180, 100))
	_assert_hotspot(left, "ObjectLayer/LockedBox", Vector2(160, 120))

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

