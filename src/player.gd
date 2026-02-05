class_name Player
extends Sprite2D


@onready var move: MoveNode = %Move
@onready var speed: RichTextLabel = %Speed


func _process(delta: float) -> void:
	speed.text = "%d / %d" % [move.current_speed, move.max_speed]
