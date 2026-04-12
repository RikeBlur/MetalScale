class_name archive_manager
extends Node

# ====================================================================================================
# ============================================ 存档路径 ================================================
# ====================================================================================================

# 快速存档文件路径
const QUICK_SAVE_PATH: String = "user://quick_save.json"

# 存档根目录
const ROOT_DIR: String = "user://"

# 存档文件名字典
var save_path_dict: Dictionary = {
	0: "save_0.json",
	1: "save_1.json",
	2: "save_2.json",
	3: "save_3.json",
	4: "save_4.json",
	5: "save_5.json"
}

# 存档状态字典
var save_state_dict: Dictionary = {
	0: false,
	1: false,
	2: false,
	3: false,
	4: false,
	5: false
}

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================

func check_save_state() -> void:
	"""
	检查存档状态：通过查看根目录下是否存在save_path_dict中的路径
	初始化存档状态save_state_dict
	false表示无存档；true表示有存档
	"""
	# 遍历所有存档路径
	for slot_id in save_path_dict.keys():
		var save_path = ROOT_DIR.path_join(save_path_dict[slot_id])
		
		# 检查文件是否存在
		if FileAccess.file_exists(save_path):
			save_state_dict[slot_id] = true
		else:
			save_state_dict[slot_id] = false
	
	print("ArchiveManager: 存档状态检查完成")


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
	
	# 创建PlayerData实例并从player节点读取数据
	var player_data = PlayerData.new()
	player_data.from_player_node(player_node)
	
	# 使用PlayerData的to_dict方法序列化
	return player_data.to_dict()

func _deserialize_player_data(player_node: player, data: Dictionary) -> void:
	"""
	反序列化玩家数据
	
	参数:
		player_node: player节点
		data: 玩家数据字典
	"""
	if not player_node or data.is_empty():
		return
	
	# 创建PlayerData实例并从字典加载数据
	var player_data = PlayerData.new()
	player_data.from_dict(data)
	
	# 使用PlayerData的apply_to_player_node方法应用到player节点
	player_data.apply_to_player_node(player_node)

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
	
	# 使用SceneData的to_dict方法序列化
	return scene_data.to_dict()

func _deserialize_scene_data(data: Dictionary) -> SceneData:
	"""
	反序列化SceneData
	
	参数:
		data: SceneData的字典表示
	
	返回:
		SceneData资源对象
	"""
	var scene_data = SceneData.new()
	
	# 使用SceneData的from_dict方法反序列化
	scene_data.from_dict(data)
	
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

func _get_npc_manager() -> npc_manager:
	return get_node_or_null("/root/NPCManager") as npc_manager

func _serialize_all_npcs(npc_mgr: npc_manager) -> Dictionary:
	var result := {}
	if not npc_mgr:
		return result

	if npc_mgr.has_method("_update_inscene_npc_data"):
		npc_mgr._update_inscene_npc_data()

	for npc_id in npc_mgr.npc_dict.keys():
		var npc_data: NPCData = npc_mgr.npc_dict[npc_id]
		if not npc_data:
			continue

		var data := npc_data.to_dict()
		if npc_data.npc_node:
			data["npc_node_path"] = npc_data.npc_node.resource_path
		result[npc_id] = data

	return result

func _deserialize_all_npcs(npc_mgr: npc_manager, npc_dict_data: Dictionary) -> void:
	if not npc_mgr or npc_dict_data.is_empty():
		return

	npc_mgr._npc_instances.clear()
	npc_mgr._eye_wander_timers.clear()
	npc_mgr._eye_chase_timers.clear()

	for npc_id in npc_dict_data.keys():
		var data: Dictionary = npc_dict_data[npc_id]
		var npc_data: NPCData = npc_mgr.npc_dict.get(npc_id)

		if not npc_data:
			var npc_scene_path: String = data.get("npc_node_path", "")
			var npc_scene: PackedScene = null
			if npc_scene_path != "":
				npc_scene = load(npc_scene_path) as PackedScene
			if not npc_scene:
				push_warning("ArchiveManager: skip unknown NPC '%s' without a valid scene path" % npc_id)
				continue
			npc_data = NPCData.new()
			npc_data.npc_node = npc_scene
			npc_mgr.npc_dict[npc_id] = npc_data

		npc_data.from_dict(data)

	print("ArchiveManager: restored NPC data")

func _refresh_current_scene_npcs(npc_mgr: npc_manager) -> void:
	if npc_mgr and npc_mgr.has_method("_on_player_reseted"):
		npc_mgr._on_player_reseted()

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================


# ====================================================================================================
# ========================================== 正经存档系统 ==============================================
# ====================================================================================================

func game_save(index : int) -> bool:
	# 修改存档状态
	if save_state_dict[index] == false : 
		save_state_dict[index] = true
	else :
		print("会覆盖存档！")
	# 获取scene_manager引用
	var scene_mgr = get_node_or_null("/root/SceneManager")
	if not scene_mgr:
		push_error("ArchiveManager: 未找到SceneManager节点")
		return false
	
	# 获取player节点
	var player_node = GameManager.get_player()
	if not player_node:
		push_error("ArchiveManager: 未找到player节点")
		return false
	
	# 构建存档数据
	var npc_mgr := _get_npc_manager()

	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"game_archive_msec": GameManager.game_archive_msec,
		
		# 玩家信息
		"player": _serialize_player_data(player_node),
		
		# 场景信息
		"scene": {
			"scene_now": scene_mgr.get_current_scene_key(),
			"scene_dict": _serialize_all_scenes(scene_mgr)
		},
		
		# NPC信息
		"npc": _serialize_all_npcs(npc_mgr)
	}
	
	# 转换为JSON字符串
	var json_string = JSON.stringify(save_data, "\t")
	
	# 写入文件
	var save_path = ROOT_DIR.path_join(save_path_dict[index])
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("ArchiveManager: 无法打开存档文件进行写入: %s" % save_path)
		return false
	
	file.store_string(json_string)
	file.close()
	
	print("ArchiveManager: 快速存档已保存到 %s" % save_path)
	return true

func game_load(index : int) -> bool:
	# 游戏总线 pipeline
	GameManager.set_game_state(GameManager.GameState.LOADING)
	GameManager.Loading.emit()
	print("ArchiveManager: 开始读档")

	# 检查存档文件是否存在
	var save_path = ROOT_DIR.path_join(save_path_dict[index])
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
	
	# 恢复游戏存档时长（毫秒）
	GameManager.game_archive_msec = save_data.get("game_archive_msec", 0)
	
	# 获取scene_manager引用
	var scene_mgr = get_node_or_null("/root/SceneManager")
	if not scene_mgr:
		push_error("ArchiveManager: 未找到SceneManager节点")
		return false
	
	# Step 1: 用保存好的SceneData重置scene_manager的字典
	var npc_mgr := _get_npc_manager()

	if save_data["scene"].has("scene_dict"):
		scene_mgr.scene_dict = _deserialize_all_scenes(save_data["scene"]["scene_dict"])
		print("ArchiveManager: 已恢复场景字典")

	if save_data.has("npc"):
		_deserialize_all_npcs(npc_mgr, save_data["npc"])
	
	# 获取scene_now
	var scene_now = save_data["scene"].get("scene_now", "")
	if scene_now == "":
		push_error("ArchiveManager: 存档中没有当前场景信息")
		return false
	
	# 检查是否存在player节点（判断是否是首次加载）
	var player_node = GameManager.get_player()
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
		player_node = GameManager.get_player()
		if not player_node:
			push_error("ArchiveManager: 场景加载后未找到player节点")
			return false
		
	else:
		# 已有场景和player - 使用change_scene切换
		print("ArchiveManager: 使用change_scene切换场景")
		scene_mgr.change_scene(scene_now, 0)
		
		# 等待player_reseted信号发出（表示玩家位置已设置好）
		await scene_mgr.player_reseted
		
		# 重新获取player节点引用
		player_node = GameManager.get_player()
	
	_refresh_current_scene_npcs(npc_mgr)

	# 恢复player参数
	if player_node and save_data.has("player"):
		_deserialize_player_data(player_node, save_data["player"])
		
		# 再次显式设置位置，确保覆盖 BaseLevel 的初始位置设置
		var saved_position = Vector2(save_data["player"]["global_position"]["x"], save_data["player"]["global_position"]["y"])
		player_node.global_position = saved_position
		
		print("ArchiveManager: 已恢复玩家数据")
	else:
		push_warning("ArchiveManager: 无法恢复玩家数据")
	
	print("ArchiveManager: 读档完成")
	GameManager.Loaded.emit()

	return true

func save_delete(index: int) -> bool:
	# 检查索引是否有效
	if not save_path_dict.has(index):
		push_error("ArchiveManager: 无效的存档索引: %d" % index)
		return false
	
	var save_path = ROOT_DIR.path_join(save_path_dict[index])
	
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
	save_state_dict[index] = false
	
	print("ArchiveManager: 已删除存档: %s" % save_path)
	return true

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
	
	# 获取player节点
	var player_node = GameManager.get_player()
	if not player_node:
		push_error("ArchiveManager: 未找到player节点")
		return false
	
	# 构建存档数据
	var npc_mgr := _get_npc_manager()

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
		
		# NPC信息
		"npc": _serialize_all_npcs(npc_mgr)
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
	
	# Step 1: 用保存好的SceneData重置scene_manager的字典
	var npc_mgr := _get_npc_manager()

	if save_data["scene"].has("scene_dict"):
		scene_mgr.scene_dict = _deserialize_all_scenes(save_data["scene"]["scene_dict"])
		print("ArchiveManager: 已恢复场景字典")

	if save_data.has("npc"):
		_deserialize_all_npcs(npc_mgr, save_data["npc"])
	
	# 获取scene_now
	var scene_now = save_data["scene"].get("scene_now", "")
	if scene_now == "":
		push_error("ArchiveManager: 存档中没有当前场景信息")
		return false
	
	# 检查是否存在player节点（判断是否是首次加载）
	var player_node = GameManager.get_player()
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
		player_node = GameManager.get_player()
		if not player_node:
			push_error("ArchiveManager: 场景加载后未找到player节点")
			return false
		
	else:
		# 已有场景和player - 使用change_scene切换
		print("ArchiveManager: 使用change_scene切换场景")
		await scene_mgr.change_scene(scene_now)
		
		# 重新获取player节点引用
		player_node = GameManager.get_player()
	
	_refresh_current_scene_npcs(npc_mgr)

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
