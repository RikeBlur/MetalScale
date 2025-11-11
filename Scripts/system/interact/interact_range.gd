extends Area2D

@export var interacted : interact_component
@export var player_node : player

func _ready() -> void:
	interacted.player_node = player_node
