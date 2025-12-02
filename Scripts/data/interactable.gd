class_name InteractableData
extends Resource

@export var node_path: NodePath = NodePath("")  # 节点路径（相对于BaseLevel），可在Inspector中选择
@export_enum("门", "可拾取物", "其他机关") var type: int = 0  # 类型：0=门, 1=可拾取物, 2=其他机关
@export var state: int = 0  # 状态（根据type有不同含义）
