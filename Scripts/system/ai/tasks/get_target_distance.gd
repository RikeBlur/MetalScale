extends BTAction

@export var target_var: StringName = &"target"
@export var distance_var: StringName = &"target_distance"

func _tick(_delta: float) -> Status:
	# 获取目标节点
	var target: Node = blackboard.get_var(target_var)
	
	# 检查目标节点是否有效
	if not is_instance_valid(target):
		return FAILURE
	
	# 计算距离
	var distance: float = agent.position.distance_to(target.position)
	
	# 将距离写入黑板变量
	blackboard.set_var(distance_var, distance)
	
	return SUCCESS
