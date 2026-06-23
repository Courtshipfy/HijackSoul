@tool
extends "res://modules/interaction/interactive_object.gd"
class_name PuzzleEntryObject

func _init() -> void:
	object_kind = ObjectKind.PUZZLE_ENTRY
