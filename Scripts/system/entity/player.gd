class_name player
extends CharacterBody2D

# 移动相关参数/状态
@export var player_walk_speed_max : int = 200
@export var player_run_speed_max : int = 450
@export var player_walk_speed_min : int = 100
@export var player_run_speed_min : int = 200
@export var player_walk_acceleration : int = 10
@export var player_run_acceleration : int = 30

# 输入控制
var player_input_blocked : bool = false
var can_move : bool = true
var can_interact : bool = true
var can_act : bool = true

# 方向控制
var player_direction : Vector2 = Vector2.DOWN
var player_last_direction : Vector2 = Vector2.DOWN

# player info 展示信息
@export var character_name : String = "On_i_______"
@export var self_talk : String = "“空气太浑浊了...”"
@export var player_state_info : String = "健康"

# tool
@export var tool_available : Array[ToolManager.Tool]
@export var tool : int = -1

# Arrgo
var aggro_value : float = 0.0

# 战斗系统 ———— 受伤
var health_max : float = 100.0
var health_now : float = 100.0
var is_died : bool = false

signal player_hurted

func _process(_delta: float) -> void:
	if player_input_blocked != InputEvents.player_input_blocked:
		player_input_blocked = InputEvents.player_input_blocked

	if InputEvents.suicide():
		player_died()


# ============================= 死了 ==========================

func player_died() -> void:
	if is_died:
		return

	is_died = true
	health_now = 0.0
	can_move = false
	can_interact = false
	can_act = false
	velocity = Vector2.ZERO
	InputEvents.set_player_input_blocked(true)

	GameManager.notify_player_died(self)
 
