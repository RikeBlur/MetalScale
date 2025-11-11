class_name SceneData
extends Resource

## 场景数据资源类
## 用于存储单个场景的所有元数据

# 场景文件路径
@export var path: String = ""

# 场景显示名称（可选）
@export var display_name: String = ""

# 其他自定义数据（可扩展）
@export var custom_data: Dictionary = {}


func _init(p_path: String = "", p_display_name: String = ""):
	"""
	初始化场景数据
	
	参数:
		p_path: 场景路径
		p_display_name: 显示名称
		p_description: 描述
	"""
	path = p_path
	display_name = p_display_name

func to_dict() -> Dictionary:
	"""
	将场景数据序列化为字典
	
	返回:
		包含所有场景数据的字典
	"""
	return {
		"path": path,
		"display_name": display_name,
		"custom_data": custom_data
	}

func from_dict(data: Dictionary) -> void:
	"""
	从字典反序列化场景数据
	
	参数:
		data: 场景数据字典
	"""
	if data.is_empty():
		return
	
	if data.has("path"):
		path = data["path"]
	if data.has("display_name"):
		display_name = data["display_name"]
	if data.has("custom_data"):
		custom_data = data["custom_data"]
