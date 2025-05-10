extends CharacterBody2D


const PlayerProps = preload("res://assets/scripts/player/player_props.gd")

var props = PlayerProps.new()


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	pass


func _physics_process(delta):
	self.update_move(delta)


## Move the player horizontally.
func update_move(delta: float):
	# Add the gravity.
	if not self.is_on_floor():
		self.velocity.y += gravity * delta
	
	var move_input = Vector2(
		int(Input.get_axis("move_left", "move_right")),
		int(Input.get_axis("move_up", "move_down")))
	
	if self.is_on_floor():
		self.velocity = self._get_ground_move(delta, move_input)

	self.move_and_slide()


## Get the velocity vector for grounded movement
func _get_ground_move(delta: float, move_input: Vector2) -> Vector2:
	
	# note that magnitudes here have a horizontal value based on whether it is
	# positive or negative, contrary to the naming
	var rel_magnitude = self.velocity.length() if self.velocity.x < 0 else -self.velocity.length()
	var mod_magnitude = rel_magnitude + move_input.x * props.GROUND_ACCEL * delta
	print(mod_magnitude)
	return Vector2(mod_magnitude, 0)
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
		return self.velocity
		# stop the character
#		if absf(rel_magnitude) < props.STOP_SPEED:
#			return Vector2(0.0, 0.0)
#		else:
#			rel_magnitude *= pow(delta, props.TRACTION)
#			return Vector2(rel_magnitude * 1, 0)






