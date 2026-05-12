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
#@export var transition_player : AnimationPlayer = null

# 可交互对象数组（编辑器配置用，运行时会同步到 SceneData）
@export var interactables: Array[InteractableData] = []

# 当前场景的 SceneData 引用（从 SceneManager 获取）
var current_scene_data: SceneData = null

# 「其他」类型隐藏时暂存 CollisionObject2D 的层掩码，用于恢复碰撞
const _META_OTHER_SAVED_COLLISION_LAYER := &"_baselevel_other_saved_collision_layer"
const _META_OTHER_SAVED_COLLISION_MASK := &"_baselevel_other_saved_collision_mask"


func _ready():
	# 加载新场景后初始化一次 UI系统
	UIManager.refresh_ui_manager()
	
	# 使用全局 LightingManager（已在GameManager中加载）
	# 不再需要每个场景单独创建lighting_manager节点
	
	# 获取当前场景的 SceneData ！！
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
		
		# 根据类型应用状态（与 InteractableData @export_enum 一致：门/可拾取物/对话/谜题/其他/灯）
		match interactable.type:
			0:  # 门
				_apply_door_state(node, interactable.state)
			1:  # 可拾取物
				_apply_collectible_state(node, interactable.state)
			2:  # 对话
				_apply_dialogue_state(node, interactable.state)
			3:  # 谜题
				_apply_puzzle_state(node, interactable.state)
			4:  # 其他
				_apply_other_state(node, interactable.state)
			5:  # 灯
				_apply_light_state(node, interactable.state)
			_:
				push_warning("BaseLevel: 未知的 interactable 类型: %d" % interactable.type)
	
	print("BaseLevel: 可交互对象状态应用完成")

# ====================================================================================================

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
	
# ====================================================================================================

func _apply_dialogue_state(dialogue_node: Node, state: int) -> void:
	# 对话状态：直接映射到 DialogueComponent.current_flag
	# 约定：-1 表示停用；>=0 表示使用对应 trigger_flag 索引
	if dialogue_node is DialogueComponent:
		var dialogue_comp: DialogueComponent = dialogue_node
		
		# 允许 -1（停用）
		if state == -1:
			dialogue_comp.current_flag = -1
			print("BaseLevel: 对话状态应用 - 节点: %s, current_flag: -1(停用)" % dialogue_node.name)
			return
		
		# 非负索引需要做边界检查，避免运行时越界
		if state >= 0 and state < dialogue_comp.trigger_flag.size():
			dialogue_comp.current_flag = state
			print("BaseLevel: 对话状态应用 - 节点: %s, current_flag: %d" % [dialogue_node.name, state])
		else:
			push_warning("BaseLevel: 对话状态越界，节点: %s, state: %d, trigger_flag.size: %d" % [dialogue_node.name, state, dialogue_comp.trigger_flag.size()])
	else:
		push_warning("BaseLevel: 节点 %s 不是 DialogueComponent 类型" % dialogue_node.name)
	
# ====================================================================================================

func _apply_puzzle_state(puzzle_node: Node, state: int) -> void:
	"""
	应用谜题状态
	
	参数:
		puzzle_node: 谜题根节点
	state: 0=不可交互, 1=可交互且未完成, 2=已完成且不可交互, 3=已完成但可交互
	"""
	if state < 0 or state > 3:
		push_warning("BaseLevel: 谜题状态应为 0、1、2 或 3，节点: %s，收到: %d" % [puzzle_node.name, state])
	var interactable := state == 1 or state == 3
	if puzzle_node.has_method("set_puzzle_state"):
		puzzle_node.call("set_puzzle_state", state)
		print("BaseLevel: 谜题 set_puzzle_state - 节点: %s, state: %d" % [puzzle_node.name, state])
		return
	if puzzle_node.has_method("set_puzzle_interactable"):
		puzzle_node.call("set_puzzle_interactable", interactable)
		print("BaseLevel: 谜题 set_puzzle_interactable - 节点: %s, %s" % [puzzle_node.name, interactable])
		return
	var interact_comps: Array[interact_component] = []
	var interacted_comps: Array[interacted_component] = []
	_collect_interact_components_recursive(puzzle_node, interact_comps)
	_collect_interacted_components_recursive(puzzle_node, interacted_comps)
	if interact_comps.is_empty() and interacted_comps.is_empty():
		push_warning("BaseLevel: 谜题节点 %s 未实现 set_puzzle_state/set_puzzle_interactable，且子树中无 interact_component / interacted_component" % puzzle_node.name)
		return
	for ic in interact_comps:
		var ar: Area2D = ic.interact_rage if ic.interact_rage else ic.get_parent() as Area2D
		if ar:
			ar.monitoring = interactable
			ar.monitorable = interactable
	for idc in interacted_comps:
		var ar2: Area2D = idc.interacted_rage if idc.interacted_rage else idc.get_parent() as Area2D
		if ar2:
			ar2.monitoring = interactable
			ar2.monitorable = interactable
	print("BaseLevel: 谜题状态应用 - 节点: %s, 可交互: %s (Area2D.monitorable)" % [puzzle_node.name, interactable])

func _collect_interact_components_recursive(n: Node, out: Array[interact_component]) -> void:
	if n is interact_component:
		out.append(n as interact_component)
	for c in n.get_children():
		_collect_interact_components_recursive(c, out)

func _collect_interacted_components_recursive(n: Node, out: Array[interacted_component]) -> void:
	if n is interacted_component:
		out.append(n as interacted_component)
	for c in n.get_children():
		_collect_interacted_components_recursive(c, out)

# ====================================================================================================

func _apply_other_state(other_node: Node, state: int) -> void:
	"""
	应用「其他」类型对象状态
	
	参数:
		other_node: 对象根节点
		state: 0=不可见且不参与物理碰撞, 1=可见且恢复碰撞（子树内所有 CollisionObject2D）
	"""
	if state != 0 and state != 1:
		push_warning("BaseLevel: 「其他」状态应为 0 或 1，节点: %s，收到: %d" % [other_node.name, state])
	if other_node.has_method("set_other_visibility_state"):
		other_node.call("set_other_visibility_state", state)
		print("BaseLevel: 「其他」set_other_visibility_state - 节点: %s, state: %d" % [other_node.name, state])
		return
	if other_node is CanvasItem:
		var visible := state == 1
		(other_node as CanvasItem).visible = visible
		_apply_other_collision_subtree(other_node, visible)
		print("BaseLevel: 「其他」可见性/碰撞 - 节点: %s, visible: %s" % [other_node.name, visible])
	else:
		push_warning("BaseLevel: 「其他」节点 %s 不是 CanvasItem 且无 set_other_visibility_state，无法应用可见性" % other_node.name)

func _apply_other_collision_subtree(root: Node, collision_enabled: bool) -> void:
	if root is CollisionObject2D:
		_apply_other_collision_object2d(root as CollisionObject2D, collision_enabled)
	for c in root.get_children():
		_apply_other_collision_subtree(c, collision_enabled)

func _apply_other_collision_object2d(co: CollisionObject2D, collision_enabled: bool) -> void:
	if collision_enabled:
		if co.has_meta(_META_OTHER_SAVED_COLLISION_LAYER):
			co.collision_layer = int(co.get_meta(_META_OTHER_SAVED_COLLISION_LAYER))
			co.remove_meta(_META_OTHER_SAVED_COLLISION_LAYER)
		if co.has_meta(_META_OTHER_SAVED_COLLISION_MASK):
			co.collision_mask = int(co.get_meta(_META_OTHER_SAVED_COLLISION_MASK))
			co.remove_meta(_META_OTHER_SAVED_COLLISION_MASK)
	else:
		if not co.has_meta(_META_OTHER_SAVED_COLLISION_LAYER):
			co.set_meta(_META_OTHER_SAVED_COLLISION_LAYER, co.collision_layer)
		if not co.has_meta(_META_OTHER_SAVED_COLLISION_MASK):
			co.set_meta(_META_OTHER_SAVED_COLLISION_MASK, co.collision_mask)
		co.collision_layer = 0
		co.collision_mask = 0

# ====================================================================================================

func _apply_light_state(light_node: Node, state: int) -> void:
	"""
	应用灯的状态

	参数:
		light_node: 灯节点（应该是 ElectronicScreen 类型）
		state: 状态（0=关闭, 1=开启）
	"""
	if state != 0 and state != 1:
		push_warning("BaseLevel: 灯状态应为 0 或 1，节点: %s，收到: %d" % [light_node.name, state])
	if light_node is ElectronicScreen:
		var screen := light_node as ElectronicScreen
		screen.turned_on = state != 0
		print("BaseLevel: 已应用灯状态 - 节点: %s, turned_on: %s" % [light_node.name, screen.turned_on])
	else:
		push_warning("BaseLevel: 节点 %s 不是 ElectronicScreen 类型，无法应用灯状态" % light_node.name)

# ====================================================================================================

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

# ====================================================================================================

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
