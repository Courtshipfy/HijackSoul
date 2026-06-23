@tool
extends "res://modules/interaction/interactive_object.gd"
class_name InspectObject

func _init() -> void:
	object_kind = ObjectKind.INSPECT
