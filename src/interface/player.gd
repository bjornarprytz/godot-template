class_name Player
extends Sprite2D


@onready var move: MoveSystem = %Move
@onready var speed: RichTextLabel = %Speed


func _ready() -> void:
	move.warp_to(global_position)
	move.moved.connect(_on_move_moved)


func _process(delta: float) -> void:
	speed.text = "%d / %d" % [move.current_speed, move.stats.max_speed]


func _on_move_moved(position: Vector2, new_rotation: float) -> void:
	global_position = position
	rotation = new_rotation
