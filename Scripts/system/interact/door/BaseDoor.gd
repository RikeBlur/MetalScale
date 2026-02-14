class_name BaseDoor
extends Node2D

# 门的状态：0可以打开、1上锁、2不能从这一侧打开
@export_enum("可打开", "上锁", "不可从此侧打开") var state: int = 0

@export var responding_key : ToolManager.Tool = ToolManager.Tool.NONE

# 场景路径
@export var scene_from: String = ""
@export var scene_to: String = ""
@export var scene_to_index: int = 0

# InteractedComponent引用
var interacted_component_node: interacted_component = null

# Reminder预加载和实例存储
var can_open_reminder = preload("res://System/RPG/interact/door/reminder/can_open_reminder.tscn")
var need_key_reminder = preload("res://System/RPG/interact/door/reminder/need_key_reminder.tscn")
var not_this_side_reminder = preload("res://System/RPG/interact/door/reminder/not_this_side_reminder.tscn")

var reminder_instance: Node = null

@onready var open_sfx: SFXPlayer = $open_sfx
@onready var cant_open_sfx: SFXPlayer = $cant_open_sfx
@onready var use_key_sfx: SFXPlayer = $use_key_sfx

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
	interacted_component_node.interacted.connect(_on_door_interacted)
	
	print("BaseDoor: 已连接所有信号")

# ============ Reminder管理 ============

func _spawn_reminder() -> void:
	"""生成reminder提示"""
	# 如果已经有reminder，先销毁
	if reminder_instance and is_instance_valid(reminder_instance):
		_destroy_reminder()
	
	# 实例化reminder
	match state :
		0:
			reminder_instance = can_open_reminder.instantiate()
		1:
			reminder_instance = need_key_reminder.instantiate()
		2:
			reminder_instance = not_this_side_reminder.instantiate()
	
	# 添加到场景树
	add_child(reminder_instance)
	
	# 设置位置偏移（相对于door的位置）
	var offset = Vector2(50, -80)  # 向上偏移100像素
	reminder_instance.position = offset
	
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

# ============ 交互处理 ============

func _on_door_interacted() -> void:
	"""当门被交互时调用"""
	print("BaseDoor: 门被交互，当前状态: %d" % state)

	
	# 根据状态处理
	match state:
		0:  # 可以打开
			_open_door()
		1:  # 上锁
			_door_lock()
		2:  # 不能从这一侧打开
			cant_open_sfx.play_once()
			print("BaseDoor: 不能从这一侧打开门")
			# 可以在这里显示提示

func _open_door() -> void:
	"""打开门并切换场景"""
	_destroy_reminder()
	
	# 播放音效
	open_sfx.play_once()
	
	if scene_to == "":
		push_warning("BaseDoor: scene_to为空，无法切换场景")
		return
	
	print("BaseDoor: 打开门，切换到场景: %s" % scene_to)
	
	# 调用SceneManager的场景切换， 通过 index 确认场景初始落点
	SceneManager.change_scene(scene_to, scene_to_index)

func _door_lock() -> void:
	"""处理上锁的门"""
	
	print("BaseDoor: 门已上锁")
	
	# 获取玩家引用
	var player_node = GameManager.get_player()
	if not player_node:
		push_warning("BaseDoor: 无法获取玩家实例")
		return
	
	# 检查是否配置了对应的钥匙
	if responding_key == ToolManager.Tool.NONE:
		print("BaseDoor: 未配置钥匙，无法通过常规方式打开")
		return
	
	# 检查玩家是否有对应的 tool
	# tool_available 是 Array[ToolManager.Tool]
	var key_index = player_node.tool_available.find(responding_key)
	
	if key_index != -1:
		# 玩家拥有钥匙
		print("BaseDoor: 发现钥匙 %s (索引: %d)，正在开锁..." % [responding_key, key_index])
		
		_destroy_reminder()
		
		# 1. 将玩家的tool_available对应的tool设为none
		player_node.tool_available[key_index] = ToolManager.Tool.NONE
		# 播放音效
		use_key_sfx.play_once()
		
		print("BaseDoor: 钥匙已消耗")
		
		# 2. 将门的状态设置为0 (可打开)
		state = 0
		print("BaseDoor: 门状态已更新为可打开 (0)")
		
		# 更新 BaseLevel 中对应的 InteractableData 的状态
		var base_level = _find_base_level()
		if base_level:
			base_level.update_interactable_state(get_path(), 0)
		else:
			push_warning("BaseDoor: 未找到 BaseLevel，无法更新 interactables 状态")
		
		_spawn_reminder()
		
		# 自动尝试打开门
		#_open_door()
		
	else:
		# 玩家没有钥匙
		print("BaseDoor: 玩家没有钥匙 %s" % responding_key)
		# 弹出提示（这里暂时用print，实际项目可能需要UI管理器）
		cant_open_sfx.play_once()
		# TODO: 实现UI提示 "门已上锁无法打开"
	
# ============ 工具函数 ============

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

func set_door_state(new_state: int) -> void:
	"""设置门的状态"""
	if new_state >= 0 and new_state <= 2:
		state = new_state
		print("BaseDoor: 门状态已设置为: %d" % state)
	else:
		push_warning("BaseDoor: 无效的门状态: %d" % new_state)

func is_locked() -> bool:
	"""检查门是否上锁"""
	return state == 1

func can_open() -> bool:
	"""检查门是否可以打开"""
	return state == 0
