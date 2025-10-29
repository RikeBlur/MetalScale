class_name ExitWindow
extends Control

var own_manager: UI_manager = null

func _on_yes_pressed() -> void:
	"""确认退出游戏"""
	print("确认退出游戏...")
	# 安全释放自身
	safe_remove_self()
	# 退出游戏
	get_tree().quit()

func _on_no_pressed() -> void:
	"""取消退出，关闭退出窗口"""
	print("取消退出游戏")
	safe_remove_self()

func safe_remove_self() -> void:
	"""安全地释放自身节点"""
	# 通知UI管理器移除当前UI实例（在清理引用之前）
	if own_manager:
		own_manager.remove_ui(UI_manager.UI_component.EXITWINDOWS)
	
	# 清理引用，防止内存泄漏
	own_manager = null
	
	# 使用queue_free()安全释放节点
	queue_free()
	print("ExitWindow: 安全释放自身节点")
