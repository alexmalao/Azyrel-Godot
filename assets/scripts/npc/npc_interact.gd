extends Node2D

class_name NpcInteract


@export var dialogue_open: String = 'akyra_dev1'
@export var dialogue_cont: String = 'akyra_dev2'

var interacted: bool = false
var pcam: PhantomCamera2D
var interact_box: Area2D
var interact_label: Label


func _ready():
	self.interacted = false
	self.pcam = get_node("NpcPCam")
	self.interact_box = get_node("InteractBox")
	self.interact_label = get_node("InteractLabel")


func _process(delta: float):
	var areas: Array = self.interact_box.get_overlapping_areas()
	if areas.size() > 0:
		self.interact_label.show()
	else:
		self.interact_label.hide()


func interact():
	self.pcam.set_priority(10)
	if not self.interacted:
		self.interacted = true
		Dialogic.start(dialogue_open)
	else:
		Dialogic.start(dialogue_cont)
	await Dialogic.timeline_ended
	self.pcam.set_priority(0)
