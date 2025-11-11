class_name Toolbox
extends Container

var state : int = 0 #0未激活 1激活 2不可使用
var tool : ToolManager.Tool = ToolManager.Tool.NONE
var config : int = 0:
	set(value):
		if config != value:
			config = value
			update_children_based_on_config()

@export var icon : TextureRect = null
@export var durability : ProgressBar = null
@export var consumption : Label = null
@export var back : TextureRect = null

const DURABILITY_BAR_SCENE = preload("res://System/RPG/tools/durability_bar.tscn")
const CONSUMPTION_LABEL_SCENE = preload("res://System/RPG/tools/consumption_label.tscn")

func _ready() -> void:
	icon = $Icon
	update_children_based_on_config()

func update_children_based_on_config() -> void:
	# 需要在下一帧执行，确保子节点已经准备好
	_apply_config()

func _apply_config() -> void:
	match config:
		0:
			# config=0: 清除除Icon外的所有子节点
			for child in get_children():
				if child != icon and child != back:
					child.queue_free()
			durability = null
			
		1:
			# config=1: 确保有DurabilityBar，清除其他多余子节点
			var durability_bar_node = get_node_or_null("DurabilityBar")
			
			# 如果没有DurabilityBar，实例化一个
			if not durability_bar_node:
				durability_bar_node = DURABILITY_BAR_SCENE.instantiate()
				durability_bar_node.name = "DurabilityBar"
				add_child(durability_bar_node)
				# 确保是第一个子节点
				move_child(durability_bar_node, 0)
			
			# 更新引用
			durability = durability_bar_node
			
			# 清除除了Icon和DurabilityBar外的所有子节点
			for child in get_children():
				if child != icon and child != durability_bar_node and child != back:
					child.queue_free()
					
		2:
			var consumption_label_node = get_node_or_null("ConsumptionLabel")
			
			# 如果没有ConsumptionLabel，实例化一个
			if not consumption_label_node:
				consumption_label_node = CONSUMPTION_LABEL_SCENE.instantiate()
				consumption_label_node.name = "ConsumptionLabel"
				add_child(consumption_label_node)
			
			# 更新引用
			consumption = consumption_label_node
			
			# config=2: 清除除Icon和ConsumptionLabel外的所有子节点
			for child in get_children():
				if child != icon and child != consumption_label_node and child != back:
					child.queue_free()
			
