class_name MoveState
extends RefCounted

var stats: MoveStats
var position: Vector2
var rotation: float = 0.0
var current_speed: float = 0.0

var target: Vector2
var _direction: Vector2 = Vector2.ZERO


func _init(p_stats: MoveStats, start_position: Vector2) -> void:
	stats = p_stats
	position = start_position
	target = start_position


func advance(delta: float) -> void:
	var to_target: Vector2 = target - position
	var distance_to_target: float = to_target.length()

	if distance_to_target < 1.0:
		current_speed = 0.0
		return

	_direction = to_target.normalized()

	# Accelerate
	current_speed = min(current_speed + stats.acceleration * delta, stats.max_speed)

	# Move
	var movement: Vector2 = _direction * current_speed * delta
	position += movement

	# Rotate towards movement direction
	if movement.length() > 0.0:
		var target_angle: float = movement.angle()
		var angle_diff: float = wrapf(target_angle - rotation, -PI, PI)

		var max_rotation: float = stats.rotation_speed * delta
		angle_diff = clamp(angle_diff, -max_rotation, max_rotation)

		rotation += angle_diff
