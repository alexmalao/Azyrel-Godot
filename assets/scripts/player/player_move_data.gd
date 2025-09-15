extends Node

## Data class for storing active movement data.
class_name PlayerMoveData


# movement attributes
@export var cur_jumps: int = 1
@export var has_wall_run: bool = true
@export var has_ceiling_hang: bool = true
@export var has_ceiling_run: bool = true
@export var facing_right: bool = false
@export var on_right_wall: bool = false
@export var on_left_wall: bool = false
@export var on_ceiling: bool = false

# duration based values
@export var dashing: bool = false
@export var wall_running: bool = false
@export var wall_vaulted: bool = false
@export var ceiling_sliding: bool = false

# logic values
@export var edge_jump: bool = false
@export var _airborne: bool = false  # soley used to calculate last frame airborne
@export var last_frame_airborne: bool = false
@export var _grounded: bool = false  # soley used to calculate last frame grounded
@export var last_frame_grounded: bool = false
@export var _vel: Vector2 = Vector2(0, 0)  # soley used to calculate last frame velocity
@export var last_frame_vel: Vector2 = Vector2(0, 0)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


## Reset wall run. Call upon performing any jump or landing.
func reset_wall_run():
	self.has_wall_run = true
	self.has_ceiling_hang = true
	self.has_ceiling_run = true
	self.wall_running = false


## Determine whether a wall run is possible, then disable the wall run.
func attempt_wall_run():
	if self.has_wall_run:
		self.has_wall_run = false
		return true
	return false


## Determine whether a ceiling hang is possible, then disable the ceiling hang.
func attempt_ceiling_hang():
	if self.has_ceiling_hang:
		self.has_ceiling_hang = false
		return true
	return false


## Determine whether a ceiling run is possible, then disable the ceiling run.
func attempt_ceiling_run():
	if self.has_ceiling_run:
		self.has_ceiling_run = false
		return true
	return false


## Reset the total amount of jumps. Call this upon landing.
func reset_jumps(total_jumps: int):
	self.cur_jumps = total_jumps


## Determine whether a jump is possible, then decrement the available jumps.
func attempt_jump():
	print(self.cur_jumps)
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
