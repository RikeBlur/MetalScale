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

@export var camera_position: Vector2 = Vector2(999.0, 999.0)
@export_range(0.05, 10.0, 0.05) var camera_transition_time: float = 1.0
