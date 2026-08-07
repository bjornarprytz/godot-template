extends Control

@onready var _0: ColorRect = %"0"
@onready var _1: ColorRect = %"1"
@onready var _2: ColorRect = %"2"

var tween_0 : Tween
var tween_1 : Tween
var tween_2 : Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tween_0 = create_tween().set_loops()
	tween_1 = create_tween().set_loops()
	tween_2 = create_tween().set_loops()
	
	tween_0.tween_property(_0, "scale", Vector2(.1, .1), 3)
	tween_0.tween_property(_0, "scale", Vector2(1, 1), 3)
	tween_1.tween_property(_1, "rotation_degrees", 360, 3.0).as_relative()
	tween_2.tween_property(_2, "rotation_degrees", -360, 4.0).as_relative()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
