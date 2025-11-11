class_name GlobalFucntion
extends Node

# 存储的player节点引用
var stored_player: player = null

# 存储的camera节点引用
var stored_camera: AdvancedCamera = null

# ====================================================================================================
# ====================================== 读取并存储节点（全局、场景） =====================================
# ====================================================================================================

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

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
	
	
	
# ====================================================================================================
# ========================================= 获取已存储的全局节点 ========================================
# ====================================================================================================

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
	
# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
