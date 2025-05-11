extends Node

class_name PlayerProps


const GROUND_ACCEL: float = 750.0
const MIN_GROUND_SPEED: float = 500.0
const MAX_GROUND_SPEED: float = 1250.0

# speed epnalty for being faster than max ground speed
const GROUND_SPEED_PENALTY: float = 250.0
# fraction of velocity retained each second while grounded
const TRACTION = 0.04
# speed at which player will default stop while grounded
const STOP_SPEED = 100.0

const JUMP_VEL: float = 1750.0
const SHORT_JUMP_VEL: float = 1150.0

const AIR_JUMP_VEL: float = 1750.0
const AIR_X_ACCEL: float = 1250.0
## minimum horizontal jump speed if a direction is held
const AIR_MAX_X_SPEED: float = 650.0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

