class_name JumpscareAnimatedSprite
extends AnimatedSprite2D

@export var start_scale: Vector2 = Vector2.ONE
@export var end_scale: Vector2 = Vector2.ONE
@export var start_position: Vector2 = Vector2.ZERO
@export var end_position: Vector2 = Vector2.ZERO
@export var start_rotate: float = 0.0
@export var end_rotate: float = 0.0
@export var animate_time: float = 0.0
@export var wait_time: float = 0.0
@export var dissolve_time: float = 0.0
@export var dissolved_paramater: StringName = &"DissolveValue"
