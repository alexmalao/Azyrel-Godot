extends CharacterBody2D

class_name PlayerController


var props = PlayerProps
var move_data: PlayerMoveData
var player_input: PlayerInput
@onready var _sprite = $AnimatedSprite2D


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	self.props = PlayerProps.new()
	self.move_data = PlayerMoveData.new()
	self.player_input = get_node("PlayerInput")

	self.player_input.instant_jump_requested.connect(self.instant_jump)
	self.player_input.jump_requested.connect(self.jump)
	self.player_input.short_jump_requested.connect(self.short_jump)


func _physics_process(delta):
	self.update_move(delta)
	self.update_move_data(delta)


## Perform an aerial or wall jump if possible.
func instant_jump():
	if self._is_airborne() and self.move_data.attempt_jump():
		var horizontal = self.player_input.get_directional_input().x
		
		# perform jump, apply the maximum jump x speed
		var x_vel = self.velocity.x
		if horizontal == 1:
			x_vel = max(x_vel, props.AIR_MAX_X_SPEED)
		elif horizontal == -1:
			x_vel = min(x_vel, -props.AIR_MAX_X_SPEED)
		var jump_vel = min(-props.AIR_JUMP_VEL, self.velocity.y)
		self.velocity = Vector2(x_vel, jump_vel)
		self.move_data.update_direction(x_vel)
	elif self.is_on_floor():
		# record user input for attempting a jump in case near edge
		self.move_data.edge_jump = true


## Perform a grounded full jump.
func jump():
	self._ground_jump(-props.JUMP_VEL)


## Perform a grounded full jump.
func short_jump():
	self._ground_jump(-props.SHORT_JUMP_VEL)


## Perform any grounded jump.
func _ground_jump(jump_vel: float):
	if self.is_on_floor() or self.move_data.edge_jump:
		jump_vel = min(jump_vel, self.velocity.y)
		self.velocity = Vector2(self.velocity.x, jump_vel)
	self.move_data.edge_jump = false


## Move the player horizontally.
func update_move(delta: float):
	# Add the gravity.
	if not self.is_on_floor():
		self.velocity.y += gravity * delta
	
	var move_input = self.player_input.get_directional_input()
	
	if self.move_data.on_left_wall:
		pass
	elif self.move_data.on_right_wall:
		pass
	elif self.is_on_floor():
		self.velocity = self._get_ground_move(delta, move_input)
	else:
		self.velocity = self._get_airborne_move(delta, move_input)

	self.move_and_slide()


## Update the movement data for the player
func update_move_data(delta: float):
	if self.is_on_floor():
		self.move_data.update_direction(self.velocity.x)
		self.move_data.reset_jumps(props.JUMPS)
		self.move_data.on_left_wall = false
		self.move_data.on_right_wall = false
	self._update_state()


## Update the character sprite
func _update_state():
	_sprite.flip_h = self.move_data.facing_right


## Get the velocity vector for grounded movement
func _get_ground_move(delta: float, move_input: Vector2) -> Vector2:
	
	## executing jump or land, steepest grounded state is 45 degrees
	if abs(self.velocity.y) > abs(self.velocity.x) + 1.0:
		return self.velocity
	
	# note that magnitudes here have a horizontal value based on whether it is
	# positive or negative, contrary to the naming
	var rel_magnitude = self.velocity.length() if self.velocity.x > 0 else -self.velocity.length()
	var mod_magnitude = rel_magnitude + move_input.x * props.GROUND_ACCEL * delta
	var speed_penalty = props.GROUND_SPEED_PENALTY * delta
	# grounded horizontal movement only triggers when in same direction
	# of current velocity
	if move_input.x == 1 and self.velocity.x > -0.01:
		mod_magnitude = max(mod_magnitude, props.MIN_GROUND_SPEED)
		if mod_magnitude > props.MAX_GROUND_SPEED:
			mod_magnitude = max(rel_magnitude - speed_penalty, props.MAX_GROUND_SPEED)
		return Vector2(mod_magnitude, 0)
	elif move_input.x == -1 and self.velocity.x < 0.01:
		mod_magnitude = min(mod_magnitude, -props.MIN_GROUND_SPEED)
		if mod_magnitude < -props.MAX_GROUND_SPEED:
			mod_magnitude = min(rel_magnitude + speed_penalty, -props.MAX_GROUND_SPEED)
		return Vector2(mod_magnitude, 0)
	else:
		# stop the character
		if absf(rel_magnitude) < props.STOP_SPEED:
			return Vector2(0.0, 0.0)
		else:
			rel_magnitude -= rel_magnitude * props.TRACTION * delta
			return Vector2(rel_magnitude * 1, 0)


## Get the velocity vector for airborne movement.
func _get_airborne_move(delta: float, move_input: Vector2) -> Vector2:
	var new_x_vel
	
	# airborne movement does not apply traction or slowdown
	var mod_speed = self.velocity.x + move_input.x * props.AIR_X_ACCEL * delta
	if mod_speed > props.AIR_MAX_X_SPEED:
		new_x_vel = min(mod_speed, self.velocity.x)  # only allow slowing down
		new_x_vel = max(new_x_vel, props.AIR_MAX_X_SPEED)  # can't accelerate past max air speed
	elif mod_speed < -props.AIR_MAX_X_SPEED:
		new_x_vel = max(mod_speed, self.velocity.x)
		new_x_vel = min(new_x_vel, props.AIR_MAX_X_SPEED)
	else:
		new_x_vel = mod_speed
	
	return Vector2(new_x_vel, self.velocity.y)


## Determine if the player is airborne
func _is_airborne() -> bool:
	return (not self.is_on_floor()
		and not self.move_data.on_left_wall
		and not self.move_data.on_right_wall)
	





