class_name dialogue_double
extends Node2D

@export var a_index : Array[int]
@export var b_index : Array[int]
@export var dialogue : Array[DialogueResource]
@export var a_first : bool = true

@export var a : dialogue_base
@export var b : dialogue_base

var current_dialogue_item : int = 0

func _ready() -> void:
	if a == null or b == null:
		print("WARING: CANT FIND A&B IN DOUBLE DIALOGUE")
		return
	else :
		for i in a_index.size():
			a.dialogue[i] = dialogue[a_index[i]]
		for i in b_index.size():
			b.dialogue[i] = dialogue[b_index[i]]
			
	print(a_index)
	print(b_index)
	
	a_first = !a_index[0]
	if a_first:
		b.get_into_dark(false)
	else:
		a.get_into_dark(true)

func _process(delta: float) -> void:
	var new_current_dialogue_item = a.current_dialogue_item + b.current_dialogue_item
	if new_current_dialogue_item != current_dialogue_item:
		current_dialogue_item = new_current_dialogue_item
		print("UPDATE")
		_update_dark_light()
		
func _update_dark_light() -> void:
	print(current_dialogue_item, a.current_dialogue_item, b.current_dialogue_item)
	if current_dialogue_item in a_index:
		b.get_into_dark(false)
		a.back_to_light(true)
	elif current_dialogue_item in b_index:
		a.get_into_dark(true)
		b.back_to_light(false)
