class_name UI_manager
extends Node2D

# UI组件枚举
enum UI_component {
	TOOLBAR,
	SETTINGS
}

# UI场景预加载
const TOOLBAR_SCENE = preload("res://System/RPG/tools/toolbar.tscn")
# settings场景路径（暂时使用字符串，待场景创建后可改为preload）
# const SETTINGS_SCENE_PATH = "res://Scripts/system/view/UI/settings/settings.tscn"

# UI配置：场景路径和目标layer
const UI_CONFIG = {
	UI_component.TOOLBAR: {
		"layer": 1,
		"stage": 0  # stage0时加载
	},
	#UI_component.SETTINGS: {
	#	"layer": 2,
	#	"stage": -1  # 不在初始化时加载
	#}
}

# Canvas Layers存储
var layers: Dictionary = {}

# UI实例存储
var ui_instances: Dictionary = {}

# Settings相关状态
var is_settings_showing: bool = false

# Shader资源（需要时可以预加载）
@export var layer1_shader: Shader
@export var game_scene_shader: Shader

# 对玩家的引用（用于传递给toolbar等UI）
@export var player_now: CharacterBody2D

func _ready():
	# 初始化canvas layers
	_initialize_layers()
	# 初始化stage0的UI
	_initialize_stage0_ui()

func _process(_delta):
	# 检测退出键
	if InputEvents.quit_once():
		_toggle_settings()

func _initialize_layers():
	"""初始化所有canvas layer引用"""
	layers.clear()
	
	# 获取场景根节点
	# 方法1：通过owner获取（如果UI_manager是场景的一部分）
	var root = owner
	
	# 方法2：如果owner为空，尝试通过父节点链向上查找
	if not root:
		root = get_parent()
		while root and root.get_parent():
			var parent = root.get_parent()
			# 如果父节点是SceneTree的root，说明当前节点就是场景根节点
			if parent == get_tree().root:
				break
			root = parent
	
	if not root:
		push_warning("UI_manager: 无法获取场景根节点")
		return
	
	# 遍历场景根节点的所有子节点，查找CanvasLayer
	for child in root.get_children():
		if child is CanvasLayer:
			# 根据layer属性存储
			var layer_id = child.layer if child.layer > 0 else 1
			layers[layer_id] = child
			print("UI_manager: 找到 layer %d - %s" % [layer_id, child.name])

func _initialize_stage0_ui():
	"""初始化stage0阶段的UI"""
	for ui_type in UI_CONFIG:
		var config = UI_CONFIG[ui_type]
		if config.stage == 0:
			_instantiate_ui(ui_type)

func _instantiate_ui(ui_type: UI_component) -> Node:
	"""实例化指定的UI组件"""
	# 检查是否已经实例化
	if ui_instances.has(ui_type):
		push_warning("UI_manager: UI类型 %d 已经实例化" % ui_type)
		return ui_instances[ui_type]
	
	var config = UI_CONFIG[ui_type]
	var target_layer = layers.get(config.layer)
	
	if not target_layer:
		push_error("UI_manager: 未找到layer %d" % config.layer)
		return null
	
	# 根据UI类型获取场景并实例化
	var ui_instance: Node = null
	
	match ui_type:
		UI_component.TOOLBAR:
			ui_instance = TOOLBAR_SCENE.instantiate()
	#	UI_component.SETTINGS:
	#		# 尝试加载settings场景
	#		if ResourceLoader.exists(SETTINGS_SCENE_PATH):
	#			var settings_scene = load(SETTINGS_SCENE_PATH)
	#			ui_instance = settings_scene.instantiate()
	#		else:
	#			push_warning("UI_manager: Settings场景文件不存在，跳过实例化")
	#			return null
	
	if not ui_instance:
		push_error("UI_manager: 无法实例化UI类型 %d" % ui_type)
		return null
	
	# 特殊处理：为toolbar设置player引用
	if ui_type == UI_component.TOOLBAR and player_now:
		if "player_now" in ui_instance:
			ui_instance.player_now = player_now
	
	# 添加到对应layer
	target_layer.add_child(ui_instance)
	
	# 存储实例
	ui_instances[ui_type] = ui_instance
	
	print("UI_manager: 实例化 UI类型 %d 到 layer %d" % [ui_type, config.layer])
	
	return ui_instance

func _toggle_settings():
	"""切换设置界面显示/隐藏"""
	if not is_settings_showing:
		# 显示settings
		_show_settings()
	else:
		# 隐藏settings
		_hide_settings()

func _show_settings():
	"""显示设置界面"""
	# 实例化settings（如果还未实例化）
	if not ui_instances.has(UI_component.SETTINGS):
		_instantiate_ui(UI_component.SETTINGS)
	else:
		# 如果已存在，显示它
		var settings = ui_instances[UI_component.SETTINGS]
		if settings:
			settings.show()  # 使用 show() 方法
			# 确保可以接收输入
			if settings is Control:
				settings.mouse_filter = Control.MOUSE_FILTER_STOP
			# 启用处理
			settings.process_mode = Node.PROCESS_MODE_INHERIT
	
	is_settings_showing = true
	
	# 应用shader效果
	_apply_settings_shader(true)
	
	print("UI_manager: 显示设置界面")

func _hide_settings():
	"""隐藏设置界面"""
	var settings = ui_instances.get(UI_component.SETTINGS)
	if settings:
		settings.hide()  # 使用 hide() 方法
		# 确保不接收任何输入（多重保护）
		if settings is Control:
			settings.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 禁用处理，防止任何交互
		settings.process_mode = Node.PROCESS_MODE_DISABLED
	
	is_settings_showing = false
	
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
			# 这里可以设置shader参数
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

# ============ 工具函数 ============

func get_ui_instance(ui_type: UI_component) -> Node:
	"""获取UI实例"""
	return ui_instances.get(ui_type)

func remove_ui(ui_type: UI_component):
	"""移除UI实例"""
	var ui = ui_instances.get(ui_type)
	if ui:
		ui.queue_free()
		ui_instances.erase(ui_type)
		print("UI_manager: 移除 UI类型 %d" % ui_type)
