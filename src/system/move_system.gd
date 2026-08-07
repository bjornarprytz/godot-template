class_name MoveSystem
extends Node

## Facade: owns a MoveState and exposes it as signals/methods.
## Holds no reference to any rendering node - callers react to `moved`.

signal moved(position: Vector2, rotation: float)
signal target_changed(new_target: Vector2)

@export var stats: MoveStats

var current_speed: float:
	get:
		return _state.current_speed if _state else 0.0

var _state: MoveState


func warp_to(start_position: Vector2) -> void:
	_state = MoveState.new(stats, start_position)


func move_to(target: Vector2) -> void:
	_state.target = target
	target_changed.emit(target)


func _process(delta: float) -> void:
	if _state == null:
		return

	_state.advance(delta)
	moved.emit(_state.position, _state.rotation)
