class_name player
extends CharacterBody2D

@export var player_walk_speed_max : int = 200
@export var player_run_speed_max : int = 450
@export var player_walk_speed_min : int = 100
@export var player_run_speed_min : int = 200
@export var player_walk_acceleration : int = 10
@export var player_run_acceleration : int = 30

@export var can_move : bool = true
@export var character : String = "Oni"

var player_direction : Vector2 = Vector2.DOWN
var player_last_direction : Vector2 = Vector2.DOWN

@export var tool_available : Array[ToolManager.Tool]
var tool : int = 0



 
