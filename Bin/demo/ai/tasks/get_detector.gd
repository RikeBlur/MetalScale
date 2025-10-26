@tool
extends BTAction

@export var output_var: StringName = &"detector"

func _tick(_delta: float) -> Status:
	var node = agent.get_child(0)
	if node is not light_detector:
		return FAILURE
	blackboard.set_var(output_var, node)
	return SUCCESS
