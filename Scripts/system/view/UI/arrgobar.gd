class_name ArrgoBar
extends Control

var own_manager: UI_manager = null
var player_now: CharacterBody2D = null

var activated : bool = false

@export var arrgo_bar : ProgressBar = null


func _process(_delta: float) -> void:
	# 功能1：从 GameManager 同步玩家仇恨状态
	activated = GameManager.player_arrgo
	
	# 功能2：从玩家读取 aggro_value 并设置进度条
	if player_now and is_instance_valid(player_now) and arrgo_bar:
		arrgo_bar.value = player_now.aggro_value
