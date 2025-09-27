extends CharacterBody2D

@export var player_speed : int = 50
@export var can_move : bool = true

var player_direction : Vector2 = Vector2.DOWN
var player_last_direction : Vector2 = Vector2.DOWN
