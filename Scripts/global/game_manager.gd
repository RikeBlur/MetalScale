class_name game_manager
extends Node

signal Preloaded
signal Loading
signal Loaded
signal player_died

# Arrgo系统信号
signal get_in_arrgo   # aggro_value 从0开始上升时
signal arrgoed        # aggro_value 达到100时
signal not_arrgoed    # aggro_value 从100降下、回到0时（与get_out_arrgo同时发出）
signal get_out_arrgo  # aggro_value 归零时（与not_arrgoed同时发出）

# ====================================================================================================
# ========================================= 全局管理器路径 ===============================================
# ====================================================================================================

const SCENE_MANAGER_PATH = "res://Scripts/global/scene_manager.gd"
const ARCHIVE_MANAGER_PATH = "res://Scripts/global/archive_manager.gd"
const UI_MANAGER_PATH = "res://Scripts/global/ui_manager.gd"
const LIGHTING_MANAGER_PATH = "res://Scripts/system/lighting/lighting_manager.gd"
const BGM_MANAGER_PATH = "res://Scripts/global/bgm_manager.gd"
const PLAYER_SCENE_PATH = "res://System/RPG/entity/controllable/player_Oni.tscn"
const CAMERA_SCENE_PATH = "res://System/RPG/entity/camera.tscn"
const OPENING_MENU_SCENE_PATH = "res://DEMO/AdiosToMe/OpeningMenu.tscn"
const CONFIG_PATH: String = "user://config.tres"
const DEFAULT_GLOBAL_VFX_SHADER_PATH: String = "res://Effect/Shader/default_global_vfx/global_vfx_vhs.gdshader"
const DEFAULT_FIRST_DIALOGUE: String = "ObjectAndCharacter/Interactable/DialogueComponent"

# ====================================================================================================
# ============================================ 游戏状态枚举 =============================================
# ====================================================================================================

# ！！！   DEBUG 选项    ！！！
var debug : bool = false
# ！！！   DEBUG 选项    ！！！

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
var start_scene: String = "2-2"
var start_position: Vector2 = Vector2(870, 290)

# 玩家仇恨状态：0=无仇恨 1=仇恨中（0<aggro<100） 2=完全仇恨（aggro==100）
var player_arrgo: int = 0
var arrgo_in_threshold: float = 10.0
var _prev_aggro_value: float = 0.0       # 上一帧的 aggro_value，用于边沿检测
var _debug_signal_log: Array[String] = [] # 最近发出的 arrgo 信号日志（最多4条）
var _is_player_death_flow_running: bool = false

# 全局配置数据（对应 user://config.tres）
var config_data: ConfigData = null

# BGM音量
var BGM_gain: float = 100.0
# SFX音量
var SFX_gain: float = 100.0
# 全局屏幕亮度（1.0为默认亮度）
var Gamma: float = 1.0
# 默认环境光照颜色
var default_lighting: Color = Color(0.21, 0.157, 0.157, 1.0)


# ====================================================================================================
# ========================================== 节点引用存储 ==============================================
# ====================================================================================================

# 存储实例化的节点引用
var player_instance: player = null
var camera_instance: AdvancedCamera = null
#var startpoint_instance: Node2D = null

# Debug UI元素
var debug_canvas: CanvasLayer = null
var debug_label: Label = null
# 全局亮度控制节点（后处理覆盖，作用于整个视窗）
var gamma_canvas_layer: CanvasLayer = null
var gamma_screen_rect: ColorRect = null
var gamma_material: ShaderMaterial = null
var default_global_vfx_canvas_layer: CanvasLayer = null
var default_global_vfx_screen_rect: ColorRect = null
var default_global_vfx_material: ShaderMaterial = null
var _viewport_size_changed_connected: bool = false
var _opening_menu_mask_tween: Tween = null
var _opening_menu_mask_transition_id: int = 0

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================

func _ready() -> void:
	# 记录游戏启动时间
	game_start_time_msec = Time.get_ticks_msec()
	# 先加载配置，设置好 BGM_gain / SFX_gain / Gamma 变量
	load_config()
	# _ready 期间父节点正在初始化，defer 到下一帧再挂载后处理层（届时会读取 Gamma）
	_ensure_gamma_postprocess_layer.call_deferred()
	
	# 创建debug UI
	if debug:
		_create_debug_ui()
	
	# _ready 期间根节点 blocked，defer 到下一帧再开始预加载
	preloading.call_deferred()
	# 加载完毕执行的函数
	Loaded.connect(_on_loaded)
	if not player_died.is_connected(_on_player_died):
		player_died.connect(_on_player_died)
	
func _process(delta: float) -> void:
	# 仅在运行状态下累加存档时长（毫秒）
	if current_state == GameState.RUNNING:
		game_archive_msec += int(delta * 1000.0)
	
	# 兜底：MENU 状态下如果鼠标不可见，强制显示
	if current_state == GameState.MENU and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		InputEvents.show_mouse()
	
	# 实时监测 aggro_value 边沿，更新 player_arrgo 并发出对应信号
	_update_player_arrgo()
	
	# 更新debug UI
	if debug and debug_label:
		_update_debug_ui()

# ====================================================================================================
# ============================================= 游戏总线 ==============================================
# ====================================================================================================

func preloading() -> void:
	"""
	预加载所有需要的node，播放preloading动画，完成后preloading动画消失，展现主菜单
	PRELOADING -> MENU
	
	包括:
		- packed的玩家节点和camera节点
		- 场景管理器
		- 存档管理器
		- UI管理器
		- 光照管理器
		- 默认视觉效果
	"""	
	print("GameManager: 开始预加载流程...")
	
	# 1. 加载 Player 和 Camera 实例
	_ensure_player_and_camera_instances()
	
	# 2. 加载 SceneManager
	# 负责场景切换和节点存储
	_install_manager(SCENE_MANAGER_PATH, "SceneManager")
	
	# 3. 加载 ArchiveManager (依赖 SceneManager, GameManager)
	# 负责读写存档
	var arc_mgr = _install_manager(ARCHIVE_MANAGER_PATH, "ArchiveManager")
	# 初始化存档管理器
	if arc_mgr and arc_mgr.has_method("check_save_state"):
		arc_mgr.check_save_state()
	
	# 4. 加载 UIManager (依赖 GameManager)
	# 负责UI管理
	var ui_mgr = _install_manager(UI_MANAGER_PATH, "UIManager")
	# 初始化UI管理器
	#if ui_mgr and ui_mgr.has_method("refresh_ui_manager"):
	#	ui_mgr.refresh_ui_manager()
	
	# 5. 加载 LightingManager
	# 负责光照系统管理
	_install_manager(LIGHTING_MANAGER_PATH, "LightingManager")

	# 6. 加载 BGMManager
	# 负责 BGM 播放和音量管理
	_install_manager(BGM_MANAGER_PATH, "BgmManager")

	# 等待一帧，确保所有节点都已进入场景树并执行了_ready
	_ensure_default_global_vfx_layer()
	await get_tree().process_frame
	
	print("GameManager: 所有管理器加载完成")
	emit_signal("Preloaded")
	
	# 切换状态到 MENU
	set_game_state(GameState.MENU)
	_fade_out_opening_menu_mask()


func start_new_game() -> void:
	"""
	开始新游戏
	
	功能:
		- 先将 player 和 camera 临时添加到当前场景
		- 调用 SceneManager 切换到 start_scene
		- 刷新 UIManager
		- 更新游戏状态为 RUNNING
	"""
	if current_state != GameState.MENU:
		print("GameManager: start_new_game ignored because current state is %s" % GameState.keys()[current_state])
		return

	print("GameManager: 开始新游戏")
	
	# 更新游戏状态
	set_game_state(GameState.LOADING)
	game_archive_msec = 0
	_is_player_death_flow_running = false
	_ensure_player_and_camera_instances()
	_reset_player_runtime_state()
	
	# 临时添加玩家和摄像机到当前场景（SceneManager.change_scene 需要它们在场景树中）
	var parent = get_tree().current_scene
	# 设置初始坐标位置
	player_instance.global_position = start_position
	parent.add_child(player_instance)
	parent.add_child(camera_instance)
	camera_instance.target = player_instance
	
	# 等待一帧确保节点完全进入场景树
	await get_tree().process_frame
	
	# 先把 OpeningMenu/mask 淡入到不透明，避免开场 cutscene 前露出菜单
	await _fade_in_opening_menu_mask()

	# 加载开场 cutscene
	CutsceneManager.play_cutscene("test")
	await CutsceneManager.cutscene_playback_finished
	print("GameManager: 开场 cutscene 播放完成")
	
	# 调用 SceneManager 切换到起始场景
	print("GameManager: 切换到起始场景 %s" % start_scene)
	await SceneManager.change_scene(start_scene, 0, start_position)
	
	# 刷新 UIManager
	print("GameManager: 刷新 UI Manager")
	UIManager.refresh_ui_manager()
	
	# 执行初始对话框
	var current_scene = get_tree().current_scene
	var start_dialogue = current_scene.get_node(DEFAULT_FIRST_DIALOGUE)
	start_dialogue.trigger_dialogue()

	# 更新游戏状态为运行中
	Loaded.emit()


func _on_loaded() -> void:
	"""
	游戏加载完成
	由信号触发
	"""
	set_game_state(GameState.RUNNING)
	set_running_state(RunningState.CONTROL)
	_is_player_death_flow_running = false
	print("GameManager: 新游戏启动完成，当前状态: RUNNING")
	InputEvents.hide_mouse()
	_connect_player_arrgo()


func quit_game() -> void:
	"""
	退出游戏
	
	功能:
		- 退出游戏应用程序
	"""
	print("GameManager: 退出游戏")
	get_tree().quit()

# ============================================= 死了 ==============================================

func notify_player_died(dead_player: player = null) -> void:
	"""
	玩家死亡入口：
		- 标记 player.is_died
		- 切换 RunningState → AUTO
		- 阻塞玩家输入
		- 发出 player_died 信号通知各监听方
	"""
	if _is_player_death_flow_running:
		return

	var p: player = dead_player
	if not p or not is_instance_valid(p):
		p = get_player()
	if not p or not is_instance_valid(p):
		push_warning("GameManager: notify_player_died ignored because player is missing")
		return

	_is_player_death_flow_running = true
	player_instance = p
	p.is_died = true
	p.health_now = 0.0
	p.can_move = false
	p.can_interact = false
	p.can_act = false
	p.velocity = Vector2.ZERO
	set_running_state(RunningState.AUTO)

	print("GameManager: player died")
	player_died.emit()


func _on_player_died() -> void:
	"""
	GameManager 自身监听 player_died：
	等待死亡过场完成后，回到 OpeningMenu。
	"""
	print("GameManager: 等待死亡过场动画完成")
	if CutsceneManager.has_signal("death_cutscene_finished"):
		await CutsceneManager.death_cutscene_finished
	else:
		await get_tree().process_frame

	await _return_to_opening_menu_after_death()


func _return_to_opening_menu_after_death() -> void:
	set_game_state(GameState.LOADING)
	InputEvents.show_mouse()

	var result = get_tree().change_scene_to_file(OPENING_MENU_SCENE_PATH)
	if result != OK:
		push_error("GameManager: 无法切换到 OpeningMenu: %s" % OPENING_MENU_SCENE_PATH)
		return

	await _fade_out_opening_menu_mask()

	player_instance = null
	camera_instance = null
	player_arrgo = 0
	_prev_aggro_value = 0.0
	_debug_signal_log.clear()
	_ensure_player_and_camera_instances()
	_reset_player_runtime_state()
	set_game_state(GameState.MENU)
	set_running_state(RunningState.NOPE)
	_is_player_death_flow_running = false
	print("GameManager: 玩家死亡流程结束，已返回 OpeningMenu")


func _fade_out_opening_menu_mask() -> void:
	await _fade_opening_menu_mask(0.0, true)


func _fade_in_opening_menu_mask() -> void:
	await _fade_opening_menu_mask(1.0, false)


func _fade_opening_menu_mask(target_alpha: float, hide_on_finish: bool) -> void:
	var transition_id := _begin_opening_menu_mask_transition()
	var mask := await _get_opening_menu_mask()
	if transition_id != _opening_menu_mask_transition_id:
		return
	if not mask:
		push_warning("GameManager: OpeningMenu/mask not found")
		return

	mask.visible = true

	_opening_menu_mask_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	# mask 取消时间
	_opening_menu_mask_tween.tween_property(mask, "modulate:a", target_alpha, 1.0)
	await _opening_menu_mask_tween.finished

	if transition_id != _opening_menu_mask_transition_id:
		return

	if hide_on_finish:
		mask.visible = false
	_opening_menu_mask_tween = null


func _begin_opening_menu_mask_transition() -> int:
	_opening_menu_mask_transition_id += 1
	if _opening_menu_mask_tween and _opening_menu_mask_tween.is_valid():
		_opening_menu_mask_tween.kill()
	_opening_menu_mask_tween = null
	return _opening_menu_mask_transition_id


func _get_opening_menu_mask() -> Sprite2D:
	for _i in range(5):
		var current_scene := get_tree().current_scene
		if current_scene:
			var mask := current_scene.get_node_or_null("OpeningMenu/mask") as Sprite2D
			if mask:
				return mask
		await get_tree().process_frame

	return null


# ====================================================================================================
# ================================================= ARRGO ==========================================
# ====================================================================================================


func _connect_player_arrgo() -> void:
	"""重置 arrgo 追踪状态（player_arrgo 由 _update_player_arrgo 每帧驱动，无需连接信号）"""
	_prev_aggro_value = 0.0
	player_arrgo = 0
	_debug_signal_log.clear()


func _update_player_arrgo() -> void:
	"""每帧读取 player.aggro_value，检测边沿并发出对应信号"""
	if current_state != GameState.RUNNING:
		return

	var p = get_player()
	if not p or not is_instance_valid(p):
		return
	if not ("aggro_value" in p):
		return

	var val: float = p.aggro_value

	# 边沿1：从0上升到阈值 → get_in_arrgo
	if player_arrgo == 0 and _prev_aggro_value < arrgo_in_threshold and val >= arrgo_in_threshold:
		player_arrgo = 1
		get_in_arrgo.emit()
		_log_arrgo_signal("get_in_arrgo")

	# 边沿2：到达100 → arrgoed
	if _prev_aggro_value < 100.0 and val >= 100.0:
		player_arrgo = 2
		arrgoed.emit()
		_log_arrgo_signal("arrgoed")

	# 边沿3：归零 → not_arrgoed + get_out_arrgo
	if _prev_aggro_value > 0.0 and val == 0.0:
		player_arrgo = 0
		not_arrgoed.emit()
		get_out_arrgo.emit()
		_log_arrgo_signal("not_arrgoed + get_out_arrgo")

	_prev_aggro_value = val


func _log_arrgo_signal(sig_name: String) -> void:
	"""将信号记录追加到 debug 日志（最多保留4条）"""
	var entry := "[%.1fs] %s" % [Time.get_ticks_msec() / 1000.0, sig_name]
	_debug_signal_log.append(entry)
	if _debug_signal_log.size() > 4:
		_debug_signal_log.remove_at(0)


# ====================================================================================================
# ======================================= 获取Player和Camera =========================================
# ====================================================================================================

func _ensure_player_and_camera_instances() -> void:
	"""确保全局 player / camera 实例可用；死亡回主菜单后会重新创建。"""
	if not player_instance or not is_instance_valid(player_instance):
		var player_scene: PackedScene = load(PLAYER_SCENE_PATH)
		if not player_scene:
			push_error("GameManager: 无法加载 Player 场景: %s" % PLAYER_SCENE_PATH)
			return
		player_instance = player_scene.instantiate()

	if not camera_instance or not is_instance_valid(camera_instance):
		var camera_scene: PackedScene = load(CAMERA_SCENE_PATH)
		if not camera_scene:
			push_error("GameManager: 无法加载 Camera 场景: %s" % CAMERA_SCENE_PATH)
			return
		camera_instance = camera_scene.instantiate()

	if camera_instance and is_instance_valid(camera_instance):
		camera_instance.target = player_instance


func _reset_player_runtime_state() -> void:
	"""重置玩家单局运行时状态，供新游戏和死亡回菜单后复用。"""
	if not player_instance or not is_instance_valid(player_instance):
		return

	player_instance.is_died = false
	player_instance.health_now = player_instance.health_max
	player_instance.can_move = true
	player_instance.can_interact = true
	player_instance.can_act = true
	player_instance.velocity = Vector2.ZERO
	InputEvents.set_player_input_blocked(false)


func get_player() -> player:
	"""获取存储的player节点"""
	if not player_instance or not is_instance_valid(player_instance):
		# 如果存储的player无效，尝试从场景树中重新查找
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_instance = players[0]
			print("GameManager: 重新获取player节点")
		else:
			push_warning("GameManager: 未找到player分组的节点")
	return player_instance

func get_camera() -> AdvancedCamera:
	"""获取存储的camera节点"""
	if not camera_instance or not is_instance_valid(camera_instance):
		# 如果存储的camera无效，尝试从场景树中重新查找
		var root = get_tree().current_scene
		if root:
			camera_instance = _find_camera_recursive(root)
			if camera_instance:
				print("GameManager: 重新获取camera节点")
			else:
				push_warning("GameManager: 未找到AdvancedCamera节点")
	return camera_instance

func _find_camera_recursive(node: Node) -> AdvancedCamera:
	"""递归查找AdvancedCamera节点"""
	if node is AdvancedCamera:
		return node
	
	for child in node.get_children():
		var result = _find_camera_recursive(child)
		if result:
			return result
	
	return null

# ====================================================================================================
# =================================================  config  ========================================
# ====================================================================================================

func load_config() -> void:
	"""
	从本地加载 ConfigData（user://config.tres），不存在则使用默认值。
	直接赋值变量，不触发副作用（此时场景树尚未完全就绪）。
	"""
	if FileAccess.file_exists(CONFIG_PATH):
		var loaded = ResourceLoader.load(CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		if loaded is ConfigData:
			config_data = loaded
	if not config_data:
		config_data = ConfigData.new()
	BGM_gain = config_data.BGM_gain
	SFX_gain = config_data.SFX_gain
	Gamma    = config_data.Gamma
	print("GameManager: 配置已加载 (BGM=%.0f SFX=%.0f Gamma=%.2f)" % [BGM_gain, SFX_gain, Gamma])

func save_config() -> void:
	"""将当前变量同步回 config_data 并保存到本地。"""
	if not config_data:
		config_data = ConfigData.new()
	config_data.BGM_gain = BGM_gain
	config_data.SFX_gain = SFX_gain
	config_data.Gamma    = Gamma
	ResourceSaver.save(config_data, CONFIG_PATH)
	print("GameManager: 配置已保存")

func apply_config() -> void:
	"""从 config_data 重新应用所有设置（含副作用，如 Gamma 后处理）。"""
	if not config_data:
		return
	BGM_gain = config_data.BGM_gain
	SFX_gain = config_data.SFX_gain
	set_gamma(config_data.Gamma) 

	
# ====================================================================================================
# ================================================= Gamma设置 ========================================
# ====================================================================================================

func set_gamma(value: float) -> void:
	"""
	设置全局屏幕亮度（2D）
	
	参数:
		value: 亮度值，范围建议 0.3~2.0，1.0 为默认
	"""
	Gamma = clamp(value, 0.1, 3.0)
	_apply_gamma()
	
	# 更新debug UI
	if debug and debug_label:
		_update_debug_ui()

func _ensure_gamma_postprocess_layer() -> void:
	"""确保全局亮度后处理层存在（覆盖整个视窗）"""
	if gamma_canvas_layer and is_instance_valid(gamma_canvas_layer):
		return
	
	var existing = get_tree().root.get_node_or_null("GlobalGammaCanvasLayer")
	if existing and existing is CanvasLayer:
		gamma_canvas_layer = existing
		gamma_screen_rect = gamma_canvas_layer.get_node_or_null("GlobalGammaScreenRect")
	else:
		gamma_canvas_layer = CanvasLayer.new()
		gamma_canvas_layer.name = "GlobalGammaCanvasLayer"
		gamma_canvas_layer.layer = 999
		get_tree().root.add_child(gamma_canvas_layer)
		
		gamma_screen_rect = ColorRect.new()
		gamma_screen_rect.name = "GlobalGammaScreenRect"
		gamma_screen_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gamma_screen_rect.color = Color.WHITE
		gamma_canvas_layer.add_child(gamma_screen_rect)
		# CanvasLayer 不是 Control，anchors 无效，必须手动设置 size
		gamma_screen_rect.position = Vector2.ZERO
		gamma_screen_rect.size = get_viewport().get_visible_rect().size
		_ensure_viewport_size_changed_connected()
	
	if not gamma_material or not is_instance_valid(gamma_material):
		gamma_material = ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float gamma_value = 1.0;

void fragment() {
	vec4 src = texture(screen_texture, SCREEN_UV);
	float safe_gamma = max(gamma_value, 0.001);
	src.rgb = pow(src.rgb, vec3(1.0 / safe_gamma));
	COLOR = src;
	}
"""
		gamma_material.shader = shader
	if gamma_screen_rect:
		_ensure_viewport_size_changed_connected()
		gamma_screen_rect.material = gamma_material
	
	# 节点刚挂载完，立即同步当前 Gamma 值
	_apply_gamma()

func _apply_gamma() -> void:
	"""应用全局亮度到后处理材质"""
	if not gamma_material or not is_instance_valid(gamma_material):
		return
	gamma_material.set_shader_parameter("gamma_value", Gamma)

func _ensure_default_global_vfx_layer() -> void:
	"""纭繚榛樿鍏ㄥ眬 VHS 婊ら暅灞傚瓨鍦紝鍦?GameManager 鑺傜偣涓嬭鐩栨暣涓绐椼€?"""
	if default_global_vfx_canvas_layer and is_instance_valid(default_global_vfx_canvas_layer):
		return

	var existing = get_node_or_null("DefaultGlobalVFXCanvasLayer")
	if existing and existing is CanvasLayer:
		default_global_vfx_canvas_layer = existing
		default_global_vfx_screen_rect = default_global_vfx_canvas_layer.get_node_or_null("DefaultGlobalVFXScreenRect")
	else:
		default_global_vfx_canvas_layer = CanvasLayer.new()
		default_global_vfx_canvas_layer.name = "DefaultGlobalVFXCanvasLayer"
		default_global_vfx_canvas_layer.layer = 9
		add_child(default_global_vfx_canvas_layer)

		default_global_vfx_screen_rect = ColorRect.new()
		default_global_vfx_screen_rect.name = "DefaultGlobalVFXScreenRect"
		default_global_vfx_screen_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		default_global_vfx_screen_rect.color = Color.WHITE
		default_global_vfx_canvas_layer.add_child(default_global_vfx_screen_rect)
		default_global_vfx_screen_rect.position = Vector2.ZERO
		default_global_vfx_screen_rect.size = get_viewport().get_visible_rect().size
		_ensure_viewport_size_changed_connected()

	if not default_global_vfx_material or not is_instance_valid(default_global_vfx_material):
		var shader := load(DEFAULT_GLOBAL_VFX_SHADER_PATH) as Shader
		if not shader:
			push_warning("GameManager: 鏃犳硶鍔犺浇榛樿鍏ㄥ眬 VHS Shader: %s" % DEFAULT_GLOBAL_VFX_SHADER_PATH)
			return
		default_global_vfx_material = ShaderMaterial.new()
		default_global_vfx_material.shader = shader

	if default_global_vfx_screen_rect:
		_ensure_viewport_size_changed_connected()
		default_global_vfx_screen_rect.material = default_global_vfx_material

func _ensure_viewport_size_changed_connected() -> void:
	if _viewport_size_changed_connected:
		return
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_viewport_size_changed_connected = true

func _on_viewport_size_changed() -> void:
	"""视窗尺寸变化时同步更新后处理层的覆盖尺寸"""
	if gamma_screen_rect and is_instance_valid(gamma_screen_rect):
		gamma_screen_rect.size = get_viewport().get_visible_rect().size
	if default_global_vfx_screen_rect and is_instance_valid(default_global_vfx_screen_rect):
		default_global_vfx_screen_rect.size = get_viewport().get_visible_rect().size

	
# ====================================================================================================
# =================================================  功能函数  ========================================
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
	
	
func set_game_state(new_state: GameState) -> void:
	"""
	设置游戏状态
	
	参数:
		new_state: 新的游戏状态
	"""
	current_state = new_state
	print("GameManager: 游戏状态已更改为: %s" % GameState.keys()[new_state])
	
	# 更新debug UI
	if debug and debug_label:
		_update_debug_ui()


func get_game_state() -> GameState:
	"""
	获取当前游戏状态
	
	返回:
		当前的游戏状态
	"""
	return current_state

func set_running_state(new_state: RunningState) -> void:
	"""
	设置运行状态
	
	参数:
		new_state: 新的运行状态
	"""
	current_runnnig_state = new_state
	if new_state == RunningState.AUTO:
		InputEvents.set_player_input_blocked(true)
	elif new_state == RunningState.CONTROL or new_state == RunningState.NOPE:
		InputEvents.set_player_input_blocked(false)
	print("GameManager: 运行状态已更改为: %s" % RunningState.keys()[new_state])
	
	# 更新debug UI
	if debug and debug_label:
		_update_debug_ui()

func get_running_state() -> RunningState:
	"""
	获取当前运行状态
	
	返回:
		当前的运行状态
	"""
	return current_runnnig_state

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

# ====================================================================================================
# =========================================== Debug UI功能 ============================================
# ====================================================================================================

func _create_debug_ui() -> void:
	"""创建调试UI - 在屏幕右下角显示游戏状态"""
	# 创建CanvasLayer（确保UI始终在最上层）
	debug_canvas = CanvasLayer.new()
	debug_canvas.name = "DebugCanvas"
	debug_canvas.layer = 100  # 设置为高层级，确保显示在最上层
	add_child(debug_canvas)
	
	# 创建背景面板
	var panel = PanelContainer.new()
	panel.name = "DebugPanel"
	debug_canvas.add_child(panel)
	
	# 设置面板样式
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.7)  # 半透明黑色背景
	style_box.border_color = Color(0.8, 0.8, 0.8, 0.9)
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(8)
	style_box.content_margin_left = 15
	style_box.content_margin_right = 15
	style_box.content_margin_top = 10
	style_box.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style_box)
	
	# 创建Label
	debug_label = Label.new()
	debug_label.name = "DebugLabel"
	panel.add_child(debug_label)
	
	# 设置Label样式
	debug_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	debug_label.add_theme_font_size_override("font_size", 16)
	
	# 设置面板位置（右下角）
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 10)
	panel.position = Vector2(-10, -10)  # 从右下角偏移一点距离
	
	print("GameManager: Debug UI已创建")
	_update_debug_ui()

func _update_debug_ui() -> void:
	"""更新调试UI显示的内容"""
	if not debug_label:
		return
	
	var state_text = ""
	
	# 获取当前GameState
	var game_state_name = GameState.keys()[current_state]
	state_text += "[游戏状态]\n"
	state_text += "GameState: %s\n" % game_state_name
	
	# 如果是RUNNING状态，显示RunningState
	if current_state == GameState.RUNNING:
		var running_state_name = RunningState.keys()[current_runnnig_state]
		state_text += "RunningState: %s\n" % running_state_name
	
	# 添加额外信息
	state_text += "\n[额外信息]\n"
	state_text += "运行时长: %s\n" % get_runtime_formatted()
	state_text += "存档时长: %.1fs\n" % (game_archive_msec / 1000.0)
	var arrgo_state_name: String = (["无仇恨", "仇恨中", "完全仇恨"] as Array[String])[player_arrgo]
	var aggro_val: float = 0.0
	var p := get_player()
	if p and is_instance_valid(p) and "aggro_value" in p:
		aggro_val = p.aggro_value
	state_text += "player_arrgo: %d (%s) | aggro: %.1f\n" % [player_arrgo, arrgo_state_name, aggro_val]
	state_text += "Gamma: %.2f\n" % Gamma
	state_text += "[Arrgo信号]"
	if _debug_signal_log.is_empty():
		state_text += "  (无)\n"
	else:
		for entry in _debug_signal_log:
			state_text += "  %s\n" % entry
	
	debug_label.text = state_text

func toggle_debug_ui() -> void:
	"""切换debug UI的显示/隐藏"""
	if debug_canvas:
		debug_canvas.visible = not debug_canvas.visible
		print("GameManager: Debug UI 可见性切换为: ", debug_canvas.visible)

func set_debug_mode(enabled: bool) -> void:
	"""设置debug模式"""
	debug = enabled
	if debug and not debug_canvas:
		_create_debug_ui()
	elif not debug and debug_canvas:
		debug_canvas.visible = false
	print("GameManager: Debug模式设置为: ", debug)

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
