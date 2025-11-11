class_name scene_manager
extends Node

# ====================================================================================================
# ============================================ 场景字典 ================================================
# ====================================================================================================

# 场景数据字典，key为场景名，value为SceneData资源
var scene_dict: Dictionary = {
	"level_1_1": SceneData.new("res://DEMO/demo1_1118/levels/level_1_1.tscn", "关卡 1-1"),
	"level_1_2": SceneData.new("res://DEMO/demo1_1118/levels/level_1_2.tscn", "关卡 1-2"),
	"level_2_1": SceneData.new("res://DEMO/demo1_1118/levels/level_2_1.tscn", "关卡 2-1")
}

# 当前场景的key
var current_scene_key: String = ""

signal player_reseted

# ====================================================================================================
# ====================================== 读取并存储节点（全局、场景） =====================================
# ====================================================================================================

func _find_base_level(node: Node) -> BaseLevel:
	"""查找BaseLevel节点"""
	if node is BaseLevel:
		return node
	
	for child in node.get_children():
		var result = _find_base_level(child)
		if result:
			return result
	
	return null

func _find_transition_player(node: Node) -> AnimationPlayer:
	"""查找名为transition_player的AnimationPlayer节点"""
	# 优先通过名称直接查找
	var transition_player = node.get_node_or_null("transition_player")
	if transition_player and transition_player is AnimationPlayer:
		return transition_player
	
	# 如果直接查找失败，递归查找
	return _find_transition_player_recursive(node)

func _find_transition_player_recursive(node: Node) -> AnimationPlayer:
	"""递归查找transition_player"""
	if node.name == "transition_player" and node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_transition_player_recursive(child)
		if result:
			return result
	
	return null

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================



# ====================================================================================================
# ============================================ 场景管理 ================================================
# ====================================================================================================

func get_scene_data(scene_key: String) -> SceneData:
	"""
	根据场景key获取场景数据
	
	参数:
		scene_key: 场景的key
	
	返回:
		SceneData对象，如果key不存在则返回null
	"""
	if scene_dict.has(scene_key):
		return scene_dict[scene_key]
	else:
		push_error("SceneManager: 场景key '%s' 不存在于场景字典中" % scene_key)
		return null

func get_scene_path(scene_key: String) -> String:
	"""
	根据场景key获取场景路径
	
	参数:
		scene_key: 场景的key
	
	返回:
		场景路径，如果key不存在则返回空字符串
	"""
	var scene_data = get_scene_data(scene_key)
	if scene_data:
		return scene_data.path
	else:
		return ""

func get_current_scene_key() -> String:
	"""获取当前场景的key"""
	return current_scene_key

func save_current_scene_as_packed() -> PackedScene:
	"""
	将当前场景（包括所有子节点）保存为PackedScene
	用于存档系统
	
	返回:
		PackedScene对象，如果保存失败则返回null
	"""
	var current_scene = get_tree().current_scene
	if not current_scene:
		push_error("SceneManager: 无法获取当前场景")
		return null

	# 创建PackedScene对象
	var packed_scene = PackedScene.new()
	
	# 打包当前场景
	var result = packed_scene.pack(current_scene)
	
	if result != OK:
		push_error("SceneManager: 打包场景失败")
		return null
	
	print("SceneManager: 当前场景已打包为PackedScene")
	return packed_scene

# ====================================================================================================
# ============================================ 场景切换 ================================================
# ====================================================================================================

func change_scene(scene_key: String, scene_to_index: int) -> void:
	"""
	根据场景key切换场景
	自动在场景中重新添加player和camera
	
	参数:
		scene_key: 场景的key（在scene_dict中定义）
	"""
	# 获取场景路径
	var scene_path = get_scene_path(scene_key)
	if scene_path == "":
		return
	
	# 保存当前player和camera的引用
	var current_player = GlobalFunction.get_player()
	var current_camera = GlobalFunction.get_camera()
	
	if not current_player:
		push_error("SceneManager: 无法切换场景，player节点不存在")
		return
	
	if not current_camera:
		push_error("SceneManager: 无法切换场景，camera节点不存在")
		return
	
	# 禁用玩家移动和交互
	current_player.can_move = false
	current_player.can_interact = false
	
	# 播放当前场景的转场结束动画
	var current_scene = get_tree().current_scene
	var current_transition_player = _find_transition_player(current_scene)
	if current_transition_player:
		if current_transition_player.has_animation("transition_end"):
			current_transition_player.play("transition_end")
			await current_transition_player.animation_finished
			print("SceneManager: 转场结束动画播放完成")
	else:
		print("SceneManager: 当前场景没有转场动画")
	
	# 从当前父节点移除player和camera（保留它们）
	var player_parent = current_player.get_parent()
	var camera_parent = current_camera.get_parent()
	if player_parent:
		player_parent.remove_child(current_player)
	if camera_parent:
		camera_parent.remove_child(current_camera)
	
	print("SceneManager: 开始切换场景到 %s (%s)" % [scene_key, scene_path])
	
	# 加载新场景!!
	var result = get_tree().change_scene_to_file(scene_path)
	
	if result != OK:
		push_error("SceneManager: 加载场景失败: %s" % scene_path)
		return
	
	# 更新当前场景key
	current_scene_key = scene_key
	
	# 等待新场景加载完成
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 获取新场景根节点
	var new_scene = get_tree().current_scene
	if not new_scene:
		push_error("SceneManager: 无法获取新场景根节点")
		return
	
	# 重新添加player到新场景
	new_scene.add_child(current_player)
	print("SceneManager: 已添加player到新场景")
	
	# 检查新场景是否有BaseLevel并应用初始位置和朝向
	var base_level = _find_base_level(new_scene)
	if base_level:
		base_level.apply_initial_values_to_player(current_player, scene_to_index)
	else:
		# 如果没有BaseLevel，设置默认位置
		current_player.global_position = Vector2.ZERO
		print("SceneManager: 未找到BaseLevel，使用默认位置")
	
	# 重新添加camera到新场景
	new_scene.add_child(current_camera)
	
	# 设置camera的target为player
	current_camera.target = current_player
	
	# 重置camera位置
	current_camera.reset_camera()
	
	# 玩家位置设置好之后发送该信号
	player_reseted.emit()
	
	print("SceneManager: 已添加camera到新场景并设置target为player")
	
	# 等待新场景加载完成
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 播放新场景的转场开始动画
	var new_transition_player = _find_transition_player(new_scene)
	if new_transition_player:
		if new_transition_player.has_animation("transition_begin"):
			new_transition_player.play("transition_begin")
			await new_transition_player.animation_finished
			print("SceneManager: 转场开始动画播放完成")
	
	# 恢复玩家移动和交互
	current_player.can_move = true
	current_player.can_interact = true
	
	print("SceneManager: 场景切换完成，当前场景key: %s" % current_scene_key)

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
