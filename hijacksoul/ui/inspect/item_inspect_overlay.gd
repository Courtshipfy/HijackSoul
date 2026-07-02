extends CanvasLayer

const DESIGN_SIZE := Vector2(1920, 1080)
const PANEL_SIZE := Vector2(760, 620)
const TARGET_BUTTON_SIZE := Vector2(260, 64)

var _root: Control
var _panel: PanelContainer
var _title_label: Label
var _body_label: RichTextLabel
var _target_button: Button
var _prev_button: Button
var _next_button: Button
var _page_label: Label
var _close_button: Button

var _config: Dictionary = {}
var _context: Dictionary = {}
var _pages: Array = []
var _page_index := 0
var _detail_clicks := 0
var _completion_running := false

func _ready() -> void:
	layer = 40
	_build_ui()
	visible = false
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		bus.item_inspect_requested.connect(_on_item_inspect_requested)

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.58)
	_root.add_child(dim)

	_panel = PanelContainer.new()
	_panel.name = "InspectPanel"
	_panel.position = (DESIGN_SIZE - PANEL_SIZE) * 0.5
	_panel.size = PANEL_SIZE
	_root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	layout.add_child(header)

	_title_label = Label.new()
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 30)
	_title_label.text = "Inspect"
	header.add_child(_title_label)

	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.custom_minimum_size = Vector2(108, 44)
	_close_button.pressed.connect(_hide_overlay)
	header.add_child(_close_button)

	var display_frame := PanelContainer.new()
	display_frame.custom_minimum_size = Vector2(0, 250)
	display_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(display_frame)

	var display_margin := MarginContainer.new()
	display_margin.add_theme_constant_override("margin_left", 18)
	display_margin.add_theme_constant_override("margin_top", 18)
	display_margin.add_theme_constant_override("margin_right", 18)
	display_margin.add_theme_constant_override("margin_bottom", 18)
	display_frame.add_child(display_margin)

	var display_label := Label.new()
	display_label.name = "PlaceholderVisual"
	display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	display_label.add_theme_font_size_override("font_size", 24)
	display_label.text = "Object Preview"
	display_margin.add_child(display_label)

	_body_label = RichTextLabel.new()
	_body_label.custom_minimum_size = Vector2(0, 160)
	_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_label.fit_content = true
	_body_label.bbcode_enabled = false
	_body_label.scroll_active = true
	layout.add_child(_body_label)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 14)
	layout.add_child(footer)

	_prev_button = Button.new()
	_prev_button.text = "Prev"
	_prev_button.custom_minimum_size = Vector2(108, 44)
	_prev_button.pressed.connect(_show_previous_page)
	footer.add_child(_prev_button)

	_page_label = Label.new()
	_page_label.custom_minimum_size = Vector2(100, 44)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(_page_label)

	_next_button = Button.new()
	_next_button.text = "Next"
	_next_button.custom_minimum_size = Vector2(108, 44)
	_next_button.pressed.connect(_show_next_page)
	footer.add_child(_next_button)

	_target_button = Button.new()
	_target_button.custom_minimum_size = TARGET_BUTTON_SIZE
	_target_button.pressed.connect(_on_target_pressed)
	layout.add_child(_target_button)

func _on_item_inspect_requested(config: Dictionary, context: Dictionary) -> void:
	_config = config.duplicate(true)
	_context = context.duplicate(true)
	_detail_clicks = 0
	_completion_running = false
	_page_index = 0
	_pages = _normalize_pages(_config)
	_title_label.text = String(_config.get("title", _config.get("inspect_id", "Inspect")))
	_target_button.text = String(_config.get("detail_label", ""))
	_target_button.visible = int(_config.get("detail_required_clicks", 0)) > 0 or not _target_button.text.strip_edges().is_empty()
	_target_button.disabled = _completion_running
	visible = true
	_refresh_page()

func _normalize_pages(config: Dictionary) -> Array:
	var result: Array = []
	var raw_pages: Variant = config.get("pages", [])
	if typeof(raw_pages) == TYPE_ARRAY:
		for page in raw_pages:
			var text := String(page).strip_edges()
			if not text.is_empty():
				result.append(text)
	var body := String(config.get("body", "")).strip_edges()
	if result.is_empty() and not body.is_empty():
		result.append(body)
	if result.is_empty():
		result.append("No details yet.")
	return result

func _refresh_page() -> void:
	_page_index = clampi(_page_index, 0, _pages.size() - 1)
	_body_label.text = String(_pages[_page_index])
	_prev_button.disabled = _page_index <= 0
	_next_button.disabled = _page_index >= _pages.size() - 1
	_page_label.text = "%d / %d" % [_page_index + 1, _pages.size()]

func _show_previous_page() -> void:
	_page_index -= 1
	_refresh_page()

func _show_next_page() -> void:
	_page_index += 1
	_refresh_page()

func _on_target_pressed() -> void:
	if _completion_running:
		return
	_detail_clicks += 1
	_emit_detail_sound()
	_show_detail_feedback()

	var required := int(_config.get("detail_required_clicks", 0))
	if required <= 0 or _detail_clicks < required:
		return

	_completion_running = true
	_target_button.disabled = true
	await _run_completion_actions()
	_hide_overlay()

func _emit_detail_sound() -> void:
	var sounds: Array = []
	var raw_sounds: Variant = _config.get("detail_sounds", [])
	if typeof(raw_sounds) == TYPE_ARRAY:
		sounds = raw_sounds
	var sound_id := ""
	if _detail_clicks - 1 < sounds.size():
		sound_id = String(sounds[_detail_clicks - 1])
	else:
		sound_id = String(_config.get("detail_sound_id", ""))
	if sound_id.is_empty():
		return
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		bus.sound_play_requested.emit(String(_context.get("object_id", "")), sound_id, {
			"inspect_id": String(_config.get("inspect_id", "")),
			"clicks": _detail_clicks
		})

func _show_detail_feedback() -> void:
	var messages: Array = []
	var raw_messages: Variant = _config.get("detail_messages", [])
	if typeof(raw_messages) == TYPE_ARRAY:
		messages = raw_messages
	if _detail_clicks - 1 < messages.size():
		_body_label.text = String(messages[_detail_clicks - 1])

func _run_completion_actions() -> void:
	var actions: Array = []
	var raw_actions: Variant = _config.get("completion_actions", [])
	if typeof(raw_actions) == TYPE_ARRAY:
		actions = raw_actions
	var completion_message := String(_config.get("completion_message", "")).strip_edges()
	if not completion_message.is_empty():
		actions.append({"type": "show_toast", "message": completion_message})
	if actions.is_empty():
		return
	var runner := get_tree().root.get_node_or_null("ActionRunner")
	if runner == null:
		return
	var context := _context.duplicate(true)
	context["inspect_id"] = String(_config.get("inspect_id", ""))
	context["save_reason"] = "item_inspect"
	await runner.run_actions(actions, context)

func _hide_overlay() -> void:
	visible = false
	_config.clear()
	_context.clear()
	_pages.clear()
	_page_index = 0
	_detail_clicks = 0
	_completion_running = false
