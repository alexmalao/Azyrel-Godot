extends Node

## Data class for storing active movement data.
class_name PlayerMoveData


# movement attributes
@export var cur_jumps: int = 1
@export var has_wall_run: bool = true
@export var facing_right: bool = false
@export var on_right_wall: bool = false
@export var on_left_wall: bool = false
@export var on_ceiling: bool = false

# duration based values
@export var suspend_gravity: bool = false
@export var wall_running: bool = false
@export var wall_vaulted: bool = false

# logic values
@export var edge_jump: bool = false
@export var last_frame_airborne: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


## Reset wall run. Call upon performing any jump or landing.
func reset_wall_run():
	self.has_wall_run = true
	self.wall_running = false


## Determine whether a wall run is possible, then disable the wall run.
func attempt_wall_run():
	if self.has_wall_run:
		self.has_wall_run = false
		return true
	return false


## Reset the total amount of jumps. Call this upon landing.
func reset_jumps(total_jumps: int):
	self.cur_jumps = total_jumps


## Determine whether a jump is possible, then decrement the available jumps.
func attempt_jump():
	if self.cur_jumps > 0:
		self.cur_jumps -= 1
		return true
	return false


## Update the character's facing direction.
func update_direction(x_vel: float):
	if x_vel > 0.001:
		self.facing_right = true
	if x_vel < -0.001:
		self.facing_right = false
