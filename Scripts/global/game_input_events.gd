class_name InputEvents
extends Node2D

static var valid_direction : Vector2 = Vector2.ZERO
static var valid_last_direction : Vector2 = Vector2.ZERO
static var temp_direction : Vector2 = Vector2.ZERO
static var temp_last_direction : Vector2 = Vector2.ZERO

static var start_flag : bool = false
static var able_flag : bool = false

static var timer : float = 0
static var last_time : float = 0.03

func _physics_process(delta: float) -> void:
	if start_flag == true:
		timer += delta
		print(timer)
	if timer >= last_time:
		timer = 0
		start_flag = false
		able_flag = true



static func movement_input() -> Vector2:
	var input_vector = Vector2.ZERO
	
	# 检测水平方向
	if Input.is_action_pressed("left"):
		input_vector.x -= 1
	if Input.is_action_pressed("right"):
		input_vector.x += 1
	
	# 检测垂直方向  
	if Input.is_action_pressed("up"):
		input_vector.y -= 1
	if Input.is_action_pressed("down"):
		input_vector.y += 1
	
	# 计算新的方向
	temp_last_direction = temp_direction
	temp_direction = input_vector.normalized() if input_vector.length() > 0 else Vector2.ZERO

	if temp_last_direction != temp_direction:
		start_flag = true
		timer = 0
	
	if able_flag == true:
		valid_last_direction = valid_direction  # 保存之前的方向
		valid_direction = temp_last_direction   # 更新当前方向
		able_flag = false

	return valid_direction
	
static func is_movement() -> bool:
	if valid_direction != Vector2.ZERO:
		return true
	else:
		return false
		
static func is_act() -> bool:
	if Input.is_action_pressed("act"):
		return true
	else:
		return false

# 新增：获取最后一个有效移动方向的函数
static func get_last_valid_direction() -> Vector2:
	if valid_last_direction == Vector2.ZERO:
		return valid_direction
	else:
		return valid_last_direction
