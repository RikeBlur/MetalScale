class_name SavegameWindow
extends Control

var own_manager: UI_manager = null

func _on_save_pressed() -> void:
	print("保存游戏...")
	safe_remove_self()
	ArchiveManager.quick_save()

func _on_load_pressed() -> void:
	print("读取游戏")
	safe_remove_self()
	ArchiveManager.quick_load()

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
