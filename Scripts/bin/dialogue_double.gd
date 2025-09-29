class_name dialogue_double
extends Node2D

@export var a_index : Array[int]
@export var b_index : Array[int]
@export var dialogue : Array[DialogueResource]
@export var a_first : bool = true

@export var a : dialogue_base
@export var b : dialogue_base

var current_dialogue_item : int = 0
var player_node : CharacterBody2D = null

func _ready() -> void:
	if a == null or b == null:
		print("WARING: CANT FIND A&B IN DOUBLE DIALOGUE")
		a = get_child(0)
		b = get_child(1)
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
		
	for i in get_tree().get_nodes_in_group("player"):
		player_node = i


func _process(delta: float) -> void:	
	# 计算总的对话进度，但避免重复计算
	var total_progress = 0
	if a.current_dialogue_item > 0:
		total_progress += a.current_dialogue_item
	if b.current_dialogue_item > 0:
		total_progress += b.current_dialogue_item
	
	# 检查是否完成所有对话
	if total_progress >= dialogue.size():
		player_node.can_move = true
		queue_free()
		return

	# 检查是否需要切换对话
	var new_current_dialogue_item = total_progress
	if new_current_dialogue_item != current_dialogue_item:
		# 检查是否在a_index和b_index之间切换
		var was_in_a = current_dialogue_item in a_index
		var was_in_b = current_dialogue_item in b_index
		var now_in_a = new_current_dialogue_item in a_index
		var now_in_b = new_current_dialogue_item in b_index
		
		# 只有在真正切换对话时才更新
		if (was_in_a and now_in_b) or (was_in_b and now_in_a):
			current_dialogue_item = new_current_dialogue_item
			_update_dark_light()
			print("UPDATE: switched dialogue")
			return
			
		current_dialogue_item = new_current_dialogue_item
		
	print("Progress:", current_dialogue_item, "A:", a.current_dialogue_item, "B:", b.current_dialogue_item)	
		
		
func _update_dark_light() -> void:
	print(current_dialogue_item, a.current_dialogue_item, b.current_dialogue_item)
	if current_dialogue_item in a_index:
		b.get_into_dark(false)
		a.back_to_light(true)
	elif current_dialogue_item in b_index:
		a.get_into_dark(true)
		b.back_to_light(false)
