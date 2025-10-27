extends DialogueResource
class_name DialogueText

@export var speaker_entity: String = "AX"
@export var sprite_animation_name: String = "idle"

@export_multiline var text: String
@export_range(0.1, 30.0, 0.1) var text_speed: float = 8.0

@export var text_sound: AudioStream
@export var text_volume_db: int
@export var text_volume_pitch_min: float = 0.85
@export var text_volume_pitch_max: float = 1.15
