@tool
extends "res://modules/interaction/interactive_object.gd"
class_name LockedObject

func _init() -> void:
	object_kind = ObjectKind.LOCKED
