@tool
extends CanvasLayer

const PLAYER_SPEAKERS := ["player", "玩家", "主角", "我"]
const NARRATION_SPEAKERS := ["narrator", "旁白"]
const DEFAULT_NPC_BUBBLE_POSITION := Vector2(437, 445)
const PLAYER_BUBBLE_MIN_WIDTH := 353.0
const NPC_BUBBLE_MIN_WIDTH := 360.0
const BUBBLE_MAX_WIDTH := 1040.0
const PLAYER_TEXT_INSET := Vector2(16, 12)
const NPC_TEXT_INSET := Vector2(14, 10)
const PLAYER_TAIL_CENTER := Vector2(922, 956)
const PLAYER_BUBBLE_TOP := 935.0
const NPC_RIGHT_TAIL_EDGE_OVERLAP := 6.0
const NPC_LEFT_TAIL_EDGE_OVERLAP := 14.0
const NPC_TAIL_OFFSET_BY_SIDE := {
	"left": Vector2(-14, 38),
	"right": Vector2(354, 38),
	"up": Vector2(44, -14),
	"down": Vector2(44, 86)
}

@export_group("Scene Dialogue Layout")
@export var player_tail_center := PLAYER_TAIL_CENTER:
	set(value):
		player_tail_center = value
		_refresh_editor_layout()
@export var player_bubble_top := PLAYER_BUBBLE_TOP:
	set(value):
		player_bubble_top = value
		_refresh_editor_layout()
@export var npc_bubble_position := DEFAULT_NPC_BUBBLE_POSITION:
	set(value):
		npc_bubble_position = value
		_default_npc_position = value
		_refresh_editor_layout()
@export_enum("left", "right", "up", "down") var npc_tail_side := "right":
	set(value):
		npc_tail_side = _normalized_side(value)
		_refresh_editor_layout()
@export var narration_position := Vector2(1503, 473):
	set(value):
		narration_position = value
		_refresh_editor_layout()
@export var narration_size := Vector2(396, 130):
	set(value):
		narration_size = value
		_refresh_editor_layout()

@export_group("Editor Preview")
@export var show_editor_preview := true:
	set(value):
		show_editor_preview = value
		_refresh_editor_layout()
@export_enum("all", "player", "npc", "narration") var editor_preview_mode := "all":
	set(value):
		editor_preview_mode = value
		_refresh_editor_layout()
@export var preview_player_text := "玩家对话预览":
	set(value):
		preview_player_text = value
		_refresh_editor_layout()
@export var preview_npc_name := "NPC":
	set(value):
		preview_npc_name = value
		_refresh_editor_layout()
@export var preview_npc_text := "NPC 对话预览":
	set(value):
		preview_npc_text = value
		_refresh_editor_layout()
@export var preview_narration_text := "旁白预览":
	set(value):
		preview_narration_text = value
		_refresh_editor_layout()

@onready var _stage: Control = $DialogueStage
@onready var _player_group: Control = $DialogueStage/PlayerDialogueBubble
@onready var _player_panel: Panel = $DialogueStage/PlayerDialogueBubble/PlayerBubble
@onready var _player_label: Label = $DialogueStage/PlayerDialogueBubble/PlayerBubble/PlayerText
@onready var _player_tail: ColorRect = $DialogueStage/PlayerDialogueBubble/PlayerTail
@onready var _npc_group: Control = $DialogueStage/NpcDialogueBubble
@onready var _npc_panel: Panel = $DialogueStage/NpcDialogueBubble/NpcBubble
@onready var _npc_name_label: Label = $DialogueStage/NpcDialogueBubble/NpcBubble/NpcName
@onready var _npc_text_label: Label = $DialogueStage/NpcDialogueBubble/NpcBubble/NpcText
@onready var _npc_tail: ColorRect = $DialogueStage/NpcDialogueBubble/NpcTail
@onready var _narration_panel: PanelContainer = $DialogueStage/NarrationBanner
@onready var _narration_label: Label = $DialogueStage/NarrationBanner/Margin/NarrationText
@onready var _choice_layer: Control = $DialogueStage/ChoiceLayer

var _speaker_positions: Dictionary = {}
var _speaker_sides: Dictionary = {}
var _default_npc_position := DEFAULT_NPC_BUBBLE_POSITION
var _active := false

func _ready() -> void:
	_default_npc_position = npc_bubble_position
	_apply_fixed_theme()
	if Engine.is_editor_hint():
		_apply_editor_preview()
		return
	_connect_stage_input()
	_connect_story_bridge()
	_apply_scene_layout()
	_hide_all()

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if _should_advance_from_input(event):
		_next_dialogue()
		get_viewport().set_input_as_handled()

func _apply_fixed_theme() -> void:
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_npc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_narration_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prepare_label(_player_label)
	_prepare_label(_npc_name_label)
	_prepare_label(_npc_text_label)
	_prepare_label(_narration_label)
	_player_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_npc_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _prepare_label(label: Label) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

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
	_fit_player_bubble()
	_player_group.visible = true

func _show_narration_line(text: String) -> void:
	_hide_dialogue_panels()
	_narration_label.text = text
	_narration_panel.visible = true

func _show_npc_line(speaker: String, text: String) -> void:
	_hide_dialogue_panels()
	_npc_name_label.text = speaker if not speaker.is_empty() else "NPC"
	_npc_text_label.text = text
	_fit_npc_bubble()
	_position_npc_bubble(speaker)
	_npc_group.visible = true

func _position_npc_bubble(speaker: String) -> void:
	var position: Vector2 = _speaker_positions.get(speaker, _default_npc_position)
	var side := _normalized_side(String(_speaker_sides.get(speaker, npc_tail_side)))
	var tail_position: Vector2 = position + NPC_TAIL_OFFSET_BY_SIDE.get(side, NPC_TAIL_OFFSET_BY_SIDE["right"])
	_npc_tail.position = tail_position
	match side:
		"left":
			_npc_panel.position = Vector2(tail_position.x + NPC_LEFT_TAIL_EDGE_OVERLAP, position.y)
		"right":
			_npc_panel.position = Vector2(tail_position.x - (_npc_panel.size.x - NPC_RIGHT_TAIL_EDGE_OVERLAP), position.y)
		"up":
			_npc_panel.position = Vector2(tail_position.x - 44.0, position.y)
		"down":
			_npc_panel.position = Vector2(tail_position.x - 44.0, position.y)
		_:
			_npc_panel.position = Vector2(tail_position.x - (_npc_panel.size.x - NPC_RIGHT_TAIL_EDGE_OVERLAP), position.y)

func _fit_player_bubble() -> void:
	var width: float = _bubble_width_for_text(_player_label, _player_label.text, PLAYER_BUBBLE_MIN_WIDTH, PLAYER_TEXT_INSET.x * 2.0)
	_player_panel.position = Vector2(player_tail_center.x - width * 0.5, player_bubble_top)
	_player_panel.size.x = width
	_player_label.size.x = maxf(1.0, width - PLAYER_TEXT_INSET.x * 2.0)

func _fit_npc_bubble() -> void:
	var text_width: float = _bubble_width_for_text(_npc_text_label, _npc_text_label.text, NPC_BUBBLE_MIN_WIDTH, NPC_TEXT_INSET.x * 2.0)
	var name_width: float = _bubble_width_for_text(_npc_name_label, _npc_name_label.text, NPC_BUBBLE_MIN_WIDTH, NPC_TEXT_INSET.x * 2.0)
	var width: float = maxf(text_width, name_width)
	_npc_panel.size.x = width
	_npc_name_label.size.x = maxf(1.0, width - NPC_TEXT_INSET.x * 2.0)
	_npc_text_label.size.x = maxf(1.0, width - NPC_TEXT_INSET.x * 2.0)

func _bubble_width_for_text(label: Label, text: String, min_width: float, horizontal_padding: float) -> float:
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	return clampf(ceil(text_width + horizontal_padding), min_width, BUBBLE_MAX_WIDTH)

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
	_player_group.visible = false
	_npc_group.visible = false
	_narration_panel.visible = false

func _clear_choices() -> void:
	for child in _choice_layer.get_children():
		child.queue_free()

func _apply_scene_layout() -> void:
	_player_tail.position = player_tail_center - _player_tail.pivot_offset
	_narration_panel.position = narration_position
	_narration_panel.size = narration_size
	_default_npc_position = npc_bubble_position
	_position_npc_bubble("")

func _apply_editor_preview() -> void:
	if not _node_refs_ready():
		return
	_clear_choices()
	if not show_editor_preview:
		_hide_dialogue_panels()
		return

	_player_label.text = preview_player_text
	_npc_name_label.text = preview_npc_name
	_npc_text_label.text = preview_npc_text
	_narration_label.text = preview_narration_text
	_fit_player_bubble()
	_fit_npc_bubble()
	_apply_scene_layout()
	_player_group.visible = editor_preview_mode == "all" or editor_preview_mode == "player"
	_npc_group.visible = editor_preview_mode == "all" or editor_preview_mode == "npc"
	_narration_panel.visible = editor_preview_mode == "all" or editor_preview_mode == "narration"

func _refresh_editor_layout() -> void:
	if not is_inside_tree() or not Engine.is_editor_hint():
		return
	call_deferred("_apply_editor_preview")

func _node_refs_ready() -> bool:
	return _stage != null \
		and _player_group != null \
		and _player_panel != null \
		and _player_label != null \
		and _player_tail != null \
		and _npc_group != null \
		and _npc_panel != null \
		and _npc_name_label != null \
		and _npc_text_label != null \
		and _npc_tail != null \
		and _narration_panel != null \
		and _narration_label != null \
		and _choice_layer != null


func _is_player_speaker(speaker: String) -> bool:
	return PLAYER_SPEAKERS.has(speaker.strip_edges().to_lower())

func _is_narration_speaker(speaker: String) -> bool:
	return NARRATION_SPEAKERS.has(speaker.strip_edges().to_lower())

func _normalized_side(side: String) -> String:
	var normalized := side.strip_edges().to_lower()
	if ["left", "right", "up", "down"].has(normalized):
		return normalized
	return "right"
