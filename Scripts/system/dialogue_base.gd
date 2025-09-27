class_name dialogue_base
extends Node2D

const DialogueButtonPreload = preload("res://System/QA/botton.tscn")

@export var back_sprite : Sprite2D = null
@export var dialogue_label : RichTextLabel = null
@export var speaker_sprite : AnimatedSprite2D = null
@export var botton_container : HBoxContainer = null
@export var text_sound : AudioStreamPlayer2D = null

@export var dialogue: Array[DialogueResource]
var current_dialogue_item : int = 0
var next_item : bool = true

var player_node : CharacterBody2D

func _ready() -> void:
	visible = false
	back_sprite = $back_sprite
	dialogue_label = $Control/HBoxContainer/VBoxContainer/RichTextLabel
	botton_container = $Control/HBoxContainer/VBoxContainer/botton_container
	speaker_sprite = $Control/HBoxContainer/SpeakerParent
	text_sound = $AudioStreamPlayer2D
	botton_container.visible = false
	
	for i in get_tree().get_nodes_in_group("player"):
		player_node = i
	
func _process(_delta: float) -> void:
	if current_dialogue_item == dialogue.size():
		print("dialogue over")
		if !player_node:
			for i in get_tree().get_nodes_in_group("player"):
				player_node = i
			return
		player_node.can_move = true
		queue_free()
		return
		
	if next_item == true:
		next_item = false
		var i = dialogue[current_dialogue_item]
		
		if i is DialogueFunction:
			if i.hide_dialogue_box:
				visible = false
			else :
				visible = true
			_funtion_resource(i)
		elif i is DialogueChoice:
			visible = true
			_choice_resource(i)
		elif i is DialogueText:	
			visible = true
			_text_resource(i)	
		else :
			printerr("You accidentally added a DE resource")
			current_dialogue_item += 1
			next_item = true
	
func _funtion_resource(i: DialogueFunction) -> void :
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
	
func _choice_resource(i: DialogueChoice) -> void :
	dialogue_label.text = i.text
	dialogue_label.visible_characters = -1
	if i.speaker_img:
		speaker_sprite.visible = true
		speaker_sprite.texture = i.speaker_img
		speaker_sprite.hframe = i.speaker_img_Hframes
		speaker_sprite.frame =  min(i.speaker_img_select_frame, i.speaker_img_Hframes-1)
	else :
		speaker_sprite.visible = false
	botton_container.visible = true
	
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
			_choice_botton_pressed.bind(get_node(function_resource.target_path), function_resource.wait_for_signal_to_continue),
			CONNECT_ONE_SHOT)
			
		else:
			DialogueBottonVar.connect("pressed", _choice_botton_pressed.bind(null, ""), CONNECT_ONE_SHOT)	
		
		botton_container.add_child(DialogueBottonVar)
	botton_container.get_child(0).grab_focus()
		
		
func _choice_botton_pressed(target_node : Node, wait_for_signal_to_continue: String) -> void :
	botton_container.visible = false
	for i in botton_container.get_children():
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
	
func _text_resource(i: DialogueText) -> void :
	text_sound.stream = i.text_sound
	text_sound.volume_db = i.text_volume_db
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera and i.camera_position != Vector2(999.0, 999.0):
		var camera_tween : Tween = create_tween().set_trans(Tween.TRANS_SINE)
		camera_tween.tween_property(camera, "global_position", i.camera_position, i.camera_transition_time)
			
	if i.speaker_img:
		speaker_sprite.visible = true
		speaker_sprite.texture = i.speaker_img
		speaker_sprite.hframe = i.speaker_img_Hframes
		speaker_sprite.frame =  0
	else :
		speaker_sprite.visible = false
	
	dialogue_label.visible_characters = 0
	dialogue_label.text = i.text
	var text_without_square_brackets: String = _text_without_square_brackets(i.text)
	var total_character: int = text_without_square_brackets.length()
	var character_timer: float = 0.0
	while dialogue_label.visible_characters < total_character:
		if Input.is_action_just_pressed("skip"):
			print("skip dialogue")
			dialogue_label.visible_characters = total_character
			break
		
		character_timer += get_process_delta_time()
		
		if character_timer >= (1.0 / i.text_speed) or text_without_square_brackets[dialogue_label.visible_characters] == "":
			var character = text_without_square_brackets[dialogue_label.visible_characters]
			dialogue_label.visible_characters += 1
			if character != "":
				text_sound.pitch_scale = randf_range(i.text_volume_pitch_min, i.text_volume_pitch_max)
				text_sound.play()
				if i.speaker_img_Hframes != 1:
					if speaker_sprite.frame < i.speaker_img_Hframes -1:
						speaker_sprite.frame += 1
					else:
						speaker_sprite.frame = 0
			character_timer = 0
			
		await get_tree().process_frame
	speaker_sprite.frame = min(i.speaker_img_rest_frame, i.speaker_img_Hframes)
	
	while true:
		await get_tree().process_frame
		if dialogue_label.visible_characters == total_character:
			if Input.is_action_just_pressed("skip"):
				await get_tree().process_frame
				current_dialogue_item += 1
				next_item = true	
	
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
	
	
