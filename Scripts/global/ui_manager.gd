class_name UI_manager
extends Node2D

# UI组件枚举
enum UI_component {
	TOOLBAR,
	SETTINGS,
	GAMECONFIG,
	EXITWINDOW,
	SAVEGAMEWINDOW,
	LOADGAMEWINDOW,
	ARRGOBAR,
	COLLECTWINDOW,
	PLAYERINFO,
	# 谜题
	PUZZLESWITCH,
	PUZZLESWITCH2,
	PUZZLESWITCH3,
	WATERSIGN,
	NEWSPAPER1,
	SAFEBOX
}

# UI统一数据结构：name(UI_component)、scene、layer、stage
const UI_DATA = {
	UI_component.TOOLBAR: {
		"name": UI_component.TOOLBAR,
		"scene": preload("res://System/RPG/UI/toolbar.tscn"),
		"layer": 1,
		"stage": 0
	},
	UI_component.SETTINGS: {
		"name": UI_component.SETTINGS,
		"scene": preload("res://System/RPG/UI/settings.tscn"),
		"layer": 1,
		"stage": 0
	},
	UI_component.GAMECONFIG: {
		"name": UI_component.GAMECONFIG,
		"scene": preload("res://System/RPG/UI/game_config.tscn"),
		"layer": 2,
		"stage": -1
	},
	UI_component.PLAYERINFO: {
		"name": UI_component.PLAYERINFO,
		"scene": preload("res://System/RPG/UI/player_info.tscn"),
		"layer": 2,
		"stage": -1
	},
	UI_component.EXITWINDOW: {
		"name": UI_component.EXITWINDOW,
		"scene": preload("res://System/RPG/UI/windows/exit_window.tscn"),
		"layer": 3,
		"stage": -1
	},
	UI_component.SAVEGAMEWINDOW: {
		"name": UI_component.SAVEGAMEWINDOW,
		"scene": preload("res://System/RPG/UI/save_game.tscn"),
		"layer": 2,
		"stage": -1
	},
	UI_component.LOADGAMEWINDOW: {
		"name": UI_component.LOADGAMEWINDOW,
		"scene": preload("res://System/RPG/UI/load_game.tscn"),
		"layer": 2,
		"stage": -1
	},
	UI_component.ARRGOBAR: {
		"name": UI_component.ARRGOBAR,
		"scene": preload("res://System/RPG/UI/arrgobar.tscn"),
		"layer": 1,
		"stage": 0
	},
	UI_component.COLLECTWINDOW: {
		"name": UI_component.COLLECTWINDOW,
		"scene": preload("res://System/RPG/UI/windows/collected_window.tscn"),
		"layer": 3,
		"stage": -1
	},
	UI_component.PUZZLESWITCH: {
		"name": UI_component.PUZZLESWITCH,
		"scene": preload("res://System/RPG/interact/puzzle/puzzle_switch_1.tscn"),
		"layer": 2,
		"stage": -1
	},
	UI_component.PUZZLESWITCH2: {
		"name": UI_component.PUZZLESWITCH2,
		"scene": preload("res://System/RPG/interact/puzzle/puzzle_switch_2.tscn"),
		"layer": 2,
		"stage": -1
	},
	UI_component.PUZZLESWITCH3: {
		"name": UI_component.PUZZLESWITCH3,
		"scene": preload("res://System/RPG/interact/puzzle/puzzle_switch_3.tscn"),
		"layer": 2,
		"stage": -1
	},
	UI_component.WATERSIGN: {
		"name": UI_component.WATERSIGN,
		"scene": preload("res://System/RPG/interact/puzzle/water_sign.tscn"),
		"layer": 2,
		"stage": -1
	},
	UI_component.NEWSPAPER1: {
		"name": UI_component.NEWSPAPER1,
		"scene": preload("res://System/RPG/interact/puzzle/newspaper_1.tscn"),
		"layer": 2,
		"stage": -1
	},
	UI_component.SAFEBOX: {
		"name": UI_component.SAFEBOX,
		"scene": preload("res://System/RPG/interact/puzzle/safebox.tscn"),
		"layer": 2,
		"stage": -1
	}
}

# Canvas Layers存储
var layers: Dictionary = {}

# UI实例存储
var ui_instances: Dictionary = {}

# 每个layer当前显示的UI组件（只有visible的才算显示）
# 格式: layer_id -> Array[UI_component]
var layer_visible_uis: Dictionary = {}

# Settings相关状态
var is_settings_showing: bool = false

# Toolbar相关状态
var is_toolbar_showing: bool = true  # toolbar默认显示
@export var toolbar_x_offset: float = 300.0  # 隐藏时沿x负轴移出屏幕的距离，应 >= toolbar宽度
const TOOLBAR_SLIDE_DURATION: float = 0.3
var _toolbar_tween: Tween = null
var _toolbar_shown_x: float = 0.0       # 记录toolbar"显示"时的position.x
var _toolbar_x_initialized: bool = false # 首次hide后为true

# Settings相关滑入动画
@export var settings_y_offset: float = 300.0  # 隐藏时沿y负轴移出屏幕的距离，应 >= settings高度
const SETTINGS_SLIDE_DURATION: float = 0.3
var _settings_tween: Tween = null
var _settings_shown_y: float = 0.0        # 记录settings"显示"时的position.y
var _settings_y_initialized: bool = false  # 首次show后为true

# arrgobar相关状态
var is_arrgobar_showing: bool = true  # toolbar默认显示
@export var arrgobar_x_offset: float = -300.0  # 隐藏时沿x负轴移出屏幕的距离，应 >= toolbar宽度
const ARRGOBAR_SLIDE_DURATION: float = 0.3
var _arrgobar_tween: Tween = null
var _arrgobar_shown_x: float = 0.0       # 记录toolbar"显示"时的position.x
var _arrgobar_x_initialized: bool = false # 首次hide后为true


# Shader资源（需要时可以预加载）
@export var ui_layers : Node
@export var layer1_shader: Shader
@export var game_scene_shader: Shader

# 对玩家的引用（用于传递给toolbar等UI）
@export var player_now: CharacterBody2D

# Debug UI（复用 GameManager.debug 开关）
var _debug_canvas: CanvasLayer = null
var _debug_label: Label = null

# ================================ 初始化 ================================

func refresh_ui_manager() -> void:
	# 自动读取UI_LAYERS节点
	if not ui_layers or not is_instance_valid(ui_layers):
		ui_layers = get_tree().current_scene.get_node_or_null("UI_LAYERS")
	# 自动从GameManager读取player
	if not player_now or not is_instance_valid(player_now):
		player_now = GameManager.get_player()
	# 初始化canvas layers
	_initialize_layers()
	# 初始化stage0的UI
	_initialize_stage0_ui()
	# 隐藏（settings / toolbar 默认隐藏）
	_hide_settings()
	_hide_toolbar()
	# 连接 GameManager arrgo 信号
	_connect_arrgobar_signals()
	# 根据当前仇恨状态恢复 ARRGOBAR 可见性（player_arrgo>0 说明仇恨中，保持显示）
	if GameManager.player_arrgo > 0:
		_show_arrgobar()
	else:
		_hide_arrgobar()
	# 初始化 Debug UI（复用 GameManager.debug 开关）
	if GameManager.debug and not _debug_canvas:
		_create_debug_ui()

# ================================ 核心退出功能 ================================

func _process(_delta):
	# 检测退出键，按层级处理 UI 关闭/打开
	if InputEvents.quit_once() or _puzzle_quit_once():
		_handle_quit_pressed()
	
	# 检测Tab键，切换toolbar显示/隐藏
	if Input.is_action_just_pressed("tab"):
		_toggle_toolbar()
	
	# 更新 Debug UI
	if GameManager.debug and _debug_label:
		_update_debug_ui()

func _handle_quit_pressed() -> void:
	# 优先销毁最高层可见UI（先 layer3，再 layer2）
	if _try_close_top_visible_ui_in_layers([3, 2]):
		return
	
	# 如果 settings 正在显示，且没有更高层窗口，则关闭 settings
	if is_settings_showing:
		_toggle_settings()
		return
	
	# 只有 RUNNING + CONTROL 才允许按 ESC 打开 settings
	if GameManager.get_game_state() == GameManager.GameState.RUNNING \
	and GameManager.get_running_state() == GameManager.RunningState.CONTROL:
		_toggle_settings()

func _try_close_top_visible_ui_in_layers(layer_ids: Array[int]) -> bool:
	for layer_id in layer_ids:
		var visible_list = get_visible_uis_in_layer(layer_id)
		if visible_list.size() > 0:
			var top_ui = visible_list[visible_list.size() - 1]
			remove_ui(top_ui)
			return true
	return false


# ============================== 谜题退出机制 ================================

func _puzzle_quit_once() -> bool:
	if not Input.is_action_just_pressed("quit"):
		return false
	if is_ui_visible(UI_component.PUZZLESWITCH):
		return true
	if UI_DATA.has(UI_component.PUZZLESWITCH2) and is_ui_visible(UI_component.PUZZLESWITCH2):
		return true
	if UI_DATA.has(UI_component.PUZZLESWITCH3) and is_ui_visible(UI_component.PUZZLESWITCH3):
		return true
	if UI_DATA.has(UI_component.WATERSIGN) and is_ui_visible(UI_component.WATERSIGN):
		return true
	if UI_DATA.has(UI_component.NEWSPAPER1) and is_ui_visible(UI_component.NEWSPAPER1):
		return true
	if UI_DATA.has(UI_component.SAFEBOX) and is_ui_visible(UI_component.SAFEBOX):
		return true
	return false

# ===================================================================
# ============================ 实例化！！ ============================
# ===================================================================

func instantiate_ui(ui_type: UI_component) -> Node:
	"""实例化指定的UI组件"""
	# 检查是否已经实例化且实例仍然有效
	if ui_instances.has(ui_type):
		var existing_instance = ui_instances[ui_type]
		if is_instance_valid(existing_instance):
			push_warning("UI_manager: UI类型 %d 已经实例化" % ui_type)
			return existing_instance
		else:
			# 实例已失效，从字典中移除
			ui_instances.erase(ui_type)
			print("UI_manager: UI类型 %d 的旧实例已失效，将重新实例化" % ui_type)
	
	var ui_data = UI_DATA.get(ui_type)
	if not ui_data:
		push_error("UI_manager: 未找到UI类型 %d 的数据配置" % ui_type)
		return null
	var target_layer = layers.get(ui_data["layer"])
	
	if not target_layer:
		push_error("UI_manager: 未找到layer %d" % ui_data["layer"])
		return null
	
	# 统一通过 UI_DATA 的 scene 实例化
	var scene: PackedScene = ui_data["scene"]
	if not scene:
		push_error("UI_manager: UI类型 %d 未配置scene" % ui_type)
		return null
	var ui_instance: Node = scene.instantiate()
	
	if not ui_instance:
		push_error("UI_manager: 无法实例化UI类型 %d" % ui_type)
		return null
	
	# 特殊处理：为toolbar设置player引用
	if ui_type == UI_component.TOOLBAR and player_now:
		if "player_now" in ui_instance:
			ui_instance.player_now = player_now
			
	# 特殊处理：为setting设置own_manager引用
	if ui_type == UI_component.SETTINGS :
		if "own_manager" in ui_instance:
			ui_instance.own_manager = self
	
	# 特殊处理：为gameconfig设置own_manager引用
	if ui_type == UI_component.GAMECONFIG :
		if "own_manager" in ui_instance:
			ui_instance.own_manager = self
		_add_ui_to_visible_list(UI_component.GAMECONFIG)
			
	# 特殊处理：为exitwindow设置own_manager引用
	if ui_type == UI_component.EXITWINDOW :
		if "own_manager" in ui_instance:
			ui_instance.own_manager = self
		_add_ui_to_visible_list(UI_component.EXITWINDOW)
			
	# 特殊处理：为savegamewindow设置own_manager引用
	if ui_type == UI_component.SAVEGAMEWINDOW :
		if "own_manager" in ui_instance:
			ui_instance.own_manager = self
		_add_ui_to_visible_list(UI_component.SAVEGAMEWINDOW)
		
	# 特殊处理：为loadgamewindow设置own_manager引用
	if ui_type == UI_component.LOADGAMEWINDOW :
		if "own_manager" in ui_instance:
			ui_instance.own_manager = self
		_add_ui_to_visible_list(UI_component.LOADGAMEWINDOW)
		
	# 特殊处理：为arrgobar设置own_manager引用和player引用，且隐藏掉
	if ui_type == UI_component.ARRGOBAR :
		if "own_manager" in ui_instance:
			ui_instance.own_manager = self
		if "player_now" in ui_instance:
			ui_instance.player_now = player_now
			ui_instance.hide()
	
	# 特殊处理：为collectwindow设置own_manager引用
	if ui_type == UI_component.COLLECTWINDOW :
		if "own_manager" in ui_instance:
			ui_instance.own_manager = self
		_add_ui_to_visible_list(UI_component.COLLECTWINDOW)

	# 特殊处理：为playerinfo设置own_manager引用和player引用
	if ui_type == UI_component.PLAYERINFO :
		if "own_manager" in ui_instance:
			ui_instance.own_manager = self
		if "player_now" in ui_instance:
			ui_instance.player_now = player_now
		_add_ui_to_visible_list(UI_component.PLAYERINFO)
		
# ========================= 谜题场景实例化 ==============================

	if ui_type == UI_component.PUZZLESWITCH :
		if "own_manager" in ui_instance:
			ui_instance.own_manager = self
		if "ui_type" in ui_instance:
			ui_instance.ui_type = UI_component.PUZZLESWITCH
		_add_ui_to_visible_list(UI_component.PUZZLESWITCH)

	if ui_type == UI_component.PUZZLESWITCH2 :
		if "own_manager" in ui_instance:
			ui_instance.own_manager = self
		if "ui_type" in ui_instance:
			ui_instance.ui_type = UI_component.PUZZLESWITCH2
		_add_ui_to_visible_list(UI_component.PUZZLESWITCH2)
		
	if ui_type == UI_component.PUZZLESWITCH3 :
		if "own_manager" in ui_instance:
			ui_instance.own_manager = self
		if "ui_type" in ui_instance:
			ui_instance.ui_type = UI_component.PUZZLESWITCH3
		_add_ui_to_visible_list(UI_component.PUZZLESWITCH3)

	if ui_type == UI_component.WATERSIGN :
		if "own_manager" in ui_instance:
			ui_instance.own_manager = self
		if "ui_type" in ui_instance:
			ui_instance.ui_type = UI_component.WATERSIGN
		_add_ui_to_visible_list(UI_component.WATERSIGN)
	
	if ui_type == UI_component.NEWSPAPER1 :
		if "own_manager" in ui_instance:
			ui_instance.own_manager = self
		if "ui_type" in ui_instance:
			ui_instance.ui_type = UI_component.NEWSPAPER1
		_add_ui_to_visible_list(UI_component.NEWSPAPER1)

	if ui_type == UI_component.SAFEBOX :
		if "own_manager" in ui_instance:
			ui_instance.own_manager = self
		if "ui_type" in ui_instance:
			ui_instance.ui_type = UI_component.SAFEBOX
		_add_ui_to_visible_list(UI_component.SAFEBOX)

	target_layer.add_child(ui_instance)
	
	# 存储实例
	ui_instances[ui_type] = ui_instance

	if ui_instance.has_method("play_ui_enter"):
		ui_instance.call("play_ui_enter")
	
	print("UI_manager: 实例化 UI类型 %d 到 layer %d" % [ui_type, ui_data["layer"]])
	
	return ui_instance


func remove_ui(ui_type: UI_component):
	"""移除UI实例"""
	var ui = ui_instances.get(ui_type)
	if ui:
		# 检查节点是否仍然有效
		if is_instance_valid(ui):
			# 从显示列表移除
			_remove_ui_from_visible_list(ui_type)
			
			# 直接从字典中移除引用，避免循环调用
			ui_instances.erase(ui_type)
			# 使用queue_free安全释放节点
			if ui.has_method("play_ui_exit"):
				ui.call("play_ui_exit", Callable(ui, "queue_free"))
			else:
				ui.queue_free()
			print("UI_manager: 移除 UI类型 %d" % ui_type)
		else:
			# 节点已无效，直接从字典中移除
			_remove_ui_from_visible_list(ui_type)
			ui_instances.erase(ui_type)
			print("UI_manager: UI类型 %d 节点已无效，从字典中移除" % ui_type)
	else:
		print("UI_manager: UI类型 %d 不存在" % ui_type)


func _initialize_layers():
	"""初始化所有canvas layer引用"""
	layers.clear()
	layer_visible_uis.clear()
	
	# 遍历场景根节点的所有子节点，查找CanvasLayer
	if !ui_layers : return
	for child in ui_layers.get_children():
		if child is CanvasLayer:
			# 根据layer属性存储
			var layer_id = child.layer if child.layer > 0 else 1
			layers[layer_id] = child
			# 初始化该layer的显示UI列表
			layer_visible_uis[layer_id] = []
			print("UI_manager: 找到 layer %d - %s" % [layer_id, child.name])

func _initialize_stage0_ui():
	"""初始化stage0阶段的UI"""
	for ui_type in UI_DATA:
		var ui_data = UI_DATA[ui_type]
		if ui_data["stage"] == 0:
			instantiate_ui(ui_type)

# --------------------------------------------------------------------------------------------------
# -------------------------------------------- ESC操作 ----------------------------------------------
# --------------------------------------------------------------------------------------------------
func _toggle_settings():
	"""切换设置界面显示/隐藏"""
	if not is_settings_showing:
		# 显示settings
		_show_settings()
		GameManager.set_running_state(GameManager.RunningState.MENU)
		# RUNNING.MENU状态下鼠标可以操作
		InputEvents.show_mouse()
	else:
		# 隐藏settings
		_hide_settings()
		GameManager.set_running_state(GameManager.RunningState.CONTROL)
		# RUNNING.CONTROL状态下鼠标不可以操作
		InputEvents.hide_mouse()

func _show_settings():
	"""显示设置界面：从y负轴方向平滑滑入"""
	if not ui_instances.has(UI_component.SETTINGS) or not is_instance_valid(ui_instances.get(UI_component.SETTINGS)):
		instantiate_ui(UI_component.SETTINGS)

	var settings = ui_instances.get(UI_component.SETTINGS)
	if settings and is_instance_valid(settings):
		# 首次show时记录"显示"原点，并将节点预置到屏幕外
		if not _settings_y_initialized:
			_settings_shown_y = settings.position.y
			_settings_y_initialized = true
			settings.position.y = _settings_shown_y - settings_y_offset
		settings.show()
		settings.process_mode = Node.PROCESS_MODE_INHERIT
		if settings is Control:
			settings.mouse_filter = Control.MOUSE_FILTER_STOP
		_settings_slide(settings, _settings_shown_y)

	is_settings_showing = true
	_add_ui_to_visible_list(UI_component.SETTINGS)
	_apply_settings_shader(true)
	print("UI_manager: 显示设置界面")

func _hide_settings():
	"""隐藏设置界面：沿y负轴平滑滑出，动画结束后禁用节点"""
	var settings = ui_instances.get(UI_component.SETTINGS)
	if settings and is_instance_valid(settings):
		# 若还未记录"显示"原点，在滑出前先记录（避免init阶段_hide比_show先调用导致原点丢失）
		if not _settings_y_initialized:
			_settings_shown_y = settings.position.y
			_settings_y_initialized = true
		if settings is Control:
			settings.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_settings_slide(settings, _settings_shown_y - settings_y_offset, true)

	is_settings_showing = false
	_remove_ui_from_visible_list(UI_component.SETTINGS)
	_apply_settings_shader(false)
	print("UI_manager: 隐藏设置界面")

func _settings_slide(settings: Control, target_y: float, disable_after: bool = false) -> void:
	"""以平滑曲线将settings的position.y tween到target_y"""
	if _settings_tween and _settings_tween.is_valid():
		_settings_tween.kill()
	_settings_tween = create_tween()
	_settings_tween.set_trans(Tween.TRANS_CUBIC)
	_settings_tween.set_ease(Tween.EASE_IN_OUT)
	_settings_tween.tween_property(settings, "position:y", target_y, SETTINGS_SLIDE_DURATION)
	if disable_after:
		_settings_tween.tween_callback(func() -> void:
			settings.hide()
			settings.process_mode = Node.PROCESS_MODE_DISABLED
		)

func _apply_settings_shader(apply: bool):
	"""应用或移除设置界面的shader效果"""
	# 对layer1应用shader
	var layer1 = layers.get(1)
	if layer1 and layer1_shader:
		if apply:
			# 创建shader material并应用
			var shader_mat = ShaderMaterial.new()
			shader_mat.shader = layer1_shader
			# 这里可以设置shader参数 !!
			# shader_mat.set_shader_parameter("param_name", value)
			
			# 对layer1的子节点应用（需要根据实际节点类型调整）
			for child in layer1.get_children():
				if child is Control or child is CanvasItem:
					child.material = shader_mat
		else:
			# 移除shader
			for child in layer1.get_children():
				if child is Control or child is CanvasItem:
					child.material = null
	
	# 对游戏画面应用shader（非canvas layer）
	if game_scene_shader:
		var root = get_parent()
		if root and apply:
			# 这里需要根据实际游戏场景结构调整
			# 可以对Camera2D或其他节点应用shader
			pass

# --------------------------------------------------------------------------------------------------
# -------------------------------------------- TAB操作 ----------------------------------------------
# --------------------------------------------------------------------------------------------------
func _toggle_toolbar():
	"""切换工具栏显示/隐藏"""
	if not is_toolbar_showing:
		# 显示toolbar
		_show_toolbar()
	else:
		# 隐藏toolbar
		_hide_toolbar()

func _show_toolbar():
	"""显示工具栏：沿x正轴平滑滑入"""
	var toolbar = ui_instances.get(UI_component.TOOLBAR)
	if toolbar and is_instance_valid(toolbar):
		if toolbar is Control:
			toolbar.mouse_filter = Control.MOUSE_FILTER_STOP
		_toolbar_slide(toolbar, _toolbar_shown_x)

	is_toolbar_showing = true
	_add_ui_to_visible_list(UI_component.TOOLBAR)
	print("UI_manager: 显示工具栏")

func _hide_toolbar():
	"""隐藏工具栏：沿x负轴平滑滑出。首次调用立即到位（避免启动闪烁）"""
	var toolbar = ui_instances.get(UI_component.TOOLBAR)
	if toolbar and is_instance_valid(toolbar):
		if not _toolbar_x_initialized:
			# 首次hide：记录"显示"原点，直接跳到隐藏位置，不播放动画
			_toolbar_shown_x = toolbar.position.x
			_toolbar_x_initialized = true
			toolbar.position.x = _toolbar_shown_x - toolbar_x_offset
		else:
			_toolbar_slide(toolbar, _toolbar_shown_x - toolbar_x_offset)
		if toolbar is Control:
			toolbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 注意：不修改process_mode，保持toolbar的处理过程

	is_toolbar_showing = false
	_remove_ui_from_visible_list(UI_component.TOOLBAR)
	print("UI_manager: 隐藏工具栏")

func _toolbar_slide(toolbar: Control, target_x: float) -> void:
	"""以平滑曲线将toolbar的position.x tween到target_x"""
	if _toolbar_tween and _toolbar_tween.is_valid():
		_toolbar_tween.kill()
	_toolbar_tween = create_tween()
	_toolbar_tween.set_trans(Tween.TRANS_CUBIC)
	_toolbar_tween.set_ease(Tween.EASE_IN_OUT)
	_toolbar_tween.tween_property(toolbar, "position:x", target_x, TOOLBAR_SLIDE_DURATION)

# --------------------------------------------------------------------------------------------------
# -------------------------------------------- ARRGOBAR操作 -----------------------------------------
# --------------------------------------------------------------------------------------------------
func _connect_arrgobar_signals() -> void:
	"""连接 GameManager 的 arrgo 信号到 ARRGOBAR 显示控制"""
	if not GameManager.get_in_arrgo.is_connected(_show_arrgobar):
		GameManager.get_in_arrgo.connect(_show_arrgobar)
	if not GameManager.get_out_arrgo.is_connected(_hide_arrgobar):
		GameManager.get_out_arrgo.connect(_hide_arrgobar)


func _show_arrgobar() -> void:
	"""显示 ARRGOBAR（立即显示）"""
	var arrgobar = ui_instances.get(UI_component.ARRGOBAR)
	if arrgobar and is_instance_valid(arrgobar):
		arrgobar.show()
		if arrgobar is Control:
			arrgobar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_arrgobar_slide(arrgobar, _arrgobar_shown_x)
		_add_ui_to_visible_list(UI_component.ARRGOBAR)
		print("UI_manager: 显示 ARRGOBAR")


func _hide_arrgobar() -> void:
	"""隐藏 ARRGOBAR（立即隐藏）"""
	var arrgobar = ui_instances.get(UI_component.ARRGOBAR)
	if arrgobar and is_instance_valid(arrgobar):
		if not _arrgobar_x_initialized:
			# 首次hide：记录"显示"原点，直接跳到隐藏位置，不播放动画
			_arrgobar_shown_x = arrgobar.position.x
			_arrgobar_x_initialized = true
			arrgobar.position.x = _arrgobar_shown_x - arrgobar_x_offset
		else:
			_arrgobar_slide(arrgobar, _arrgobar_shown_x - arrgobar_x_offset)
		if arrgobar is Control:
			arrgobar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	is_arrgobar_showing = false
	_remove_ui_from_visible_list(UI_component.ARRGOBAR)
	print("UI_manager: 隐藏注目值")

func _arrgobar_slide(arrgobar: Control, target_x: float) -> void:
	"""以平滑曲线将toolbar的position.x tween到target_x"""
	if _arrgobar_tween and _arrgobar_tween.is_valid():
		_arrgobar_tween.kill()
	_arrgobar_tween = create_tween()
	_arrgobar_tween.set_trans(Tween.TRANS_CUBIC)
	_arrgobar_tween.set_ease(Tween.EASE_IN_OUT)
	_arrgobar_tween.tween_property(arrgobar, "position:x", target_x, ARRGOBAR_SLIDE_DURATION)


# --------------------------------------------------------------------------------------------------
# ---------------------------------------- COLLECTWINDOW操作 ----------------------------------------
# --------------------------------------------------------------------------------------------------
func show_collect_window(tool_name: String) -> void:
	"""
	显示工具收集提示窗口
	
	参数:
		tool_name: 工具的显示名称
	"""
	# 实例化窗口
	var collect_window = instantiate_ui(UI_component.COLLECTWINDOW)
	if not collect_window or not is_instance_valid(collect_window):
		push_error("UI_manager: 无法实例化 COLLECTWINDOW")
		return
	
	# 设置显示文本
	if collect_window.has_method("set_tool_name"):
		collect_window.set_tool_name(tool_name)
	
	print("UI_manager: 显示收集窗口 - 工具: %s" % tool_name)
	
# --------------------------------------------------------------------------------------------------
# ------------------------------------------ 工具函数 ----------------------------------------------
# --------------------------------------------------------------------------------------------------


func _add_ui_to_visible_list(ui_type: UI_component) -> void:
	"""将UI添加到其layer的可见列表中"""
	var ui_data = UI_DATA.get(ui_type)
	if not ui_data:
		return
	
	var layer_id = ui_data["layer"]
	
	# 确保该layer的列表存在
	if not layer_visible_uis.has(layer_id):
		layer_visible_uis[layer_id] = []
	
	# 如果UI不在列表中，添加它
	var visible_list = layer_visible_uis[layer_id]
	if not visible_list.has(ui_type):
		visible_list.append(ui_type)
		print("UI_manager: UI类型 %d 添加到 layer %d 的显示列表" % [ui_type, layer_id])

func _remove_ui_from_visible_list(ui_type: UI_component) -> void:
	"""将UI从其layer的可见列表中移除"""
	var ui_data = UI_DATA.get(ui_type)
	if not ui_data:
		return
	
	var layer_id = ui_data["layer"]
	
	# 如果该layer的列表存在，从中移除UI
	if layer_visible_uis.has(layer_id):
		var visible_list = layer_visible_uis[layer_id]
		var index = visible_list.find(ui_type)
		if index >= 0:
			visible_list.erase(ui_type)
			print("UI_manager: UI类型 %d 从 layer %d 的显示列表移除" % [ui_type, layer_id])

func get_visible_uis_in_layer(layer_id: int) -> Array:
	"""
	获取指定layer当前显示的所有UI组件
	
	参数:
		layer_id: layer的ID
	
	返回:
		该layer当前显示的UI_component数组
	"""
	return layer_visible_uis.get(layer_id, []).duplicate()

func is_ui_visible(ui_type: UI_component) -> bool:
	"""
	检查指定UI是否当前显示（visible）
	
	参数:
		ui_type: UI组件类型
	
	返回:
		true表示UI当前显示，false表示隐藏或不存在
	"""
	var ui_data = UI_DATA.get(ui_type)
	if not ui_data:
		return false
	
	var layer_id = ui_data["layer"]
	if not layer_visible_uis.has(layer_id):
		return false
	
	return layer_visible_uis[layer_id].has(ui_type)

func get_ui_instance(ui_type: UI_component) -> Node:
	"""获取UI实例"""
	return ui_instances.get(ui_type)

func safe_remove_all_ui():
	"""安全移除所有UI实例"""
	print("UI_manager: 开始安全移除所有UI实例")
	for ui_type in ui_instances.keys():
		remove_ui(ui_type)
	# 清空显示列表
	layer_visible_uis.clear()
	print("UI_manager: 完成移除所有UI实例")


func prepare_for_scene_change() -> void:
	"""场景切换前释放可见UI，避免旧UI状态带到新场景"""
	print("UI_manager: 场景切换前清理可见UI")
	var should_restore_control := is_settings_showing and GameManager.get_running_state() == GameManager.RunningState.MENU
	_kill_ui_tweens()
	_sync_layer1_visible_ui_state()

	var visible_ui_types: Array = []
	for layer_id in layer_visible_uis.keys():
		for ui_type in layer_visible_uis[layer_id]:
			if not visible_ui_types.has(ui_type):
				visible_ui_types.append(ui_type)

	for ui_type in visible_ui_types:
		_free_ui_instance_immediately(ui_type)

	layer_visible_uis.clear()
	layers.clear()
	ui_layers = null
	_reset_ui_visibility_state()
	if should_restore_control:
		GameManager.set_running_state(GameManager.RunningState.CONTROL)
		InputEvents.hide_mouse()


func _sync_layer1_visible_ui_state() -> void:
	if is_settings_showing:
		_add_ui_to_visible_list(UI_component.SETTINGS)
	if is_toolbar_showing:
		_add_ui_to_visible_list(UI_component.TOOLBAR)
	if is_arrgobar_showing:
		_add_ui_to_visible_list(UI_component.ARRGOBAR)


func _free_ui_instance_immediately(ui_type: UI_component) -> void:
	var ui = ui_instances.get(ui_type)
	ui_instances.erase(ui_type)
	if ui and is_instance_valid(ui):
		ui.queue_free()


func _kill_ui_tweens() -> void:
	if _toolbar_tween and _toolbar_tween.is_valid():
		_toolbar_tween.kill()
	if _settings_tween and _settings_tween.is_valid():
		_settings_tween.kill()
	if _arrgobar_tween and _arrgobar_tween.is_valid():
		_arrgobar_tween.kill()
	_toolbar_tween = null
	_settings_tween = null
	_arrgobar_tween = null


func _reset_ui_visibility_state() -> void:
	is_settings_showing = false
	is_toolbar_showing = true
	is_arrgobar_showing = true
	_settings_y_initialized = false
	_toolbar_x_initialized = false
	_arrgobar_x_initialized = false


func safe_remove_self():
	"""安全地释放UI_manager自身"""
	print("UI_manager: 开始安全释放自身")
	
	# 先移除所有UI实例
	safe_remove_all_ui()
	
	# 清理引用
	layers.clear()
	ui_instances.clear()
	player_now = null
	
	# 使用queue_free()安全释放节点
	queue_free()
	print("UI_manager: 安全释放自身完成")

# ====================================================================================================
# ============================================ Debug UI =============================================
# ====================================================================================================

func _create_debug_ui() -> void:
	"""创建 Debug UI —— 右上角半透明面板，显示 ui_instances 和 visible_list"""
	_debug_canvas = CanvasLayer.new()
	_debug_canvas.name = "UIManagerDebugCanvas"
	_debug_canvas.layer = 101  # 比 GameManager debug(100) 高一层，确保不遮挡
	add_child(_debug_canvas)
	
	var panel := PanelContainer.new()
	panel.name = "UIManagerDebugPanel"
	_debug_canvas.add_child(panel)
	
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color(0.05, 0.05, 0.2, 0.75)
	style_box.border_color = Color(0.4, 0.6, 1.0, 0.9)
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(8)
	style_box.content_margin_left = 12
	style_box.content_margin_right = 12
	style_box.content_margin_top = 8
	style_box.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style_box)
	
	_debug_label = Label.new()
	_debug_label.name = "UIManagerDebugLabel"
	_debug_label.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0, 1.0))
	_debug_label.add_theme_font_size_override("font_size", 14)
	panel.add_child(_debug_label)
	
	# 固定右上角：右边缘贴屏幕右侧，向左向下增长
	panel.anchor_left   = 1.0
	panel.anchor_right  = 1.0
	panel.anchor_top    = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_right  = -10.0
	panel.offset_top    = 10.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN  # 向左增长
	panel.grow_vertical   = Control.GROW_DIRECTION_END    # 向下增长
	
	print("UI_manager: Debug UI 已创建")
	_update_debug_ui()


func _update_debug_ui() -> void:
	"""刷新 Debug 面板内容"""
	if not _debug_label:
		return
	
	var text := "[UI_manager Debug]\n"
	
	# ── 已实例化的 UI ──
	text += "\n[Instances] (%d)\n" % ui_instances.size()
	if ui_instances.is_empty():
		text += "  (空)\n"
	else:
		for key in ui_instances:
			var inst = ui_instances[key]
			var valid: bool = inst != null and is_instance_valid(inst)
			text += "  %s : %s\n" % [UI_component.keys()[key], "OK" if valid else "INVALID"]
	
	# ── 各 layer 的 visible_list ──
	text += "\n[Visible List]\n"
	if layer_visible_uis.is_empty():
		text += "  (空)\n"
	else:
		for layer_id in layer_visible_uis:
			var arr: Array = layer_visible_uis[layer_id]
			var names := []
			for comp in arr:
				names.append(UI_component.keys()[comp])
			text += "  L%d: %s\n" % [layer_id, ", ".join(names) if names else "—"]
	
	_debug_label.text = text
		
