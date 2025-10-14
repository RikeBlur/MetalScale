extends BTAction

@export var speed : float = 50
@export var move_duration: float = 2.0

var _move_direction: Vector2
var _move_timer: float = 0.0
var Animated_Sprite: AnimatedSprite2D = null

## 8个标准逃离方向
const HANGOUT_DIRECTION = {
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

func _enter() -> void:
	# 进入任务时重新选择方向
	Animated_Sprite = agent.animated_sprite
	choose_random_direction()
	_play_run_animation(_move_direction)
	_move_timer = 0.0

func _tick(delta: float) -> Status:
	# 更新移动计时器
	_move_timer += delta
	
	# 执行移动
	var desired_velocity: Vector2 = _move_direction * speed
	agent.move(desired_velocity)
	
	# 检查移动时间是否完成
	if _move_timer >= move_duration:
		return SUCCESS
	
	return RUNNING

func choose_random_direction() -> void:
	# 生成随机方向向量
	var dirs = HANGOUT_DIRECTION.values()
	_move_direction = dirs[randi() % dirs.size()]

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
