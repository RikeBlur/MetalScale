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
## 让角色远离光源的 BTAction 任务，使用8方向移动和碰撞避免。[br]
## Returns [code]RUNNING[/code] while moving away from light sources. [br]
## Returns [code]SUCCESS[/code] when movement duration is complete. [br]
## Returns [code]FAILURE[/code] if the detector is not valid. [br]

## 8个标准逃离方向
const FLEE_DIRECTION = {
	"right": Vector2(1, 0),
	"left": Vector2(-1, 0),
	"front": Vector2(0, 1),
	"back": Vector2(0, -1),
	"front_right": Vector2(0.7071067811865476, 0.7071067811865476),  # Vector2(1, 1).normalized()
	"back_right": Vector2(0.7071067811865476, -0.7071067811865476),  # Vector2(1, -1).normalized()
	"front_left": Vector2(-0.7071067811865476, 0.7071067811865476),  # Vector2(-1, 1).normalized()
	"back_left": Vector2(-0.7071067811865476, -0.7071067811865476)   # Vector2(-1, -1).normalized()
}

## 方向的相邻关系（用于碰撞避免时的方向选择）
const ADJACENT_DIRECTIONS = {
	"right": ["front_right", "back_right"],
	"left": ["front_left", "back_left"],
	"front": ["front_left", "front_right"],
	"back": ["back_left", "back_right"],
	"front_right": ["right", "front"],
	"back_right": ["right", "back"],
	"front_left": ["left", "front"],
	"back_left": ["left", "back"]
}

## Blackboard 变量名，存储 light_detector 节点
@export var detector_var: StringName = &"detector"

## Blackboard 变量名，存储移动速度
@export var speed_var: StringName = &"speed"

## 单次逃离持续时间
@export var last_time: float = 0.5

var _move_direction: Vector2
var _move_timer: float = 0.0
var _tried_directions: Array[String] = []
var _flee_direction: Vector2
var Animated_Sprite: AnimatedSprite2D = null


# 显示自定义名称（需要 @tool）
func _generate_name() -> String:
	return "FleeFromLight " + LimboUtility.decorate_var(detector_var)


# 每次进入任务时调用
func _enter() -> void:
	var detector = blackboard.get_var(detector_var, null)
	if not is_instance_valid(detector):
		return
		
	Animated_Sprite = agent.animated_sprite
	
	# 重置计时器和尝试方向列表
	_move_timer = 0.0
	_tried_directions.clear()
	
	# 计算逃离方向
	_calculate_flee_direction(detector)
	
	# 选择安全的移动方向
	_move_direction = _select_safe_direction(_flee_direction)
	
	if Animated_Sprite: _play_run_animation(_move_direction)


# 每次任务被 tick（执行）时调用
func _tick(delta: float) -> Status:
	var detector = blackboard.get_var(detector_var, null)
	if not is_instance_valid(detector):
		return FAILURE
	
	# 更新移动计时器
	_move_timer += delta
	
	# 执行移动
	var speed: float = blackboard.get_var(speed_var, 200.0)
	var desired_velocity: Vector2 = _move_direction * speed
	agent.move(desired_velocity)
	
	# 检查移动时间是否完成
	if _move_timer >= last_time:
		return SUCCESS
	
	return RUNNING


## 计算逃离方向（远离所有光源的合力方向）
func _calculate_flee_direction(detector) -> void:
	var flee_vector = Vector2.ZERO
	var agent_pos = agent.global_position
	
	# 收集所有有效的光源位置
	for light_source in detector.nearby_light_sources:
		if is_instance_valid(light_source):
			# 计算从光源到角色的向量
			var to_agent = agent_pos - light_source.global_position
			flee_vector += to_agent.normalized()
	
	# 如果计算出的逃离向量太小，添加一些随机性
	if flee_vector.length() < 0.1:
		flee_vector = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	
	_flee_direction = flee_vector.normalized()


## 根据逃离方向向量找到最接近的8方向
func _get_closest_flee_direction() -> String:
	var closest_dir: String = "right"
	var max_dot: float = -1.0
	
	for dir_name in FLEE_DIRECTION.keys():
		var dot = _flee_direction.dot(FLEE_DIRECTION[dir_name])
		if dot > max_dot:
			max_dot = dot
			closest_dir = dir_name
	
	return closest_dir


## 选择安全的移动方向（避开碰撞）
func _select_safe_direction(flee_direction: Vector2, preferred_dir: String = "") -> Vector2:
	# 如果没有指定优先方向，找到最接近逃离方向的方向
	if preferred_dir == "":
		preferred_dir = _get_closest_flee_direction()
	
	# 如果这个方向已经尝试过，跳过
	if preferred_dir in _tried_directions:
		# 尝试相邻方向
		if preferred_dir in ADJACENT_DIRECTIONS:
			for adjacent_dir in ADJACENT_DIRECTIONS[preferred_dir]:
				if adjacent_dir not in _tried_directions:
					return _select_safe_direction(flee_direction, adjacent_dir)
		# 所有相邻方向都试过了，返回原方向
		return FLEE_DIRECTION[preferred_dir]
	
	# 记录已尝试的方向
	_tried_directions.append(preferred_dir)
	
	# 获取速度
	var speed: float = blackboard.get_var(speed_var, 200.0)
	var direction = FLEE_DIRECTION[preferred_dir]
	
	# 计算预测位置
	var predicted_pos = agent.global_position + direction * last_time * speed
	
	# 检查预测位置是否会碰撞
	if _is_collision_at_position(predicted_pos):
		# 如果会碰撞，尝试相邻方向
		if preferred_dir in ADJACENT_DIRECTIONS:
			for adjacent_dir in ADJACENT_DIRECTIONS[preferred_dir]:
				if adjacent_dir not in _tried_directions:
					return _select_safe_direction(flee_direction, adjacent_dir)
		# 所有相邻方向都试过了，返回原方向
		return direction
	
	return direction


## 检查指定位置是否存在碰撞（collision layer == 1）
func _is_collision_at_position(pos: Vector2) -> bool:
	var space_state = agent.get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 1  # 检查 collision layer 1
	
	var result = space_state.intersect_point(query, 1)
	return result.size() > 0

func _play_run_animation(anim_direction: Vector2) -> void:
	if anim_direction == Vector2.DOWN:
		Animated_Sprite.play("run_front")
	elif anim_direction == Vector2.UP:
		Animated_Sprite.play("run_back")
	elif anim_direction == Vector2.LEFT:
		Animated_Sprite.play("run_left")
	elif anim_direction == Vector2.RIGHT:
		Animated_Sprite.play("run_right")
	elif anim_direction.x > 0 and anim_direction.y > 0:
		Animated_Sprite.play("run_front_right")
	elif anim_direction.x > 0 and anim_direction.y < 0:
		Animated_Sprite.play("run_back_right")
	elif anim_direction.x < 0 and anim_direction.y > 0:
		Animated_Sprite.play("run_front_left")
	elif anim_direction.x < 0 and anim_direction.y < 0:
		Animated_Sprite.play("run_back_left")
