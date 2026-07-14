extends Node2D


func _on_left_button_pressed() -> void:
	print("Pressed left button")

func _on_right_button_pressed() -> void:
	print("Pressed right button")

func _on_button_mouse_entered(source: Control) -> void:
	print("Hovering button %s" % [source])
