extends Node

const ENVIRONMENT_ASSET_PATTERN := "res://arts/%s/environment/%s.png"
const DEFAULT_LIGHTING_TRANSITION_SECONDS := 0.0
const TRAIN_TUNNEL_TEXTURE_TARGETS := [
	{"path": "ScreenLayer/Background", "textures": ["tunnel_train", "tunel_train"]},
	{"path": "ScreenLayer/LeftWindowViewVisual", "textures": ["tunnel_left", "tunel_left"]},
	{"path": "ScreenLayer/RightWindowViewVisual", "textures": ["tunnel_right", "tunel_right"]},
	{"path": "ObjectLayer/girl/Sprite2D", "textures": ["tunnel_girl", "tunel_girl"]},
	{"path": "ObjectLayer/desk/Sprite2D", "textures": ["tunnel_desk", "tunel_desk"]},
	{"path": "ObjectLayer/OrangeVisual", "textures": ["tunnel_orange"]},
	{"path": "ObjectLayer/BookVisual", "textures": ["tunnel_book"]}
]
const CLEAR_LIGHTING_STATES := {
	"day": true,
	"normal": true,
	"clear": true
}

var _lighting_restore_cache: Dictionary = {}

func _ready() -> void:
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		bus.environment_state_change_requested.connect(_on_environment_state_change_requested)

func _on_environment_state_change_requested(environment_id: String, state_id: String, payload: Dictionary) -> void:
	var parts := environment_id.split(".", false, 1)
	if parts.size() != 2:
		push_warning("Environment id must be {scene_id}.{visual_node_name}: %s" % environment_id)
		return

	var scene_id := String(parts[0]).strip_edges()
	var node_name := String(parts[1]).strip_edges()
	var texture_name := state_id.strip_edges()
	if scene_id.is_empty() or node_name.is_empty() or texture_name.is_empty():
		push_warning("Environment event requires scene, node, and state: %s / %s" % [environment_id, state_id])
		return

	if not _is_current_scene(scene_id):
		return

	var scene_root := _find_scene_root(scene_id)
	if scene_root == null:
		push_warning("Environment scene root not found: %s" % scene_id)
		return

	if node_name == "lighting":
		_apply_lighting_state(scene_root, scene_id, state_id, payload)
		return

	var target := _find_node_by_name(scene_root, node_name)
	if target == null:
		push_warning("Environment node not found: %s" % environment_id)
		return

	var texture := _load_environment_texture(scene_id, [texture_name])
	if texture == null:
		push_warning("Environment texture not found: %s" % (ENVIRONMENT_ASSET_PATTERN % [scene_id, texture_name]))
		return

	if not _set_visual_texture(target, texture):
		push_warning("Environment node must be Sprite2D or TextureRect: %s" % target.get_path())

func _apply_lighting_state(scene_root: Node, scene_id: String, state_id: String, payload: Dictionary) -> void:
	var normalized_state := state_id.strip_edges().to_lower()
	var transition_seconds := _transition_seconds(payload)
	match normalized_state:
		"dark_tunnel":
			_apply_train_tunnel_state(scene_root, scene_id, transition_seconds)
		_:
			if CLEAR_LIGHTING_STATES.has(normalized_state):
				_restore_lighting_state(scene_root, scene_id, transition_seconds)
			else:
				push_warning("Unsupported lighting state: %s" % state_id)

func _apply_train_tunnel_state(scene_root: Node, scene_id: String, transition_seconds: float) -> void:
	if scene_id != "train":
		push_warning("Lighting state has no scene preset: %s" % scene_id)
		return

	for target_config in TRAIN_TUNNEL_TEXTURE_TARGETS:
		var target_path := String(target_config.get("path", ""))
		var target := scene_root.get_node_or_null(NodePath(target_path))
		if target == null:
			push_warning("Train tunnel visual node not found: %s" % target_path)
			continue

		var texture_names: Array = target_config.get("textures", [])
		var texture := _load_environment_texture(scene_id, texture_names)
		if texture == null:
			push_warning("Train tunnel texture not found for node: %s" % target_path)
			continue

		_cache_lighting_restore_state(scene_root, scene_id, target)
		var target_modulate := (target as CanvasItem).modulate if target is CanvasItem else Color.WHITE
		var fade_out_visual := _create_fade_out_visual(target, transition_seconds)
		if not _set_visual_texture(target, texture, false):
			push_warning("Train tunnel visual must be Sprite2D or TextureRect: %s" % target.get_path())
			if fade_out_visual != null:
				fade_out_visual.queue_free()
			continue
		_crossfade_to_target(target, fade_out_visual, transition_seconds, target_modulate)

func _restore_lighting_state(scene_root: Node, scene_id: String, transition_seconds: float) -> void:
	var scene_cache: Dictionary = _lighting_restore_cache.get(scene_id, {})
	for relative_path in scene_cache.keys():
		var target := scene_root.get_node_or_null(NodePath(relative_path))
		if target == null:
			continue

		var restore_state: Dictionary = scene_cache[relative_path]
		var texture: Variant = restore_state.get("texture", null)
		var fade_out_visual := _create_fade_out_visual(target, transition_seconds)
		if target is Sprite2D:
			(target as Sprite2D).texture = texture as Texture2D
		elif target is TextureRect:
			(target as TextureRect).texture = texture as Texture2D

		if target is CanvasItem:
			(target as CanvasItem).visible = bool(restore_state.get("visible", true))
		if target is Node2D:
			var node_2d := target as Node2D
			node_2d.position = restore_state.get("position", node_2d.position)
			node_2d.scale = restore_state.get("scale", node_2d.scale)
		if target is CanvasItem:
			_crossfade_to_target(target, fade_out_visual, transition_seconds, restore_state.get("modulate", Color.WHITE))

	_lighting_restore_cache.erase(scene_id)

func _cache_lighting_restore_state(scene_root: Node, scene_id: String, target: Node) -> void:
	var relative_path := str(scene_root.get_path_to(target))
	var scene_cache: Dictionary = _lighting_restore_cache.get(scene_id, {})
	if scene_cache.has(relative_path):
		return

	var texture: Texture2D = null
	if target is Sprite2D:
		texture = (target as Sprite2D).texture
	elif target is TextureRect:
		texture = (target as TextureRect).texture

	scene_cache[relative_path] = {
		"texture": texture,
		"visible": (target as CanvasItem).visible if target is CanvasItem else true,
		"modulate": (target as CanvasItem).modulate if target is CanvasItem else Color.WHITE,
		"position": (target as Node2D).position if target is Node2D else Vector2.ZERO,
		"scale": (target as Node2D).scale if target is Node2D else Vector2.ONE
	}
	_lighting_restore_cache[scene_id] = scene_cache

func _transition_seconds(payload: Dictionary) -> float:
	var params: Variant = payload.get("params", {})
	if typeof(params) == TYPE_DICTIONARY:
		return maxf(0.0, float((params as Dictionary).get("transition_seconds", DEFAULT_LIGHTING_TRANSITION_SECONDS)))
	return DEFAULT_LIGHTING_TRANSITION_SECONDS

func _create_fade_out_visual(target: Node, transition_seconds: float) -> CanvasItem:
	if transition_seconds <= 0.0 or not target is CanvasItem:
		return null

	var source := target as CanvasItem
	if not source.visible or is_zero_approx(source.modulate.a):
		return null

	var parent := target.get_parent()
	if parent == null:
		return null

	var fade_visual := target.duplicate() as CanvasItem
	if fade_visual == null:
		return null

	fade_visual.name = "%sFadeOut" % target.name
	parent.add_child(fade_visual)
	parent.move_child(fade_visual, min(target.get_index() + 1, parent.get_child_count() - 1))
	fade_visual.visible = true
	return fade_visual

func _crossfade_to_target(target: Node, fade_out_visual: CanvasItem, transition_seconds: float, target_modulate: Color = Color.WHITE) -> void:
	if not target is CanvasItem:
		return

	var target_visual := target as CanvasItem
	if transition_seconds <= 0.0:
		target_visual.modulate = target_modulate
		if fade_out_visual != null:
			fade_out_visual.queue_free()
		return

	var final_modulate := target_modulate
	var start_modulate := final_modulate
	start_modulate.a = 0.0
	target_visual.modulate = start_modulate

	if not target_visual.visible:
		if fade_out_visual != null:
			fade_out_visual.queue_free()
		target_visual.modulate = final_modulate
		return

	var tween := target_visual.create_tween()
	tween.set_parallel(true)
	tween.tween_property(target_visual, "modulate", final_modulate, transition_seconds)
	if fade_out_visual != null:
		var fade_modulate := fade_out_visual.modulate
		fade_modulate.a = 0.0
		tween.tween_property(fade_out_visual, "modulate", fade_modulate, transition_seconds)
	tween.finished.connect(func():
		target_visual.modulate = final_modulate
		if fade_out_visual != null and is_instance_valid(fade_out_visual):
			fade_out_visual.queue_free()
	)

func _load_environment_texture(scene_id: String, texture_names: Array) -> Texture2D:
	for texture_name in texture_names:
		var normalized_name := String(texture_name).strip_edges()
		if normalized_name.is_empty():
			continue

		for candidate_name in _texture_name_candidates(normalized_name):
			var texture_path := ENVIRONMENT_ASSET_PATTERN % [scene_id, candidate_name]
			if not ResourceLoader.exists(texture_path, "Texture2D"):
				continue

			var texture := load(texture_path) as Texture2D
			if texture != null:
				return texture

	return null

func _texture_name_candidates(texture_name: String) -> Array[String]:
	var candidates: Array[String] = [texture_name]
	if texture_name.begins_with("tunnel_"):
		var legacy_name := "tunel_%s" % texture_name.trim_prefix("tunnel_")
		if not candidates.has(legacy_name):
			candidates.append(legacy_name)
	return candidates

func _set_visual_texture(target: Node, texture: Texture2D, reveal: bool = true) -> bool:
	if target is Sprite2D:
		(target as Sprite2D).texture = texture
		if reveal:
			(target as Sprite2D).visible = true
		return true
	if target is TextureRect:
		(target as TextureRect).texture = texture
		if reveal:
			(target as TextureRect).visible = true
		return true
	return false

func _is_current_scene(scene_id: String) -> bool:
	var game_state := get_tree().root.get_node_or_null("GameState")
	if game_state == null:
		return true

	var current_view_id := String(game_state.get("current_view_id"))
	return current_view_id.is_empty() or current_view_id == scene_id

func _find_scene_root(scene_id: String) -> Node:
	var current := get_tree().current_scene
	if _node_matches_scene_id(current, scene_id):
		return current

	for child in get_tree().root.get_children():
		if _node_matches_scene_id(child, scene_id):
			return child

	return get_tree().root if _is_current_scene(scene_id) else null

func _node_matches_scene_id(node: Node, scene_id: String) -> bool:
	if node == null:
		return false

	var view_value: Variant = node.get("view_id")
	if typeof(view_value) == TYPE_STRING and String(view_value) == scene_id:
		return true

	return node.name.to_snake_case() == scene_id

func _find_node_by_name(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root

	for child in root.get_children():
		var found := _find_node_by_name(child, node_name)
		if found != null:
			return found

	return null
