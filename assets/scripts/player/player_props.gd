extends Node

class_name PlayerProps


@export var GROUND_ACCEL: float = 20000.0
@export var MIN_GROUND_SPEED: float = 250.0
@export var MAX_GROUND_SPEED: float = 2500.0

# speed epnalty for being faster than max ground speed
@export var GROUND_SPEED_PENALTY: float = 250.0
# fraction of velocity retained each second while grounded
@export var TRACTION = 0.04
# speed at which player will default stop while grounded
@export var STOP_SPEED = 100.0


@export var JUMP_VELOCITY: float = 750.0
@export var SPEED: float = 750.0



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



