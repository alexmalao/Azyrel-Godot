extends CharacterBody2D

class_name PlayerController


var props = PlayerProps
var move_data: PlayerMoveData
var player_input: PlayerInput
var interact_box: Area2D
var _velocity: Vector2

@export var char_width: float = 100
@export var char_height: float = 190
@onready var _sprite = $AnimatedSprite2D


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	self.props = PlayerProps.new()
	self.move_data = PlayerMoveData.new()
	self.player_input = get_node("PlayerInput")
	self.interact_box = get_node("InteractBox")
	self._velocity = Vector2(0, 0)

	self.player_input.instant_jump_requested.connect(self.instant_jump)
	self.player_input.jump_requested.connect(self.jump)
	self.player_input.short_jump_requested.connect(self.short_jump)
	self.player_input.dash_requested.connect(self.dash)
	self.player_input.interact_requested.connect(self.interact)


func _init():
	# i'm not sure these entirely do something
	self.floor_stop_on_slope = false
	self.floor_constant_speed = true
	self.floor_snap_length = 0
	self.set_floor_stop_on_slope_enabled(false)
	self.set_floor_max_angle(PI / 8 - 0.1)

func _physics_process(delta):
	self.update_position(delta)
	self.update_move_data(delta)
	self.update_move(delta)
	self._update_state()


## Interact with area.
func interact():
	var areas: Array = self.interact_box.get_overlapping_areas()
	if areas.size() > 0:
		areas[0].get_parent().interact()


## Perform an aerial or wall jump if possible.
func instant_jump():
	if self._is_touching_wall(1) and not self._is_grounded():
		self._velocity = props.RIGHT_WALL_JUMP_VECTOR * props.WALL_JUMP_SPEED
		self.move_data.on_right_wall = false
		self.move_data.facing_right = false
		self.move_data.reset_wall_run()
		self._wall_vault()
	elif self._is_touching_wall(-1) and not self._is_grounded():
		self._velocity = props.LEFT_WALL_JUMP_VECTOR * props.WALL_JUMP_SPEED
		self.move_data.on_left_wall = false
		self.move_data.facing_right = true
		self.move_data.reset_wall_run()
		self._wall_vault()
	elif self._is_airborne() and self.move_data.attempt_jump():
		self.move_data.dashing = false
		var horizontal = self.player_input.get_directional_input().x
		
		# perform jump, apply the maximum jump x speed
		var x_vel: float = self._velocity.x
		if horizontal == 1:
			x_vel = max(x_vel, props.AIR_MAX_X_SPEED)
		elif horizontal == -1:
			x_vel = min(x_vel, -props.AIR_MAX_X_SPEED)
		elif horizontal == 0 and abs(x_vel) < props.AIR_JUMP_STOP_SPEED:
			x_vel = 0
		var jump_vel: float = min(-props.AIR_JUMP_VEL, self._velocity.y)
		self._velocity = Vector2(x_vel, jump_vel)
		self.move_data.update_direction(x_vel)
		self.move_data.reset_wall_run()
	elif self._is_grounded():
		# record user input for attempting a jump in case near edge
		self.move_data.edge_jump = true


## Perform a grounded or aerial dash if possible.
func dash():
	var horizontal: int = self.player_input.get_directional_input().x
	if horizontal == 0:
		# record direction to be facing direction for no input
		horizontal = 1 if self.move_data.facing_right else -1
	
	if self._is_touching_wall(1) and not self._is_grounded():
		# dash off right wall
		self._velocity = Vector2(-props.MAX_GROUND_SPEED, 0)
		self.move_data.on_right_wall = false
		self.move_data.facing_right = false
		self.move_data.reset_wall_run()
		self._wall_vault()
		self._suspend_dash_gravity(props.DASH_FLOAT_DUR)
	elif self._is_touching_wall(-1) and not self._is_grounded():
		# dash off left wall
		self._velocity = Vector2(props.MAX_GROUND_SPEED, 0)
		self.move_data.on_left_wall = false
		self.move_data.facing_right = true
		self.move_data.reset_wall_run()
		self._wall_vault()
		self._suspend_dash_gravity(props.DASH_FLOAT_DUR)
	elif self._is_grounded():
		# ground dash
		var new_vel: float
		var rel_magnitude: float = self._velocity.length() if self._velocity.x > 0 else -self._velocity.length()
		## executing jump or land, revoking magnitude
		if abs(self._velocity.y) > abs(self._velocity.x) + 1.0:
			rel_magnitude = 0
		
		if horizontal > 0:
			new_vel = max(rel_magnitude, props.MAX_GROUND_SPEED)
		else:
			new_vel = min(rel_magnitude, -props.MAX_GROUND_SPEED)
		self._velocity = new_vel * self._get_floor_slope()
		self._suspend_dash_gravity(props.DASH_FLOAT_DUR)
	elif self._is_airborne():
		# aerial dash
		var move_input = self.player_input.get_directional_input()
		if move_input.y == 1 and self._velocity.y >= 0:
			# dash downwards
			self.move_data.dashing = false
			var new_y_vel = max(self._velocity.y, props.AIR_DOWN_DASH_VEL)
			self._velocity = Vector2(self._velocity.x, new_y_vel)
			self.move_data.update_direction(self._velocity.x)
		if move_input.y != 1 and self.move_data.attempt_jump():
			# dash horizontally
			var new_x_vel
			if horizontal > 0:
				new_x_vel = max(self._velocity.x, props.MAX_GROUND_SPEED)
			else:
				new_x_vel = min(self._velocity.x, -props.MAX_GROUND_SPEED)
			self._velocity = Vector2(new_x_vel, 0.0)
			self.move_data.update_direction(self._velocity.x)
			self._suspend_dash_gravity(props.DASH_FLOAT_DUR)


## Perform a grounded full jump.
func jump():
	self._ground_jump(-props.JUMP_VEL)


## Perform a grounded full jump.
func short_jump():
	self._ground_jump(-props.SHORT_JUMP_VEL)


## Update the position of the player
func update_position(delta: float):
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	# corner positions relative to character height and width
	var corner_offsets: Array[Vector2] = [
		Vector2(self.char_width / 2, 0),
		Vector2(-self.char_width / 2, 0),
		Vector2(self.char_width / 2, -self.char_height),
		Vector2(-self.char_width / 2, -self.char_height),
	]

	var colliding: bool = true
	var frame_vel: Vector2 = self._velocity * delta
	while colliding:
		# use velocity raycasts for continuous collision detection
		colliding = false
		for offset in corner_offsets:
			# store the new position to calculate leftover velocity
			var to_pos: Vector2 = Vector2(self.position.x + offset.x + frame_vel.x,
										  self.position.y + offset.y + frame_vel.y)
			var br_query = PhysicsRayQueryParameters2D.create(
				Vector2(self.position.x + offset.x, self.position.y + offset.y),
				to_pos,
				1)
			var result: Dictionary = space_state.intersect_ray(br_query)
			if result:
				self.position = Vector2(
					result.position.x - offset.x,
					result.position.y - offset.y,
				)
				colliding = true
				frame_vel = self.project_vectors(to_pos - result.position, result.normal.orthogonal())

	self.position = Vector2(self.position.x + self._velocity.x * delta,
							self.position.y + self._velocity.y * delta)


## Move the player horizontally.
func update_move(delta: float):
	# Add the gravity.
	if self._is_airborne() and not self.move_data.dashing:
		self._velocity.y += gravity * delta
	
	var move_input: Vector2 = self.player_input.get_directional_input()
	
	if self._is_touching_ceiling():
		if self.move_data.on_ceiling:
			self._velocity = self._get_ceiling_move(delta, move_input)
		else:
			self._velocity = Vector2(self._velocity.x, 100)
	elif self.move_data.on_right_wall:
		self._velocity = self._get_wall_move(delta, move_input, 1)
	elif self.move_data.on_left_wall:
		self._velocity = self._get_wall_move(delta, move_input, -1)
	elif self._is_grounded() or self.move_data.last_frame_grounded:
		self._project_wall()
		self._velocity = self._get_ground_move(delta, move_input)
	else:
		self._project_wall()
		self._velocity = self._get_airborne_move(delta, move_input)
	
	self.move_and_slide()


## Update the movement data for the player
func update_move_data(delta: float) -> void:
	var move_input = self.player_input.get_directional_input()
	
	self.move_data.last_frame_grounded = self.move_data._grounded
	if self._is_touching_ceiling() and move_input.y == -1 and self.move_data.attempt_ceiling_hang():
		self.move_data.on_ceiling = true
	elif self._is_grounded():
		self.move_data.update_direction(self._velocity.x)
		self.move_data.reset_jumps(props.JUMPS)
		self.move_data.reset_wall_run()
		self.move_data.on_right_wall = false
		self.move_data.on_left_wall = false
		self.move_data._grounded = true
	else:
		self.move_data._grounded = false
	
	self.move_data.last_frame_airborne = self.move_data._airborne
	self.move_data._airborne = self._is_airborne()
	if not self._is_touching_ceiling() or move_input.y != -1 :
		self.move_data.on_ceiling = false
		self.move_data.ceiling_sliding = false
	# only attach to the wall if there is a towards input
	if self._is_touching_wall(1) and move_input.x == 1 and not self.move_data.wall_vaulted:
		self.move_data.on_right_wall = true
		self.move_data.facing_right = true
	elif not self._is_touching_wall(1) or move_input.y == 1:
		self.move_data.on_right_wall = false
	if self._is_touching_wall(-1) and move_input.x == -1 and not self.move_data.wall_vaulted:
		self.move_data.on_left_wall = true
		self.move_data.facing_right = false
	elif not self._is_touching_wall(-1) or move_input.y == 1:
		self.move_data.on_left_wall = false
	if not self._is_touching_wall(1) and not self._is_touching_wall(-1):
		self.move_data.wall_running = false


## PRIVATE METHODS

## Update the character sprite
func _update_state() -> void:
	_sprite.flip_h = self.move_data.facing_right


## Perform any grounded jump.
func _ground_jump(jump_vel: float) -> void:
	if self._is_grounded() or self.move_data.edge_jump:
		jump_vel = min(jump_vel, self._velocity.y)
		self._velocity = Vector2(self._velocity.x, jump_vel)
		self.move_data.dashing = false
	
	# delay disabling edge jump by 2 frames to allow ground jumping
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	self.move_data.edge_jump = false


## Get the velocity vector of the player for ceiling movement
func _get_ceiling_move(delta: float, move_input: Vector2) -> Vector2:
	
	var ceiling_slope: Vector2 = self._get_ceiling_slope()

	# note that magnitudes here have a horizontal value based on whether it is
	# positive or negative, contrary to the naming

	var rel_magnitude: float = self._velocity.length()

	if self.move_data.last_frame_airborne:
		if ((move_input.x == 1 and self._velocity.x >= -0.1)
			or (move_input.x == -1 and self._velocity.x <= 0.1)):
			if self.move_data.attempt_ceiling_run():
				self._ceiling_slide(props.CEILING_SLIDE_DUR)
				if (move_input.x != 0 and ((move_input.x == 1 and self._velocity.x >= -0.1)
					or (move_input.x == -1 and self._velocity.x <= 0.1))):
				
					rel_magnitude = max(abs(self._velocity.x), props.CEILING_RUN_SPEED) * move_input.x
					return rel_magnitude * ceiling_slope
	
	if (move_input.x == 1 and self._velocity.x > 0.1
		or move_input.x == -1 and self._velocity.x < -0.1):
		if self.move_data.attempt_ceiling_run():
			self._ceiling_slide(props.CEILING_SLIDE_DUR)
			
			rel_magnitude = max(abs(self._velocity.x), props.CEILING_RUN_SPEED) * move_input.x
			return rel_magnitude * ceiling_slope
	# stop the character
	if absf(self._velocity.length()) < props.STOP_SPEED:
		self._ceiling_hang(props.CEILING_HANG_DUR)
		return Vector2(0, 0)
	elif not self.move_data.ceiling_sliding:
		var retained_speed_ratio: float = ((rel_magnitude - rel_magnitude * props.CEILING_TRACTION * delta)
											/ rel_magnitude)
		return self.project_vectors(self._velocity * retained_speed_ratio, ceiling_slope)
	return self.project_vectors(self._velocity, ceiling_slope)


## Get the velocity vector of the player for wall movement.
func _get_wall_move(delta: float, move_input: Vector2, wall_dir: int) -> Vector2:
	
	var wall_slope: Vector2 = self._get_wall_slope(wall_dir)
	
	if move_input.x == -wall_dir:
		# no longer touching the wall
		self.move_data.on_left_wall = false
		self.move_data.on_right_wall = false
		self.move_data.wall_running = false
		return self._velocity
	if move_input.y == -1 and self.move_data.attempt_wall_run():
		self._wall_run(props.WALL_RUN_DUR)

	var temp_vel: Vector2 = self.project_vectors(self._velocity, wall_slope)

	var new_magnitude: float = temp_vel.length() if temp_vel.y > 0 else -temp_vel.length()
	# sliding upwards too fast
	if new_magnitude < props.WALL_SLIDE_MAX_SPEED:
		new_magnitude = min(props.WALL_SLIDE_MAX_SPEED, new_magnitude + props.WALL_SLIDE_ACCEL * delta)
	else:
		new_magnitude = max(props.WALL_SLIDE_MAX_SPEED, new_magnitude - props.WALL_SLIDE_ACCEL * delta)
	
	## run up the wall
	if self.move_data.wall_running:
		if new_magnitude < -props.WALL_RUN_SPEED:
			return new_magnitude * wall_slope
		return wall_slope * -props.WALL_RUN_SPEED
	
	return new_magnitude * wall_slope

## Get the velocity vector for grounded movement
func _get_ground_move(delta: float, move_input: Vector2) -> Vector2:
	
	var ground_slope: Vector2 = self._get_floor_slope()

	if self.move_data.last_frame_airborne or not self.move_data.last_frame_grounded:
		## calculate projection here using projb a = ((a ⋅ b) / |b|²) * b
		return project_vectors(self._velocity, self._get_floor_slope())

	## executing jump, allow vertical momentum for a frame.
	if ((-self._velocity.y > abs(self._velocity.x) + 100.0 or self.move_data.edge_jump)
		and self.move_data.last_frame_grounded):
		return self._velocity
	
	var min_ground_speed: float = props.MIN_GROUND_SPEED
	var max_ground_speed: float = props.MAX_GROUND_SPEED
	# note that magnitudes here have a horizontal value based on whether it is
	# positive or negative, contrary to the naming
	var vel: Vector2 = self._velocity
	var rel_magnitude: float = vel.length() if vel.x > 0 else -vel.length()
	var mod_magnitude: float = rel_magnitude + move_input.x * props.GROUND_ACCEL * delta
	var speed_penalty: float = props.GROUND_SPEED_PENALTY * delta
	# grounded horizontal movement only triggers when in same direction
	# of current velocity
	if is_equal_approx(abs(ground_slope.x), abs(ground_slope.y)) and move_input.y == 1:
		if move_input.x == 0:
			move_input.x = 1 if ground_slope.y > 0 else -1
		mod_magnitude = rel_magnitude + move_input.x * props.SLIDE_ACCEL * delta
		min_ground_speed = props.MIN_SLIDE_SPEED
		max_ground_speed = props.MAX_SLIDE_SPEED
	if move_input.x == 1 and self._velocity.x > -1:
		mod_magnitude = max(mod_magnitude, min_ground_speed)
		if mod_magnitude > max_ground_speed and not self.move_data.dashing:
			mod_magnitude = max(rel_magnitude - speed_penalty, max_ground_speed)
		return ground_slope * mod_magnitude
	elif move_input.x == -1 and self._velocity.x < 1:
		mod_magnitude = min(mod_magnitude, -min_ground_speed)
		if mod_magnitude < -max_ground_speed and not self.move_data.dashing:
			mod_magnitude = min(rel_magnitude + speed_penalty, -max_ground_speed)
		return ground_slope * mod_magnitude
	else:
		# stop the character
		if absf(rel_magnitude) < props.STOP_SPEED:
			return Vector2(0.0, 0.0)
		else:
			rel_magnitude -= rel_magnitude * props.TRACTION * delta
			# what the fuck does this do
			# if is_equal_approx(abs(ground_slope.x), abs(ground_slope.y)):
			# 	return ground_slope * rel_magnitude * pow(2, 1/2)
			return ground_slope * rel_magnitude


## Get the velocity vector for airborne movement.
func _get_airborne_move(delta: float, move_input: Vector2) -> Vector2:
	var new_x_vel: float
	
	# airborne movement does not apply traction or slowdown
	var mod_speed: float = self._velocity.x + move_input.x * props.AIR_X_ACCEL * delta
	if mod_speed > props.AIR_MAX_X_SPEED:
		# only allow slowing down
		new_x_vel = min(mod_speed, self._velocity.x - self._velocity.x * props.AIR_TRACTION * delta)
		new_x_vel = max(new_x_vel, props.AIR_MAX_X_SPEED)  # can't accelerate past max air speed
	elif mod_speed < -props.AIR_MAX_X_SPEED:
		new_x_vel = max(mod_speed, self._velocity.x - self._velocity.x * props.AIR_TRACTION * delta)
		new_x_vel = min(new_x_vel, props.AIR_MAX_X_SPEED)
	else:
		new_x_vel = mod_speed
	
	return Vector2(new_x_vel, self._velocity.y)


##  Determine if the player is on a wall.
func _is_touching_wall(horizontal: int) -> bool:
	var touching: bool = false
	if horizontal < 0:
		var raycast_one: RayCast2D = get_node("LeftRaycast1")
		var raycast_two: RayCast2D = get_node("LeftRaycast2")
		if raycast_one.is_colliding():
			var angle: float = raycast_one.get_collision_normal().angle()
			touching = touching or (PI / 4 - 0.1 > angle and angle > -PI / 4 + 0.1)
		if raycast_two.is_colliding():
			var angle: float = raycast_one.get_collision_normal().angle()
			touching = touching or (PI / 4 - 0.1 > angle and angle > -PI / 4 + 0.1)
	elif horizontal > 0:
		var raycast_one: RayCast2D = get_node("RightRaycast1")
		var raycast_two: RayCast2D = get_node("RightRaycast2")
		if raycast_one.is_colliding():
			var angle: float = raycast_one.get_collision_normal().angle()
			touching = touching or (3 * PI / 4 + 0.1 < angle or angle < -3 * PI / 4 - 0.1)
		if raycast_two.is_colliding():
			var angle: float = raycast_one.get_collision_normal().angle()
			touching = touching or (3 * PI / 4 + 0.1 < angle or angle < -3 * PI / 4 - 0.1)
	return touching


## Determine if the player is airborne.
func _is_airborne() -> bool:
	return (not self._is_grounded()
		and not self.move_data.on_left_wall
		and not self.move_data.on_right_wall
		and not self.move_data.on_ceiling)


## Determine if the player is on the ceiling.
func _is_touching_ceiling() -> bool:
	var touching: bool = false
	var raycast_one: RayCast2D = get_node('UpRaycast1')
	var raycast_two: RayCast2D = get_node('UpRaycast2')
	if raycast_one.is_colliding():
		var angle: float = raycast_one.get_collision_normal().angle()
		touching = touching or (PI / 4 - 0.1 < angle and angle < 3 * PI / 4 + 0.1)
	if raycast_two.is_colliding():
		var angle: float = raycast_one.get_collision_normal().angle()
		touching = touching or (PI / 4 - 0.1 < angle and angle < 3 * PI / 4 + 0.1)
	return touching


## Determine if the player is grounded.
func _is_grounded() -> bool:
	var touching: bool = false
	var raycast_one: RayCast2D = get_node("DownRaycast1")
	var raycast_two: RayCast2D = get_node("DownRaycast2")
	if raycast_one.is_colliding():
		var angle: float = raycast_one.get_collision_normal().angle()
		# TODO: Figure this out
		# print(angle)
		touching = touching or (-PI / 4 + 0.1 > angle and angle > -3 * PI / 4 - 0.1)
	if raycast_two.is_colliding():
		var angle: float = raycast_one.get_collision_normal().angle()
		# TODO: Figure this out
		# print(angle)
		touching = touching or (-PI / 4 - 0.1 > angle and angle > -3 * PI / 4 - 0.1)
	return touching



# project the velocity vector onto the wall if necessary
func _project_wall():
	if self._is_touching_wall(1) and self._velocity.x > 0.1:
		self._velocity = self.project_vectors(self._velocity, self._get_wall_slope(1))
	if self._is_touching_wall(-1) and self._velocity.x < -0.1: 
		self._velocity = self.project_vectors(self._velocity, self._get_wall_slope(-1))


## Get the floor slope angle.
func _get_floor_slope() -> Vector2:
	return self._get_slope("DownRaycast1", "DownRaycast2")


## Get the ceiling slope angle.
func _get_ceiling_slope() -> Vector2:
	return self._get_slope("UpRaycast1", "UpRaycast2")


## get the wall slope angle.
func _get_wall_slope(horizontal: int) -> Vector2:
	if horizontal < 0:
		return self._get_slope("LeftRaycast1", "LeftRaycast2", false)
	elif horizontal > 0:
		return self._get_slope("RightRaycast1", "RightRaycast2", false)
	
	return Vector2(0, 1)


# helper to get sharpest slope angle given two raycasts.
func _get_slope(raycast_str_one: String, raycast_str_two: String, horizontal: bool = true):
	
	var raycast_one: RayCast2D = get_node(raycast_str_one)
	var raycast_two: RayCast2D = get_node(raycast_str_two)
	var slope: Vector2 = Vector2(1, 0)
	if raycast_one.is_colliding():
		var temp_slope: Vector2 = raycast_one.get_collision_normal().orthogonal()
		if horizontal:
			slope = temp_slope if temp_slope.x > 0 else -temp_slope
		else:
			slope = temp_slope if temp_slope.y > 0 else -temp_slope
	if raycast_two.is_colliding():
		var temp_slope: Vector2 = raycast_two.get_collision_normal().orthogonal()
		if horizontal:
			temp_slope = temp_slope if temp_slope.x > 0 else -temp_slope
			if abs(temp_slope.y / temp_slope.x) > abs(slope.y / slope.x):
				slope = temp_slope
		else:
			slope = temp_slope if temp_slope.y > 0 else -temp_slope
			if abs(temp_slope.x / temp_slope.y) > abs(slope.x / slope.y):
				slope = temp_slope
	
	return slope
	

## Suspend gravity for a set amount of time.
func _suspend_dash_gravity(time: float) -> void:
	self.move_data.dashing = true
	await get_tree().create_timer(time).timeout
	self.move_data.dashing = false


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


## Suspend ceiling friction for a set amount of time.
func _ceiling_slide(time: float) -> void:
	self.move_data.ceiling_sliding = true
	await get_tree().create_timer(time).timeout
	self.move_data.ceiling_sliding = false


## Forcibly disable ceiling hang after the set duration
func _ceiling_hang(time: float) -> void:
	await get_tree().create_timer(time).timeout
	if self.move_data.on_ceiling:
		self.move_data.on_ceiling = false


## UTILITY METHODS

func project_vectors(a: Vector2, b: Vector2) -> Vector2:
	# projb a = ((a ⋅ b) / |b|²) * b
	# redundant power, b.length() is 1
	var new_magnitude: float = a.dot(b) / pow(b.length(), 2)
	return new_magnitude * b
