extends Node

signal item_added(item_id: String)
signal item_removed(item_id: String)
signal selection_changed(item_id: String)
signal inventory_reset

const SNAPSHOT_SCHEMA_VERSION := 1

var items: Array[String] = []
var selected_item_id: String = ""

func _ready() -> void:
	var bus := _event_bus()
	if bus == null:
		return
	bus.item_pickup_requested.connect(func(item_id: String, _context: Dictionary):
		add_item(item_id)
	)
	bus.item_remove_requested.connect(func(item_id: String, _context: Dictionary):
		remove_item(item_id)
	)
	bus.inventory_selection_requested.connect(func(item_id: String):
		select_item(item_id)
	)

func reset() -> void:
	items.clear()
	selected_item_id = ""
	inventory_reset.emit()
	selection_changed.emit(selected_item_id)

func add_item(item_id: String) -> bool:
	if item_id.is_empty():
		push_warning("Ignored empty item_id.")
		return false
	if items.has(item_id):
		return false
	items.append(item_id)
	item_added.emit(item_id)
	return true

func remove_item(item_id: String) -> bool:
	if not items.has(item_id):
		return false
	items.erase(item_id)
	if selected_item_id == item_id:
		selected_item_id = ""
		selection_changed.emit(selected_item_id)
	item_removed.emit(item_id)
	return true

func has_item(item_id: String) -> bool:
	return items.has(item_id)

func select_item(item_id: String) -> bool:
	if item_id.is_empty():
		selected_item_id = ""
		selection_changed.emit(selected_item_id)
		return true
	if not items.has(item_id):
		push_warning("Cannot select missing inventory item: %s" % item_id)
		return false
	selected_item_id = item_id
	selection_changed.emit(selected_item_id)
	return true

func get_selected_item_id() -> String:
	return selected_item_id

func get_items() -> Array[String]:
	return items.duplicate()

func create_snapshot() -> Dictionary:
	return {
		"schema_version": SNAPSHOT_SCHEMA_VERSION,
		"items": items.duplicate(),
		"selected_item_id": selected_item_id
	}

func restore_snapshot(snapshot: Dictionary) -> bool:
	if int(snapshot.get("schema_version", 0)) != SNAPSHOT_SCHEMA_VERSION:
		push_error("Unsupported InventoryManager snapshot schema: %s" % str(snapshot.get("schema_version", "")))
		return false

	items.clear()
	for item in snapshot.get("items", []):
		items.append(String(item))
	selected_item_id = String(snapshot.get("selected_item_id", ""))
	if not selected_item_id.is_empty() and not items.has(selected_item_id):
		selected_item_id = ""
	inventory_reset.emit()
	selection_changed.emit(selected_item_id)
	return true

func _event_bus() -> Node:
	return get_tree().root.get_node_or_null("EventBus")

