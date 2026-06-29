extends Node

signal interaction_requested(payload: Dictionary)
signal interaction_hover_started(payload: Dictionary)
signal interaction_hover_ended(payload: Dictionary)
signal actions_requested(actions: Array, context: Dictionary)
signal action_failed(action: Dictionary, context: Dictionary, message: String)
signal action_completed(action: Dictionary, context: Dictionary)
signal action_chain_completed(context: Dictionary)

signal current_view_changed(view_id: String)
signal item_pickup_requested(item_id: String, context: Dictionary)
signal item_remove_requested(item_id: String, context: Dictionary)
signal inventory_selection_requested(item_id: String)

signal dialogue_requested(payload: Dictionary)
signal dialogue_face_change_requested(role_id: String, face_id: String, payload: Dictionary)
signal dialogue_posture_change_requested(role_id: String, posture_id: String, payload: Dictionary)
signal dialogue_npc_bubble_position_requested(payload: Dictionary)
signal object_animation_requested(object_id: String, animation_id: String, payload: Dictionary)
signal object_material_switch_requested(resource_id: String, material_id: String, payload: Dictionary)
signal matter_inspect_requested(object_id: String, matter_id: String, payload: Dictionary)
signal sound_play_requested(object_id: String, sound_id: String, payload: Dictionary)
signal environment_state_change_requested(environment_id: String, state_id: String, payload: Dictionary)
signal journal_entry_unlocked_requested(entry_id: String, text: String, payload: Dictionary)
signal replay_line_registered(line_id: String, speaker_id: String, text: String, payload: Dictionary)
signal toast_requested(message: String, payload: Dictionary)
signal puzzle_open_requested(puzzle_id: String, context: Dictionary)
signal story_event_requested(event_id: String, payload: Dictionary)
signal story_event_failed(event_type: String, payload: Dictionary, message: String)
signal autosave_requested(reason: String)

func request_interaction(payload: Dictionary) -> void:
	interaction_requested.emit(payload)

func request_interaction_hover_started(payload: Dictionary) -> void:
	interaction_hover_started.emit(payload)

func request_interaction_hover_ended(payload: Dictionary) -> void:
	interaction_hover_ended.emit(payload)

func request_actions(actions: Array, context: Dictionary = {}) -> void:
	actions_requested.emit(actions, context)

func request_autosave(reason: String = "interaction") -> void:
	autosave_requested.emit(reason)
