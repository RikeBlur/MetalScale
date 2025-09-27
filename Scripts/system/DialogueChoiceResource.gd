extends DialogueResource
class_name DialogueChoice

@export var speaker_entity: String
@export var sprite_animation_name: String

@export_multiline var text: String 

@export var choice_text: Array[String]
@export var choice_function_call: Array[DialogueFunction]
