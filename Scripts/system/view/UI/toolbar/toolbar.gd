class_name Toolbar
extends Control

const TOOL_ICONS = {
	ToolManager.Tool.NONE: null,
	ToolManager.Tool.RADIUS_LIGHT: preload("res://Assests/sprite/icon/light-bulb-clipart-md.png")
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
	# 清空数组
	tool_boxes.clear()
	durability_bars.clear()

	# 从tool_bar的子节点中获取工具箱
	for child in tool_bar.get_children():
		if child is HBoxContainer :
			tool_boxes.append(child)

			# 获取或创建Icon节点
			var icon = child.get_node_or_null("Icon")
			if not icon:
				icon = TextureRect.new()
				icon.name = "Icon"
				icon.custom_minimum_size = Vector2(32, 32)
				child.add_child(icon)

			# 获取或创建DurabilityBar节点
			var durability_bar = child.get_node_or_null("DurabilityBar")
			if not durability_bar:
				durability_bar = durability_process_bar.new()
				durability_bar.name = "DurabilityBar"
				durability_bar.custom_minimum_size = Vector2(10, 0)
				durability_bar.visible = false
				child.add_child(durability_bar)
			durability_bar.max_value = ToolManager.max_durability
			durability_bars.append(durability_bar)

func _process(_delta):
	if not player_now: return
	if not tool_manager: return
	
	_update_durability()
	
func _update_durability() -> void:
	for i in range(min(6, player_now.tool_available.size())):
		var tool_type = player_now.tool_available[i]
		var durability_bar = durability_bars[i]

		if tool_type != ToolManager.Tool.NONE and durability_bar.visible:
			if tool_manager.durability.has(tool_type):
				durability_bar.value = tool_manager.durability[tool_type]
				durability_bar.update_color()
				#print(tool_manager.durability[tool_type])

func _update_toolbar():
	if not player_now or tool_boxes.is_empty(): return

	for i in range(min(6, player_now.tool_available.size())):
		var tool_type = player_now.tool_available[i]
		var icon = tool_boxes[i].get_node("Icon") as TextureRect
		var durability_bar = durability_bars[i]

		icon.texture = TOOL_ICONS.get(tool_type)
		durability_bar.visible = tool_type != ToolManager.Tool.NONE

		if tool_type != ToolManager.Tool.NONE:
			if tool_manager and tool_manager.durability.has(tool_type):
				durability_bar.max_value = ToolManager.max_durability
				durability_bar.value = tool_manager.durability[tool_type]
