class_name BaseLevel
extends Node2D

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================

# 玩家进入场景时的初始位置（全局坐标）
@export var player_initial_position: Array[Vector2]

# 玩家进入场景时的初始朝向（Vector2方向，如Vector2.DOWN, Vector2.UP等）
@export var player_initial_direction: Array[Vector2]

# 玩家节点引用（可选，如果场景中已有player节点可指定）
#@export var player_node: player = null

# 转产动画
@export var transition_player : AnimationPlayer = null

# 可交互对象数组（编辑器配置用，运行时会同步到 SceneData）
@export var interactables: Array[InteractableData] = []

# 当前场景的 SceneData 引用（从 SceneManager 获取）
var current_scene_data: SceneData = null


func _ready():
	# 加载新场景后初始化一次 UI系统
	UIManager.refresh_ui_manager()
	
	# 获取当前场景的 SceneData
	var scene_key = SceneManager.get_current_scene_key()
	if scene_key != "":
		current_scene_data = SceneManager.get_scene_data(scene_key)
		if current_scene_data:
			print("BaseLevel: 已获取当前场景数据: %s" % scene_key)
			
			# 如果 SceneData 中的 interactables 为空，从 BaseLevel 同步过去 （权宜之计）
			# 这样既保留了编辑器配置能力，又实现了运行时状态持久化 （后续需要为为每个场景写初始 SceneData）
			if current_scene_data.interactables.is_empty() and not interactables.is_empty():
				print("BaseLevel: SceneData 中 interactables 为空，正在从 BaseLevel 同步...")
				for interactable in interactables:
					if interactable:
						current_scene_data.interactables.append(interactable)
				print("BaseLevel: 已同步 %d 个 interactable 到 SceneData" % current_scene_data.interactables.size())
		else:
			push_warning("BaseLevel: 无法获取场景数据: %s" % scene_key)
	else:
		push_warning("BaseLevel: 当前场景key为空")
	
	# 应用可交互对象的状态
	apply_interactable_states()


func apply_initial_values_to_player(target_player: player, index: int) -> void:
	"""
	将初始位置和朝向应用到指定的玩家节点
	
	参数:
		target_player: 要应用初始值的玩家节点
	"""
	if not target_player:
		push_warning("BaseLevel: target_player为空，无法应用初始值")
		return
	
	# 设置玩家位置（全局坐标）
	target_player.global_position = player_initial_position[index]
	
	# 设置玩家朝向
	target_player.player_direction = player_initial_direction[index]
	target_player.player_last_direction = player_initial_direction[index]
	
	print("BaseLevel: 已将初始位置 %s 和朝向 %s 应用到玩家" % [player_initial_position, player_initial_direction])

# ====================================================================================================
# ===================================== 可交互对象状态管理 ===========================================
# ====================================================================================================

func apply_interactable_states() -> void:
	"""
	根据 SceneData 中的 interactables 数组初始化场景中的可交互对象状态
	在场景加载时自动调用
	"""
	if not current_scene_data or current_scene_data.interactables.is_empty():
		return
	
	print("BaseLevel: 开始应用可交互对象状态，共 %d 个对象" % current_scene_data.interactables.size())
	
	for interactable in current_scene_data.interactables:
		if not interactable:
			continue
		
		# 获取节点（路径相对于BaseLevel）
		var node = get_node_or_null(interactable.node_path)
		
		if not node:
			push_warning("BaseLevel: 找不到节点 %s" % interactable.node_path)
			continue
		
		# 根据类型应用状态
		match interactable.type:
			0:  # 门
				_apply_door_state(node, interactable.state)
			1:  # 可拾取物
				_apply_collectible_state(node, interactable.state)
			2:  # 其他机关
				_apply_mechanism_state(node, interactable.state)
			_:
				push_warning("BaseLevel: 未知的 interactable 类型: %d" % interactable.type)
	
	print("BaseLevel: 可交互对象状态应用完成")

func _apply_door_state(door_node: Node, state: int) -> void:
	"""
	应用门的状态
	
	参数:
		door_node: 门节点（应该是 BaseDoor 类型）
		state: 状态（0=可打开, 1=上锁, 2=不可从此侧打开）
	"""
	if door_node is BaseDoor:
		door_node.set_door_state(state)
		print("BaseLevel: 已应用门状态 %d 到节点 %s" % [state, door_node.name])
	else:
		push_warning("BaseLevel: 节点 %s 不是 BaseDoor 类型" % door_node.name)

func _apply_collectible_state(collectible_node: Node, state: int) -> void:
	"""
	应用可拾取物的状态
	
	参数:
		collectible_node: 可拾取物节点
		state: 状态（0=可拾取, 1=不可拾取）
	
	TODO: 根据实际的可拾取物类实现此方法
	"""
	collectible_node.collectable_state = state
	
	print("BaseLevel: 可拾取物状态应用 - 节点: %s, 状态: %d (待实现)" % [collectible_node.name, state])

func _apply_mechanism_state(mechanism_node: Node, state: int) -> void:
	"""
	应用其他机关的状态
	
	参数:
		mechanism_node: 机关节点
		state: 状态（0=可交互, 1=不可交互）
	
	TODO: 根据实际的机关类实现此方法
	"""
	# 示例实现（假设机关有 set_mechanism_state 方法）
	# if mechanism_node.has_method("set_mechanism_state"):
	#     mechanism_node.set_mechanism_state(state)
	
	print("BaseLevel: 机关状态应用 - 节点: %s, 状态: %d (待实现)" % [mechanism_node.name, state])

func update_interactable_state(node_path: Variant, new_state: int) -> void:
	"""
	更新某个可交互对象的状态, 同时更新当前场景的 Interactables 和 全局保存的 SceneData 里的 Interactables
	
	参数:
		node_path: 节点路径（可以是 NodePath 或 String，支持绝对路径和相对路径）
		new_state: 新的状态值
	"""
	# 转换为字符串
	var path_str = String(node_path)
	
	# 如果是绝对路径，尝试转换为相对路径
	var relative_path = path_str
	if path_str.begins_with("/"):
		# 尝试通过节点获取相对路径
		var target_node = get_node_or_null(path_str)
		if target_node:
			relative_path = String(get_path_to(target_node))
	
	# 检查 SceneData 是否存在
	if not current_scene_data:
		push_warning("BaseLevel: 当前场景数据为空，无法更新状态")
		return
	
	# 查找并更新 SceneData 中的 interactables
	for interactable in current_scene_data.interactables:
		if not interactable:
			continue
		
		var interactable_path = String(interactable.node_path)
		
		# 比较相对路径或原始路径
		if interactable_path == relative_path or interactable_path == path_str:
			interactable.state = new_state
			print("BaseLevel: 已更新 %s 的状态为 %d (保存到 SceneData)" % [interactable_path, new_state])
			return
	
	push_warning("BaseLevel: interactables 中不存在路径 %s (相对路径: %s)" % [path_str, relative_path])

func get_interactable_by_path(node_path: Variant) -> InteractableData:
	"""
	根据节点路径获取可交互对象数据
	
	参数:
		node_path: 节点路径（可以是 NodePath 或 String，支持绝对路径和相对路径）
	
	返回:
		找到的 InteractableData 对象，如果不存在则返回 null
	"""
	# 转换为字符串
	var path_str = String(node_path)
	
	# 如果是绝对路径，尝试转换为相对路径
	var relative_path = path_str
	if path_str.begins_with("/"):
		# 尝试通过节点获取相对路径
		var target_node = get_node_or_null(path_str)
		if target_node:
			relative_path = String(get_path_to(target_node))
	
	# 检查 SceneData 是否存在
	if not current_scene_data:
		return null
	
	# 查找 SceneData 中的 interactables
	for interactable in current_scene_data.interactables:
		if not interactable:
			continue
		
		var interactable_path = String(interactable.node_path)
		
		# 比较相对路径或原始路径
		if interactable_path == relative_path or interactable_path == path_str:
			return interactable
	
	return null

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
