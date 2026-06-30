extends Node

const WAIT_STORY_PATH := "user://story_wait_runner.nrstory"

var _line_times: Array[float] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_write_wait_story()

	var story_bridge: Node = get_tree().root.get_node("StoryBridge")
	story_bridge.dialogue_line_requested.connect(func(_payload: Dictionary):
		_line_times.append(Time.get_ticks_msec() / 1000.0)
	)

	if not story_bridge.start_story(WAIT_STORY_PATH):
		push_error("Expected StoryBridge to start wait test story.")
		get_tree().quit(1)
		return

	await get_tree().process_frame
	if _line_times.size() != 1:
		push_error("Expected first dialogue line before wait. Got: %s" % _line_times.size())
		get_tree().quit(1)
		return

	var wait_started_at := Time.get_ticks_msec() / 1000.0
	story_bridge.next()
	await get_tree().create_timer(0.1).timeout
	story_bridge.next()
	await get_tree().process_frame
	if _line_times.size() != 1:
		push_error("Expected timeline.wait to ignore advance input before timer completes.")
		get_tree().quit(1)
		return

	await get_tree().create_timer(1.05).timeout
	if _line_times.size() != 2:
		push_error("Expected second dialogue line after timeline.wait completes. Got: %s" % _line_times.size())
		get_tree().quit(1)
		return

	var elapsed := _line_times[1] - wait_started_at
	if elapsed < 0.8:
		push_error("Expected timeline.wait to delay at least 0.8 seconds. Got: %.3f" % elapsed)
		get_tree().quit(1)
		return

	print("story_wait_runner passed")
	get_tree().quit(0)

func _write_wait_story() -> void:
	var file := FileAccess.open(WAIT_STORY_PATH, FileAccess.WRITE)
	file.store_string("""meta:
  schemaVersion: 1
  storyId: story_wait_runner
  entryNodeId: N_First

variables: []

nodes:
  - nodeId: N_First
    nodeType: Dialogue
    dialogue:
      speakerId: Test
      textKey: before wait
    enterActions: []
    exitActions: []

  - nodeId: N_Wait
    nodeType: EmitEvent
    eventType: timeline.wait
    params:
      seconds: 1.0

  - nodeId: N_Second
    nodeType: Dialogue
    dialogue:
      speakerId: Test
      textKey: after wait
    enterActions: []
    exitActions: []

  - nodeId: N_End
    nodeType: End

edges:
  - sourceNodeId: N_First
    targetNodeId: N_Wait
    priority: 0
    condition:
      logic: All
      terms: []

  - sourceNodeId: N_Wait
    targetNodeId: N_Second
    priority: 0
    condition:
      logic: All
      terms: []

  - sourceNodeId: N_Second
    targetNodeId: N_End
    priority: 0
    condition:
      logic: All
      terms: []
""")
