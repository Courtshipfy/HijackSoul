extends CanvasLayer

const PLAYER_SPEAKERS := ["player", "玩家", "主角", "我"]
const NARRATION_SPEAKERS := ["narrator", "旁白"]
const DEFAULT_NPC_BUBBLE_POSITION := Vector2(760, 260)

@onready var _stage: Control = $DialogueStage
@onready var _player_panel: PanelContainer = $DialogueStage/PlayerBubble
@onready var _player_label: Label = $DialogueStage/PlayerBubble/Margin/PlayerText
@onready var _npc_panel: PanelContainer = $DialogueStage/NpcBubble
@onready var _npc_name_label: Label = $DialogueStage/NpcBubble/Margin/Content/NpcName
@onready var _npc_text_label: Label = $DialogueStage/NpcBubble/Margin/Content/NpcText
@onready var _npc_tail: ColorRect = $DialogueStage/NpcTail
@onready var _narration_panel: PanelContainer = $DialogueStage/NarrationBanner
@onready var _narration_label: Label = $DialogueStage/NarrationBanner/Margin/NarrationText
@onready var _choice_layer: Control = $DialogueStage/ChoiceLayer

var _speaker_positions: Dictionary = {}
var _speaker_sides: Dictionary = {}
var _default_npc_position := DEFAULT_NPC_BUBBLE_POSITION
var _active := false

func _ready() -> void:
	_apply_fixed_theme()
	_connect_stage_input()
	_connect_story_bridge()
	_hide_all()

func _unhandled_input(event: InputEvent) -> void:
	if _should_advance_from_input(event):
		_next_dialogue()
		get_viewport().set_input_as_handled()

func _apply_fixed_theme() -> void:
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_panel_style(_player_panel, Color(0.02, 0.55, 0.82, 0.94), Color(0.01, 0.34, 0.52, 1.0))
	_apply_panel_style(_npc_panel, Color(0.98, 0.98, 0.94, 0.96), Color(0.10, 0.10, 0.10, 1.0))
	_apply_panel_style(_narration_panel, Color(0.04, 0.04, 0.04, 0.72), Color(0.20, 0.20, 0.20, 0.80))
	_apply_label_style(_player_label, Color.WHITE, 18)
	_apply_label_style(_npc_name_label, Color(0.12, 0.12, 0.12, 1.0), 14)
	_apply_label_style(_npc_text_label, Color(0.08, 0.08, 0.08, 1.0), 18)
	_apply_label_style(_narration_label, Color.WHITE, 18)
	_npc_tail.color = Color(0.98, 0.98, 0.94, 0.96)

func _apply_panel_style(panel: PanelContainer, fill: Color, border: Color) -> void:
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)

func _apply_label_style(label: Label, font_color: Color, font_size: int) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_font_size_override("font_size", font_size)

func _connect_story_bridge() -> void:
	var story_bridge := get_tree().root.get_node_or_null("StoryBridge")
	if story_bridge == null:
		return
	story_bridge.dialogue_line_requested.connect(_on_dialogue_line_requested)
	story_bridge.dialogue_choices_requested.connect(_on_dialogue_choices_requested)
	story_bridge.dialogue_ended.connect(_on_dialogue_ended)
	story_bridge.dialogue_npc_bubble_position_requested.connect(_on_npc_bubble_position_requested)

func _connect_stage_input() -> void:
	var callback := Callable(self, "_on_stage_gui_input")
	if not _stage.gui_input.is_connected(callback):
		_stage.gui_input.connect(callback)

func _on_dialogue_line_requested(payload: Dictionary) -> void:
	_active = true
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
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
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_hide_dialogue_panels()
	_clear_choices()

	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var text := String(choice.get("textKey", "")).strip_edges()
		if text.is_empty():
			text = String(choice.get("text", "")).strip_edges()
		_add_choice_button(i, text)

func _on_dialogue_ended() -> void:
	_hide_all()

func _on_npc_bubble_position_requested(payload: Dictionary) -> void:
	var position: Vector2 = payload.get("position", DEFAULT_NPC_BUBBLE_POSITION)
	var speaker := String(payload.get("speakerId", "")).strip_edges()
	var side := _normalized_side(String(payload.get("side", "right")))
	if speaker.is_empty():
		_default_npc_position = position
	else:
		_speaker_positions[speaker] = position
		_speaker_sides[speaker] = side

	if _npc_panel.visible and (speaker.is_empty() or speaker == _npc_name_label.text):
		_position_npc_bubble(speaker)

func _show_player_line(text: String) -> void:
	_hide_dialogue_panels()
	_player_label.text = text
	_player_panel.visible = true

func _show_narration_line(text: String) -> void:
	_hide_dialogue_panels()
	_narration_label.text = text
	_narration_panel.visible = true

func _show_npc_line(speaker: String, text: String) -> void:
	_hide_dialogue_panels()
	_npc_name_label.text = speaker if not speaker.is_empty() else "NPC"
	_npc_text_label.text = text
	_position_npc_bubble(speaker)
	_npc_panel.visible = true
	_npc_tail.visible = true

func _position_npc_bubble(speaker: String) -> void:
	var position: Vector2 = _speaker_positions.get(speaker, _default_npc_position)
	var side := _normalized_side(String(_speaker_sides.get(speaker, "right")))
	_npc_panel.position = position
	match side:
		"left":
			_npc_tail.position = position + Vector2(-14, 38)
		"right":
			_npc_tail.position = position + Vector2(_npc_panel.size.x - 6.0, 38)
		"up":
			_npc_tail.position = position + Vector2(44, -14)
		"down":
			_npc_tail.position = position + Vector2(44, _npc_panel.size.y - 6.0)
		_:
			_npc_tail.position = position + Vector2(_npc_panel.size.x - 6.0, 38)

func _add_choice_button(index: int, text: String) -> void:
	var slots := [
		Vector2(170, 558),
		Vector2(430, 520),
		Vector2(704, 558),
		Vector2(948, 524)
	]
	var button := Button.new()
	button.name = "ChoiceBubble%d" % index
	button.text = text
	button.position = slots[index % slots.size()] + Vector2(0, 48 * int(index / slots.size()))
	button.size = Vector2(210, 50)
	button.custom_minimum_size = Vector2(210, 50)
	button.clip_text = true
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_on_choice_pressed.bind(index))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.82, 0.04, 0.07, 0.96)
	normal.border_color = Color(0.82, 0.04, 0.07, 1.0)
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 3
	normal.corner_radius_top_right = 3
	normal.corner_radius_bottom_left = 3
	normal.corner_radius_bottom_right = 3
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.08)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.12)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 16)
	_choice_layer.add_child(button)

	if index == 0:
		button.grab_focus.call_deferred()

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

func _hide_all() -> void:
	_active = false
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hide_dialogue_panels()
	_clear_choices()

func _hide_dialogue_panels() -> void:
	_player_panel.visible = false
	_npc_panel.visible = false
	_npc_tail.visible = false
	_narration_panel.visible = false

func _clear_choices() -> void:
	for child in _choice_layer.get_children():
		child.queue_free()

func _is_player_speaker(speaker: String) -> bool:
	return PLAYER_SPEAKERS.has(speaker.strip_edges().to_lower())

func _is_narration_speaker(speaker: String) -> bool:
	return NARRATION_SPEAKERS.has(speaker.strip_edges().to_lower())

func _normalized_side(side: String) -> String:
	var normalized := side.strip_edges().to_lower()
	if ["left", "right", "up", "down"].has(normalized):
		return normalized
	return "right"
