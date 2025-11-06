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
	safe_remove_self()
	if save_on_chosen >= 0:
		ArchiveManager.game_save(save_on_chosen)
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
	pass # Replace with function body.

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
# ====================================================================================================
# ====================================================================================================
