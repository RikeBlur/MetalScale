class_name scene_manager
extends Node

# ====================================================================================================
# ============================================ 场景字典 ================================================
# ====================================================================================================

# 场景数据字典，key为场景名，value为SceneData资源, Interactables 先全部设为 []
var scene_dict: Dictionary = {
	#"level_1_1": SceneData.new("res://DEMO/demo1_1118/levels/level_1_1.tscn", "关卡 1-1", []),
	#"level_1_2": SceneData.new("res://DEMO/demo1_1118/levels/level_1_2.tscn", "关卡 1-2", []),
	#"level_2_1": SceneData.new("res://DEMO/demo1_1118/levels/level_2_1.tscn", "关卡 2-1", []),
	#"level_2_2": SceneData.new("res://DEMO/demo1_1118/levels/level_2_2.tscn", "关卡 2-2", []),
	"0-0": SceneData.new("res://DEMO/AdiosToMe/Levels/0/TeacherRestRoom.tscn", "教师休息室", []),
	"0-1": SceneData.new("res://DEMO/AdiosToMe/Levels/0/CorridorSecondFloor.tscn", "二层走廊", [])
}

# 当前场景的key
var current_scene_key: String = ""

# 全局转场场景路径（挂到 Root 上，与当前场景同级，避免被 change_scene_to_file 一起销毁）
const TRANSITION_SCENE_PATH: String = "res://System/RPG/view/transition_Mask.tscn"

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

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================

# ====================================================================================================
# =========================================== 场景信息更新 =============================================
# ====================================================================================================

func update_interactable_state() -> void:
	pass

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
	var current_player = GameManager.get_player()
	var current_camera = GameManager.get_camera()
	
	if not current_player:
		push_error("SceneManager: 无法切换场景，player节点不存在")
		return
	
	if not current_camera:
		push_error("SceneManager: 无法切换场景，camera节点不存在")
		return
	
	# 进入加载状态
	GameManager.current_state = GameManager.GameState.LOADING
	GameManager.Loading.emit()
	current_player.can_move = false
	current_player.can_act = false
	current_player.can_interact = false
	
	# 在 Root 上实例化全局转场（与当前场景同级，change_scene_to_file 不会销毁它）
	var transition_packed = load(TRANSITION_SCENE_PATH) as PackedScene
	if not transition_packed:
		push_error("SceneManager: 无法加载转场场景: %s" % TRANSITION_SCENE_PATH)
		return
	var transition_node = transition_packed.instantiate()
	transition_node.name = "SceneManagerTransition"
	get_tree().root.add_child(transition_node)
	var transition_player_node = transition_node.get_node_or_null("ColorRect/TransitionPlayer")
	if transition_player_node and transition_player_node is AnimationPlayer:
		if transition_player_node.has_animation("appear"):
			transition_player_node.play("appear")
			await transition_player_node.animation_finished
			print("SceneManager: 转场 appear 播放完成")
	
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
	
	# 重新添加player到新场景（若有 ObjectAndCharacter 则加入其下以参与 y_sort，否则加入根节点）
	var new_player_parent: Node = new_scene
	var object_and_character = new_scene.get_node_or_null("ObjectAndCharacter")
	if object_and_character and object_and_character is Node2D:
		new_player_parent = object_and_character
	new_player_parent.add_child(current_player)
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
	
	# 播放全局转场的 disappear 并销毁
	var root_transition = get_tree().root.get_node_or_null("SceneManagerTransition")
	if root_transition:
		var end_player = root_transition.get_node_or_null("ColorRect/TransitionPlayer")
		if end_player and end_player is AnimationPlayer and end_player.has_animation("disappear"):
			end_player.play("disappear")
			await end_player.animation_finished
			print("SceneManager: 转场 disappear 播放完成")
		root_transition.queue_free()
	
	# 恢复玩家移动和交互，切回运行状态
	current_player.can_move = true
	current_player.can_act = true
	current_player.can_interact = true
	GameManager.current_state = GameManager.GameState.RUNNING
	
	print("SceneManager: 场景切换完成，当前场景key: %s" % current_scene_key)

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
