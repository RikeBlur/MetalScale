class_name InteractableData
extends Resource

@export var node_path: NodePath = NodePath("")  # 节点路径（相对于BaseLevel），可在Inspector中选择
@export_enum("门", "可拾取物", "对话", "其他机关") var type: int = 0  # 类型：0=门, 1=可拾取物, 2=对话关
@export var state: int = 0  # 状态（根据type有不同含义）
# 对于可拾取物，是否可收集？ 0 否 1 是
# 对于门，0 开 1 锁 2 不能从这一侧打开
# 对于对话，表示 current_flag
