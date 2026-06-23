@tool
extends "res://modules/interaction/interactive_object.gd"
class_name PickupObject

func _init() -> void:
	object_kind = ObjectKind.PICKUP
