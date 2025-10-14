@tool
extends BTCondition

@export var target_var: StringName = &"detector"
@export var tolerance: float = 0.1
@export var required_frames: int = 3  # 需要连续检测到的帧数

var detector : light_detector
var success_frames: int = 0  # 当前连续成功的帧数

# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "IsCaughtByLight " + LimboUtility.decorate_var(target_var)

func _enter() -> void:
	detector = blackboard.get_var(target_var)
	success_frames = 0  # 重置帧计数

# Called each time this task is ticked (aka exdecuted).
func _tick(_delta: float) -> Status:
	#print(detector.intensity_future,' ',detector.intensity_now)
	if detector.intensity_future + detector.intensity_now >= tolerance:
		success_frames += 1
		if success_frames >= required_frames:
			return SUCCESS
		return RUNNING
	else:
		success_frames = 0  # 重置连续帧计数
		return FAILURE
