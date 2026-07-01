extends Node

const ENVIRONMENT_ASSET_PATTERN := "res://arts/%s/environment/%s.png"
const LIGHTING_OVERLAY_NODE := "LightingOverlay"
const DARK_TUNNEL_ALPHA := 1.0
const DEFAULT_LIGHTING_TRANSITION_SECONDS := 0.8

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
		_apply_lighting_state(scene_root, state_id, payload)
		return

	var target := _find_node_by_name(scene_root, node_name)
	if target == null:
		push_warning("Environment node not found: %s" % environment_id)
		return

	var texture_path := ENVIRONMENT_ASSET_PATTERN % [scene_id, texture_name]
	if not ResourceLoader.exists(texture_path, "Texture2D"):
		push_warning("Environment texture not found: %s" % texture_path)
		return

	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_warning("Environment texture failed to load: %s" % texture_path)
		return

	if target is Sprite2D:
		(target as Sprite2D).texture = texture
		(target as Sprite2D).visible = true
	elif target is TextureRect:
		(target as TextureRect).texture = texture
		(target as TextureRect).visible = true
	else:
		push_warning("Environment node must be Sprite2D or TextureRect: %s" % target.get_path())

func _apply_lighting_state(scene_root: Node, state_id: String, payload: Dictionary) -> void:
	var overlay := _find_node_by_name(scene_root, LIGHTING_OVERLAY_NODE) as CanvasItem
	if overlay == null:
		push_warning("Lighting overlay node not found: %s" % LIGHTING_OVERLAY_NODE)
		return

	var normalized_state := state_id.strip_edges().to_lower()
	var target_alpha := 0.0
	match normalized_state:
		"dark_tunnel":
			target_alpha = DARK_TUNNEL_ALPHA
		"day", "normal", "clear":
			target_alpha = 0.0
		_:
			push_warning("Unsupported lighting state: %s" % state_id)
			return

	var transition_seconds := _transition_seconds(payload)
	if transition_seconds <= 0.0:
		overlay.modulate.a = target_alpha
		overlay.visible = target_alpha > 0.0
		return

	overlay.visible = true
	var tween := overlay.create_tween()
	tween.tween_property(overlay, "modulate:a", target_alpha, transition_seconds)
	if target_alpha <= 0.0:
		tween.tween_callback(func(): overlay.visible = false)

func _transition_seconds(payload: Dictionary) -> float:
	var params: Variant = payload.get("params", {})
	if typeof(params) == TYPE_DICTIONARY:
		return float((params as Dictionary).get("transition_seconds", DEFAULT_LIGHTING_TRANSITION_SECONDS))
	return DEFAULT_LIGHTING_TRANSITION_SECONDS

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
