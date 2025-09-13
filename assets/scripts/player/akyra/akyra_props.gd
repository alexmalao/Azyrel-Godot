extends PlayerProps


class_name AkyraProps


func _init():
	# see PlayerProps for documentation
	GROUND_ACCEL = 725.0
	MIN_GROUND_SPEED = 475.0
	MAX_GROUND_SPEED = 1250.0

	GROUND_SPEED_PENALTY = 1250.0
	TRACTION = 7.0

	JUMP_VEL = 1700.0
	SHORT_JUMP_VEL = 1150.0

	AIR_JUMP_VEL = 1700.0
	AIR_X_ACCEL = 1225.0
	AIR_MAX_X_SPEED = 725.0
