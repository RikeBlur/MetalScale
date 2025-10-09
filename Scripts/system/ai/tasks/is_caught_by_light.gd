@tool
extends BTCondition

@export var target_var: StringName = &"detector"
@export var tolerance: float = 0.1

var detector : light_detector

# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "IsCaughtByLight " + LimboUtility.decorate_var(target_var)

func _enter() -> void:
	detector = blackboard.get_var(target_var)

# Called each time this task is ticked (aka exdecuted).
func _tick(_delta: float) -> Status:
	#print(detector.intensity_future,' ',detector.intensity_now)
	if detector.intensity_future + detector.intensity_now >= tolerance:
		return SUCCESS
	else:
		return FAILURE
