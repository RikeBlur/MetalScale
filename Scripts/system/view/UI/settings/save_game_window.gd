class_name SavegameWindow
extends Control

@export var saveboxes: Array[SaveBox] = []

var own_manager: UI_manager = null
var save_on_chosen : int = -1

# ====================================================================================================
# ============================================ 操作按钮 ================================================
# ====================================================================================================

func _on_save_pressed() -> void:
	print("保存游戏...")
	if save_on_chosen >= 0:
		ArchiveManager.game_save(save_on_chosen)
		call_deferred("update_save_info", save_on_chosen)
	else :
		print("请选择存档序号！！")

func _on_load_pressed() -> void:
	print("读取游戏")
	safe_remove_self()
	if save_on_chosen >= 0:
		ArchiveManager.game_load(save_on_chosen)
	else :
		print("请选择存档序号！！")

func _on_delete_pressed() -> void:
	print("删除游戏...")
	if save_on_chosen >= 0:
		ArchiveManager.save_delete(save_on_chosen)
		call_deferred("update_save_info", save_on_chosen)
	else :
		print("请选择存档序号！！")

func safe_remove_self() -> void:
	"""安全地释放自身节点"""
	# 通知UI管理器移除当前UI实例（在清理引用之前）
	if own_manager:
		own_manager.remove_ui(UI_manager.UI_component.SAVEGAMEWINDOW)
	
	# 清理引用，防止内存泄漏
	own_manager = null
	
	# 使用queue_free()安全释放节点
	queue_free()
	print("ExitWindow: 安全释放自身节点")
	
# ====================================================================================================
# ====================================================================================================
# ====================================================================================================


# ====================================================================================================
# ============================================ 存档选择 ================================================
# ====================================================================================================

func update_save_on_chosen() -> void:
	for i in saveboxes.size():
		if is_instance_valid(saveboxes[i]):
			if saveboxes[i].button.button_pressed == true:
				save_on_chosen = i 
			else :
				continue

func _process(_delta: float) -> void:
	update_save_on_chosen()

# ====================================================================================================
# ==============================================存档信息显示============================================
# ====================================================================================================

func _ready() -> void:
	for i in saveboxes.size():
		call_deferred("update_save_info", i)

func update_save_info(index : int) -> void:
	"""
	根据存档状态更新存档信息label
	
	参数:
		index: 存档索引
	"""
	# 检查索引是否有效
	if index < 0 or index >= saveboxes.size():
		push_error("SavegameWindow: 无效的存档索引: %d" % index)
		return
	
	var savebox = saveboxes[index]
	if not is_instance_valid(savebox) or not savebox.label:
		push_error("SavegameWindow: 存档槽位 %d 无效" % index)
		return
	
	# 检查存档状态
	var has_save = ArchiveManager.save_state_dict.get(index, false)
	
	if not has_save:
		# 空存档：显示 "空存档\n\nindex"
		savebox.label.text = "空存档\n\n%d" % index
	else:
		# 非空存档：需要从JSON文件读取信息
		var save_path = ArchiveManager.ROOT_DIR.path_join(ArchiveManager.save_path_dict[index])
		
		# 读取存档文件
		if not FileAccess.file_exists(save_path):
			# 文件不存在，显示为空存档
			savebox.label.text = "空存档\n\n%d" % index
			return
		
		var file = FileAccess.open(save_path, FileAccess.READ)
		if not file:
			push_error("SavegameWindow: 无法读取存档文件: %s" % save_path)
			savebox.label.text = "存档 %d\n\n读取失败" % index
			return
		
		var json_string = file.get_as_text()
		file.close()
		
		# 解析JSON
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result != OK:
			push_error("SavegameWindow: JSON解析失败，错误行: %d" % json.get_error_line())
			savebox.label.text = "存档 %d\n\n解析失败" % index
			return
		
		var save_data = json.data
		
		# 提取信息
		var scene_name: String = "未知场景"
		var archive_time: String = "00:00:00"
		
		# 获取存档运行时长（毫秒）
		if save_data.has("game_archive_msec"):
			archive_time = _format_msec(save_data["game_archive_msec"])
		
		# 获取场景名称
		if save_data.has("scene"):
			var scene_data = save_data["scene"]
			if scene_data.has("scene_now") and scene_data.has("scene_dict"):
				var scene_now = scene_data["scene_now"]
				var scene_dict = scene_data["scene_dict"]
				if scene_dict.has(scene_now):
					var current_scene = scene_dict[scene_now]
					if current_scene.has("display_name"):
						scene_name = current_scene["display_name"]
		
		# 格式化显示文本：存档index\n\n'scene_name'\n\n'archive_time'
		savebox.label.text = "存档 %d\n\n%s\n\n%s" % [index, scene_name, archive_time]

func _format_msec(msec: int) -> String:
	"""将毫秒格式化为 HH:MM:SS"""
	var total_seconds = int(msec / 1000.0)
	var hours = int(total_seconds / 3600.0)
	var minutes = int((total_seconds % 3600) / 60.0)
	var seconds = total_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
