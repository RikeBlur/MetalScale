class_name interact_component
extends Node2D

@export var interact_rage : Area2D = null
@export var player_node : CharacterBody2D = null

signal interact

func _ready() -> void:
	if interact_rage == null :
		print("Automic interacted rage")
		interact_rage = get_parent()
	# 检查并设置碰撞层和碰撞遮罩
	if interact_rage.collision_layer != 7 or interact_rage.collision_mask != 8:
		interact_rage.collision_layer = 7
		interact_rage.collision_mask = 8
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		interact.emit()
