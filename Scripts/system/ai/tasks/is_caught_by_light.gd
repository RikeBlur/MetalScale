@tool
extends BTCondition

@export var target_var: StringName = &"detector"
@export var tolerance: float = 0.01

# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "IsCaughtByLight " + LimboUtility.decorate_var(target_var)


# Called each time this task is ticked (aka executed).
func _tick(_delta: float) -> Status:
	var detector_inst = blackboard.get_var(target_var)
	#if detector_inst is light_detector: return SUCCESS
	print(detector_inst.intensity_now)
	if detector_inst.intensity_now <= tolerance:
		return FAILURE
	else:
		return SUCCESS
