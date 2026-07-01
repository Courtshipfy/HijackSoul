extends SceneTree

const TRAIN_SCENE := "res://scenes/train.tscn"
const EXPECTED_LEFT_TEXTURE := "res://arts/train/environment/field_left.png"
const EXPECTED_RIGHT_TEXTURE := "res://arts/train/environment/field_right.png"
const EXPECTED_ORANGE_TEXTURE := "res://arts/train/environment/orange.png"
const EXPECTED_BOOK_TEXTURE := "res://arts/train/environment/book.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var train: Node = load(TRAIN_SCENE).instantiate()
	train.set("enter_actions", [])
	root.add_child(train)
	await process_frame

	var bus := root.get_node("EventBus")
	bus.environment_state_change_requested.emit("train.LeftWindowViewVisual", "field_left", {})
	bus.environment_state_change_requested.emit("train.RightWindowViewVisual", "field_right", {})
	bus.environment_state_change_requested.emit("train.OrangeVisual", "orange", {})
	bus.environment_state_change_requested.emit("train.BookVisual", "book", {})
	await process_frame

	_assert_sprite_texture(train, "ScreenLayer/LeftWindowViewVisual", EXPECTED_LEFT_TEXTURE)
	_assert_sprite_texture(train, "ScreenLayer/RightWindowViewVisual", EXPECTED_RIGHT_TEXTURE)
	_assert_sprite_texture(train, "ObjectLayer/OrangeVisual", EXPECTED_ORANGE_TEXTURE)
	_assert_sprite_texture(train, "ObjectLayer/BookVisual", EXPECTED_BOOK_TEXTURE)

	print("train_environment_controller_runner passed")
	quit(0)

func _assert_sprite_texture(root: Node, node_path: NodePath, expected_path: String) -> void:
	var sprite := root.get_node_or_null(node_path) as Sprite2D
	if sprite == null:
		push_error("Expected Sprite2D at %s." % str(node_path))
		quit(1)
		return

	if sprite.texture == null or sprite.texture.resource_path != expected_path:
		push_error("Unexpected texture on %s: expected %s got %s" % [
			str(node_path),
			expected_path,
			sprite.texture.resource_path if sprite.texture != null else ""
		])
		quit(1)

	if not sprite.visible:
		push_error("Expected %s to be visible after environment event." % str(node_path))
		quit(1)
