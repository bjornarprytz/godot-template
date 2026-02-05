class_name MoveNode
extends Node

signal target_changed(new_target: Vector2)

@export var max_speed: float = 200.0
@export var acceleration: float = 10.0

@export var rotation_speed: float = 5.0 # Radians per second

@export var body: Node2D
	
var current_speed: float = 0.0:
	get:
		return current_speed

var _target: Vector2
var _direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	assert(body != null)
	_target = body.global_position

func move_to(global_target: Vector2):
	_target = global_target
	target_changed.emit(_target)

func _process(delta: float) -> void:
	var to_target: Vector2 = _target - body.global_position
	var distance_to_target: float = to_target.length()
	
	if distance_to_target < 1.0:
		current_speed = 0.0
		return
	
	_direction = to_target.normalized()
	
	# Accelerate
	current_speed = min(current_speed + acceleration * delta, max_speed)
	
	# Move the body
	var movement: Vector2 = _direction * current_speed * delta
	body.global_position += movement
	
	# Rotate towards movement direction
	if movement.length() > 0.0:
		var target_angle: float = movement.angle()
		var current_angle: float = body.rotation
		var angle_diff: float = wrapf(target_angle - current_angle, -PI, PI)
		
		var max_rotation: float = rotation_speed * delta
		angle_diff = clamp(angle_diff, -max_rotation, max_rotation)
		
		body.rotation += angle_diff
