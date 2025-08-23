class_name qa_system
extends Node2D

# 存储所有slide节点的数组
var slide_nodes: Array[Node2D] = []
# 当前显示的slide索引
var current_slide_index: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_collect_slide_nodes()
	_initialize_slides()

# 收集所有slide类的子节点
func _collect_slide_nodes() -> void:
	slide_nodes.clear()
	
	for child in get_children():
		# 检查是否为slide_component类或继承自Node2D的slide相关节点
		if child is Node2D and child.is_in_group("slide") :
			slide_nodes.append(child)
	
	print("收集到的slide节点数量: ", slide_nodes.size())
	for i in range(slide_nodes.size()):
		print("Slide ", i, ": ", slide_nodes[i].name)

# 初始化slides显示状态
func _initialize_slides() -> void:
	if slide_nodes.size() == 0:
		print("警告: 没有找到slide节点")
		return
	
	# 隐藏所有slide，只显示第一个
	for i in range(slide_nodes.size()):
		slide_nodes[i].visible = (i == 0)
	
	current_slide_index = 0
	print("初始化完成，当前显示slide: ", current_slide_index)

# 切换到下一个slide
func next_slide() -> void:
	if slide_nodes.size() == 0:
		print("没有slide可以切换")
		return
	
	# 隐藏当前slide
	slide_nodes[current_slide_index].visible = false
	
	# 移动到下一个slide
	current_slide_index += 1
	
	# 检查是否到达末尾
	if current_slide_index >= slide_nodes.size():
		print("已到达最后一个slide")
		current_slide_index = slide_nodes.size() - 1  # 保持在最后一个
		reset_to_first_slide()
		return
	
	# 显示下一个slide
	slide_nodes[current_slide_index].visible = true
	print("切换到slide: ", current_slide_index)

# 公共方法：获取当前slide索引
func get_current_slide_index() -> int:
	return current_slide_index

# 公共方法：获取slide总数
func get_total_slides() -> int:
	return slide_nodes.size()

# 公共方法：跳转到指定slide
func goto_slide(index: int) -> void:
	if index < 0 or index >= slide_nodes.size():
		print("无效的slide索引: ", index)
		return
	
	# 隐藏当前slide
	slide_nodes[current_slide_index].visible = false
	
	# 显示目标slide
	current_slide_index = index
	slide_nodes[current_slide_index].visible = true
	print("跳转到slide: ", current_slide_index)

# 公共方法：是否为最后一个slide
func is_last_slide() -> bool:
	return current_slide_index >= slide_nodes.size() - 1

# 公共方法：重置到第一个slide
func reset_to_first_slide() -> void:
	if slide_nodes.size() > 0:
		slide_nodes[current_slide_index].visible = false
		current_slide_index = 0
		slide_nodes[current_slide_index].visible = true
		print("重置到第一个slide")
