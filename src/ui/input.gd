class_name InputNode
extends Node

@export var move_node: MoveNode

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var global_position: Vector2 = move_node.body.get_global_mouse_position() # bit of a hack
		move_node.move_to(global_position)
