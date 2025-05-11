extends Node

class_name PlayerProps


@export var GROUND_ACCEL: float = 750.0
@export var MIN_GROUND_SPEED: float = 500.0
@export var MAX_GROUND_SPEED: float = 1250.0

# speed penalty for being faster than max ground speed
@export var GROUND_SPEED_PENALTY: float = 250.0
# fraction of velocity retained each second while grounded
@export var TRACTION: float = 0.04
# speed at which player will default stop while grounded
@export var STOP_SPEED: float = 100.0

@export var JUMP_VEL: float = 1750.0
@export var SHORT_JUMP_VEL: float = 1150.0

@export var AIR_JUMP_VEL: float = 1750.0
@export var AIR_X_ACCEL: float = 1250.0
## minimum horizontal jump speed if a direction is held
@export var AIR_MAX_X_SPEED: float = 750.0

