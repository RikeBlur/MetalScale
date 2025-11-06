class_name archive_manager
extends Node

# ====================================================================================================
# ============================================ 存档路径 ================================================
# ====================================================================================================

# 快速存档文件路径
const QUICK_SAVE_PATH: String = "user://quick_save.json"

var save_path_dict: Dictionary = {
	0: "user://save_0.json",
	1: "user://save_1.json",
	2: "user://save_2.json",
	3: "user://save_3.json",
	4: "user://save_4.json",
	5: "user://save_5.json"
}

var save_name_dict: Dictionary = {
	0: "",
	1: "",
	2: "",
	3: "",
	4: "",
	5: ""
}

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================



# ====================================================================================================
# ======================================== 序列化辅助方法 =============================================
# ====================================================================================================

func _serialize_player_data(player_node: player) -> Dictionary:
	"""
	序列化玩家数据
	
	参数:
		player_node: player节点
	
	返回:
		包含所有玩家数据的字典
	"""
	if not player_node:
		return {}
	
	var data = {
		"player_walk_speed_max": player_node.player_walk_speed_max,
		"player_run_speed_max": player_node.player_run_speed_max,
		"player_walk_speed_min": player_node.player_walk_speed_min,
		"player_run_speed_min": player_node.player_run_speed_min,
		"player_walk_acceleration": player_node.player_walk_acceleration,
		"player_run_acceleration": player_node.player_run_acceleration,
		"can_move": player_node.can_move,
		"can_interact": player_node.can_interact,
		"character": player_node.character,
		"player_direction": {"x": player_node.player_direction.x, "y": player_node.player_direction.y},
		"player_last_direction": {"x": player_node.player_last_direction.x, "y": player_node.player_last_direction.y},
		"tool": player_node.tool,
		"health_max": player_node.health_max,
		"health_now": player_node.health_now,
		"is_died": player_node.is_died,
		"global_position": {"x": player_node.global_position.x, "y": player_node.global_position.y}
	}
	
	return data

func _deserialize_player_data(player_node: player, data: Dictionary) -> void:
	"""
	反序列化玩家数据
	
	参数:
		player_node: player节点
		data: 玩家数据字典
	"""
	if not player_node or data.is_empty():
		return
	
	# 恢复所有变量
	if data.has("player_walk_speed_max"):
		player_node.player_walk_speed_max = data["player_walk_speed_max"]
	if data.has("player_run_speed_max"):
		player_node.player_run_speed_max = data["player_run_speed_max"]
	if data.has("player_walk_speed_min"):
		player_node.player_walk_speed_min = data["player_walk_speed_min"]
	if data.has("player_run_speed_min"):
		player_node.player_run_speed_min = data["player_run_speed_min"]
	if data.has("player_walk_acceleration"):
		player_node.player_walk_acceleration = data["player_walk_acceleration"]
	if data.has("player_run_acceleration"):
		player_node.player_run_acceleration = data["player_run_acceleration"]
	if data.has("can_move"):
		player_node.can_move = data["can_move"]
	if data.has("can_interact"):
		player_node.can_interact = data["can_interact"]
	if data.has("character"):
		player_node.character = data["character"]
	if data.has("player_direction"):
		player_node.player_direction = Vector2(data["player_direction"]["x"], data["player_direction"]["y"])
	if data.has("player_last_direction"):
		player_node.player_last_direction = Vector2(data["player_last_direction"]["x"], data["player_last_direction"]["y"])
	if data.has("tool"):
		player_node.tool = data["tool"]
	if data.has("health_max"):
		player_node.health_max = data["health_max"]
	if data.has("health_now"):
		player_node.health_now = data["health_now"]
	if data.has("is_died"):
		player_node.is_died = data["is_died"]
	if data.has("global_position"):
		player_node.global_position = Vector2(data["global_position"]["x"], data["global_position"]["y"])

func _serialize_scene_data(scene_data: SceneData) -> Dictionary:
	"""
	序列化SceneData
	
	参数:
		scene_data: SceneData资源
	
	返回:
		SceneData的字典表示
	"""
	if not scene_data:
		return {}
	
	return {
		"path": scene_data.path,
		"display_name": scene_data.display_name,
		"custom_data": scene_data.custom_data
	}

func _deserialize_scene_data(data: Dictionary) -> SceneData:
	"""
	反序列化SceneData
	
	参数:
		data: SceneData的字典表示
	
	返回:
		SceneData资源对象
	"""
	var scene_data = SceneData.new()
	
	if data.has("path"):
		scene_data.path = data["path"]
	if data.has("display_name"):
		scene_data.display_name = data["display_name"]
	if data.has("custom_data"):
		scene_data.custom_data = data["custom_data"]
	
	return scene_data

func _serialize_all_scenes(scene_mgr: scene_manager) -> Dictionary:
	"""
	序列化所有场景数据
	
	参数:
		scene_mgr: scene_manager节点
	
	返回:
		所有场景的字典表示
	"""
	var scenes_dict = {}
	
	for key in scene_mgr.scene_dict.keys():
		var scene_data = scene_mgr.scene_dict[key]
		scenes_dict[key] = _serialize_scene_data(scene_data)
	
	return scenes_dict

func _deserialize_all_scenes(scenes_dict: Dictionary) -> Dictionary:
	"""
	反序列化所有场景数据
	
	参数:
		scenes_dict: 场景字典的序列化数据
	
	返回:
		恢复的scene_dict
	"""
	var result = {}
	
	for key in scenes_dict.keys():
		result[key] = _deserialize_scene_data(scenes_dict[key])
	
	return result

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================



# ====================================================================================================
# ========================================== 快速存档系统 ==============================================
# ====================================================================================================

func quick_save() -> bool:
	"""
	快速存档：将游戏状态保存为JSON文件
	
	返回:
		true表示保存成功，false表示失败
	"""
	# 获取scene_manager引用
	var scene_mgr = get_node_or_null("/root/SceneManager")
	if not scene_mgr:
		push_error("ArchiveManager: 未找到SceneManager节点")
		return false
	
	# 获取GlobalFunction引用
	var global_func = get_node_or_null("/root/GlobalFunction")
	if not global_func:
		push_error("ArchiveManager: 未找到GlobalFunction节点")
		return false
	
	# 获取player节点
	var player_node = global_func.get_player()
	if not player_node:
		push_error("ArchiveManager: 未找到player节点")
		return false
	
	# 构建存档数据
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		
		# 玩家信息
		"player": _serialize_player_data(player_node),
		
		# 场景信息
		"scene": {
			"scene_now": scene_mgr.get_current_scene_key(),
			"scene_dict": _serialize_all_scenes(scene_mgr)
		},
		
		# NPC信息（暂时空着）
		"npc": {}
	}
	
	# 转换为JSON字符串
	var json_string = JSON.stringify(save_data, "\t")
	
	# 写入文件
	var file = FileAccess.open(QUICK_SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("ArchiveManager: 无法打开存档文件进行写入: %s" % QUICK_SAVE_PATH)
		return false
	
	file.store_string(json_string)
	file.close()
	
	print("ArchiveManager: 快速存档已保存到 %s" % QUICK_SAVE_PATH)
	return true

func quick_load() -> bool:
	"""
	快速读档：从JSON文件加载游戏状态
	
	返回:
		true表示加载成功，false表示失败
	"""
	# 检查存档文件是否存在
	if not FileAccess.file_exists(QUICK_SAVE_PATH):
		push_error("ArchiveManager: 快速存档文件不存在: %s" % QUICK_SAVE_PATH)
		return false
	
	# 读取文件
	var file = FileAccess.open(QUICK_SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("ArchiveManager: 无法打开存档文件进行读取: %s" % QUICK_SAVE_PATH)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("ArchiveManager: JSON解析失败，错误行: %d" % json.get_error_line())
		return false
	
	var save_data = json.data
	
	# 验证数据结构
	if not save_data.has("player") or not save_data.has("scene"):
		push_error("ArchiveManager: 存档数据格式错误")
		return false
	
	# 获取scene_manager引用
	var scene_mgr = get_node_or_null("/root/SceneManager")
	if not scene_mgr:
		push_error("ArchiveManager: 未找到SceneManager节点")
		return false
	
	# 获取GlobalFunction引用
	var global_func = get_node_or_null("/root/GlobalFunction")
	if not global_func:
		push_error("ArchiveManager: 未找到GlobalFunction节点")
		return false
	
	# Step 1: 用保存好的SceneData重置scene_manager的字典
	if save_data["scene"].has("scene_dict"):
		scene_mgr.scene_dict = _deserialize_all_scenes(save_data["scene"]["scene_dict"])
		print("ArchiveManager: 已恢复场景字典")
	
	# 获取scene_now
	var scene_now = save_data["scene"].get("scene_now", "")
	if scene_now == "":
		push_error("ArchiveManager: 存档中没有当前场景信息")
		return false
	
	# 检查是否存在player节点（判断是否是首次加载）
	var player_node = global_func.get_player()
	var is_first_load = (player_node == null)
	
	if is_first_load:
		# 首次加载（游戏刚启动）- 直接加载场景
		print("ArchiveManager: 首次加载，直接加载场景")
		
		var scene_path = scene_mgr.get_scene_path(scene_now)
		if scene_path == "":
			return false
		
		# 直接加载场景
		var result = get_tree().change_scene_to_file(scene_path)
		if result != OK:
			push_error("ArchiveManager: 加载场景失败: %s" % scene_path)
			return false
		
		# 更新当前场景key
		scene_mgr.current_scene_key = scene_now
		
		# 等待场景加载完成
		await get_tree().process_frame
		await get_tree().process_frame
		
		# 获取新加载场景中的player节点
		player_node = global_func.get_player()
		if not player_node:
			push_error("ArchiveManager: 场景加载后未找到player节点")
			return false
		
	else:
		# 已有场景和player - 使用change_scene切换
		print("ArchiveManager: 使用change_scene切换场景")
		await scene_mgr.change_scene(scene_now)
		
		# 重新获取player节点引用
		player_node = global_func.get_player()
	
	# 恢复player参数
	if player_node and save_data.has("player"):
		_deserialize_player_data(player_node, save_data["player"])
		
		# 再次显式设置位置，确保覆盖 BaseLevel 的初始位置设置
		var saved_position = Vector2(save_data["player"]["global_position"]["x"], save_data["player"]["global_position"]["y"])
		player_node.global_position = saved_position
		
		print("ArchiveManager: 已恢复玩家数据")
	else:
		push_warning("ArchiveManager: 无法恢复玩家数据")
	
	print("ArchiveManager: 快速读档完成")
	return true

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================



# ====================================================================================================
# ========================================== 正经存档系统 ==============================================
# ====================================================================================================

func game_save(index : int) -> bool:
	# 获取scene_manager引用
	var scene_mgr = get_node_or_null("/root/SceneManager")
	if not scene_mgr:
		push_error("ArchiveManager: 未找到SceneManager节点")
		return false
	
	# 获取GlobalFunction引用
	var global_func = get_node_or_null("/root/GlobalFunction")
	if not global_func:
		push_error("ArchiveManager: 未找到GlobalFunction节点")
		return false
	
	# 获取player节点
	var player_node = global_func.get_player()
	if not player_node:
		push_error("ArchiveManager: 未找到player节点")
		return false
	
	# 构建存档数据
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		
		# 玩家信息
		"player": _serialize_player_data(player_node),
		
		# 场景信息
		"scene": {
			"scene_now": scene_mgr.get_current_scene_key(),
			"scene_dict": _serialize_all_scenes(scene_mgr)
		},
		
		# NPC信息（暂时空着）
		"npc": {}
	}
	
	# 转换为JSON字符串
	var json_string = JSON.stringify(save_data, "\t")
	
	# 写入文件
	var save_path = save_path_dict[index]
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("ArchiveManager: 无法打开存档文件进行写入: %s" % save_path)
		return false
	
	file.store_string(json_string)
	file.close()
	
	print("ArchiveManager: 快速存档已保存到 %s" % save_path)
	return true

func game_load(index : int) -> bool:
	"""
	快速读档：从JSON文件加载游戏状态
	
	返回:
		true表示加载成功，false表示失败
	"""
	# 检查存档文件是否存在
	var save_path = save_path_dict[index]
	if not FileAccess.file_exists(save_path):
		push_error("ArchiveManager: 快速存档文件不存在: %s" % save_path)
		return false
	
	# 读取文件
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		push_error("ArchiveManager: 无法打开存档文件进行读取: %s" % save_path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("ArchiveManager: JSON解析失败，错误行: %d" % json.get_error_line())
		return false
	
	var save_data = json.data
	
	# 验证数据结构
	if not save_data.has("player") or not save_data.has("scene"):
		push_error("ArchiveManager: 存档数据格式错误")
		return false
	
	# 获取scene_manager引用
	var scene_mgr = get_node_or_null("/root/SceneManager")
	if not scene_mgr:
		push_error("ArchiveManager: 未找到SceneManager节点")
		return false
	
	# 获取GlobalFunction引用
	var global_func = get_node_or_null("/root/GlobalFunction")
	if not global_func:
		push_error("ArchiveManager: 未找到GlobalFunction节点")
		return false
	
	# Step 1: 用保存好的SceneData重置scene_manager的字典
	if save_data["scene"].has("scene_dict"):
		scene_mgr.scene_dict = _deserialize_all_scenes(save_data["scene"]["scene_dict"])
		print("ArchiveManager: 已恢复场景字典")
	
	# 获取scene_now
	var scene_now = save_data["scene"].get("scene_now", "")
	if scene_now == "":
		push_error("ArchiveManager: 存档中没有当前场景信息")
		return false
	
	# 检查是否存在player节点（判断是否是首次加载）
	var player_node = global_func.get_player()
	var is_first_load = (player_node == null)
	
	if is_first_load:
		# 首次加载（游戏刚启动）- 直接加载场景
		print("ArchiveManager: 首次加载，直接加载场景")
		
		var scene_path = scene_mgr.get_scene_path(scene_now)
		if scene_path == "":
			return false
		
		# 直接加载场景
		var result = get_tree().change_scene_to_file(scene_path)
		if result != OK:
			push_error("ArchiveManager: 加载场景失败: %s" % scene_path)
			return false
		
		# 更新当前场景key
		scene_mgr.current_scene_key = scene_now
		
		# 等待场景加载完成
		await get_tree().process_frame
		await get_tree().process_frame
		
		# 获取新加载场景中的player节点
		player_node = global_func.get_player()
		if not player_node:
			push_error("ArchiveManager: 场景加载后未找到player节点")
			return false
		
	else:
		# 已有场景和player - 使用change_scene切换
		print("ArchiveManager: 使用change_scene切换场景")
		await scene_mgr.change_scene(scene_now)
		
		# 重新获取player节点引用
		player_node = global_func.get_player()
	
	# 恢复player参数
	if player_node and save_data.has("player"):
		_deserialize_player_data(player_node, save_data["player"])
		
		# 再次显式设置位置，确保覆盖 BaseLevel 的初始位置设置
		var saved_position = Vector2(save_data["player"]["global_position"]["x"], save_data["player"]["global_position"]["y"])
		player_node.global_position = saved_position
		
		print("ArchiveManager: 已恢复玩家数据")
	else:
		push_warning("ArchiveManager: 无法恢复玩家数据")
	
	print("ArchiveManager: 快速读档完成")
	return true

func save_delete(index: int) -> bool:
	"""
	删除指定的存档
	
	参数:
		index: 存档索引
	
	返回:
		true表示删除成功，false表示失败
	"""
	# 检查索引是否有效
	if not save_path_dict.has(index):
		push_error("ArchiveManager: 无效的存档索引: %d" % index)
		return false
	
	var save_path = save_path_dict[index]
	
	# 检查存档文件是否存在
	if not FileAccess.file_exists(save_path):
		push_warning("ArchiveManager: 存档文件不存在，无需删除: %s" % save_path)
		return true
	
	# 删除文件
	var err = DirAccess.remove_absolute(save_path)
	if err != OK:
		push_error("ArchiveManager: 删除存档文件失败: %s, 错误代码: %d" % [save_path, err])
		return false
	
	# 清空存档名称
	save_name_dict[index] = ""
	
	print("ArchiveManager: 已删除存档: %s" % save_path)
	return true

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
