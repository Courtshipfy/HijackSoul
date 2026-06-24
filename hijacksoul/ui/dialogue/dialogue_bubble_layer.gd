@tool
extends CanvasLayer

const NPC_COLOR := Color(0.80, 0.91, 0.97, 1.0)
const NPC_BUBBLE_COLOR := Color(0.98, 0.98, 0.96, 1.0)
const PLAYER_BUBBLE_COLOR := Color(0.03, 0.62, 0.86, 1.0)
const NARRATION_BUBBLE_COLOR := Color(0.08, 0.08, 0.08, 0.82)
const CHOICE_BUBBLE_COLOR := Color(0.84, 0.05, 0.08, 1.0)
const INK_COLOR := Color(0.08, 0.08, 0.08, 1.0)
const NPC_SLOT_POSITIONS := [
	Vector2(470, 190),
	Vector2(270, 220),
	Vector2(760, 220)
]

class BubblePanel:
	extends PanelContainer

	var tail_direction := Vector2.RIGHT
	var tail_offset := 26.0
	var tail_size := Vector2(22.0, 18.0)
	var bubble_color := Color.WHITE
	var border_color := Color.BLACK
	var border_width := 2

	func _ready() -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = bubble_color
		style.border_color = border_color
		style.set_border_width_all(border_width)
		add_theme_stylebox_override("panel", style)

	func _draw() -> void:
		if tail_direction == Vector2.ZERO:
			return

		var points := PackedVector2Array()
		if absf(tail_direction.x) >= absf(tail_direction.y):
			var base_y := clampf(tail_offset, 10.0, size.y - 10.0)
			if tail_direction.x >= 0.0:
				points = PackedVector2Array([
					Vector2(size.x - 1.0, base_y - tail_size.y * 0.5),
					Vector2(size.x + tail_size.x, base_y + tail_size.y),
					Vector2(size.x - 1.0, base_y + tail_size.y * 0.5)
				])
			else:
				points = PackedVector2Array([
					Vector2(1.0, base_y - tail_size.y * 0.5),
					Vector2(-tail_size.x, base_y + tail_size.y),
					Vector2(1.0, base_y + tail_size.y * 0.5)
				])
		else:
			var base_x := clampf(tail_offset, 10.0, size.x - 10.0)
			if tail_direction.y >= 0.0:
				points = PackedVector2Array([
					Vector2(base_x - tail_size.x * 0.5, size.y - 1.0),
					Vector2(base_x + tail_size.x, size.y + tail_size.y),
					Vector2(base_x + tail_size.x * 0.5, size.y - 1.0)
				])
			else:
				points = PackedVector2Array([
					Vector2(base_x - tail_size.x * 0.5, 1.0),
					Vector2(base_x + tail_size.x, -tail_size.y),
					Vector2(base_x + tail_size.x * 0.5, 1.0)
				])
		draw_colored_polygon(points, bubble_color)
		draw_polyline(points + PackedVector2Array([points[0]]), border_color, float(border_width))

class TailMarker:
	extends Control

	var color := Color.WHITE
	var flipped := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var points := PackedVector2Array([
			Vector2(0, 0),
			Vector2(24, 0),
			Vector2(24, 24)
		])
		if flipped:
			points = PackedVector2Array([
				Vector2(24, 0),
				Vector2(0, 0),
				Vector2(0, 24)
			])
		draw_colored_polygon(points, color)

@export var show_preview_when_root := true

var _stage: Control
var _npc_layer: Control
var _choice_layer: Control
var _player_bubble: BubblePanel
var _player_text_label: Label
var _narration_bubble: BubblePanel
var _narration_text_label: Label
var _npc_views: Dictionary = {}
var _active := false

func _ready() -> void:
	_build_stage()
	if Engine.is_editor_hint():
		_show_preview()
		return

	_set_dialogue_visible(false)
	_connect_story_bridge()
	if show_preview_when_root and get_tree().current_scene == self:
		_show_preview()

func _unhandled_input(event: InputEvent) -> void:
	if _should_advance_from_input(event):
		_next_dialogue()
		get_viewport().set_input_as_handled()

func _build_stage() -> void:
	_stage = Control.new()
	_stage.name = "DialogueStage"
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.gui_input.connect(_on_stage_gui_input)
	add_child(_stage)

	_npc_layer = Control.new()
	_npc_layer.name = "NpcLayer"
	_npc_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_npc_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_npc_layer)

	_player_bubble = _create_bubble("PlayerSpeechBubble", PLAYER_BUBBLE_COLOR, PLAYER_BUBBLE_COLOR, Vector2.RIGHT, Vector2(300, 58))
	_player_bubble.position = Vector2(250, 560)
	_stage.add_child(_player_bubble)

	_player_text_label = _create_bubble_label(Color.WHITE)
	_player_bubble.add_child(_wrap_label(_player_text_label, 12))

	_narration_bubble = _create_bubble("NarrationBubble", NARRATION_BUBBLE_COLOR, NARRATION_BUBBLE_COLOR, Vector2.ZERO, Vector2(620, 64))
	_narration_bubble.position = Vector2(330, 545)
	_stage.add_child(_narration_bubble)

	_narration_text_label = _create_bubble_label(Color.WHITE)
	_narration_bubble.add_child(_wrap_label(_narration_text_label, 14))

	_choice_layer = Control.new()
	_choice_layer.name = "ChoiceLayer"
	_choice_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(_choice_layer)

func _connect_story_bridge() -> void:
	var story_bridge := get_tree().root.get_node_or_null("StoryBridge")
	if story_bridge == null:
		return
	story_bridge.dialogue_line_requested.connect(_on_dialogue_line_requested)
	story_bridge.dialogue_choices_requested.connect(_on_dialogue_choices_requested)
	story_bridge.dialogue_ended.connect(_on_dialogue_ended)

func _on_dialogue_line_requested(payload: Dictionary) -> void:
	_active = true
	_set_dialogue_visible(true)
	_clear_choices()

	var speaker := String(payload.get("speakerId", "")).strip_edges()
	var text := String(payload.get("textKey", "")).strip_edges()
	if text.is_empty():
		text = String(payload.get("text", "")).strip_edges()

	if _is_player_speaker(speaker):
		_show_player_line(text)
	elif _is_narration_speaker(speaker):
		_show_narration_line(text)
	else:
		_show_npc_line(speaker, text)

func _on_dialogue_choices_requested(choices: Array) -> void:
	_active = true
	_set_dialogue_visible(true)
	_hide_player_and_narration()
	_hide_npc_bubbles()
	_clear_choices()

	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var text := String(choice.get("textKey", "")).strip_edges()
		if text.is_empty():
			text = String(choice.get("text", "")).strip_edges()
		_add_choice_button(i, text)

func _on_dialogue_ended() -> void:
	_active = false
	_set_dialogue_visible(false)
	_hide_player_and_narration()
	_hide_npc_bubbles()
	_clear_choices()

func _show_preview() -> void:
	_active = true
	_set_dialogue_visible(true)
	var npc_view := _get_or_create_npc_view("女孩")
	var npc_bubble: BubblePanel = npc_view.get("bubble")
	var npc_label: Label = npc_view.get("text_label")
	npc_bubble.visible = true
	npc_label.text = "（弯腰捡起，目光落在那行字上）你的笔？"
	_fit_bubble(npc_bubble, npc_label, Vector2(220, 64), Vector2(390, 132))

	_player_bubble.visible = true
	_player_text_label.text = "是的，谢谢"
	_fit_bubble(_player_bubble, _player_text_label, Vector2(300, 58), Vector2(460, 118))

	_narration_bubble.visible = true
	_narration_text_label.text = "列车晃动着向南行驶，窗外是连绵的丘陵。"
	_fit_bubble(_narration_bubble, _narration_text_label, Vector2(620, 64), Vector2(720, 150))

func _show_npc_line(speaker: String, text: String) -> void:
	_hide_player_and_narration()
	_hide_npc_bubbles()
	var view := _get_or_create_npc_view(speaker)
	var bubble: BubblePanel = view.get("bubble")
	var label: Label = view.get("text_label")
	bubble.visible = true
	label.text = text
	_fit_bubble(bubble, label, Vector2(220, 64), Vector2(390, 132))

func _show_player_line(text: String) -> void:
	_hide_npc_bubbles()
	_narration_bubble.visible = false
	_player_bubble.visible = true
	_player_text_label.text = text
	_fit_bubble(_player_bubble, _player_text_label, Vector2(300, 58), Vector2(460, 118))

func _show_narration_line(text: String) -> void:
	_hide_npc_bubbles()
	_player_bubble.visible = false
	_narration_bubble.visible = true
	_narration_text_label.text = text
	_fit_bubble(_narration_bubble, _narration_text_label, Vector2(620, 64), Vector2(720, 150))

func _get_or_create_npc_view(speaker: String) -> Dictionary:
	var key := speaker
	if key.is_empty():
		key = "NPC"
	if _npc_views.has(key):
		return _npc_views[key]

	var slot_index := _npc_views.size() % NPC_SLOT_POSITIONS.size()
	var slot_position: Vector2 = NPC_SLOT_POSITIONS[slot_index]
	var group := Control.new()
	group.name = "Npc_%s" % key
	group.position = slot_position
	group.custom_minimum_size = Vector2(120, 170)
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_npc_layer.add_child(group)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = key
	name_label.position = Vector2(20, -28)
	name_label.size = Vector2(88, 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	group.add_child(name_label)

	var head := ColorRect.new()
	head.name = "Head"
	head.color = NPC_COLOR
	head.position = Vector2(42, 0)
	head.size = Vector2(40, 40)
	group.add_child(head)

	var body := ColorRect.new()
	body.name = "Body"
	body.color = NPC_COLOR
	body.position = Vector2(18, 40)
	body.size = Vector2(88, 114)
	group.add_child(body)

	var bubble := _create_bubble("SpeechBubble", NPC_BUBBLE_COLOR, INK_COLOR, Vector2.LEFT, Vector2(220, 64))
	bubble.position = slot_position + Vector2(112, 44)
	_stage.add_child(bubble)

	var text_label := _create_bubble_label(INK_COLOR)
	bubble.add_child(_wrap_label(text_label, 12))

	var view := {
		"group": group,
		"bubble": bubble,
		"text_label": text_label
	}
	_npc_views[key] = view
	return view

func _create_bubble(name: String, fill: Color, border: Color, tail: Vector2, minimum_size: Vector2) -> BubblePanel:
	var bubble := BubblePanel.new()
	bubble.name = name
	bubble.bubble_color = fill
	bubble.border_color = border
	bubble.tail_direction = tail
	bubble.custom_minimum_size = minimum_size
	bubble.size = minimum_size
	bubble.visible = false
	return bubble

func _create_bubble_label(font_color: Color) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", font_color)
	return label

func _wrap_label(label: Label, padding: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", padding)
	margin.add_theme_constant_override("margin_top", padding)
	margin.add_theme_constant_override("margin_right", padding)
	margin.add_theme_constant_override("margin_bottom", padding)
	margin.add_child(label)
	return margin

func _add_choice_button(index: int, text: String) -> void:
	var positions := [
		Vector2(240, 548),
		Vector2(500, 516),
		Vector2(770, 560),
		Vector2(1010, 525)
	]
	var button := Button.new()
	button.name = "ChoiceBubble%d" % index
	button.text = text
	button.position = positions[index % positions.size()] + Vector2(0, 42 * int(index / positions.size()))
	button.size = Vector2(190, 44)
	button.custom_minimum_size = Vector2(190, 44)
	button.clip_text = true
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_on_choice_pressed.bind(index))

	var normal := StyleBoxFlat.new()
	normal.bg_color = CHOICE_BUBBLE_COLOR
	normal.border_color = CHOICE_BUBBLE_COLOR
	normal.set_border_width_all(2)
	var hover := normal.duplicate()
	hover.bg_color = CHOICE_BUBBLE_COLOR.lightened(0.08)
	var pressed := normal.duplicate()
	pressed.bg_color = CHOICE_BUBBLE_COLOR.darkened(0.12)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	_choice_layer.add_child(button)

	var tail := TailMarker.new()
	tail.name = "Tail"
	tail.color = CHOICE_BUBBLE_COLOR
	tail.flipped = index % 2 == 1
	tail.position = Vector2(150 if tail.flipped else 24, 38)
	tail.size = Vector2(24, 24)
	button.add_child(tail)

	if index == 0:
		button.grab_focus.call_deferred()

func _fit_bubble(bubble: Control, label: Label, min_size: Vector2, max_size: Vector2) -> void:
	var text_size := label.get_theme_font("font").get_multiline_string_size(
		label.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		max_size.x - 28.0,
		label.get_theme_font_size("font_size")
	)
	bubble.size = Vector2(
		clampf(text_size.x + 32.0, min_size.x, max_size.x),
		clampf(text_size.y + 32.0, min_size.y, max_size.y)
	)

func _on_stage_gui_input(event: InputEvent) -> void:
	if _should_advance_from_input(event):
		_next_dialogue()
		_stage.accept_event()

func _should_advance_from_input(event: InputEvent) -> bool:
	if not _active or _choice_layer.get_child_count() > 0:
		return false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	return event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select")

func _on_choice_pressed(index: int) -> void:
	var story_bridge := get_tree().root.get_node_or_null("StoryBridge")
	if story_bridge != null:
		story_bridge.choose(index)

func _next_dialogue() -> void:
	var story_bridge := get_tree().root.get_node_or_null("StoryBridge")
	if story_bridge != null:
		story_bridge.next()

func _hide_player_and_narration() -> void:
	_player_bubble.visible = false
	_narration_bubble.visible = false

func _hide_npc_bubbles() -> void:
	for view in _npc_views.values():
		var bubble: BubblePanel = view.get("bubble")
		bubble.visible = false

func _clear_choices() -> void:
	for child in _choice_layer.get_children():
		child.queue_free()

func _set_dialogue_visible(is_visible: bool) -> void:
	visible = is_visible
	if _stage != null:
		_stage.mouse_filter = Control.MOUSE_FILTER_STOP if is_visible else Control.MOUSE_FILTER_IGNORE

func _is_player_speaker(speaker: String) -> bool:
	var normalized := speaker.strip_edges().to_lower()
	return normalized == "player" or normalized == "玩家" or normalized == "主角" or normalized == "我"

func _is_narration_speaker(speaker: String) -> bool:
	var normalized := speaker.strip_edges().to_lower()
	return normalized == "narrator" or normalized == "旁白"
