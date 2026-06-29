extends Node

signal story_event_unhandled(event_type: String, payload: Dictionary)
signal story_event_failed(event_type: String, payload: Dictionary, message: String)

const EVENT_DIALOGUE_CHANGE_FACE := "dialogue.change_face"
const EVENT_DIALOGUE_CHANGE_POSTURE := "dialogue.change_posture"
const EVENT_DIALOGUE_SET_NPC_BUBBLE_POSITION := "dialogue.set_npc_bubble_position"
const EVENT_OBJECT_PLAY_ANIMATION := "object.play_animation"
const EVENT_OBJECT_SET_STATE := "object.set_state"
const EVENT_OBJECT_SET_VISIBLE := "object.set_visible"
const EVENT_OBJECT_SWITCH_MATERIAL := "object.switch_material"
const EVENT_MATTER_INSPECT := "matter.inspect"
const EVENT_AUDIO_PLAY_SOUND := "audio.play_sound"
const EVENT_SCENE_JUMP := "scene.jump"
const EVENT_STATE_SET_FLAG := "state.set_flag"
const EVENT_UI_SHOW_TOAST := "ui.show_toast"
const EVENT_ENVIRONMENT_SET_STATE := "environment.set_state"
const EVENT_JOURNAL_UNLOCK_ENTRY := "journal.unlock_entry"
const EVENT_DIALOGUE_SET_REPLAY_LINE := "dialogue.set_replay_line"
const EVENT_TIMELINE_WAIT := "timeline.wait"

func handle_event(payload: Dictionary) -> bool:
	var event_type := String(payload.get("eventType", payload.get("eventId", ""))).strip_edges()
	if event_type.is_empty():
		return _fail(event_type, payload, "NarrRail event missing eventType.")

	var params_value: Variant = _event_params(payload)
	if params_value == null:
		return _fail(event_type, payload, "NarrRail event '%s' params must be a Dictionary." % event_type)
	var params: Dictionary = params_value

	match event_type:
		EVENT_DIALOGUE_CHANGE_FACE, "change_face":
			return _handle_dialogue_change_face(params, payload)
		EVENT_DIALOGUE_CHANGE_POSTURE, "change_posture":
			return _handle_dialogue_change_posture(params, payload)
		EVENT_DIALOGUE_SET_NPC_BUBBLE_POSITION, "set_npc_bubble_position":
			return _handle_dialogue_set_npc_bubble_position(params, payload)
		EVENT_OBJECT_PLAY_ANIMATION, "play_animation":
			return _handle_object_play_animation(params, payload)
		EVENT_OBJECT_SET_STATE, "set_object_state":
			return await _handle_object_set_state(params, payload)
		EVENT_OBJECT_SET_VISIBLE, "set_object_visible":
			return await _handle_object_set_visible(params, payload)
		EVENT_OBJECT_SWITCH_MATERIAL, "switch_material":
			return _handle_object_switch_material(params, payload)
		EVENT_MATTER_INSPECT, "inspect_matter":
			return _handle_matter_inspect(params, payload)
		EVENT_AUDIO_PLAY_SOUND, "play_sound":
			return _handle_audio_play_sound(params, payload)
		EVENT_SCENE_JUMP, "jump_scene":
			return await _handle_scene_jump(params, payload)
		EVENT_STATE_SET_FLAG:
			return await _handle_state_set_flag(params, payload)
		EVENT_UI_SHOW_TOAST:
			return await _handle_ui_show_toast(params, payload)
		EVENT_ENVIRONMENT_SET_STATE, "set_environment_state":
			return _handle_environment_set_state(params, payload)
		EVENT_JOURNAL_UNLOCK_ENTRY, "unlock_journal_entry":
			return await _handle_journal_unlock_entry(params, payload)
		EVENT_DIALOGUE_SET_REPLAY_LINE, "set_replay_line":
			return _handle_dialogue_set_replay_line(params, payload)
		EVENT_TIMELINE_WAIT, "wait":
			return await _handle_timeline_wait(params, payload)
		_:
			story_event_unhandled.emit(event_type, payload)
			return true

func _handle_dialogue_change_face(params: Dictionary, payload: Dictionary) -> bool:
	var role_id := String(params.get("role", params.get("role_id", ""))).strip_edges()
	var face_id := String(params.get("face", params.get("face_id", ""))).strip_edges()
	if role_id.is_empty() or face_id.is_empty():
		return _fail(EVENT_DIALOGUE_CHANGE_FACE, payload, "dialogue.change_face requires params.role and params.face.")

	var bus := _event_bus()
	if bus != null:
		bus.dialogue_face_change_requested.emit(role_id, face_id, payload.duplicate(true))
	return true

func _handle_dialogue_change_posture(params: Dictionary, payload: Dictionary) -> bool:
	var role_id := String(params.get("role", params.get("role_id", ""))).strip_edges()
	var posture_id := String(params.get("posture", params.get("posture_id", ""))).strip_edges()
	if role_id.is_empty() or posture_id.is_empty():
		return _fail(EVENT_DIALOGUE_CHANGE_POSTURE, payload, "dialogue.change_posture requires params.role and params.posture.")

	var bus := _event_bus()
	if bus != null:
		bus.dialogue_posture_change_requested.emit(role_id, posture_id, payload.duplicate(true))
	return true

func _handle_dialogue_set_npc_bubble_position(params: Dictionary, payload: Dictionary) -> bool:
	var position: Variant = _event_position_from_params(params)
	if position == null:
		return _fail(EVENT_DIALOGUE_SET_NPC_BUBBLE_POSITION, payload, "dialogue.set_npc_bubble_position requires params.x and params.y.")

	var bus := _event_bus()
	if bus != null:
		bus.dialogue_npc_bubble_position_requested.emit({
			"speakerId": String(params.get("speakerId", params.get("speaker_id", ""))).strip_edges(),
			"position": position,
			"side": String(params.get("side", "right")).strip_edges(),
			"payload": payload.duplicate(true)
		})
	return true

func _handle_object_play_animation(params: Dictionary, payload: Dictionary) -> bool:
	var object_id := String(params.get("object", params.get("object_id", ""))).strip_edges()
	var animation_id := String(params.get("animation", params.get("animation_id", ""))).strip_edges()
	if object_id.is_empty() or animation_id.is_empty():
		return _fail(EVENT_OBJECT_PLAY_ANIMATION, payload, "object.play_animation requires params.object and params.animation.")

	var bus := _event_bus()
	if bus != null:
		bus.object_animation_requested.emit(object_id, animation_id, payload.duplicate(true))
	return true

func _handle_object_set_state(params: Dictionary, payload: Dictionary) -> bool:
	var object_id := String(params.get("object", params.get("object_id", ""))).strip_edges()
	if object_id.is_empty():
		return _fail(EVENT_OBJECT_SET_STATE, payload, "object.set_state requires params.object.")

	var state: Dictionary = {}
	for key in ["visible", "enabled", "state", "picked"]:
		if params.has(key):
			state[key] = _bool_param(params[key]) if key in ["visible", "enabled", "picked"] else params[key]
	if typeof(params.get("extra", {})) == TYPE_DICTIONARY:
		var extra: Dictionary = params.get("extra", {})
		for key in extra.keys():
			state[key] = extra[key]
	if state.is_empty():
		return _fail(EVENT_OBJECT_SET_STATE, payload, "object.set_state requires at least one state field.")

	return await _run_actions([{
		"type": "set_object_state",
		"object_id": object_id,
		"state": state
	}], EVENT_OBJECT_SET_STATE, payload)

func _handle_object_set_visible(params: Dictionary, payload: Dictionary) -> bool:
	var object_id := String(params.get("object", params.get("object_id", ""))).strip_edges()
	if object_id.is_empty():
		return _fail(EVENT_OBJECT_SET_VISIBLE, payload, "object.set_visible requires params.object.")
	if not params.has("visible"):
		return _fail(EVENT_OBJECT_SET_VISIBLE, payload, "object.set_visible requires params.visible.")
	var visible: bool = _bool_param(params.get("visible"))

	return await _run_actions([{
		"type": "set_object_state",
		"object_id": object_id,
		"state": {"visible": visible}
	}], EVENT_OBJECT_SET_VISIBLE, payload)

func _handle_object_switch_material(params: Dictionary, payload: Dictionary) -> bool:
	var resource_id := String(params.get("resource", params.get("resource_id", ""))).strip_edges()
	var material_id := String(params.get("material", params.get("material_id", ""))).strip_edges()
	if resource_id.is_empty() or material_id.is_empty():
		return _fail(EVENT_OBJECT_SWITCH_MATERIAL, payload, "object.switch_material requires params.resource and params.material.")

	var bus := _event_bus()
	if bus != null:
		bus.object_material_switch_requested.emit(resource_id, material_id, payload.duplicate(true))
	return true

func _handle_matter_inspect(params: Dictionary, payload: Dictionary) -> bool:
	var object_id := String(params.get("object", params.get("object_id", ""))).strip_edges()
	var matter_id := String(params.get("matter", params.get("matter_id", ""))).strip_edges()
	if object_id.is_empty() or matter_id.is_empty():
		return _fail(EVENT_MATTER_INSPECT, payload, "matter.inspect requires params.object and params.matter.")

	var bus := _event_bus()
	if bus != null:
		bus.matter_inspect_requested.emit(object_id, matter_id, payload.duplicate(true))
	return true

func _handle_audio_play_sound(params: Dictionary, payload: Dictionary) -> bool:
	var object_id := String(params.get("object", params.get("object_id", ""))).strip_edges()
	var sound_id := String(params.get("sound", params.get("sound_id", ""))).strip_edges()
	if sound_id.is_empty():
		return _fail(EVENT_AUDIO_PLAY_SOUND, payload, "audio.play_sound requires params.sound.")

	var bus := _event_bus()
	if bus != null:
		bus.sound_play_requested.emit(object_id, sound_id, payload.duplicate(true))
	return true

func _handle_scene_jump(params: Dictionary, payload: Dictionary) -> bool:
	var scene_id := String(params.get("scene", params.get("scene_id", params.get("view_id", "")))).strip_edges()
	if scene_id.is_empty():
		return _fail(EVENT_SCENE_JUMP, payload, "scene.jump requires params.scene.")

	return await _run_actions([{
		"type": "change_view",
		"view_id": scene_id,
		"scene_path": String(params.get("scene_path", ""))
	}], EVENT_SCENE_JUMP, payload)

func _handle_state_set_flag(params: Dictionary, payload: Dictionary) -> bool:
	var flag_id := String(params.get("flag_id", params.get("flagId", params.get("flag", "")))).strip_edges()
	if flag_id.is_empty():
		return _fail(EVENT_STATE_SET_FLAG, payload, "state.set_flag requires params.flag_id.")

	return await _run_actions([{
		"type": "set_flag",
		"flag_id": flag_id,
		"value": params.get("value", true)
	}], EVENT_STATE_SET_FLAG, payload)

func _handle_ui_show_toast(params: Dictionary, payload: Dictionary) -> bool:
	var message := String(params.get("message", "")).strip_edges()
	if message.is_empty():
		return _fail(EVENT_UI_SHOW_TOAST, payload, "ui.show_toast requires params.message.")

	return await _run_actions([{
		"type": "show_toast",
		"message": message
	}], EVENT_UI_SHOW_TOAST, payload)

func _handle_environment_set_state(params: Dictionary, payload: Dictionary) -> bool:
	var environment_id := String(params.get("environment", params.get("environment_id", ""))).strip_edges()
	var state_id := String(params.get("state", params.get("state_id", ""))).strip_edges()
	if environment_id.is_empty() or state_id.is_empty():
		return _fail(EVENT_ENVIRONMENT_SET_STATE, payload, "environment.set_state requires params.environment and params.state.")

	var bus := _event_bus()
	if bus != null:
		bus.environment_state_change_requested.emit(environment_id, state_id, payload.duplicate(true))
	return true

func _handle_journal_unlock_entry(params: Dictionary, payload: Dictionary) -> bool:
	var entry_id := String(params.get("entry_id", params.get("entry", ""))).strip_edges()
	var text := String(params.get("text", "")).strip_edges()
	if entry_id.is_empty() or text.is_empty():
		return _fail(EVENT_JOURNAL_UNLOCK_ENTRY, payload, "journal.unlock_entry requires params.entry_id and params.text.")

	var source := String(params.get("source", "")).strip_edges()
	var bus := _event_bus()
	if bus != null:
		bus.journal_entry_unlocked_requested.emit(entry_id, text, payload.duplicate(true))

	return await _run_actions([{
		"type": "set_flag",
		"flag_id": "journal_entry.%s" % entry_id,
		"value": {
			"unlocked": true,
			"text": text,
			"source": source
		}
	}], EVENT_JOURNAL_UNLOCK_ENTRY, payload)

func _handle_dialogue_set_replay_line(params: Dictionary, payload: Dictionary) -> bool:
	var line_id := String(params.get("line_id", params.get("line", ""))).strip_edges()
	var speaker_id := String(params.get("speaker", params.get("speaker_id", ""))).strip_edges()
	var text := String(params.get("text", "")).strip_edges()
	if line_id.is_empty() or text.is_empty():
		return _fail(EVENT_DIALOGUE_SET_REPLAY_LINE, payload, "dialogue.set_replay_line requires params.line_id and params.text.")

	var bus := _event_bus()
	if bus != null:
		bus.replay_line_registered.emit(line_id, speaker_id, text, payload.duplicate(true))
	return true

func _handle_timeline_wait(params: Dictionary, payload: Dictionary) -> bool:
	var seconds := float(params.get("seconds", params.get("duration", 0.0)))
	if seconds <= 0.0:
		return _fail(EVENT_TIMELINE_WAIT, payload, "timeline.wait requires params.seconds greater than 0.")
	await get_tree().create_timer(seconds).timeout
	return true

func _run_actions(actions: Array, event_type: String, payload: Dictionary) -> bool:
	var runner := get_tree().root.get_node_or_null("ActionRunner")
	if runner == null:
		return _fail(event_type, payload, "ActionRunner autoload is missing.")

	return await runner.run_actions(actions, {
		"story_event_type": event_type,
		"story_event_node_id": String(payload.get("nodeId", "")),
		"story_event_phase": String(payload.get("phase", "")),
		"story_event_payload": payload.duplicate(true),
		"save_reason": "story_event"
	})

func _event_params(payload: Dictionary) -> Variant:
	var raw_params: Variant = payload.get("params", {})
	if typeof(raw_params) != TYPE_DICTIONARY:
		return null
	return (raw_params as Dictionary).duplicate(true)

func _event_position_from_params(params: Dictionary) -> Variant:
	if params.has("x") and params.has("y"):
		return Vector2(float(params.get("x")), float(params.get("y")))

	if typeof(params.get("position", {})) == TYPE_DICTIONARY:
		var position_params: Dictionary = params.get("position", {})
		if position_params.has("x") and position_params.has("y"):
			return Vector2(float(position_params.get("x")), float(position_params.get("y")))

	return null

func _bool_param(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return bool(value)
		TYPE_INT, TYPE_FLOAT:
			return float(value) != 0.0
		TYPE_STRING:
			var normalized := String(value).strip_edges().to_lower()
			return not ["", "0", "false", "no", "off", "hide", "hidden"].has(normalized)
		_:
			return bool(value)

func _fail(event_type: String, payload: Dictionary, message: String) -> bool:
	story_event_failed.emit(event_type, payload, message)
	var bus := _event_bus()
	if bus != null:
		bus.story_event_failed.emit(event_type, payload, message)
	push_error(message)
	return false

func _event_bus() -> Node:
	return get_tree().root.get_node_or_null("EventBus")
