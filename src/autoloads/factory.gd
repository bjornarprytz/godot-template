class_name Factory
extends Node2D

# Add factory methods for common scenes here. Access through the Create singleton


func sheen() -> Sheen:
	return preload("res://node_effects/sheen.tscn").instantiate() as Sheen
