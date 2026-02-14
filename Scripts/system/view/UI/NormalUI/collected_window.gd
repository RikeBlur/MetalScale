class_name CollectedWindow
extends Control

@onready var label: Label = $PanelContainer/Label

# UI管理器引用（用于自我销毁）
var own_manager: UI_manager = null

# 自动消失定时器
var auto_hide_timer: float = 3.0
var is_waiting_to_hide: bool = false

func _ready() -> void:
	# 开始计时自动隐藏
	is_waiting_to_hide = true
	
func _process(delta: float) -> void:
	# 检测 act 键单次按下（使用 is_action_just_pressed 检测单次按下）
	if Input.is_action_just_pressed("act"):
		_hide_window()
		return
	
	# 倒计时自动隐藏
	if is_waiting_to_hide:
		auto_hide_timer -= delta
		if auto_hide_timer <= 0:
			_hide_window()

func set_tool_name(tool_name: String) -> void:
	"""
	设置显示的工具名称
	
	参数:
		tool_name: 工具的显示名称
	"""
	if label:
		label.text = "获取 " + tool_name
		print("CollectedWindow: 设置工具名称为 '%s'" % tool_name)

func _hide_window() -> void:
	"""隐藏并销毁窗口"""
	if own_manager:
		own_manager.remove_ui(UI_manager.UI_component.COLLECTWINDOW)
	else:
		queue_free()
	print("CollectedWindow: 窗口已关闭")
