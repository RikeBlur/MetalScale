#*
#* flee_from_light.gd
#* =============================================================================
#* Copyright (c) 2023-present Serhii Snitsaruk and the LimboAI contributors.
#*
#* Use of this source code is governed by an MIT-style
#* license that can be found in the LICENSE file or at
#* https://opensource.org/licenses/MIT.
#* =============================================================================
#*
@tool
extends BTAction
## 让角色远离光源的 BTAction 任务
## 从 blackboard 中读取 detector 变量，获取所有附近光源的位置
## 计算一个可以远离这些光源的方向，并进行移动
## 返回 [code]RUNNING[/code] 持续移动，直到没有光源威胁

## Blackboard 变量名，存储 light_detector 节点
@export var detector_var: StringName = &"detector"

## Blackboard 变量名，存储移动速度
@export var speed_var: StringName = &"speed"

## 逃离的最小距离（像素）
@export var flee_distance: float = 200.0

## 逃离方向的最大角度偏差（弧度）
@export var max_angle_deviation: float = 0.5

var _flee_direction: Vector2
var _desired_velocity: Vector2

var detector : light_detector
var pos : Array = []

# 显示自定义名称（需要 @tool）
func _generate_name() -> String:
	return "FleeFromLight " + LimboUtility.decorate_var(detector_var)

# 每次进入任务时调用
func _enter() -> void:
	detector = blackboard.get_var(detector_var)
	for i in detector.nearby_light_sources.size():
		pos.append(detector.nearby_light_sources[i].global_position)
	_calculate_flee_direction()

# 每次任务被 tick（执行）时调用
func _tick(_delta: float) -> Status:
	# 重新计算逃离方向（因为光源可能移动）
	agent.move(_desired_velocity)
	
	return RUNNING

# 计算逃离方向
func _calculate_flee_direction() -> void:
	# 计算远离所有光源的合力方向
	var flee_vector = Vector2.ZERO
	var agent_pos = agent.global_position
	
	for position in pos:
		# 计算从光源到角色的向量
		var to_agent = agent_pos - position
		flee_vector += to_agent.normalized()
	
	# 如果计算出的逃离向量太小，添加一些随机性
	if flee_vector.length() < 0.1:
		flee_vector = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	
	# 添加一些角度偏差，使移动更自然
	var angle_deviation = randf_range(-max_angle_deviation, max_angle_deviation)
	_flee_direction = flee_vector.normalized().rotated(angle_deviation)
	
	# 计算最终速度
	var speed: float = blackboard.get_var(speed_var, 200.0)
	_desired_velocity = _flee_direction * speed
