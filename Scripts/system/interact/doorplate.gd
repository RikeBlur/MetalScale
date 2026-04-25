class_name DoorPlate
extends Node2D

@export_multiline var door_name: String = ""

@onready var dialogue_component: DialogueComponent = get_node_or_null("DialogueComponent") as DialogueComponent


func _ready() -> void:
	_apply_door_name_to_dialogue()


func _apply_door_name_to_dialogue() -> void:
	if not dialogue_component:
		return
	if dialogue_component.dialogue_content.size() == 0:
		return
	var first_dialogue := dialogue_component.dialogue_content[0]
	if not first_dialogue:
		return

	first_dialogue = first_dialogue.duplicate(true)
	dialogue_component.dialogue_content[0] = first_dialogue
	if "text" in first_dialogue:
		first_dialogue.text = door_name
