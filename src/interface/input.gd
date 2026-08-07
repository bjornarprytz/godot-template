class_name InputNode
extends Node2D

@export var move_system: MoveSystem

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		move_system.move_to(get_global_mouse_position())
