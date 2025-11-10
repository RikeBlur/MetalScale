class_name BaseLevel
extends Node2D

# 玩家进入场景时的初始位置（全局坐标）
@export var player_initial_position: Array[Vector2]

# 玩家进入场景时的初始朝向（Vector2方向，如Vector2.DOWN, Vector2.UP等）
@export var player_initial_direction: Array[Vector2]

# 玩家节点引用（可选，如果场景中已有player节点可指定）
@export var player_node: player = null

# 转产动画
@export var transition_player : AnimationPlayer = null


func _ready():
	player_node = GlobalFunction.stored_player
	UIManager.refresh_ui_manager()


func apply_initial_values_to_player(target_player: player, index: int) -> void:
	"""
	将初始位置和朝向应用到指定的玩家节点
	
	参数:
		target_player: 要应用初始值的玩家节点
	"""
	if not target_player:
		push_warning("BaseLevel: target_player为空，无法应用初始值")
		return
	
	# 设置玩家位置（全局坐标）
	target_player.global_position = player_initial_position[index]
	
	# 设置玩家朝向
	target_player.player_direction = player_initial_direction[index]
	target_player.player_last_direction = player_initial_direction[index]
	
	print("BaseLevel: 已将初始位置 %s 和朝向 %s 应用到玩家" % [player_initial_position, player_initial_direction])
