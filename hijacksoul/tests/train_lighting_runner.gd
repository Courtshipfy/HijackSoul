extends SceneTree

const TRAIN_SCENE := "res://scenes/train.tscn"
const TUNNEL_LEFT := "res://arts/train/environment/tunnel_left.png"
const TUNNEL_RIGHT := "res://arts/train/environment/tunnel_right.png"
const TUNNEL_TRAIN := "res://arts/train/environment/tunnel_train.png"
const TUNNEL_GIRL := "res://arts/train/environment/tunnel_girl.png"
const TUNNEL_ORANGE := "res://arts/train/environment/tunnel_orange.png"
const TUNNEL_BOOK := "res://arts/train/environment/tunnel_book.png"
const TUNNEL_DESK := "res://arts/train/environment/tunnel_desk.png"
const ORANGE := "res://arts/train/environment/orange.png"
const BOOK := "res://arts/train/environment/book.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var train: Node = load(TRAIN_SCENE).instantiate()
	train.set("enter_actions", [])
	root.add_child(train)
	await process_frame

	var original_left := _texture_path(train.get_node("ScreenLayer/LeftWindowViewVisual"))
	var original_right := _texture_path(train.get_node("ScreenLayer/RightWindowViewVisual"))
	var original_background := _texture_path(train.get_node("ScreenLayer/Background"))
	var girl_visual := train.get_node("ObjectLayer/girl/Sprite2D") as Sprite2D
	var original_girl_position := girl_visual.global_position
	var original_girl_scale := girl_visual.global_scale
	var original_desk := _texture_path(train.get_node("ObjectLayer/desk/Sprite2D"))
	var desk_visual := train.get_node("ObjectLayer/desk/Sprite2D") as Sprite2D
	var original_desk_global_position := desk_visual.global_position
	var original_desk_global_scale := desk_visual.global_scale
	var original_desk_position: Vector2 = (train.get_node("ObjectLayer/desk/Sprite2D") as Sprite2D).position
	var original_desk_scale: Vector2 = (train.get_node("ObjectLayer/desk/Sprite2D") as Sprite2D).scale

	var router := root.get_node("StoryEventRouter")
	await router.handle_event({
		"eventType": "environment.set_state",
		"params": {
			"environment": "train.OrangeVisual",
			"state": "orange"
		}
	})
	await router.handle_event({
		"eventType": "environment.set_state",
		"params": {
			"environment": "train.BookVisual",
			"state": "book"
		}
	})
	await process_frame

	var orange_visual := train.get_node("ObjectLayer/OrangeVisual") as Sprite2D
	var book_visual := train.get_node("ObjectLayer/BookVisual") as Sprite2D
	var original_orange_position := orange_visual.position
	var original_orange_scale := orange_visual.scale
	var original_orange_global_position := orange_visual.global_position
	var original_orange_global_scale := orange_visual.global_scale
	var original_book_position := book_visual.position
	var original_book_scale := book_visual.scale
	var original_book_global_position := book_visual.global_position
	var original_book_global_scale := book_visual.global_scale

	var dark_ok: bool = await router.handle_event({
		"eventType": "environment.set_state",
		"params": {
			"environment": "train.lighting",
			"state": "dark_tunnel"
		}
	})
	if not dark_ok:
		push_error("Expected StoryEventRouter to accept train.lighting dark_tunnel.")
		quit(1)
		return
	await process_frame

	if not _assert_texture(train, "ScreenLayer/LeftWindowViewVisual", TUNNEL_LEFT):
		quit(1)
		return
	if not _assert_texture(train, "ScreenLayer/RightWindowViewVisual", TUNNEL_RIGHT):
		quit(1)
		return
	if not _assert_texture(train, "ScreenLayer/Background", TUNNEL_TRAIN):
		quit(1)
		return
	if not _assert_texture(train, "ObjectLayer/girl/Sprite2D", TUNNEL_GIRL):
		quit(1)
		return
	if not _assert_texture(train, "ObjectLayer/desk/Sprite2D", TUNNEL_DESK):
		quit(1)
		return
	if not _assert_node2d_transform(girl_visual, original_girl_position, original_girl_scale):
		push_error("Expected girl tunnel texture to keep the normal girl transform.")
		quit(1)
		return
	if not _assert_node2d_transform(desk_visual, original_desk_global_position, original_desk_global_scale):
		push_error("Expected desk tunnel texture to keep the normal desk transform.")
		quit(1)
		return
	if not _assert_texture(train, "ObjectLayer/OrangeVisual", TUNNEL_ORANGE):
		quit(1)
		return
	if not _assert_texture(train, "ObjectLayer/BookVisual", TUNNEL_BOOK):
		quit(1)
		return
	if not _assert_node2d_transform(orange_visual, original_orange_global_position, original_orange_global_scale):
		push_error("Expected OrangeVisual tunnel texture to keep the normal orange transform.")
		quit(1)
		return
	if not _assert_node2d_transform(book_visual, original_book_global_position, original_book_global_scale):
		push_error("Expected BookVisual tunnel texture to keep the normal book transform.")
		quit(1)
		return

	var day_ok: bool = await router.handle_event({
		"eventType": "environment.set_state",
		"params": {
			"environment": "train.lighting",
			"state": "day"
		}
	})
	if not day_ok:
		push_error("Expected StoryEventRouter to accept train.lighting day.")
		quit(1)
		return
	await process_frame

	if _texture_path(train.get_node("ScreenLayer/LeftWindowViewVisual")) != original_left:
		push_error("Expected left window texture to restore after day.")
		quit(1)
		return
	if _texture_path(train.get_node("ScreenLayer/RightWindowViewVisual")) != original_right:
		push_error("Expected right window texture to restore after day.")
		quit(1)
		return
	if _texture_path(train.get_node("ScreenLayer/Background")) != original_background:
		push_error("Expected train background texture to restore after day.")
		quit(1)
		return
	if _texture_path(train.get_node("ObjectLayer/desk/Sprite2D")) != original_desk:
		push_error("Expected desk texture to restore after day.")
		quit(1)
		return
	if (train.get_node("ObjectLayer/desk/Sprite2D") as Sprite2D).position != original_desk_position:
		push_error("Expected desk position to restore after day.")
		quit(1)
		return
	if (train.get_node("ObjectLayer/desk/Sprite2D") as Sprite2D).scale != original_desk_scale:
		push_error("Expected desk scale to restore after day.")
		quit(1)
		return
	if _texture_path(orange_visual) != ORANGE or orange_visual.position != original_orange_position or orange_visual.scale != original_orange_scale:
		push_error("Expected OrangeVisual to restore its normal texture and transform after day.")
		quit(1)
		return
	if _texture_path(book_visual) != BOOK or book_visual.position != original_book_position or book_visual.scale != original_book_scale:
		push_error("Expected BookVisual to restore its normal texture and transform after day.")
		quit(1)
		return

	var transition_dark_ok: bool = await router.handle_event({
		"eventType": "environment.set_state",
		"params": {
			"environment": "train.lighting",
			"state": "dark_tunnel",
			"transition_seconds": 0.01
		}
	})
	if not transition_dark_ok:
		push_error("Expected StoryEventRouter to accept transition_seconds on dark_tunnel.")
		quit(1)
		return
	await _wait_frames(20)

	if not _assert_texture(train, "ObjectLayer/OrangeVisual", TUNNEL_ORANGE):
		quit(1)
		return
	if not is_equal_approx(orange_visual.modulate.a, 1.0):
		push_error("Expected OrangeVisual to finish transition at full alpha. Got: %s" % orange_visual.modulate.a)
		quit(1)
		return

	var transition_day_ok: bool = await router.handle_event({
		"eventType": "environment.set_state",
		"params": {
			"environment": "train.lighting",
			"state": "day",
			"transition_seconds": 0.01
		}
	})
	if not transition_day_ok:
		push_error("Expected StoryEventRouter to accept transition_seconds on day.")
		quit(1)
		return
	await _wait_frames(20)

	if _texture_path(orange_visual) != ORANGE or not is_equal_approx(orange_visual.modulate.a, 1.0):
		push_error("Expected OrangeVisual to restore after transition day.")
		quit(1)
		return

	print("train_lighting_runner passed")
	quit(0)

func _assert_texture(root_node: Node, node_path: NodePath, expected_path: String) -> bool:
	var node := root_node.get_node_or_null(node_path)
	if node == null:
		push_error("Expected node: %s" % str(node_path))
		return false
	var actual_path := _texture_path(node)
	if actual_path != expected_path:
		push_error("Expected %s texture %s, got %s" % [str(node_path), expected_path, actual_path])
		return false
	return true

func _texture_path(node: Node) -> String:
	if node is Sprite2D and (node as Sprite2D).texture != null:
		return (node as Sprite2D).texture.resource_path
	if node is TextureRect and (node as TextureRect).texture != null:
		return (node as TextureRect).texture.resource_path
	return ""

func _assert_node2d_transform(node: Node2D, expected_position: Vector2, expected_scale: Vector2) -> bool:
	return node.global_position.is_equal_approx(expected_position) and node.global_scale.is_equal_approx(expected_scale)

func _wait_frames(frame_count: int) -> void:
	for index in frame_count:
		await process_frame
