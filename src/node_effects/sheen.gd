class_name Sheen
extends Node2D

@onready var parent: Control = get_parent()
@onready var zone: ColorRect = %Zone
@onready var light: ColorRect = %Light

func _ready() -> void:
	assert(parent != null and parent is Control)
	
	parent.resized.connect(_resize)
	_resize()
	_reset_light()

func _resize():
	zone.size = parent.get_rect().size
	zone.global_position = parent.global_position
	light.size.y = zone.size.y * 3

	# Put the light offscreen safely to the left


func play(duration: float = 0.5) -> Tween:
	# Move the light across the zone
	var tween = light.create_tween()

	var target_x = zone.global_position.x + zone.size.x * 2

	tween.tween_property(light, "global_position:x", target_x, duration)
	tween.finished.connect(queue_free, ConnectFlags.CONNECT_ONE_SHOT)
	
	return tween

func _reset_light():
	# Put the light offscreen safely to the left
	light.global_position.x = zone.global_position.x - zone.size.x
