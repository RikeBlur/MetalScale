class_name GlobalFucntion
extends Node

# 存储的player节点引用
var stored_player: player = null

# 存储的camera节点引用
var stored_camera: AdvancedCamera = null

func _ready():
	# 初始化时读取并存储节点
	_read_and_store_player()
	_read_and_store_camera()

# ============ 读取并存储节点 ============

func _read_and_store_player() -> void:
	"""读取player分组的节点并存储"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		stored_player = players[0]
		print("GlobalFunction: 已存储player节点")
	else:
		push_warning("GlobalFunction: 未找到player分组的节点")

func _read_and_store_camera() -> void:
	"""读取AdvancedCamera节点并存储"""
	# 遍历场景树查找AdvancedCamera
	var root = get_tree().current_scene
	if root:
		stored_camera = _find_camera_recursive(root)
		if stored_camera:
			print("GlobalFunction: 已存储camera节点")
		else:
			push_warning("GlobalFunction: 未找到AdvancedCamera节点")

func _find_camera_recursive(node: Node) -> AdvancedCamera:
	"""递归查找AdvancedCamera节点"""
	if node is AdvancedCamera:
		return node
	
	for child in node.get_children():
		var result = _find_camera_recursive(child)
		if result:
			return result
	
	return null

# ============ 获取存储的节点 ============

func get_player() -> player:
	"""获取存储的player节点"""
	if not stored_player or not is_instance_valid(stored_player):
		# 如果存储的player无效，重新读取
		_read_and_store_player()
	return stored_player

func get_camera() -> AdvancedCamera:
	"""获取存储的camera节点"""
	if not stored_camera or not is_instance_valid(stored_camera):
		# 如果存储的camera无效，重新读取
		_read_and_store_camera()
	return stored_camera

# ============ 场景切换 ============

func change_scene(scene_path: String) -> void:
	"""
	加载并初始化一个场景
	自动在场景中重新添加player和camera
	
	参数:
		scene_path: 场景文件路径
	"""
	# 保存当前player和camera的引用
	var current_player = get_player()
	var current_camera = get_camera()
	
	if not current_player:
		push_error("GlobalFunction: 无法切换场景，player节点不存在")
		return
	
	if not current_camera:
		push_error("GlobalFunction: 无法切换场景，camera节点不存在")
		return
	
	# 从当前父节点移除player和camera（保留它们）
	var player_parent = current_player.get_parent()
	var camera_parent = current_camera.get_parent()
	
	if player_parent:
		player_parent.remove_child(current_player)
	if camera_parent:
		camera_parent.remove_child(current_camera)
	
	print("GlobalFunction: 开始切换场景到 %s" % scene_path)
	
	# 加载新场景
	var result = get_tree().change_scene_to_file(scene_path)
	
	if result != OK:
		push_error("GlobalFunction: 加载场景失败: %s" % scene_path)
		return
	
	# 等待新场景加载完成
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 获取新场景根节点
	var new_scene = get_tree().current_scene
	if not new_scene:
		push_error("GlobalFunction: 无法获取新场景根节点")
		return
	
	# 重新添加player到新场景
	new_scene.add_child(current_player)
	print("GlobalFunction: 已添加player到新场景")
	
	# 检查新场景是否有BaseLevel并应用初始位置和朝向
	var base_level = _find_base_level(new_scene)
	if base_level:
		base_level.apply_initial_values_to_player(current_player)
	else:
		# 如果没有BaseLevel，设置默认位置
		current_player.global_position = Vector2.ZERO
		print("GlobalFunction: 未找到BaseLevel，使用默认位置")
	
	# 重新添加camera到新场景
	new_scene.add_child(current_camera)
	
	# 设置camera的target为player
	current_camera.target = current_player
	
	# 重置camera位置
	current_camera.reset_camera()
	
	print("GlobalFunction: 已添加camera到新场景并设置target为player")
	print("GlobalFunction: 场景切换完成")

func _find_base_level(node: Node) -> BaseLevel:
	"""查找BaseLevel节点"""
	if node is BaseLevel:
		return node
	
	for child in node.get_children():
		var result = _find_base_level(child)
		if result:
			return result
	
	return null
