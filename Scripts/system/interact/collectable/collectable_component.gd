class_name CollectableComponent
extends Node2D

@export var collected_tool : ToolManager.Tool = ToolManager.Tool.NONE

var interacted_component_node: interacted_component = null

# Reminder预加载和实例存储
var can_collect_reminder = preload("res://System/RPG/interact/dialogue/dialogue_reminder.tscn")
var reminder_instance: Node = null
@export var reminder_offset = Vector2(50, -80)  # 向上偏移100像素

# ============================================ Interact初始化 ===========================================

func _ready() -> void:
	# 查找子节点中的InteractedComponent
	_find_and_store_interacted_component()
	
	# 连接信号
	if interacted_component_node:
		_connect_signals()
	else:
		push_warning("BaseDoor: 未找到InteractedComponent子节点")

func _find_and_store_interacted_component() -> void:
	"""查找并存储InteractedComponent子节点"""
	for child in get_children():
		if child is interacted_component:
			interacted_component_node = child
			print("BaseDoor: 找到InteractedComponent")
			return
	
	# 如果没有直接子节点，尝试递归查找
	interacted_component_node = _find_interacted_component_recursive(self)
	if interacted_component_node:
		print("BaseDoor: 在子树中找到InteractedComponent")
		

func _find_interacted_component_recursive(node: Node) -> interacted_component:
	"""递归查找InteractedComponent"""
	for child in node.get_children():
		if child is interacted_component:
			return child
		var result = _find_interacted_component_recursive(child)
		if result:
			return result
	return null

func _connect_signals() -> void:
	"""连接InteractedComponent的信号"""
	if not interacted_component_node:
		return
	
	# 连接信号
	interacted_component_node.be_interactable.connect(_spawn_reminder)
	interacted_component_node.be_not_interactable.connect(_destroy_reminder)
	interacted_component_node.interacted.connect(_on_collected)
	
	print("BaseDoor: 已连接所有信号")

# ============================================= Reminder管理 ============================================

func _spawn_reminder() -> void:
	"""生成reminder提示"""
	# 如果已经有reminder，先销毁
	if reminder_instance and is_instance_valid(reminder_instance):
		_destroy_reminder()
	
	# 实例化reminder
	reminder_instance = can_collect_reminder.instantiate()
	
	# 添加到场景树
	add_child(reminder_instance)
	
	# 设置位置偏移（相对于 collectable 的位置）
	reminder_instance.position = reminder_offset
	
	# 播放动画
	var animated_sprite = reminder_instance.get_node("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.play()
	
	print("BaseDoor: 生成reminder")

func _destroy_reminder() -> void:
	"""销毁reminder提示"""
	if reminder_instance and is_instance_valid(reminder_instance):
		# 暂停动画
		var animated_sprite = reminder_instance.get_node("AnimatedSprite2D")
		if animated_sprite:
			animated_sprite.pause()
		
		# 销毁实例
		reminder_instance.queue_free()
		reminder_instance = null
		
		print("BaseDoor: 销毁reminder")
		
# ============================================== 交互处理 =============================================
		
func _on_collected() -> void:
	var player_node = interacted_component_node.inter_com.player_node
	for i in player_node.tool_available.size():
		if player_node.tool_available[i] == ToolManager.Tool.NONE:
			player_node.tool_available[i] = collected_tool
			self.queue_free()
			return
	print("玩家的 TOOLBAR 已满")
			
