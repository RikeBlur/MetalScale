class_name game_manager
extends Node


# ====================================================================================================
# ============================================ 游戏状态枚举 =============================================
# ====================================================================================================

# 游戏状态枚举
enum GameState {
	MENU,           # 主菜单状态
	RUNNING,        # 游戏运行中
	PAUSED,         # 游戏暂停
	LOADING,        # 加载中
	GAME_OVER       # 游戏结束
}

# 当前游戏状态
var current_state: GameState = GameState.MENU

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================



# ====================================================================================================
# ========================================== 场景预加载资源 ==============================================
# ====================================================================================================

# Player预加载场景（可在编辑器中配置或代码中设置）
@export var packed_player: PackedScene

# Camera预加载场景（使用脚本创建）
@export var packed_camera: PackedScene

# 起始点预加载场景
@export var packed_startpoint: PackedScene

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================



# ====================================================================================================
# ========================================== 节点实例化接口 ==============================================
# ====================================================================================================

# 实例化节点的父节点（可通过此接口控制实例化位置）
var player_parent: Node = null
var camera_parent: Node = null
var startpoint_parent: Node = null

# 起始点位置（如果不设置startpoint场景，可以直接用这个）
var start_position: Vector2 = Vector2.ZERO

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================



# ====================================================================================================
# ========================================== 节点引用存储 ==============================================
# ====================================================================================================

# 存储实例化的节点引用
var player_instance: player = null
var camera_instance: AdvancedCamera = null
var startpoint_instance: Node2D = null

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================



# ====================================================================================================
# ============================================ 游戏管理方法 =============================================
# ====================================================================================================

func start_new_game() -> void:
	"""
	开始新游戏
	
	功能:
		- 实例化 player 和 camera
		- 设置 camera 的 target 为 player
		- 实例化 startpoint（如果有配置）
		- 更新游戏状态为 RUNNING
	"""
	print("GameManager: 开始新游戏")
	
	# 更新游戏状态
	current_state = GameState.LOADING
	
	# 1. 实例化 Player
	if packed_player:
		player_instance = packed_player.instantiate() as player
		if player_instance:
			# 确定父节点
			var parent = player_parent if player_parent else get_tree().current_scene
			if parent:
				parent.add_child(player_instance)
				print("GameManager: Player 已实例化并添加到场景")
			else:
				push_error("GameManager: 无法找到 player 的父节点")
				return
		else:
			push_error("GameManager: Player 实例化失败")
			return
	else:
		push_warning("GameManager: packed_player 未设置")
	
	# 2. 实例化 Camera
	if packed_camera:
		camera_instance = packed_camera.instantiate() as AdvancedCamera
	else:
		# 如果没有预设场景，创建一个默认的 Camera
		camera_instance = AdvancedCamera.new()
		print("GameManager: 使用默认 Camera")
	
	if camera_instance:
		# 确定父节点
		var parent = camera_parent if camera_parent else get_tree().current_scene
		if parent:
			parent.add_child(camera_instance)
			
			# 设置 camera 的 target 为 player
			if player_instance:
				camera_instance.target = player_instance
				print("GameManager: Camera 已实例化并设置 target 为 player")
			else:
				push_warning("GameManager: Player 未实例化，无法设置 camera target")
		else:
			push_error("GameManager: 无法找到 camera 的父节点")
			return
	else:
		push_error("GameManager: Camera 实例化失败")
		return
	
	# 3. 实例化 Startpoint
	if packed_startpoint:
		startpoint_instance = packed_startpoint.instantiate() as Node2D
		if startpoint_instance:
			# 确定父节点
			var parent = startpoint_parent if startpoint_parent else get_tree().current_scene
			if parent:
				parent.add_child(startpoint_instance)
				
				# 如果 player 存在，将其移动到起始点位置
				if player_instance and startpoint_instance:
					player_instance.global_position = startpoint_instance.global_position
					print("GameManager: Startpoint 已实例化，player 移动到起始点")
			else:
				push_warning("GameManager: 无法找到 startpoint 的父节点")
		else:
			push_warning("GameManager: Startpoint 实例化失败")
	else:
		# 如果没有 startpoint 场景，使用 start_position
		if player_instance:
			player_instance.global_position = start_position
			print("GameManager: 使用默认起始位置: %s" % start_position)
	
	# 更新游戏状态为运行中
	current_state = GameState.RUNNING
	print("GameManager: 新游戏启动完成，当前状态: RUNNING")


func quit_game() -> void:
	"""
	退出游戏
	
	功能:
		- 退出游戏应用程序
	"""
	print("GameManager: 退出游戏")
	get_tree().quit()


func set_game_state(new_state: GameState) -> void:
	"""
	设置游戏状态
	
	参数:
		new_state: 新的游戏状态
	"""
	current_state = new_state
	print("GameManager: 游戏状态已更改为: %s" % GameState.keys()[new_state])


func get_game_state() -> GameState:
	"""
	获取当前游戏状态
	
	返回:
		当前的游戏状态
	"""
	return current_state


func is_game_running() -> bool:
	"""
	检查游戏是否正在运行
	
	返回:
		true 表示游戏正在运行，false 表示不在运行
	"""
	return current_state == GameState.RUNNING

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
