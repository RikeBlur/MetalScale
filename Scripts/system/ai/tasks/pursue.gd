#*
#* pursue.gd
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
## Move towards the target using 8-directional movement with collision avoidance. [br]
## Returns [code]RUNNING[/code] while moving towards the target. [br]
## Returns [code]SUCCESS[/code] when movement duration is complete. [br]
## Returns [code]FAILURE[/code] if the target is not a valid [Node2D] instance. [br]

## 8个标准追击方向
const PURSUE_DIRECTION = {
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

## Blackboard variable that stores our target (expecting Node2D).
@export var target_var: StringName = &"target"

## Blackboard variable that stores desired speed.
@export var speed_var: StringName = &"speed"

## 单次追击持续时间
@export var last_time: float = 0.5

var _move_direction: Vector2
var _move_timer: float = 0.0
var _tried_directions: Array[String] = []
var Animated_Sprite : AnimatedSprite2D  = null


# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "Pursue %s" % [LimboUtility.decorate_var(target_var)]


# Called each time this task is entered.
func _enter() -> void:
	var target: Node2D = blackboard.get_var(target_var, null)
	if not is_instance_valid(target):
		return
		
	Animated_Sprite = agent.animated_sprite
	
	# 重置计时器和尝试方向列表
	_move_timer = 0.0
	_tried_directions.clear()
	
	# 计算目标方向并选择安全的移动方向
	var target_direction = (target.global_position - agent.global_position).normalized()
	_move_direction = _select_safe_direction(target_direction)
	
	if Animated_Sprite : _play_run_animation(_move_direction)


# Called each time this task is ticked (aka executed).
func _tick(delta: float) -> Status:
	var target: Node2D = blackboard.get_var(target_var, null)
	if not is_instance_valid(target):
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


## 根据目标方向向量找到最接近的8方向
func _get_closest_pursue_direction(target_direction: Vector2) -> String:
	var closest_dir: String = "right"
	var max_dot: float = -1.0
	
	for dir_name in PURSUE_DIRECTION.keys():
		var dot = target_direction.dot(PURSUE_DIRECTION[dir_name])
		if dot > max_dot:
			max_dot = dot
			closest_dir = dir_name
	
	return closest_dir


## 选择安全的移动方向（避开碰撞）
func _select_safe_direction(target_direction: Vector2, preferred_dir: String = "") -> Vector2:
	# 如果没有指定优先方向，找到最接近目标的方向
	if preferred_dir == "":
		preferred_dir = _get_closest_pursue_direction(target_direction)
	
	# 如果这个方向已经尝试过，跳过
	if preferred_dir in _tried_directions:
		# 尝试相邻方向
		if preferred_dir in ADJACENT_DIRECTIONS:
			for adjacent_dir in ADJACENT_DIRECTIONS[preferred_dir]:
				if adjacent_dir not in _tried_directions:
					return _select_safe_direction(target_direction, adjacent_dir)
		# 所有相邻方向都试过了，返回原方向
		return PURSUE_DIRECTION[preferred_dir]
	
	# 记录已尝试的方向
	_tried_directions.append(preferred_dir)
	
	# 获取速度
	var speed: float = blackboard.get_var(speed_var, 200.0)
	var direction = PURSUE_DIRECTION[preferred_dir]
	
	# 计算预测位置
	var predicted_pos = agent.global_position + direction * last_time * speed
	
	# 检查预测位置是否会碰撞
	if _is_collision_at_position(predicted_pos):
		# 如果会碰撞，尝试相邻方向
		if preferred_dir in ADJACENT_DIRECTIONS:
			for adjacent_dir in ADJACENT_DIRECTIONS[preferred_dir]:
				if adjacent_dir not in _tried_directions:
					return _select_safe_direction(target_direction, adjacent_dir)
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
	if anim_direction == Vector2.DOWN :
		Animated_Sprite.play("run_front")
	elif anim_direction == Vector2.UP :
		Animated_Sprite.play("run_back")
	elif anim_direction == Vector2.LEFT :
		Animated_Sprite.play("run_left")
	elif anim_direction == Vector2.RIGHT :
		Animated_Sprite.play("run_right")
	elif anim_direction.x > 0 and anim_direction.y > 0:
		Animated_Sprite.play("run_front_right")
	elif anim_direction.x > 0 and anim_direction.y < 0:
		Animated_Sprite.play("run_back_right")
	elif anim_direction.x < 0 and anim_direction.y > 0:
		Animated_Sprite.play("run_front_left")
	elif anim_direction.x < 0 and anim_direction.y < 0:
		Animated_Sprite.play("run_back_left")
