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
	COLLECTWINDOW
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

# ARRGOBAR 延迟隐藏控制
var _arrgobar_should_hide: bool = false

# Shader资源（需要时可以预加载）
@export var ui_layers : Node
@export var layer1_shader: Shader
@export var game_scene_shader: Shader

# 对玩家的引用（用于传递给toolbar等UI）
@export var player_now: CharacterBody2D

# Debug UI（复用 GameManager.debug 开关）
var _debug_canvas: CanvasLayer = null
var _debug_label: Label = null

	
func refresh_ui_manager() -> void:
	# 自动读取UI_LAYERS节点
	if not ui_layers:
		ui_layers = get_tree().current_scene.get_node_or_null("UI_LAYERS")
	# 自动从GameManager读取player
	if not player_now:
		player_now = GameManager.get_player()
	# 初始化canvas layers
	_initialize_layers()
	# 初始化stage0的UI
	_initialize_stage0_ui()
	# 隐藏
	_hide_settings()
	_hide_toolbar()
	_hide_arrgobar()
	# 连接玩家 ArrgoComponent 信号以控制 ARRGOBAR 显示
	_connect_arrgobar_signals()
	# 初始化 Debug UI（复用 GameManager.debug 开关）
	if GameManager.debug and not _debug_canvas:
		_create_debug_ui()

func _process(_delta):
	# 检测退出键，按层级处理 UI 关闭/打开
	if InputEvents.quit_once():
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
			
	
	# 添加到对应layer
	target_layer.add_child(ui_instance)
	
	# 存储实例
	ui_instances[ui_type] = ui_instance
	
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
	"""显示设置界面"""
	# 实例化settings（如果还未实例化或实例已失效）
	if not ui_instances.has(UI_component.SETTINGS) or not is_instance_valid(ui_instances.get(UI_component.SETTINGS)):
		instantiate_ui(UI_component.SETTINGS)
	else:
		# 如果已存在且有效，显示它
		var settings = ui_instances[UI_component.SETTINGS]
		settings.show()  # 使用 show() 方法
		# 确保可以接收输入
		if settings is Control:
			settings.mouse_filter = Control.MOUSE_FILTER_STOP
		# 启用处理
		settings.process_mode = Node.PROCESS_MODE_INHERIT
	
	is_settings_showing = true
	
	# 添加到显示列表
	_add_ui_to_visible_list(UI_component.SETTINGS)
	
	# 应用shader效果
	_apply_settings_shader(true)
	
	print("UI_manager: 显示设置界面")

func _hide_settings():
	"""隐藏设置界面"""
	var settings = ui_instances.get(UI_component.SETTINGS)
	if settings and is_instance_valid(settings):
		settings.hide()  # 使用 hide() 方法
		# 确保不接收任何输入（多重保护）
		if settings is Control:
			settings.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 禁用处理，防止任何交互
		settings.process_mode = Node.PROCESS_MODE_DISABLED
	
	is_settings_showing = false
	
	# 从显示列表移除
	_remove_ui_from_visible_list(UI_component.SETTINGS)
	
	# 移除shader效果
	_apply_settings_shader(false)
	
	print("UI_manager: 隐藏设置界面")

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
	"""连接玩家 ArrgoComponent 的信号到 ARRGOBAR 显示控制"""
	if not player_now or not is_instance_valid(player_now):
		return
	
	var arrgo = player_now.get_node_or_null("arrgo_component")
	if not arrgo or not (arrgo is ArrgoComponent):
		return
	
	# 连接信号：get_caught 时显示，get_uncaught 时隐藏
	if not arrgo.get_caught.is_connected(_on_player_get_caught):
		arrgo.get_caught.connect(_on_player_get_caught)
	if not arrgo.get_uncaught.is_connected(_on_player_get_uncaught):
		arrgo.get_uncaught.connect(_on_player_get_uncaught)


func _on_player_get_caught() -> void:
	"""玩家被发现时显示 ARRGOBAR"""
	_show_arrgobar()


func _on_player_get_uncaught() -> void:
	"""玩家脱离视线时隐藏 ARRGOBAR"""
	_hide_arrgobar()


func _show_arrgobar() -> void:
	"""显示 ARRGOBAR（立即显示）"""
	# 取消任何待执行的隐藏
	_arrgobar_should_hide = false
	
	var arrgobar = ui_instances.get(UI_component.ARRGOBAR)
	if arrgobar and is_instance_valid(arrgobar):
		arrgobar.show()
		if arrgobar is Control:
			arrgobar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_add_ui_to_visible_list(UI_component.ARRGOBAR)
		print("UI_manager: 显示 ARRGOBAR")


func _hide_arrgobar() -> void:
	"""隐藏 ARRGOBAR（延迟约 5 秒后隐藏）"""
	_arrgobar_should_hide = true
	
	# 延迟 5 秒
	await get_tree().create_timer(5.0).timeout
	
	# 5 秒后检查是否仍需隐藏（期间可能又被 show 取消了）
	if not _arrgobar_should_hide:
		return
	
	var arrgobar = ui_instances.get(UI_component.ARRGOBAR)
	if arrgobar and is_instance_valid(arrgobar):
		arrgobar.hide()
		_remove_ui_from_visible_list(UI_component.ARRGOBAR)
		print("UI_manager: 隐藏 ARRGOBAR（延迟5秒后）")

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
		
