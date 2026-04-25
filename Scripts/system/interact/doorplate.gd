class_name DoorPlate
extends Node2D

@export_multiline var door_name: String = "":
	set(value):
		door_name = value
		if is_node_ready():
			_apply_door_name_to_dialogue()

@onready var dialogue_component: DialogueComponent = get_node_or_null("DialogueComponent") as DialogueComponent


func _ready() -> void:
	_make_dialogue_component_resources_unique()
	_apply_door_name_to_dialogue()
	_connect_dialogue_refresh_before_trigger()


func _make_dialogue_component_resources_unique() -> void:
	if not dialogue_component:
		return

	var local_trigger_flags: Array[dialogue_flag] = []
	for flag_resource in dialogue_component.trigger_flag:
		if flag_resource:
			var local_flag := flag_resource.duplicate(true) as dialogue_flag
			local_flag.flag = false
			local_flag.resource_local_to_scene = true
			local_trigger_flags.append(local_flag)
		else:
			local_trigger_flags.append(null)
	dialogue_component.trigger_flag = local_trigger_flags


func _apply_door_name_to_dialogue() -> void:
	if not dialogue_component:
		return
	if dialogue_component.dialogue_content.size() == 0:
		return

	var local_dialogue_content: Array[DialogueResource] = []
	for index in range(dialogue_component.dialogue_content.size()):
		var dialogue_resource := dialogue_component.dialogue_content[index]
		if dialogue_resource:
			var local_resource := _make_local_dialogue_resource(dialogue_resource)
			if index == 0 and local_resource is DialogueText:
				(local_resource as DialogueText).text = door_name
			local_dialogue_content.append(local_resource)
		else:
			local_dialogue_content.append(null)

	dialogue_component.dialogue_content = local_dialogue_content


func _make_local_dialogue_resource(dialogue_resource: DialogueResource) -> DialogueResource:
	var local_resource: DialogueResource
	if dialogue_resource is DialogueText:
		var source := dialogue_resource as DialogueText
		var local_text := DialogueText.new()
		local_text.speaker_entity = source.speaker_entity
		local_text.sprite_animation_name = source.sprite_animation_name
		local_text.text = source.text
		local_text.text_speed = source.text_speed
		local_text.text_sound = source.text_sound
		local_text.text_volume_db = source.text_volume_db
		local_text.text_volume_pitch_min = source.text_volume_pitch_min
		local_text.text_volume_pitch_max = source.text_volume_pitch_max
		local_resource = local_text
	else:
		local_resource = dialogue_resource.duplicate(true) as DialogueResource
	local_resource.resource_local_to_scene = true
	return local_resource


func _connect_dialogue_refresh_before_trigger() -> void:
	if not dialogue_component:
		return
	var source := dialogue_component.get_node_or_null("Area2D")
	if not source or source.get_child_count() <= 0:
		return
	var inter_comp := source.get_child(0)
	if not inter_comp or not inter_comp.has_signal("interacted"):
		return
	var callable := Callable(self, "_apply_door_name_to_dialogue")
	if not inter_comp.is_connected("interacted", callable):
		inter_comp.connect("interacted", callable)
