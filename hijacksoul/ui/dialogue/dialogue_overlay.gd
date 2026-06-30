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
const NARRATION_DESIGN_SIZE := Vector2(650, 500)
const NARRATION_SERIAL_RECT := Rect2(36, 22, 186, 40)
const NARRATION_TITLE_RECT := Rect2(505, 20, 119, 44)
const NARRATION_TEXT_RECT := Rect2(64, 96, 522, 234)
const NARRATION_BOTTOM_CODE_RECT := Rect2(32, 433, 156, 43)
const NARRATION_QR_RECT := Rect2(493, 348, 130, 130)
const NARRATION_SERIAL_FONT_SIZE := 36
const NARRATION_TITLE_FONT_SIZE := 36
const NARRATION_TEXT_FONT_SIZE := 30
const NARRATION_BOTTOM_CODE_FONT_SIZE := 32
const NPC_RIGHT_TAIL_EDGE_OVERLAP := 6.0
const NPC_LEFT_TAIL_EDGE_OVERLAP := 14.0
const CHOICE_DESIGN_SIZE := Vector2(953, 295)
const CHOICE_TEXT_RECT := Rect2(145, 113, 664, 67)
const NPC_TAIL_OFFSET_BY_SIDE := {
	"left": Vector2(-14, 38),
	"right": Vector2(354, 38),
	"up": Vector2(44, -14),
	"down": Vector2(44, 86)
}

@export_group("Scene Dialogue Layout")
@export_enum("export_properties", "scene_nodes") var layout_source := "export_properties":
	set(value):
		layout_source = value
		_refresh_editor_layout()
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

@export_group("Scene Dialogue Style")
@export var player_bubble_fill := Color(0.6078117, 0.49399078, 0.37003753, 0.9411765):
	set(value):
		player_bubble_fill = value
		_refresh_editor_layout()
@export var player_bubble_border := Color(0.01, 0.34, 0.52, 1.0):
	set(value):
		player_bubble_border = value
		_refresh_editor_layout()
@export var player_text_color := Color.WHITE:
	set(value):
		player_text_color = value
		_refresh_editor_layout()
@export var player_font_size := 18:
	set(value):
		player_font_size = maxi(1, value)
		_refresh_editor_layout()
@export var player_tail_color := Color(0.6358052, 0.48747295, 0.27077094, 0.9411765):
	set(value):
		player_tail_color = value
		_refresh_editor_layout()
@export var player_background_texture: Texture2D:
	set(value):
		player_background_texture = value
		_refresh_editor_layout()
@export var player_text_font: Font:
	set(value):
		player_text_font = value
		_refresh_editor_layout()
@export var player_bubble_size := Vector2(520, 216):
	set(value):
		player_bubble_size = value.max(Vector2.ONE)
		_refresh_editor_layout()
@export var player_text_margin_left := 52:
	set(value):
		player_text_margin_left = maxi(0, value)
		_refresh_editor_layout()
@export var player_text_margin_top := 52:
	set(value):
		player_text_margin_top = maxi(0, value)
		_refresh_editor_layout()
@export var player_text_margin_right := 70:
	set(value):
		player_text_margin_right = maxi(0, value)
		_refresh_editor_layout()
@export var player_text_margin_bottom := 48:
	set(value):
		player_text_margin_bottom = maxi(0, value)
		_refresh_editor_layout()
@export var npc_bubble_fill := Color(0.98, 0.98, 0.94, 0.96):
	set(value):
		npc_bubble_fill = value
		_refresh_editor_layout()
@export var npc_bubble_border := Color(0.1, 0.1, 0.1, 1.0):
	set(value):
		npc_bubble_border = value
		_refresh_editor_layout()
@export var npc_name_color := Color(0.12, 0.12, 0.12, 1.0):
	set(value):
		npc_name_color = value
		_refresh_editor_layout()
@export var npc_text_color := Color(0.08, 0.08, 0.08, 1.0):
	set(value):
		npc_text_color = value
		_refresh_editor_layout()
@export var npc_name_font_size := 14:
	set(value):
		npc_name_font_size = maxi(1, value)
		_refresh_editor_layout()
@export var npc_text_font_size := 18:
	set(value):
		npc_text_font_size = maxi(1, value)
		_refresh_editor_layout()
@export var npc_tail_color := Color(0.98, 0.98, 0.94, 0.96):
	set(value):
		npc_tail_color = value
		_refresh_editor_layout()
@export var npc_background_texture: Texture2D:
	set(value):
		npc_background_texture = value
		_refresh_editor_layout()
@export var npc_text_font: Font:
	set(value):
		npc_text_font = value
		_refresh_editor_layout()
@export var npc_bubble_size := Vector2(520, 216):
	set(value):
		npc_bubble_size = value.max(Vector2.ONE)
		_refresh_editor_layout()
@export var npc_text_margin_left := 42:
	set(value):
		npc_text_margin_left = maxi(0, value)
		_refresh_editor_layout()
@export var npc_text_margin_top := 62:
	set(value):
		npc_text_margin_top = maxi(0, value)
		_refresh_editor_layout()
@export var npc_text_margin_right := 52:
	set(value):
		npc_text_margin_right = maxi(0, value)
		_refresh_editor_layout()
@export var npc_text_margin_bottom := 42:
	set(value):
		npc_text_margin_bottom = maxi(0, value)
		_refresh_editor_layout()
@export var narration_background_texture: Texture2D:
	set(value):
		narration_background_texture = value
		_refresh_editor_layout()
@export var narration_background_color := Color(0.04, 0.04, 0.04, 0.72):
	set(value):
		narration_background_color = value
		_refresh_editor_layout()
@export var narration_texture_modulate := Color.WHITE:
	set(value):
		narration_texture_modulate = value
		_refresh_editor_layout()
@export var narration_text_color := Color.WHITE:
	set(value):
		narration_text_color = value
		_refresh_editor_layout()
@export var narration_font_size := 18:
	set(value):
		narration_font_size = maxi(1, value)
		_refresh_editor_layout()
@export var narration_text_font: Font:
	set(value):
		narration_text_font = value
		_refresh_editor_layout()
@export var narration_code_font: Font:
	set(value):
		narration_code_font = value
		_refresh_editor_layout()
@export var narration_title_font: Font:
	set(value):
		narration_title_font = value
		_refresh_editor_layout()
@export var narration_text_margin_left := 22:
	set(value):
		narration_text_margin_left = maxi(0, value)
		_refresh_editor_layout()
@export var narration_text_margin_top := 16:
	set(value):
		narration_text_margin_top = maxi(0, value)
		_refresh_editor_layout()
@export var narration_text_margin_right := 22:
	set(value):
		narration_text_margin_right = maxi(0, value)
		_refresh_editor_layout()
@export var narration_text_margin_bottom := 16:
	set(value):
		narration_text_margin_bottom = maxi(0, value)
		_refresh_editor_layout()
@export var choice_background_texture: Texture2D:
	set(value):
		choice_background_texture = value
		_refresh_editor_layout()
@export var choice_text_font: Font:
	set(value):
		choice_text_font = value
		_refresh_editor_layout()
@export var choice_text_color := Color(0.53, 0.35, 0.35, 1.0):
	set(value):
		choice_text_color = value
		_refresh_editor_layout()
@export var choice_font_size := 36:
	set(value):
		choice_font_size = maxi(1, value)
		_refresh_editor_layout()
@export var choice_button_size := Vector2(420, 130):
	set(value):
		choice_button_size = value.max(Vector2.ONE)
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
@onready var _player_background_texture: TextureRect = $DialogueStage/PlayerDialogueBubble/PlayerBubble/BackgroundTexture
@onready var _player_label: Label = $DialogueStage/PlayerDialogueBubble/PlayerBubble/PlayerText
@onready var _player_tail: ColorRect = $DialogueStage/PlayerDialogueBubble/PlayerTail
@onready var _npc_group: Control = $DialogueStage/NpcDialogueBubble
@onready var _npc_panel: Panel = $DialogueStage/NpcDialogueBubble/NpcBubble
@onready var _npc_background_texture: TextureRect = $DialogueStage/NpcDialogueBubble/NpcBubble/BackgroundTexture
@onready var _npc_name_label: Label = $DialogueStage/NpcDialogueBubble/NpcBubble/NpcName
@onready var _npc_text_label: Label = $DialogueStage/NpcDialogueBubble/NpcBubble/NpcText
@onready var _npc_tail: ColorRect = $DialogueStage/NpcDialogueBubble/NpcTail
@onready var _narration_panel: Control = $DialogueStage/NarrationBanner
@onready var _narration_background_color: ColorRect = $DialogueStage/NarrationBanner/BackgroundColor
@onready var _narration_background_texture: TextureRect = $DialogueStage/NarrationBanner/BackgroundTexture
@onready var _narration_serial_label: Label = $DialogueStage/NarrationBanner/SerialLabel
@onready var _narration_title_label: Label = $DialogueStage/NarrationBanner/TitleLabel
@onready var _narration_bottom_code_label: Label = $DialogueStage/NarrationBanner/BottomCodeLabel
@onready var _narration_qr_texture: TextureRect = $DialogueStage/NarrationBanner/QrTexture
@onready var _narration_margin: MarginContainer = $DialogueStage/NarrationBanner/Margin
@onready var _narration_label: Label = $DialogueStage/NarrationBanner/Margin/NarrationText
@onready var _choice_layer: Control = $DialogueStage/ChoiceLayer

var _speaker_positions: Dictionary = {}
var _speaker_sides: Dictionary = {}
var _default_npc_position := DEFAULT_NPC_BUBBLE_POSITION
var _last_player_bubble_rect := Rect2()
var _last_npc_bubble_rect := Rect2()
var _last_narration_rect := Rect2()
var _active := false

func _ready() -> void:
	_default_npc_position = npc_bubble_position
	_apply_fixed_theme()
	_apply_scene_style()
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

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not _uses_scene_node_layout() or not _node_refs_ready():
		return
	if not _scene_node_layout_changed():
		return
	_fit_player_bubble()
	_fit_npc_bubble()
	_default_npc_position = _npc_panel.position
	_apply_narration_design_layout()

func _apply_fixed_theme() -> void:
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_background_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_npc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_npc_background_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_narration_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_narration_background_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_narration_background_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_narration_serial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_narration_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_narration_bottom_code_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_narration_qr_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_narration_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prepare_label(_player_label)
	_prepare_label(_npc_name_label)
	_prepare_label(_npc_text_label)
	_prepare_label(_narration_label)
	_player_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_npc_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _prepare_label(label: Label) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

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
	_begin_dialogue()
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_clear_choices()

	var speaker := String(payload.get("speakerId", "")).strip_edges()
	var text := String(payload.get("textKey", "")).strip_edges()
	if text.is_empty():
		text = String(payload.get("text", "")).strip_edges()

	if _is_player_speaker(speaker):
		_show_player_line(text)
	elif _is_narration_speaker(speaker):
		_update_narration_line(text)
	else:
		_show_npc_line(speaker, text)

func _on_dialogue_choices_requested(choices: Array) -> void:
	_begin_dialogue()
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

func _update_narration_line(text: String) -> void:
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
	if npc_background_texture != null:
		if not _uses_scene_node_layout() or _speaker_positions.has(speaker):
			_npc_panel.position = position
		return
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
	if player_background_texture != null:
		var bubble_size := player_bubble_size
		if _uses_scene_node_layout():
			bubble_size = _player_panel.size
		else:
			_player_panel.position = Vector2(player_tail_center.x - player_bubble_size.x * 0.72, player_bubble_top)
			_player_panel.size = player_bubble_size
		_player_label.position = Vector2(player_text_margin_left, player_text_margin_top)
		_player_label.size = Vector2(
			maxf(1.0, bubble_size.x - player_text_margin_left - player_text_margin_right),
			maxf(1.0, bubble_size.y - player_text_margin_top - player_text_margin_bottom)
		)
		return
	var width: float = _bubble_width_for_text(_player_label, _player_label.text, PLAYER_BUBBLE_MIN_WIDTH, PLAYER_TEXT_INSET.x * 2.0)
	_player_panel.position = Vector2(player_tail_center.x - width * 0.5, player_bubble_top)
	_player_panel.size.x = width
	_player_label.size.x = maxf(1.0, width - PLAYER_TEXT_INSET.x * 2.0)

func _fit_npc_bubble() -> void:
	if npc_background_texture != null:
		var bubble_size := npc_bubble_size
		if _uses_scene_node_layout():
			bubble_size = _npc_panel.size
		else:
			_npc_panel.size = npc_bubble_size
		_npc_name_label.visible = false
		_npc_text_label.position = Vector2(npc_text_margin_left, npc_text_margin_top)
		_npc_text_label.size = Vector2(
			maxf(1.0, bubble_size.x - npc_text_margin_left - npc_text_margin_right),
			maxf(1.0, bubble_size.y - npc_text_margin_top - npc_text_margin_bottom)
		)
		return
	_npc_name_label.visible = true
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
	var horizontal_gap := 40.0
	var vertical_gap := 18.0
	var columns := 2
	var total_width := choice_button_size.x * columns + horizontal_gap
	var start_x := (_stage.size.x - total_width) * 0.5
	if _stage.size.x <= 0:
		start_x = 500.0
	var start_y := 720.0
	var slots := [
		Vector2(start_x, start_y),
		Vector2(start_x + choice_button_size.x + horizontal_gap, start_y),
		Vector2(start_x, start_y + choice_button_size.y + vertical_gap),
		Vector2(start_x + choice_button_size.x + horizontal_gap, start_y + choice_button_size.y + vertical_gap)
	]
	var button := Button.new()
	button.name = "ChoiceBubble%d" % index
	button.text = text
	button.position = slots[index % slots.size()] + Vector2(0, (choice_button_size.y + vertical_gap) * int(index / slots.size()))
	button.size = choice_button_size
	button.custom_minimum_size = choice_button_size
	button.clip_text = true
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_on_choice_pressed.bind(index))

	var normal: StyleBox
	var hover: StyleBox
	var pressed: StyleBox
	if choice_background_texture != null:
		normal = _choice_texture_style(choice_background_texture, Color.WHITE)
		hover = _choice_texture_style(choice_background_texture, Color(1.08, 1.08, 1.08, 1.0))
		pressed = _choice_texture_style(choice_background_texture, Color(0.92, 0.92, 0.92, 1.0))
	else:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(0.82, 0.04, 0.07, 0.96)
		flat.border_color = Color(0.82, 0.04, 0.07, 1.0)
		flat.set_border_width_all(2)
		flat.corner_radius_top_left = 3
		flat.corner_radius_top_right = 3
		flat.corner_radius_bottom_left = 3
		flat.corner_radius_bottom_right = 3
		normal = flat
		hover = flat.duplicate()
		(hover as StyleBoxFlat).bg_color = flat.bg_color.lightened(0.08)
		pressed = flat.duplicate()
		(pressed as StyleBoxFlat).bg_color = flat.bg_color.darkened(0.12)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", choice_text_color)
	button.add_theme_color_override("font_hover_color", choice_text_color)
	button.add_theme_color_override("font_pressed_color", choice_text_color.darkened(0.12))
	button.add_theme_font_size_override("font_size", choice_font_size)
	if choice_text_font != null:
		button.add_theme_font_override("font", choice_text_font)
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
	_hide_speech_bubbles()
	_narration_panel.visible = false

func _hide_speech_bubbles() -> void:
	_player_group.visible = false
	_npc_group.visible = false

func _clear_choices() -> void:
	for child in _choice_layer.get_children():
		child.queue_free()

func _begin_dialogue() -> void:
	if not _active:
		_narration_label.text = ""
	_active = true

func _apply_scene_layout() -> void:
	if _uses_scene_node_layout():
		_default_npc_position = _npc_panel.position
		_apply_narration_design_layout()
		return
	_player_tail.position = player_tail_center - _player_tail.pivot_offset
	_narration_panel.position = narration_position
	_narration_panel.size = narration_size
	_apply_narration_design_layout()
	_default_npc_position = npc_bubble_position
	_position_npc_bubble("")

func _apply_scene_style() -> void:
	_player_background_texture.texture = player_background_texture
	_player_background_texture.visible = player_background_texture != null
	_npc_background_texture.texture = npc_background_texture
	_npc_background_texture.visible = npc_background_texture != null
	if player_background_texture != null:
		_player_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		_apply_panel_style(_player_panel, player_bubble_fill, player_bubble_border)
	if npc_background_texture != null:
		_npc_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		_apply_panel_style(_npc_panel, npc_bubble_fill, npc_bubble_border)
	_player_label.add_theme_color_override("font_color", player_text_color)
	_player_label.add_theme_font_size_override("font_size", player_font_size)
	if player_text_font != null:
		_player_label.add_theme_font_override("font", player_text_font)
	_npc_name_label.add_theme_color_override("font_color", npc_name_color)
	_npc_name_label.add_theme_font_size_override("font_size", npc_name_font_size)
	if npc_text_font != null:
		_npc_name_label.add_theme_font_override("font", npc_text_font)
	_npc_text_label.add_theme_color_override("font_color", npc_text_color)
	_npc_text_label.add_theme_font_size_override("font_size", npc_text_font_size)
	if npc_text_font != null:
		_npc_text_label.add_theme_font_override("font", npc_text_font)
	_player_tail.color = player_tail_color
	_player_tail.visible = player_background_texture == null
	_npc_tail.color = npc_tail_color
	_npc_tail.visible = npc_background_texture == null
	_narration_background_color.color = narration_background_color
	_narration_background_texture.texture = narration_background_texture
	_narration_background_texture.modulate = narration_texture_modulate
	_narration_background_texture.visible = narration_background_texture != null
	_narration_serial_label.add_theme_color_override("font_color", Color(0.71, 0.52, 0.47, 1.0))
	_narration_title_label.add_theme_color_override("font_color", Color.BLACK)
	_narration_bottom_code_label.add_theme_color_override("font_color", Color.BLACK)
	if narration_code_font != null:
		_narration_serial_label.add_theme_font_override("font", narration_code_font)
		_narration_bottom_code_label.add_theme_font_override("font", narration_code_font)
	if narration_title_font != null:
		_narration_title_label.add_theme_font_override("font", narration_title_font)
	_narration_label.add_theme_color_override("font_color", narration_text_color)
	_narration_label.add_theme_font_size_override("font_size", narration_font_size)
	if narration_text_font != null:
		_narration_label.add_theme_font_override("font", narration_text_font)
	_apply_narration_design_layout()

func _apply_narration_design_layout() -> void:
	var scale := _narration_design_scale()
	_apply_scaled_control_rect(_narration_serial_label, NARRATION_SERIAL_RECT, scale)
	_apply_scaled_control_rect(_narration_title_label, NARRATION_TITLE_RECT, scale)
	_apply_scaled_control_rect(_narration_bottom_code_label, NARRATION_BOTTOM_CODE_RECT, scale)
	_apply_scaled_control_rect(_narration_qr_texture, NARRATION_QR_RECT, scale)
	_narration_serial_label.add_theme_font_size_override("font_size", maxi(1, roundi(NARRATION_SERIAL_FONT_SIZE * scale.y)))
	_narration_title_label.add_theme_font_size_override("font_size", maxi(1, roundi(NARRATION_TITLE_FONT_SIZE * scale.y)))
	_narration_bottom_code_label.add_theme_font_size_override("font_size", maxi(1, roundi(NARRATION_BOTTOM_CODE_FONT_SIZE * scale.y)))
	_narration_label.add_theme_font_size_override("font_size", maxi(1, roundi(NARRATION_TEXT_FONT_SIZE * scale.y)))
	_narration_margin.add_theme_constant_override("margin_left", roundi(NARRATION_TEXT_RECT.position.x * scale.x))
	_narration_margin.add_theme_constant_override("margin_top", roundi(NARRATION_TEXT_RECT.position.y * scale.y))
	_narration_margin.add_theme_constant_override("margin_right", roundi((NARRATION_DESIGN_SIZE.x - NARRATION_TEXT_RECT.end.x) * scale.x))
	_narration_margin.add_theme_constant_override("margin_bottom", roundi((NARRATION_DESIGN_SIZE.y - NARRATION_TEXT_RECT.end.y) * scale.y))

func _narration_design_scale() -> Vector2:
	var size := _narration_panel.size
	if size.x <= 0.0 or size.y <= 0.0:
		size = narration_size
	return Vector2(size.x / NARRATION_DESIGN_SIZE.x, size.y / NARRATION_DESIGN_SIZE.y)

func _apply_scaled_control_rect(control: Control, rect: Rect2, scale: Vector2) -> void:
	control.position = Vector2(rect.position.x * scale.x, rect.position.y * scale.y)
	control.size = Vector2(rect.size.x * scale.x, rect.size.y * scale.y)

func _apply_panel_style(panel: Panel, fill: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)

func _choice_texture_style(texture: Texture2D, modulate: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	var scale := Vector2(choice_button_size.x / CHOICE_DESIGN_SIZE.x, choice_button_size.y / CHOICE_DESIGN_SIZE.y)
	style.texture = texture
	style.modulate_color = modulate
	style.draw_center = true
	style.content_margin_left = roundi(CHOICE_TEXT_RECT.position.x * scale.x)
	style.content_margin_top = roundi(CHOICE_TEXT_RECT.position.y * scale.y)
	style.content_margin_right = roundi((CHOICE_DESIGN_SIZE.x - CHOICE_TEXT_RECT.end.x) * scale.x)
	style.content_margin_bottom = roundi((CHOICE_DESIGN_SIZE.y - CHOICE_TEXT_RECT.end.y) * scale.y)
	return style

func _apply_editor_preview() -> void:
	if not _node_refs_ready():
		return
	_apply_scene_style()
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
	if _uses_scene_node_layout():
		_default_npc_position = _npc_panel.position
		_apply_narration_design_layout()
	else:
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
		and _player_background_texture != null \
		and _player_label != null \
		and _player_tail != null \
		and _npc_group != null \
		and _npc_panel != null \
		and _npc_background_texture != null \
		and _npc_name_label != null \
		and _npc_text_label != null \
		and _npc_tail != null \
		and _narration_panel != null \
		and _narration_background_color != null \
		and _narration_background_texture != null \
		and _narration_serial_label != null \
		and _narration_title_label != null \
		and _narration_bottom_code_label != null \
		and _narration_qr_texture != null \
		and _narration_margin != null \
		and _narration_label != null \
		and _choice_layer != null


func _uses_scene_node_layout() -> bool:
	return layout_source == "scene_nodes"

func _scene_node_layout_changed() -> bool:
	var player_rect := Rect2(_player_panel.position, _player_panel.size)
	var npc_rect := Rect2(_npc_panel.position, _npc_panel.size)
	var narration_rect := Rect2(_narration_panel.position, _narration_panel.size)
	var changed := player_rect != _last_player_bubble_rect \
		or npc_rect != _last_npc_bubble_rect \
		or narration_rect != _last_narration_rect
	_last_player_bubble_rect = player_rect
	_last_npc_bubble_rect = npc_rect
	_last_narration_rect = narration_rect
	return changed

func _is_player_speaker(speaker: String) -> bool:
	return PLAYER_SPEAKERS.has(speaker.strip_edges().to_lower())

func _is_narration_speaker(speaker: String) -> bool:
	return NARRATION_SPEAKERS.has(speaker.strip_edges().to_lower())

func _normalized_side(side: String) -> String:
	var normalized := side.strip_edges().to_lower()
	if ["left", "right", "up", "down"].has(normalized):
		return normalized
	return "right"
