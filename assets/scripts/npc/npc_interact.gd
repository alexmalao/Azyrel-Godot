extends Node2D

class_name NpcInteract


@export var dialogue_open: String = 'akyra_dev1'
@export var dialogue_cont: String = 'akyra_dev2'
var interacted: bool = false


func _ready():
	self.interacted = false


func interact():
	if not self.interacted:
		self.interacted = true
		Dialogic.start(dialogue_open)
	else:
		Dialogic.start(dialogue_cont)
