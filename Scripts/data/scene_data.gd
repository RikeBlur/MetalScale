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

