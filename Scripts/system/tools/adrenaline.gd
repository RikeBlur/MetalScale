class_name Adrenaline
extends Node2D

var player_now : CharacterBody2D = null

func _ready() -> void:
	var parent = get_parent()
	if parent and "player_now" in parent:
		player_now = parent.player_now
	
func _process(_delta: float) -> void:
	pass

func adrenaline_release() -> void:
	if not player_now:
		push_warning("Adrenaline could not find a player reference.")
		return
	
	print("Adrenaline effect activated!")
	# Implement adrenaline effects here, e.g., temporary speed boost.
