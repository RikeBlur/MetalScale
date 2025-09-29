class_name dialogue_dual
extends Node2D

const DialogueButtonPreload = preload("res://System/QA/botton.tscn")

@export var back_sprite : Array[AnimatedSprite2D]
@export var dialogue_label : Array[RichTextLabel]
@export var speaker_sprite : Array[AnimatedSprite2D]
@export var botton_container : Array[HBoxContainer]
@export var text_sound : Array[AudioStreamPlayer2D]

@export var dialogue: Array[DialogueResource]
var current_dialogue_item : int = 0
var next_item : bool = true

@export var a_index : Array[int]
@export var b_index : Array[int]
@export var a_first : bool = true

var player_node : CharacterBody2D
var which : int
var dialogue_node : Array[Node2D]

func _ready() -> void:
	visible = false
	
	back_sprite[0] = $a/back_sprite
	dialogue_label[0] = $a/Control/HBoxContainer/VBoxContainer/RichTextLabel
	botton_container[0] = $a/Control/HBoxContainer/VBoxContainer/botton_container
	speaker_sprite[0] = $a/illustrate
	text_sound[0] = $a/AudioStreamPlayer2D

	back_sprite[1] = $b/back_sprite	
	dialogue_label[1] = $b/Control/HBoxContainer/VBoxContainer/RichTextLabel
	botton_container[1] = $b/Control/HBoxContainer/VBoxContainer/botton_container
	speaker_sprite[1] = $b/illustrate
	text_sound[1] = $b/AudioStreamPlayer2D
	
	dialogue_node.append($a)
	dialogue_node.append($b)
	
	botton_container[0].visible = false
	botton_container[1].visible = false
	
	for i in get_tree().get_nodes_in_group("player"):
		player_node = i
	z_index = 10
	
	if a_first:
		which = 0
		_get_into_dark(1)
		dialogue_node[0].z_index = 10
		speaker_sprite[0].material.set_shader_parameter("brightness", 1)
		speaker_sprite[0].material.set_shader_parameter("contrast", 1)
	else:
		which = 1
		_get_into_dark(0)
		dialogue_node[1].z_index = 10
		speaker_sprite[1].material.set_shader_parameter("brightness", 1)
		speaker_sprite[1].material.set_shader_parameter("contrast", 1)
		
func _process(_delta: float) -> void:
	var new_which : int = 0
	
	if current_dialogue_item == dialogue.size():
		print("dialogue over")
		if !player_node:
			for i in get_tree().get_nodes_in_group("player"):
				player_node = i
			return
		player_node.can_move = true
		queue_free()
		return
	
	if current_dialogue_item in a_index:
		new_which = 0
	elif current_dialogue_item in b_index:
		new_which = 1
		
	if new_which != which :
		_get_into_dark(which)
		_back_to_light(new_which)
	
	which = new_which
		
	if next_item == true:
		next_item = false
		var i = dialogue[current_dialogue_item]
		
		if i is DialogueFunction:
			if i.hide_dialogue_box:
				visible = false
			else :
				visible = true
			_funtion_resource(which,i)
		elif i is DialogueChoice:
			visible = true
			_choice_resource(which,i)
		elif i is DialogueText:	
			visible = true
			_text_resource(which,i)	
		else :
			printerr("You accidentally added a DE resource")
			current_dialogue_item += 1
			next_item = true
	
func _funtion_resource(which: int, i: DialogueFunction) -> void :
	var target_node = get_node(i.target_path)
	if target_node.has_method(i.function_name):
		if i.function_arguments.size() == 0:
			target_node.call(i.function_name)
		else:
			target_node.callv(i.function_name, i.function_arguments)
			
	if i.wait_for_signal_to_continue:
		var signal_name = i.wait_for_signal_to_continue
		if target_node.has_signal(signal_name):
			var signal_state = {"done" : false}
			var callable = func(_args): signal_state.done = true
			target_node.connect(signal_name, callable, CONNECT_ONE_SHOT)
			while not signal_state.done:
				await get_tree().process_frame
				
	current_dialogue_item += 1
	next_item = true
	
func _choice_resource(which: int, i: DialogueChoice) -> void :
	dialogue_label[which].text = i.text
	dialogue_label[which].visible_characters = -1
	if i.sprite_animation_name:
		speaker_sprite[which].visible = true
		speaker_sprite[which].play(i.sprite_animation_name)
	else :
		speaker_sprite[which].visible = false
	botton_container[which].visible = true
	
	for item in i.choice_text.size():
		var DialogueBottonVar = DialogueButtonPreload.instantiate()
		DialogueBottonVar.text = i.choice_text[item]
		
		var function_resource : DialogueFunction = i.choice_function_call[item] 
		if function_resource:
			DialogueBottonVar.connect("pressed",
			Callable(get_node(function_resource.target_path), function_resource.function_name).bindv(function_resource.function_arguments),
			CONNECT_ONE_SHOT)
			
			if function_resource.hide_dialogue_box:
				DialogueBottonVar.connect("pressed", hide, CONNECT_ONE_SHOT)
			DialogueBottonVar.connect("pressed", 
			_choice_botton_pressed.bind(which, get_node(function_resource.target_path), function_resource.wait_for_signal_to_continue),
			CONNECT_ONE_SHOT)
			
		else:
			DialogueBottonVar.connect("pressed", _choice_botton_pressed.bind(which, null, ""), CONNECT_ONE_SHOT)	
		
		botton_container[which].add_child(DialogueBottonVar)
		
		
func _choice_botton_pressed(which: int, target_node : Node, wait_for_signal_to_continue: String) -> void :
	botton_container[which].visible = false
	for i in botton_container[which].get_children():
		i.queue_free()
	
	# add any other effect
	
	if wait_for_signal_to_continue:
		var signal_name = wait_for_signal_to_continue
		if target_node.has_signal(signal_name):
			var signal_state = {"done" : false}
			var callable = func(_args): signal_state.done = true
			target_node.connect(signal_name, callable, CONNECT_ONE_SHOT)
			while not signal_state.done:
				await get_tree().process_frame
	
	current_dialogue_item += 1
	next_item = true
	
func _text_resource(which: int, i: DialogueText) -> void :
	text_sound[which].stream = i.text_sound
	text_sound[which].volume_db = i.text_volume_db
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera and i.camera_position != Vector2(999.0, 999.0):
		var camera_tween : Tween = create_tween().set_trans(Tween.TRANS_SINE)
		camera_tween.tween_property(camera, "global_position", i.camera_position, i.camera_transition_time)
			
	if i.sprite_animation_name:
		speaker_sprite[which].visible = true
		speaker_sprite[which].play(i.sprite_animation_name)
	else :
		speaker_sprite[which].visible = false
	
	dialogue_label[which].visible_characters = 0
	dialogue_label[which].text = i.text
	var text_without_square_brackets: String = _text_without_square_brackets(i.text)
	var total_character: int = text_without_square_brackets.length()
	var character_timer: float = 0.0
	while dialogue_label[which].visible_characters < total_character:
		if Input.is_action_just_pressed("skip"):
			print("skip dialogue")
			dialogue_label[which].visible_characters = total_character
			break
		
		character_timer += get_process_delta_time()
		
		if character_timer >= (1.0 / i.text_speed) or text_without_square_brackets[dialogue_label[which].visible_characters] == "":
			var character = text_without_square_brackets[dialogue_label[which].visible_characters]
			dialogue_label[which].visible_characters += 1
			if character != "":
				text_sound[which].pitch_scale = randf_range(i.text_volume_pitch_min, i.text_volume_pitch_max)
				text_sound[which].play()
			character_timer = 0
			
		await get_tree().process_frame
	
	while true:
		await get_tree().process_frame
		if dialogue_label[which].visible_characters == total_character:
			if Input.is_action_just_pressed("skip"):
				# 添加延迟避免重复触发
				await get_tree().process_frame
				current_dialogue_item += 1
				next_item = true
				break  # 跳出循环，避免重复处理	
	
func _text_without_square_brackets(text: String) -> String:
	var result: String = ""
	var inside_bracket: bool = false
	
	for i in text:
		if i == "[":
			inside_bracket = true
			continue
		
		if i == "]":
			inside_bracket = false
			continue
			
		if !inside_bracket:
			result += i
			
	return result
	
func _get_into_dark(which : int) -> void:
	# z坐标下降（被另一个dialogue覆盖）
	dialogue_node[which].z_index = 9
	if which == 0 :
		dialogue_node[which].global_position -= Vector2(50, -20)
	else :
		dialogue_node[which].global_position += Vector2(50, 20)
	
	# RichTextLabel清空
	if dialogue_label[which]:
		dialogue_label[which].text = ""
		dialogue_label[which].visible_characters = 0
	
	# 动画停止
	if speaker_sprite[which]:
		speaker_sprite[which].stop()
		speaker_sprite[which].material.set_shader_parameter("brightness", 0.1)
		speaker_sprite[which].material.set_shader_parameter("contrast", 0.99)
	if back_sprite[which]:
		back_sprite[which].stop()
		back_sprite[which].material.set_shader_parameter("brightness", 0.1)
		back_sprite[which].material.set_shader_parameter("contrast", 0.99)	
	
	# 隐藏按钮容器
	if botton_container:
		botton_container[which].visible = false
		# 清理所有按钮
		for child in botton_container[which].get_children():
			child.queue_free()

func _back_to_light(which : int) -> void:
	# 恢复正常处理模式
	process_mode = Node.PROCESS_MODE_INHERIT
	
	# z坐标恢复正常
	dialogue_node[which].z_index = 10
	
	# 恢复位置
	if which == 0 :
		dialogue_node[which].global_position += Vector2(50, -20)
	else :
		dialogue_node[which].global_position -= Vector2(50, 20)
	
	# 动画停止
	if speaker_sprite[which]:
		speaker_sprite[which].play("idle")
		speaker_sprite[which].material.set_shader_parameter("brightness", 1)
		speaker_sprite[which].material.set_shader_parameter("contrast", 1)
	if back_sprite[which]:
		back_sprite[which].play()
		back_sprite[which].material.set_shader_parameter("brightness", 1)
		back_sprite[which].material.set_shader_parameter("contrast", 1)	

	
