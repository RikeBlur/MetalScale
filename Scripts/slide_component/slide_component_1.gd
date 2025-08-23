class_name slide_component_1
extends Node2D

@export var area_array: Array[Area2D]
@export var config: int = 1
@export var parent_qa_system: Node = null
@export var d1: Sprite2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent_qa_system = get_parent()
	if parent_qa_system != null :
		print("get qa_system")
		# 读取父节点下名为D1的Sprite2D节点
		_find_d1_node()
	_setup_connections()

# 查找并保存D1节点
func _find_d1_node() -> void:
	var d1_node = parent_qa_system.get_node_or_null("D1")
	if d1_node != null and d1_node is Sprite2D:
		d1 = d1_node as Sprite2D
		print("成功找到D1节点: ", d1.name)
	else:
		print("警告: 未找到名为D1的Sprite2D节点")

# 设置信号连接
func _setup_connections() -> void:
	if config == 1 and area_array.size() == 4:
		var a1 = area_array[0]
		var a2 = area_array[1]
		var a3 = area_array[2]
		var a4 = area_array[3]
		
		if a1 and a1.has_signal("clicked_signal"):
			a1.clicked_signal.connect(_on_a1_chosen)
		
		if a2 and a2.has_signal("clicked_signal"):
			a2.clicked_signal.connect(_on_a2_chosen)
			
		if a3 and a3.has_signal("clicked_signal"):
			a3.clicked_signal.connect(_on_a3_chosen)
			
		if a4 and a4.has_signal("clicked_signal"):
			a4.clicked_signal.connect(_on_a4_chosen)

func _skip_silde() -> void:
	parent_qa_system.next_slide()

# A1选项被选择时执行
func _on_a1_chosen() -> void:
	# TODO: 填充A1选择的处理逻辑
	print("A1选项被选择")
	_skip_silde() 
	

# A2选项被选择时执行
func _on_a2_chosen() -> void:
	# TODO: 填充A2选择的处理逻辑
	print("A2选项被选择")
	_skip_silde() 
	
	
# A3选项被选择时执行
func _on_a3_chosen() -> void:
	# TODO: 填充A3选择的处理逻辑
	print("A3选项被选择")
	_skip_silde() 
	
	
# A2选项被选择时执行
func _on_a4_chosen() -> void:
	# TODO: 填充A4选择的处理逻辑
	print("A4选项被选择")
	_skip_silde() 
