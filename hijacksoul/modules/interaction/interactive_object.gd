@tool
extends Area2D
class_name InteractiveObject

signal hover_started(object_id: String)
signal hover_ended(object_id: String)
signal interaction_requested(payload: Dictionary)

@export_group("Identity")
@export var object_id: String = ""
@export var display_name: String = ""
@export var hover_text: String = ""
@export var save_enabled: bool = true
@export var default_state: String = "default"

@export_group("Visual")
@export var sprite_texture: Texture2D:
	set(value):
		sprite_texture = value
		_sync_editor_nodes()
@export var sprite_offset: Vector2 = Vector2.ZERO:
	set(value):
		sprite_offset = value
		_sync_editor_nodes()
@export var sprite_scale: Vector2 = Vector2.ONE:
	set(value):
		sprite_scale = value
		_sync_editor_nodes()
@export var sprite_modulate: Color = Color.WHITE:
	set(value):
		sprite_modulate = value
		_sync_editor_nodes()

@export_group("Hotspot")
@export var hotspot_size: Vector2 = Vector2(64, 64):
	set(value):
		hotspot_size = value.max(Vector2.ONE)
		_sync_editor_nodes()
@export var hotspot_offset: Vector2 = Vector2.ZERO:
	set(value):
		hotspot_offset = value
		_sync_editor_nodes()

@export_group("Actions")
@export var default_actions: Array[Dictionary] = []
@export var item_interactions: Array[Dictionary] = []
@export var visible_condition: Dictionary = {}
@export var enabled_condition: Dictionary = {}
@export var story_event_on_click: String = ""
@export var pickup_item_id: String = ""
@export var target_view_id: String = ""
@export var puzzle_id: String = ""
@export var auto_build_actions: bool = true

var current_state: String = ""
var interaction_enabled: bool = true
var _default_modulate: Color = Color.WHITE

func _ready() -> void:
	_sync_editor_nodes()
	if Engine.is_editor_hint():
		return

	add_to_group("interactive_object")
	current_state = default_state
	_default_modulate = modulate
	input_pickable = true
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	var game_state := get_tree().root.get_node_or_null("GameState")
	if game_state != null and game_state.has_signal("object_state_changed"):
		game_state.object_state_changed.connect(_on_object_state_changed)
	restore_from_game_state()

func is_interaction_enabled() -> bool:
	return interaction_enabled and visible

func get_actions_for_item(item_id: String) -> Array:
	for branch in item_interactions:
		if typeof(branch) != TYPE_DICTIONARY:
			continue
		if String(branch.get("item_id", "")) == item_id:
			return (branch.get("actions", []) as Array).duplicate(true)

	if not default_actions.is_empty():
		return default_actions.duplicate(true)

	if auto_build_actions:
		return _build_default_actions()

	return []

func restore_from_game_state() -> void:
	if object_id.is_empty():
		return
	var game_state := get_tree().root.get_node_or_null("GameState")
	if game_state == null or not game_state.has_method("get_object_state"):
		return

	var state: Dictionary = game_state.get_object_state(object_id)
	if state.is_empty():
		return
	apply_object_state(state)

func apply_object_state(state: Dictionary) -> void:
	if state.has("visible"):
		visible = bool(state["visible"])
	if state.has("enabled"):
		interaction_enabled = bool(state["enabled"])
	if state.has("state"):
		current_state = String(state["state"])
	if state.has("picked") and bool(state["picked"]):
		visible = false
		interaction_enabled = false

func save_object_state(extra_state: Dictionary = {}) -> void:
	if not save_enabled or object_id.is_empty():
		return
	var game_state := get_tree().root.get_node_or_null("GameState")
	if game_state == null or not game_state.has_method("set_object_state"):
		return

	var state := {
		"visible": visible,
		"enabled": interaction_enabled,
		"state": current_state
	}
	for key in extra_state.keys():
		state[key] = extra_state[key]
	game_state.set_object_state(object_id, state)

func _build_default_actions() -> Array:
	var actions: Array = []
	if not story_event_on_click.is_empty():
		actions.append({"type": "emit_story_event", "event_id": story_event_on_click})
	if not pickup_item_id.is_empty():
		actions.append({"type": "pickup_item", "item_id": pickup_item_id})
	if not target_view_id.is_empty():
		actions.append({"type": "change_view", "view_id": target_view_id})
	if not puzzle_id.is_empty():
		actions.append({"type": "open_puzzle", "puzzle_id": puzzle_id})
	return actions

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_request_interaction()

func _request_interaction() -> void:
	var payload := {
		"object": self,
		"object_id": object_id,
		"display_name": display_name,
		"hover_text": hover_text,
		"state": current_state
	}
	interaction_requested.emit(payload)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_method("request_interaction"):
		bus.request_interaction(payload)

func _on_mouse_entered() -> void:
	modulate = _default_modulate.lightened(0.22)
	hover_started.emit(object_id)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_method("request_interaction_hover_started"):
		bus.request_interaction_hover_started({
			"object": self,
			"object_id": object_id,
			"display_name": display_name,
			"hover_text": hover_text
		})

func _on_mouse_exited() -> void:
	modulate = _default_modulate
	hover_ended.emit(object_id)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_method("request_interaction_hover_ended"):
		bus.request_interaction_hover_ended({
			"object": self,
			"object_id": object_id
		})

func _on_object_state_changed(changed_object_id: String, state: Dictionary) -> void:
	if changed_object_id != object_id:
		return
	apply_object_state(state)

func _sync_editor_nodes() -> void:
	if not is_inside_tree():
		return

	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.texture = sprite_texture
		sprite.offset = sprite_offset
		sprite.scale = sprite_scale
		sprite.modulate = sprite_modulate

	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return
	collision.position = hotspot_offset

	var rect_shape := collision.shape as RectangleShape2D
	if rect_shape == null:
		rect_shape = RectangleShape2D.new()
		collision.shape = rect_shape
	rect_shape.size = hotspot_size
