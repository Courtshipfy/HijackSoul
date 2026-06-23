extends CanvasLayer

@onready var _toast_label: Label = %ToastLabel
@onready var _state_label: Label = %StateLabel
@onready var _tooltip_label: Label = %TooltipLabel

var _toast_timer: SceneTreeTimer

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
	if inventory != null:
		items = inventory.get_items()

	_state_label.text = "flag prototype_clicked: %s\ninventory: %s\nobject_state: %s" % [
		str(flag_value),
		", ".join(items) if not items.is_empty() else "(empty)",
		str(object_state)
	]

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
