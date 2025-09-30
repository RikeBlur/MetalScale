class_name slide_component_3
extends Node2D

@export var area_array: Array[Area2D]
@export var config: int = 3
@export var parent_qa_system: Node = null
@export var d1: Sprite2D = null

@export var last_time: float = 3.0
@export var last_timer: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent_qa_system = get_parent()
	if parent_qa_system != null :
		print("get qa_system")
		# 读取父节点下名为D1的Sprite2D节点
		_find_d1_node()
	last_timer = 0.0

# 查找并保存D1节点
func _find_d1_node() -> void:
	var d1_node = parent_qa_system.get_node_or_null("D1")
	if d1_node != null and d1_node is Sprite2D:
		d1 = d1_node as Sprite2D
		print("成功找到D1节点: ", d1.name)
	else:
		print("警告: 未找到名为D1的Sprite2D节点")

func _process(delta: float) -> void:
	last_timer += delta
	if last_timer >= last_time :
		last_timer = 0.0
		_finish_slide()
	

func _skip_silde() -> void:
	parent_qa_system.next_slide()
	
func _finish_slide() -> void:
	pass
