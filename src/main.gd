extends Node2D


func _on_left_button_pressed() -> void:
	Audio.play(preload("res://assets/audio/message.wav"), $CanvasLayer/Button.global_position)

func _on_right_button_pressed() -> void:
	Audio.play(preload("res://assets/audio/message.wav"), $CanvasLayer/Button2.global_position)


func _on_button_mouse_entered(source: Control) -> void:
	NodeEffects.sheen(source)
