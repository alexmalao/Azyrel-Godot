extends Node2D

class_name NpcInteract


@export var dialogue: String = 'akyra_dev1'


func interact():
	Dialogic.start(dialogue)
