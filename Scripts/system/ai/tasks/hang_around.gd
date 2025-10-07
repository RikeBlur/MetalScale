extends BTAction

@export var speed: float = 100.0
@export var move_duration: float = 2.0

var move_direction: Vector2
var move_timer: float = 0.0

func _setup() -> void:
	# 初始化时选择随机方向
	choose_random_direction()

func _enter() -> void:
	# 进入任务时重新选择方向
	choose_random_direction()
	move_timer = 0.0

func _tick(delta: float) -> Status:
	# 更新移动计时器
	move_timer += delta
	
	# 移动agent
	agent.position += move_direction * speed * delta
	
	# 检查是否需要选择新方向
	if move_timer >= move_duration:
		choose_random_direction()
		move_timer = 0.0
	
	return RUNNING

func choose_random_direction() -> void:
	# 生成随机方向向量
	move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
