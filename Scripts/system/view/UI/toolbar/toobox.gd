class_name Toolbox
extends HBoxContainer

var state : int = 0 #0未激活 1激活 2不可使用
var tool : ToolManager.Tool = ToolManager.Tool.NONE
var config : int = 0:
	set(value):
		if config != value:
			config = value
			update_children_based_on_config()

@export var icon : TextureRect
@export var durability : ProgressBar

const DURABILITY_BAR_SCENE = preload("res://System/RPG/tools/durability_bar.tscn")

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
				if child != icon:
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
			
			# 更新引用
			durability = durability_bar_node
			
			# 清除除了Icon和DurabilityBar外的所有子节点
			for child in get_children():
				if child != icon and child != durability_bar_node:
					child.queue_free()
