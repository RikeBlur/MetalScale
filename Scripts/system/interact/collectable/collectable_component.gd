class_name CollectableComponent
extends Node2D

@export var collected_tool : ToolManager.Tool = ToolManager.Tool.NONE

# 是否可收集？ 0否1是 （他还在那里吗）
@export var collectable_state : int = 1

var interacted_component_node: interacted_component = null

# Reminder预加载和实例存储
var can_collect_reminder = preload("res://System/RPG/interact/collectable/collectable_reminder.tscn")
var reminder_instance: Node = null
@export var reminder_offset = Vector2(50, -80)

# 可拾取物的实例，可能没有
@export var content: Sprite2D = null

# 视觉标识物
@onready var flashpoint: AnimatedSprite2D = $flashpoint
@onready var light: PointLight2D = $light
@onready var collected_sfx: SFXPlayer = $CollectedSFX

# ============================================ Interact初始化 ===========================================

func _ready() -> void:
	# 查找子节点中的InteractedComponent
	_find_and_store_interacted_component()
	
	# 连接信号
	if interacted_component_node:
		_connect_signals()
	else:
		push_warning("BaseDoor: 未找到InteractedComponent子节点")
	
	# 等待一会，让节点更新好状态
	await get_tree().process_frame
	
	if collectable_state == 0 :
		_disappear_literually()

func _connect_signals() -> void:
	"""连接InteractedComponent的信号"""
	if not interacted_component_node:
		return
	
	# 连接信号
	interacted_component_node.be_interactable.connect(_spawn_reminder)
	interacted_component_node.be_not_interactable.connect(_destroy_reminder)
	interacted_component_node.interacted.connect(_on_collected)
	
	print("BaseDoor: 已连接所有信号")
	
# 使得可拾取物形式上消失（无法拾取、无法触发reminder、没有视觉提示）
func _disappear_literually() -> void:
	collectable_state = 0
	light.visible = false
	flashpoint.visible = false
	if content != null :
		content.visible = false
	_destroy_reminder()
	interacted_component_node.be_interactable.disconnect(_spawn_reminder)
	interacted_component_node.be_not_interactable.disconnect(_destroy_reminder)
	interacted_component_node.interacted.disconnect(_on_collected)
	# 值得注意的是，交互节点本身并没有消失，所以还是会触发 INTERACTED 只不过没有实际逻辑效果
	
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
	var player_node = null
	if interacted_component_node.inter_com:
		player_node = interacted_component_node.inter_com.player_node
	else:
		player_node = GameManager.get_player()

	if not player_node:
		push_warning("CollectableComponent: 找不到 player 节点")
		return

	if ToolManager.get_tool_type_static(collected_tool) == ToolData.TYPE_CONSUMABLE:
		var tool_manager := player_node.get_node_or_null("ToolManager") as ToolManager
		if tool_manager and tool_manager.add_consumable_tool(collected_tool, 1):
			_on_collect_success()
			return
		print("可消耗物已达到堆叠上限，或玩家的 TOOLBAR 已满")
		return

	for i in player_node.tool_available.size():
		if player_node.tool_available[i] == ToolManager.Tool.NONE:
			player_node.tool_available[i] = collected_tool
			_on_collect_success()
			return
	print("玩家的 TOOLBAR 已满")


func _on_collect_success() -> void:
	# 拾取后，使其形式上消失
	_disappear_literually()
	# 拾取音效播放
	collected_sfx.play_once()
	# 显示收集提示窗口
	_show_collect_window(collected_tool)
	# 更新 BaseLevel 中对应的 InteractableData 的状态
	var base_level = _find_base_level()
	if base_level:
		base_level.update_interactable_state(get_path(), 0)
	else:
		push_warning("BaseDoor: 未找到 BaseLevel，无法更新 interactables 状态")

# ============================================== 工具函数 =============================================

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


func _find_base_level() -> BaseLevel:
	"""
	查找场景树中的 BaseLevel 节点
	
	返回:
		BaseLevel 节点，如果未找到则返回 null
	"""
	# 从当前节点向上查找
	var current = get_parent()
	while current:
		if current is BaseLevel:
			return current
		current = current.get_parent()
	
	# 如果向上没找到，尝试从根场景查找
	var root = get_tree().current_scene
	if root is BaseLevel:
		return root
	
	# 递归查找子节点
	return _find_base_level_recursive(root)

func _find_base_level_recursive(node: Node) -> BaseLevel:
	"""递归查找 BaseLevel 节点"""
	if node is BaseLevel:
		return node
	
	for child in node.get_children():
		var result = _find_base_level_recursive(child)
		if result:
			return result
	
	return null

func _show_collect_window(tool: ToolManager.Tool) -> void:
	"""
	显示工具收集提示窗口
	
	参数:
		tool: 收集到的工具类型
	"""
	# 获取工具的显示名称
	var tool_display_name = ToolManager.get_tool_display_name(tool)
	
	# 通过 UIManager 显示窗口
	if UIManager:
		UIManager.show_collect_window(tool_display_name)
	else:
		push_warning("CollectableComponent: 未找到 UIManager，无法显示收集窗口")
			
