extends Node

class_name PlayerInput


signal instant_jump_requested
signal jump_requested
signal short_jump_requested
signal dash_requested
signal interact_requested


var input_signal_dict = {
	"jump": self.instant_jump_requested,
	"dash": self.dash_requested,
	"interact": self.interact_requested,
}


const JUMP_HOLD_THRESHOLD = 0.08

var no_movement = false

var jump_hold_time = 0.0
var jump_held = false


func _ready():
	Dialogic.timeline_started.connect(disable_movement)
	Dialogic.timeline_ended.connect(enable_movement)


func _init():
	self.jump_hold_time = 0.0


func _input(event: InputEvent):
	if self.no_movement:
		return

	if event.is_action_released("jump"):
		self.short_jump_requested.emit()
		self.jump_hold_time = 0
		self.jump_held = false
	
	if event.is_action_pressed("jump"):
		self.jump_held = true
	
	for input in self.input_signal_dict:
		var input_signal = self.input_signal_dict[input]
		if event.is_action_pressed(input):
			input_signal.emit()


func _physics_process(delta):
	if self.no_movement:
		self.jump_hold_time = 0
		self.jump_held = false
		return
	
	if Input.is_action_pressed("jump") and self.jump_held:
		self.jump_hold_time += delta
		if self.jump_hold_time > JUMP_HOLD_THRESHOLD:
			self.jump_requested.emit()
			self.jump_hold_time = 0
			self.jump_held = false


func get_directional_input():
	if self.no_movement:
		return Vector2(0, 0)
	return Vector2(
		int(Input.get_axis("move_left", "move_right")),
		int(Input.get_axis("move_up", "move_down")))


## Disable movement.
func disable_movement():
	self.no_movement = true


## Enable movement.
func enable_movement():
	await get_tree().create_timer(0.2).timeout
	self.no_movement = false
