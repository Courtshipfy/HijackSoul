extends CanvasLayer

const DESIGN_SIZE := Vector2(1280, 720)
const INVENTORY_WIDTH := 128.0
const CONTENT_RIGHT := DESIGN_SIZE.x - INVENTORY_WIDTH
const OUTER_MARGIN := 24.0

@onready var _toast_label: Label = %ToastLabel
@onready var _state_label: Label = %StateLabel
@onready var _tooltip_label: Label = %TooltipLabel

var _toast_timer: SceneTreeTimer
var _inventory_panel: PanelContainer
var _inventory_list: VBoxContainer

func _ready() -> void:
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		bus.toast_requested.connect(_on_toast_requested)
		bus.interaction_hover_started.connect(_on_hover_started)
		bus.interaction_hover_ended.connect(_on_hover_ended)
		bus.action_chain_completed.connect(func(_context: Dictionary):
			_refresh_state()
		)

	var inventory := get_tree().root.get_node_or_null("InventoryManager")
	if inventory != null:
		inventory.item_added.connect(func(_item_id: String):
			_refresh_state()
		)
		inventory.item_removed.connect(func(_item_id: String):
			_refresh_state()
		)
		inventory.selection_changed.connect(func(_item_id: String):
			_refresh_state()
		)

	var game_state := get_tree().root.get_node_or_null("GameState")
	if game_state != null:
		game_state.flag_changed.connect(func(_flag_id: String, _value: Variant):
			_refresh_state()
		)
		game_state.object_state_changed.connect(func(_object_id: String, _state: Dictionary):
			_refresh_state()
		)

	_toast_label.visible = false
	_tooltip_label.visible = false
	_build_inventory_panel()
	_apply_fixed_layout()
	_connect_story_errors()
	_refresh_state()

func _on_toast_requested(message: String, _payload: Dictionary) -> void:
	_toast_label.text = message
	_toast_label.visible = true
	_toast_timer = get_tree().create_timer(1.5)
	await _toast_timer.timeout
	_toast_label.visible = false

func _refresh_state() -> void:
	var game_state := get_tree().root.get_node_or_null("GameState")
	var inventory := get_tree().root.get_node_or_null("InventoryManager")

	var flag_value := false
	var object_state := {}
	if game_state != null:
		flag_value = bool(game_state.get_flag("prototype_clicked", false))
		object_state = game_state.get_object_state("prototype.room_front.test_object")

	var items: Array[String] = []
	var selected_item_id := ""
	if inventory != null:
		items = inventory.get_items()
		selected_item_id = inventory.get_selected_item_id()

	var picked_text := "picked" if bool(object_state.get("picked", false)) else "available"
	_state_label.text = "selected: %s\nprototype: %s / %s" % [
		selected_item_id if not selected_item_id.is_empty() else "(none)",
		"clicked" if flag_value else "not clicked",
		picked_text
	]
	_refresh_inventory_buttons(items, selected_item_id)

func _on_hover_started(payload: Dictionary) -> void:
	var text := String(payload.get("hover_text", ""))
	if text.is_empty():
		text = String(payload.get("display_name", ""))
	if text.is_empty():
		return
	_tooltip_label.text = text
	_tooltip_label.visible = true

func _on_hover_ended(_payload: Dictionary) -> void:
	_tooltip_label.visible = false

func _build_inventory_panel() -> void:
	_inventory_panel = PanelContainer.new()
	_inventory_panel.name = "SideInventoryPanel"
	add_child(_inventory_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 14)
	_inventory_panel.add_child(margin)

	_inventory_list = VBoxContainer.new()
	_inventory_list.name = "InventoryList"
	_inventory_list.add_theme_constant_override("separation", 8)
	margin.add_child(_inventory_list)

func _apply_fixed_layout() -> void:
	_inventory_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_inventory_panel.position = Vector2(CONTENT_RIGHT, 0)
	_inventory_panel.size = Vector2(INVENTORY_WIDTH, DESIGN_SIZE.y)

	_state_label.position = Vector2(OUTER_MARGIN, DESIGN_SIZE.y - 86.0)
	_state_label.size = Vector2(430, 64)
	_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_tooltip_label.position = Vector2(416, DESIGN_SIZE.y - 72.0)
	_tooltip_label.size = Vector2(320, 32)
	_tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_toast_label.position = Vector2(CONTENT_RIGHT - 360.0 - OUTER_MARGIN, DESIGN_SIZE.y - 76.0)
	_toast_label.size = Vector2(360, 36)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _refresh_inventory_buttons(items: Array[String], selected_item_id: String) -> void:
	if _inventory_list == null:
		return
	for child in _inventory_list.get_children():
		child.queue_free()

	for item_id in items:
		var button := Button.new()
		button.custom_minimum_size = Vector2(104, 56)
		button.text = item_id
		button.toggle_mode = true
		button.button_pressed = item_id == selected_item_id
		button.tooltip_text = item_id
		button.pressed.connect(_on_inventory_button_pressed.bind(item_id))
		_inventory_list.add_child(button)

func _on_inventory_button_pressed(item_id: String) -> void:
	var inventory := get_tree().root.get_node_or_null("InventoryManager")
	if inventory == null:
		return
	if inventory.get_selected_item_id() == item_id:
		inventory.select_item("")
	else:
		inventory.select_item(item_id)

func _connect_story_errors() -> void:
	var story_bridge := get_tree().root.get_node_or_null("StoryBridge")
	if story_bridge == null:
		return
	story_bridge.story_error.connect(func(message: String):
		_on_toast_requested(message, {})
	)
