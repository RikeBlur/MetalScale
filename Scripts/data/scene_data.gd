class_name SceneData
extends Resource

## 场景数据资源类
## 用于存储单个场景的所有元数据

# 场景文件路径
@export var path: String = ""

# 场景显示名称（可选）
@export var display_name: String = ""

# 场景中的可交互对象数据（门、可拾取物、机关等）
@export var interactables: Array[InteractableData] = []


func _init(p_path: String = "", p_display_name: String = "", p_interactables_arry: Array[InteractableData] = []):
	"""
	初始化场景数据
	
	参数:
		p_path: 场景路径
		p_display_name: 显示名称
		p_description: 描述
	"""
	path = p_path
	display_name = p_display_name
	interactables = p_interactables_arry

func to_dict() -> Dictionary:
	"""
	将场景数据序列化为字典
	
	返回:
		包含所有场景数据的字典
	"""
	# 序列化 interactables 数组
	var interactables_array = []
	for interactable in interactables:
		if interactable:
			interactables_array.append({
				"node_path": String(interactable.node_path),
				"type": interactable.type,
				"state": interactable.state
			})
	
	return {
		"path": path,
		"display_name": display_name,
		"interactables": interactables_array
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
	
	# 反序列化 interactables 数组
	if data.has("interactables"):
		interactables.clear()
		var interactables_data = data["interactables"]
		for item in interactables_data:
			var interactable = InteractableData.new()
			if item.has("node_path"):
				interactable.node_path = NodePath(item["node_path"])
			if item.has("type"):
				interactable.type = item["type"]
			if item.has("state"):
				interactable.state = item["state"]
			interactables.append(interactable)
