class_name Toolbar
extends Control

const TOOL_ICONS = {
	ToolManager.Tool.NONE: null,
	ToolManager.Tool.RADIUS_LIGHT: preload("res://Assests/sprite/icon/light-bulb-clipart-md.png")
}

const TOOL_CONFIG = {
	ToolManager.Tool.NONE: 0,
	ToolManager.Tool.RADIUS_LIGHT: 1
}

@export var player_now: CharacterBody2D

var tool_boxes: Array = []
var durability_bars: Array = []
var tool_bar : VBoxContainer = null

var tool_manager : ToolManager = null

func _ready():
	if not player_now: return
	
	tool_bar = $PanelContainer/MarginContainer/tool_bar
	tool_manager = player_now.get_node("ToolManager")

	# 从tool_bar节点下读取现有的工具箱
	_initialize_tool_boxes()
	# 根据玩家已有的tool更新toolbox
	_update_toolbar()

func _initialize_tool_boxes():
	tool_boxes.clear()
	for child in tool_bar.get_children():
		if child is Toolbox :
			tool_boxes.append(child)

func _process(_delta):
	if not player_now: return
	if not tool_manager: return
	
	_update_progressbar()
	_update_toolbar()
	
func _update_progressbar() -> void:
	for i in range(min(6, player_now.tool_available.size())):
		var tool_type = player_now.tool_available[i]
		var durability_bar = tool_boxes[i].durability

		if tool_type != ToolManager.Tool.NONE and durability_bar.visible:
			if tool_manager.durability.has(tool_type):
				durability_bar.value = tool_manager.durability[tool_type]
				durability_bar.update_color()
				#print(tool_manager.durability[tool_type])

func _update_toolbar():
	if not player_now or tool_boxes.is_empty(): return
	var activated_tool = player_now.tool

	for i in range(min(6, player_now.tool_available.size())):
		var tool_type = player_now.tool_available[i]
		var icon = tool_boxes[i].icon
		var progressbar = tool_boxes[i].progressbar
		
		tool_boxes[i].tool = tool_type
		tool_boxes[i].config = TOOL_CONFIG[tool_type]
		icon.texture = TOOL_ICONS.get(tool_type)
		
		# 设置工具箱状态和图标shader状态
		var new_state = 0
		if tool_type == activated_tool:
			new_state = 1
		elif tool_boxes[i].tool == 1 and tool_manager and tool_manager.durability.has(tool_type):
			progressbar.max_value = ToolManager.max_durability
			progressbar.value = tool_manager.durability[tool_type]
			if progressbar.value == 0.0:
				new_state = 2
		
		# 同步更新状态
		tool_boxes[i].state = new_state
		if icon.material:
			icon.material.set_shader_parameter("state", new_state)
