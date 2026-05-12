class_name InteractableData
extends Resource

@export var node_path: NodePath = NodePath("")  # 节点路径（相对于BaseLevel），可在Inspector中选择
@export_enum("门", "可拾取物", "对话", "谜题", "其他", "灯") var type: int = 0  # 类型：0=门, 1=可拾取物, 2=对话, 3=谜题, 4=其他, 5=灯
@export var state: int = 0  # 状态（根据type有不同含义）
# 对于可拾取物，是否可收集？ 0 否 1 是
# 对于门，0 开 1 锁 2 不能从这一侧打开
# 对于对话，表示 current_flag
# 对于谜题，0 表示不可交互 1 表示可交互且未完成 2 表示已完成且不可交互
# 对于其他。0 表示不可见且不参与碰撞 1 表示可见且恢复碰撞
# 对于灯，0 表示关闭 1 表示开启
