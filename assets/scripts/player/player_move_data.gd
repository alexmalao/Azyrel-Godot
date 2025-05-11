extends Node

class_name PlayerMoveData


const JUMPS: int = 1

@export var facing_right: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


## Update the character's facing direction.
func update_direction(x_vel: float):
	if x_vel > 0.001:
		self.facing_right = true
	if x_vel < -0.001:
		self.facing_right = false
