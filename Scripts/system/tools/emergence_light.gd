class_name EmergenceLight
extends Node2D

@onready var success_sfx: AudioStreamPlayer2D = $SuccessSFX
@onready var radial_light: radial_light_source = get_node_or_null("radial_light")
