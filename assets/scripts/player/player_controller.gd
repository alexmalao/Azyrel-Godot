extends CharacterBody2D

class_name PlayerController


var props = PlayerProps
var move_data: PlayerMoveData
var player_input: PlayerInput
var interact_box: Area2D
@onready var _sprite = $AnimatedSprite2D


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	self.props = PlayerProps.new()
	self.move_data = PlayerMoveData.new()
	self.player_input = get_node("PlayerInput")
	self.interact_box = get_node("InteractBox")

	self.player_input.instant_jump_requested.connect(self.instant_jump)
	self.player_input.jump_requested.connect(self.jump)
	self.player_input.short_jump_requested.connect(self.short_jump)
	self.player_input.dash_requested.connect(self.dash)
	self.player_input.interact_requested.connect(self.interact)

func _physics_process(delta):
	self.update_move(delta)
	self.update_move_data(delta)
	self._update_state()


## Interact with area.
func interact():
	var areas = self.interact_box.get_overlapping_areas()
	if areas.size() > 0:
		areas[0].get_parent().interact()


## Perform an aerial or wall jump if possible.
func instant_jump():
	if self.move_data.on_right_wall and not self.is_on_floor():
		self.velocity = props.RIGHT_WALL_JUMP_VECTOR * props.WALL_JUMP_SPEED
		self.move_data.on_right_wall = false
		self.move_data.facing_right = false
		self.move_data.reset_wall_run()
		self._wall_vault()
	elif self.move_data.on_left_wall and not self.is_on_floor():
		self.velocity = props.LEFT_WALL_JUMP_VECTOR * props.WALL_JUMP_SPEED
		self.move_data.on_left_wall = false
		self.move_data.facing_right = true
		self.move_data.reset_wall_run()
		self._wall_vault()
	elif self._is_airborne() and self.move_data.attempt_jump():
		self.move_data.suspend_gravity = false
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
		self.move_data.reset_wall_run()
	elif self.is_on_floor():
		# record user input for attempting a jump in case near edge
		self.move_data.edge_jump = true


## Perform a grounded or aerial dash if possible.
func dash():
	var horizontal = self.player_input.get_directional_input().x
	if horizontal == 0:
		# record direction to be facing direction for no input
		horizontal = 1 if self.move_data.facing_right else -1
	
	if self.move_data.on_right_wall and not self.is_on_floor():
		# dash off right wall
		self.velocity = Vector2(-props.MAX_GROUND_SPEED, 0)
		self.move_data.on_right_wall = false
		self.move_data.facing_right = false
		self.move_data.reset_wall_run()
		self._wall_vault()
		self._suspend_dash_gravity(props.DASH_FLOAT_DUR)
	elif self.move_data.on_left_wall and not self.is_on_floor():
		# dash off left wall
		self.velocity = Vector2(props.MAX_GROUND_SPEED, 0)
		self.move_data.on_left_wall = false
		self.move_data.facing_right = true
		self.move_data.reset_wall_run()
		self._wall_vault()
		self._suspend_dash_gravity(props.DASH_FLOAT_DUR)
	elif self.is_on_floor():
		# ground dash
		var new_vel
		var rel_magnitude = self.velocity.length() if self.velocity.x > 0 else -self.velocity.length()
		## executing jump or land, revoking magnitude
		if abs(self.velocity.y) > abs(self.velocity.x) + 1.0:
			rel_magnitude = 0
		
		if horizontal > 0:
			new_vel = max(rel_magnitude, props.MAX_GROUND_SPEED)
		else:
			new_vel = min(rel_magnitude, -props.MAX_GROUND_SPEED)
		self.velocity = Vector2(new_vel * 1, 0)
		self._suspend_dash_gravity(props.DASH_FLOAT_DUR)
	elif self._is_airborne():
		# aerial dash
		var move_input = self.player_input.get_directional_input()
		if move_input.y == 1 and self.velocity.y >= 0:
			# dash downwards
			self.move_data.suspend_gravity = false
			var new_y_vel = max(self.velocity.y, props.AIR_DOWN_DASH_VEL)
			self.velocity = Vector2(self.velocity.x, new_y_vel)
			self.move_data.update_direction(self.velocity.x)
		if move_input.y != 1 and self.move_data.attempt_jump():
			# dash horizontally
			var new_x_vel
			if horizontal > 0:
				new_x_vel = max(self.velocity.x, props.MAX_GROUND_SPEED)
			else:
				new_x_vel = min(self.velocity.x, -props.MAX_GROUND_SPEED)
			self.velocity = Vector2(new_x_vel, 0.0)
			self.move_data.update_direction(self.velocity.x)
			self._suspend_dash_gravity(props.DASH_FLOAT_DUR)


## Perform a grounded full jump.
func jump():
	self._ground_jump(-props.JUMP_VEL)


## Perform a grounded full jump.
func short_jump():
	self._ground_jump(-props.SHORT_JUMP_VEL)


## Move the player horizontally.
func update_move(delta: float):
	# Add the gravity.
	if self._is_airborne() and not self.move_data.suspend_gravity:
		self.velocity.y += gravity * delta
	
	var move_input = self.player_input.get_directional_input()
	
	if self.move_data.on_ceiling:
		self.velocity = self._get_ceiling_move(delta, move_input)
	elif self.move_data.on_right_wall:
		self.velocity = self._get_wall_move(delta, move_input, 1)
	elif self.move_data.on_left_wall:
		self.velocity = self._get_wall_move(delta, move_input, -1)
	elif self.is_on_floor():
		self.velocity = self._get_ground_move(delta, move_input)
	else:
		self.velocity = self._get_airborne_move(delta, move_input)

	self.move_and_slide()


## Update the movement data for the player
func update_move_data(delta: float) -> void:
	var move_input = self.player_input.get_directional_input()
	
	if self.is_on_floor():
		self.move_data.update_direction(self.velocity.x)
		self.move_data.reset_jumps(props.JUMPS)
		self.move_data.reset_wall_run()
		self.move_data.on_right_wall = false
		self.move_data.on_left_wall = false
	
	self.move_data.last_frame_airborne = self._is_airborne()
	if self._is_touching_ceiling() and move_input.y == -1:
		if not self.move_data.on_ceiling:
			self.move_data.last_frame_airborne = true
		self.move_data.on_ceiling = true
	else:
		self.move_data.on_ceiling = false
	# only attach to the wall if there is a towards input
	if self._is_touching_wall(1) and move_input.x == 1 and not self.move_data.wall_vaulted:
		self.move_data.on_right_wall = true
		self.move_data.facing_right = true
	elif not self._is_touching_wall(1):
		self.move_data.on_right_wall = false
	if self._is_touching_wall(-1) and move_input.x == -1 and not self.move_data.wall_vaulted:
		self.move_data.on_left_wall = true
		self.move_data.facing_right = false
	elif not self._is_touching_wall(-1):
		self.move_data.on_left_wall = false
	if not self._is_touching_wall(1) and not self._is_touching_wall(-1):
		self.move_data.wall_running = false


## Update the character sprite
func _update_state() -> void:
	_sprite.flip_h = self.move_data.facing_right


## Perform any grounded jump.
func _ground_jump(jump_vel: float) -> void:
	if self.is_on_floor() or self.move_data.edge_jump:
		jump_vel = min(jump_vel, self.velocity.y)
		self.velocity = Vector2(self.velocity.x, jump_vel)
		self.move_data.suspend_gravity = false
	
	# delay disabling edge jump by 2 frames to allow ground jumping
	await get_tree().process_frame
	await get_tree().process_frame
	self.move_data.edge_jump = false


## Get the velocity vector of the player for ceiling movement
func _get_ceiling_move(delta: float, move_input: Vector2) -> Vector2:

	# note that magnitudes here have a horizontal value based on whether it is
	# positive or negative, contrary to the naming
	var rel_magnitude = self.velocity.length() if self.velocity.x > 0 else -self.velocity.length()

	if (self.move_data.last_frame_airborne and move_input.x != 0
		and ((move_input.x == 1 and rel_magnitude >= -0.1)
		or (move_input.x == -1 and rel_magnitude <= 0.1))):
		
		rel_magnitude = max(abs(rel_magnitude), props.MAX_GROUND_SPEED) * move_input.x
		return Vector2(rel_magnitude, 0)

	# stop the character
	if absf(rel_magnitude) < props.STOP_SPEED:
		self._ceiling_hang(props.CEILING_HANG_DUR)
		return Vector2(0, 0)
	else:
		rel_magnitude -= rel_magnitude * props.CEILING_TRACTION * delta
		return Vector2(rel_magnitude, 0)


## Get the velocity vector of the player for wall movement.
func _get_wall_move(delta: float, move_input: Vector2, wall_dir: int) -> Vector2:
	
	if move_input.x == -wall_dir:
		# no longer touching the wall
		self.move_data.on_left_wall = false
		self.move_data.on_right_wall = false
		self.move_data.wall_running = false
		return self.velocity
	if move_input.y == -1 and self.move_data.attempt_wall_run():
		self._wall_run(props.WALL_RUN_DUR)

	var new_y_vel = self.velocity.y
	if new_y_vel > props.WALL_SLIDE_MAX_SPEED:
		new_y_vel = min(props.WALL_SLIDE_MAX_SPEED, new_y_vel - props.WALL_SLIDE_ACCEL * delta)
	elif new_y_vel < props.WALL_SLIDE_MAX_SPEED:
		new_y_vel = max(-props.WALL_SLIDE_MAX_SPEED, new_y_vel + props.WALL_SLIDE_ACCEL * delta)
	
	if self.move_data.wall_running:
		return Vector2(0, min(new_y_vel, -props.WALL_RUN_SPEED))

	return Vector2(0, new_y_vel)

## Get the velocity vector for grounded movement
func _get_ground_move(delta: float, move_input: Vector2) -> Vector2:
	
	## executing jump, allow vertical momentum for a frame.
	if abs(self.velocity.y) > abs(self.velocity.x) or self.move_data.edge_jump:
		return self.velocity
	
	var ground_slope = self._get_floor_slope()
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
		return ground_slope * mod_magnitude
	elif move_input.x == -1 and self.velocity.x < 0.01:
		mod_magnitude = min(mod_magnitude, -props.MIN_GROUND_SPEED)
		if mod_magnitude < -props.MAX_GROUND_SPEED:
			mod_magnitude = min(rel_magnitude + speed_penalty, -props.MAX_GROUND_SPEED)
		return ground_slope * mod_magnitude
	else:
		# stop the character
		if absf(rel_magnitude) < props.STOP_SPEED:
			return Vector2(0.0, 0.0)
		else:
			rel_magnitude -= rel_magnitude * props.TRACTION * delta
			return ground_slope * rel_magnitude


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


##  Determine if the player is on a wall.
func _is_touching_wall(horizontal: int) -> bool:
	if horizontal < 0:
		var raycast_one: RayCast2D = get_node("LeftRaycast1")
		var raycast_two: RayCast2D = get_node("LeftRaycast2")
		return raycast_one.is_colliding() or raycast_two.is_colliding()
	elif horizontal > 0:
		var raycast_one = get_node("RightRaycast1")
		var raycast_two = get_node("RightRaycast2")
		return raycast_one.is_colliding() or raycast_two.is_colliding()
	return false

## Determine if the player is on the ceiling.
func _is_touching_ceiling() -> bool:
	var raycast_one = get_node('UpRaycast1')
	var raycast_two = get_node('UpRaycast2')
	return raycast_one.is_colliding() or raycast_two.is_colliding()


## Determine if the player is airborne.
func _is_airborne() -> bool:
	return (not self.is_on_floor()
		and not self.move_data.on_left_wall
		and not self.move_data.on_right_wall
		and not self.move_data.on_ceiling)
	

## Suspend gravity for a set amount of time.
func _suspend_dash_gravity(time: float) -> void:
	self.move_data.suspend_gravity = true
	await get_tree().create_timer(time).timeout
	self.move_data.suspend_gravity = false


## Suspend gravity for a set amount of time.
func _wall_run(time: float) -> void:
	self.move_data.wall_running = true
	await get_tree().create_timer(time).timeout
	self.move_data.wall_running = false


## Toggle wall_vaulted for a frame to prevent sticking to wall
func _wall_vault() -> void:
	self.move_data.wall_vaulted = true
	await get_tree().process_frame
	self.move_data.wall_vaulted = false


## Forcibly disable ceiling hang after the set duration
func _ceiling_hang(time: float) -> void:
	await get_tree().create_timer(time).timeout
	self.move_data.on_ceiling = false


## Get the floor slope angle.
func _get_floor_slope() -> Vector2:
	var slope = self.get_floor_normal().orthogonal()
	if slope.x < 0:
		return slope * -1
	else:
		return slope
