class_name npc
extends CharacterBody2D

@export var running_speed: float = 200.0
@export var walking_speed: float = 100.0

var npc_direction : Vector2 = Vector2.DOWN

var health_max : float = 100.0
var health_now : float = 100.0

var state: int = 0
# 对于EYE ： 0 -> patrol ; 1 -> pursue
