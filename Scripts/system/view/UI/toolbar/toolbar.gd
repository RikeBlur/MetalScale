class_name Toolbar
extends Control

const TOOL_ICONS = {
	ToolManager.Tool.NONE: null,
	ToolManager.Tool.EMERGENCELIGHT: preload("res://Assests/sprite/UI/TOOLBAR/toolicon/EmergenceLight_icon.png"),
	ToolManager.Tool.FLASHLIGHT: preload("res://Assests/sprite/UI/TOOLBAR/toolicon/FlashLight_icon.png"),
	ToolManager.Tool.ADRENALINE: preload("res://Assests/sprite/UI/TOOLBAR/toolicon/Adrenaline_icon.png"),
	ToolManager.Tool.KEYA: preload("res://Assests/sprite/UI/TOOLBAR/toolicon/key1-1_icon.png")
}

const TOOL_CONFIG = {
	ToolManager.Tool.NONE: 0,
	ToolManager.Tool.EMERGENCELIGHT: 1,
	ToolManager.Tool.FLASHLIGHT: 1,
	ToolManager.Tool.ADRENALINE: 2,
	ToolManager.Tool.KEYA: 0
}

@export var player_now: CharacterBody2D

var tool_boxes: Array = []

var tool_bar : VBoxContainer = null

var tool_manager : ToolManager = null

func _ready():
	if not player_now: return
	
	tool_bar = $leftoffset/PanelContainer/MarginContainer/tool_bar
	tool_manager = player_now.get_node("ToolManager")

	# 从tool_bar节点下读取现有的工具箱
	_initialize_tool_boxes()
	# 根据玩家已有的tool更新toolbox
	call_deferred("_update_toolbar")

func _initialize_tool_boxes():
	tool_boxes.clear()
	for child in tool_bar.get_children():
		if child is Toolbox :
			tool_boxes.append(child)

func _process(_delta):
	if not player_now: return
	if not tool_manager: return
	
	call_deferred("_update_toolbar")
	call_deferred("_update_consumption")
	call_deferred("_update_progressbar")
	
func _update_consumption() -> void:
	for i in range(tool_boxes.size()):
		if tool_boxes[i].consumption == null:
			continue
		else:
			var tool_type = tool_boxes[i].tool
			var consumption_label_node = tool_boxes[i].consumption
			if tool_manager.consumption.has(tool_type):
				consumption_label_node.text = str(tool_manager.consumption[tool_type])

func _update_progressbar() -> void:
	for i in range(tool_boxes.size()):
		if tool_boxes[i].durability == null:
			continue
		else:
			var tool_type = tool_boxes[i].tool
			var durability_bar = tool_boxes[i].durability
			if tool_manager.durability.has(tool_type):
				durability_bar.value = tool_manager.durability[tool_type]
				durability_bar.update_color()


func _update_toolbar():
	if not player_now or tool_boxes.is_empty(): return

	for i in range(player_now.tool_available.size()):
		var tool_type = player_now.tool_available[i]
		var icon = tool_boxes[i].icon
		tool_boxes[i].tool = tool_type
		tool_boxes[i].config = TOOL_CONFIG[tool_type] #这里就会执行update_children_based_on_config
		icon.texture = TOOL_ICONS.get(tool_type)
		
		var progressbar = tool_boxes[i].durability
		
		# 设置工具箱状态和图标shader状态
		var activated_tool = player_now.tool_available[player_now.tool]
		var new_state = 0
		if tool_type == activated_tool:
			new_state = 1
		elif tool_boxes[i].config == 1 and tool_manager and tool_manager.durability.has(tool_type):
			progressbar.max_value = ToolManager.max_durability
			progressbar.value = tool_manager.durability[tool_type]
			if progressbar.value == 0.0:
				new_state = 2
		
		# 同步更新状态
		tool_boxes[i].state = new_state
		
		# 设置 shader 参数
		icon.material.set_shader_parameter("state", new_state)
