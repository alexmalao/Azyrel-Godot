extends Node

class_name PlayerInput


signal instant_jump_requested
signal jump_requested
signal short_jump_requested
signal dash_requested


var input_signal_dict = {
	"jump": self.instant_jump_requested,
	"dash": self.dash_requested,
}


const JUMP_HOLD_THRESHOLD = 0.075
var jump_hold_time = 0.0


func _init():
	self.jump_hold_time = 0.0


func _input(event: InputEvent):
	if event.is_action_released("jump"):
		self.short_jump_requested.emit()
	
	for input in self.input_signal_dict:
		var input_signal = self.input_signal_dict[input]
		if event.is_action_pressed(input):
			input_signal.emit()

	# if event.is_action_pressed("jump"):
	# 	self.instant_jump_requested.emit()
	


func _physics_process(delta):
	if Input.is_action_pressed("jump"):
		self.jump_hold_time += delta
		if self.jump_hold_time > JUMP_HOLD_THRESHOLD:
			self.jump_requested.emit()
			self.jump_hold_time = 0



func get_directional_input():
	return Vector2(
		int(Input.get_axis("move_left", "move_right")),
		int(Input.get_axis("move_up", "move_down")))
