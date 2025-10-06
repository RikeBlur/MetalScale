class_name floating_text
extends Node2D

@onready var label: Label = $Label
@export var position_offset: Vector2 = Vector2.ZERO
@export var scale_offset: Vector2 = Vector2.ZERO
@export var last_time_1 : float = 0
@export var last_time_2 : float = 0

var text : String
var position_tween : Tween
var scale_tween : Tween

func _ready() -> void:
	scale = Vector2(0.75,0.75)
	display_text(text)

func display_text(target_text : String) -> void:
	if position_tween != null and position_tween.is_running():
		position_tween.kill()
	if scale_tween != null and scale_tween.is_running():
		scale_tween.kill()	
	label.text = target_text
	
	position_tween = create_tween()
	scale_tween = create_tween()
	
	position_tween.tween_property(self, "global_position", global_position + position_offset, last_time_1)
	scale_tween.tween_property(self, "scale", scale_offset, last_time_1)
	
	position_tween.tween_property(self, "global_position", global_position + position_offset*2, last_time_2)
	scale_tween.tween_property(self, "scale", Vector2.ZERO, last_time_2)
	
