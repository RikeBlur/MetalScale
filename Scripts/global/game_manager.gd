class_name game_manager
extends Node

signal Preloaded
signal Loading
signal Loaded

# ====================================================================================================
# ========================================= 全局管理器路径 ===============================================
# ====================================================================================================

const GLOBAL_FUNCTION_PATH = "res://Scripts/global/GLOBAL_FUNCTION.gd"
const SCENE_MANAGER_PATH = "res://Scripts/global/scene_manager.gd"
const ARCHIVE_MANAGER_PATH = "res://Scripts/global/archive_manager.gd"
const UI_MANAGER_PATH = "res://Scripts/global/ui_manager.gd"

# ====================================================================================================
# ============================================ 游戏状态枚举 =============================================
# ====================================================================================================

# 游戏状态枚举
enum GameState {
	PRELOADING,
	MENU,
	RUNNING,
	LOADING,
	OVER
}

enum RunningState {
	NOPE,
	CONTROL,
	MENU,
	AUTO
}

# 当前游戏状态
var current_state: GameState = GameState.PRELOADING
var current_runnnig_state: RunningState = RunningState.NOPE

# 游戏启动时间（毫秒）（单次运行）
var game_start_time_msec: int = 0

# 游戏总体时间（毫秒）（本个存档）
var game_archive_msec: int = 0

# 游戏初次加载时玩家的世界坐标位置
var start_position: Vector2 = Vector2(0, -150)

# 玩家是否处于仇恨状态？
var player_arrgo: bool = false

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

func _ready() -> void:
	# 记录游戏启动时间
	game_start_time_msec = Time.get_ticks_msec()
	preloading()
	Loaded.connect(_on_loaded)
	
func _process(delta: float) -> void:
	# 仅在运行状态下累加存档时长（毫秒）
	if current_state == GameState.RUNNING:
		game_archive_msec += int(delta * 1000.0)

# ====================================================================================================
# ============================================= 游戏总线 ==============================================
# ====================================================================================================

func preloading() -> void:
	"""
	预加载所有需要的node，播放preloading动画，完成后preloading动画消失，展现主菜单
	PRELOADING -> MENU
	
	包括:
		- 存档管理器
		- packed的玩家节点和camera节点（GlobalFunction）
		- 场景管理器
		- UI管理器
	"""	
	print("GameManager: 开始预加载流程...")
	
	# 1. 加载 GlobalFunction (基础依赖)
	# 所有的全局查找函数都在这里，必须最先加载
	var gf = _install_manager(GLOBAL_FUNCTION_PATH, "GlobalFunction")
	# 加载 gf 所需要的玩家节点和摄像机节点
	# 加载 Player 场景
	var player_scene: PackedScene = load("res://System/RPG/entity/controllable/player_Oni.tscn")
	player_instance = player_scene.instantiate()
	gf.stored_player = player_instance
	# 加载 Camera 场景
	var camera_scene: PackedScene = load("res://System/RPG/entity/camera.tscn")
	camera_instance = camera_scene.instantiate()
	camera_instance.target = player_instance
	gf.stored_camera = camera_instance 
	
	# 2. 加载 SceneManager (依赖 GlobalFunction)
	# 负责场景切换和节点存储，ArchiveManager依赖它
	_install_manager(SCENE_MANAGER_PATH, "SceneManager")
	
	# 3. 加载 ArchiveManager (依赖 SceneManager, GlobalFunction)
	# 负责读写存档
	var arc_mgr = _install_manager(ARCHIVE_MANAGER_PATH, "ArchiveManager")
	# 初始化UI管理器
	if arc_mgr and arc_mgr.has_method("check_save_state"):
		arc_mgr.check_save_state()
	
	# 4. 加载 UIManager (依赖 GlobalFunction)
	# 负责UI管理
	var ui_mgr = _install_manager(UI_MANAGER_PATH, "UIManager")
	# 初始化UI管理器
	if ui_mgr and ui_mgr.has_method("refresh_ui_manager"):
		ui_mgr.refresh_ui_manager()
	
	# 等待一帧，确保所有节点都已进入场景树并执行了_ready
	await get_tree().process_frame
	
	print("GameManager: 所有管理器加载完成")
	emit_signal("Preloaded")
	
	# 切换状态到 MENU
	set_game_state(GameState.MENU)


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
	game_archive_msec = 0
	
	# 加载玩家和摄像机
	var parent = get_tree().current_scene
	parent.add_child(player_instance)
	parent.add_child(camera_instance)
	
	# 加载起始点
	var startpoint_scene: PackedScene = load("res://System/RPG/interact/door/door_front.tscn")
	startpoint_instance = startpoint_scene.instantiate()
	startpoint_instance.scene_to = "level_1_2"
	startpoint_instance.global_position = start_position
	parent.add_child(startpoint_instance)
	
	# 更新游戏状态为运行中
	current_state = GameState.RUNNING
	current_runnnig_state = RunningState.CONTROL
	print("GameManager: 新游戏启动完成，当前状态: RUNNING")
	InputEvents.hide_mouse()

func _on_loaded() -> void:
	"""
	游戏加载完成
	由信号触发
	"""
	current_state = GameState.RUNNING
	current_runnnig_state = RunningState.CONTROL
	print("GameManager: 新游戏启动完成，当前状态: RUNNING")
	InputEvents.hide_mouse()


func quit_game() -> void:
	"""
	退出游戏
	
	功能:
		- 退出游戏应用程序
	"""
	print("GameManager: 退出游戏")
	get_tree().quit()


# ====================================================================================================
# ================================================= 工具函数 ==========================================
# ====================================================================================================


func _install_manager(script_path: String, node_name: String) -> Node:
	"""
	实例化并挂载管理器节点到根节点
	
	参数:
		script_path: 脚本资源路径
		node_name: 挂载后的节点名称（用于 get_node("/root/Name")）
	
	返回:
		实例化的节点引用
	"""
	# 检查节点是否已存在（兼容Autoload情况，防止重复加载）
	var existing_node = get_node_or_null("/root/" + node_name)
	if existing_node:
		print("GameManager: %s 已存在，跳过加载" % node_name)
		return existing_node
		
	# 加载脚本
	var script = load(script_path)
	if not script:
		push_error("GameManager: 无法加载脚本: %s" % script_path)
		return null
		
	# 实例化并设置名称
	var instance = script.new()
	instance.name = node_name
	
	# 挂载到根节点
	get_tree().root.add_child(instance)
	print("GameManager: 已挂载 %s" % node_name)
	
	return instance


# ====================================================================================================
# ====================================================================================================
# ====================================================================================================


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

func get_runtime_seconds() -> float:
	"""
	获取游戏运行时间（秒）
	
	返回:
		从游戏启动到现在的运行时间（秒）
	"""
	return (Time.get_ticks_msec() - game_start_time_msec) / 1000.0

func get_runtime_formatted() -> String:
	"""
	获取格式化的游戏运行时间
	
	返回:
		格式为 "HH:MM:SS" 的时间字符串
	"""
	var total_seconds = int(get_runtime_seconds())
	var hours = int(total_seconds / 3600.0)
	var minutes = int((total_seconds % 3600) / 60.0)
	var seconds = total_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
