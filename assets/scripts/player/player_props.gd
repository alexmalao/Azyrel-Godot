extends Node

class_name PlayerProps


# total number of airborne jumps
@export var JUMPS: int = 1

@export var GROUND_ACCEL: float = 750.0
@export var MIN_GROUND_SPEED: float = 500.0
@export var MAX_GROUND_SPEED: float = 1250.0

@export var SLIDE_ACCEL: float = 2000.0
@export var MIN_SLIDE_SPEED: float = 500.0
@export var MAX_SLIDE_SPEED: float = 2500.0

# speed penalty for being faster than max ground speed
@export var GROUND_SPEED_PENALTY: float = 250.0
# amount of times velocity drops per second while sliding on the ground
@export var TRACTION: float = 6.0
# speed at which player will default stop while grounded
@export var STOP_SPEED: float = 100.0

@export var JUMP_VEL: float = 1750.0
@export var SHORT_JUMP_VEL: float = 1150.0

@export var AIR_JUMP_VEL: float = 1750.0
@export var AIR_TRACTION: float = 0.12
@export var AIR_JUMP_STOP_SPEED: float = 500.0
@export var AIR_X_ACCEL: float = 1250.0
## minimum horizontal jump speed if a direction is held
@export var AIR_MAX_X_SPEED: float = 750.0
@export var AIR_DOWN_DASH_VEL: float = 1500.0
@export var DASH_FLOAT_DUR: float = 0.25

@export var RIGHT_WALL_JUMP_VECTOR = Vector2(-1, -2).normalized()
@export var LEFT_WALL_JUMP_VECTOR = Vector2(1, -2).normalized()
@export var WALL_RUN_SPEED: float = 1000.0
@export var WALL_JUMP_SPEED: float = 1750.0
@export var WALL_SLIDE_ACCEL: float = 1500.0
@export var WALL_SLIDE_MAX_SPEED: float = 750.0

@export var WALL_RUN_DUR: float = 0.15

@export var CEILING_TRACTION: float = 3.5
@export var CEILING_RUN_SPEED: float = 1000.0
@export var CEILING_SLIDE_DUR: float = 0.3
@export var CEILING_HANG_DUR: float = 0.6
