class_name InputEvents
extends Node2D

# 确保 8向移动 顺滑，避免 direction 的突变
static var valid_direction : Vector2 = Vector2.ZERO
static var valid_last_direction : Vector2 = Vector2.ZERO
static var temp_direction : Vector2 = Vector2.ZERO
static var temp_last_direction : Vector2 = Vector2.ZERO

static var start_flag : bool = false
static var able_flag : bool = false

static var timer : float = 0
static var last_time : float = 0.03

# 是否正在奔跑
static var running : bool = false

#var target_position = Vector2.ZERO
#var is_dragging = false

# 如果 player_input_blocked，所有返回都设为false
static var player_input_blocked : bool = false

# 确保单次按键不要重复触发
static var _last_consume_timestamp: float = 0.0
const CONSUME_COOLDOWN: float = 0.2 
const QUIT_COOLDOWN: float = 0.2


func _physics_process(delta: float) -> void:
	if start_flag == true:
		timer += delta
		# print(timer)
	if timer >= last_time:
		timer = 0
		start_flag = false
		able_flag = true


static func movement_input() -> Vector2:
	# block!输入
	if player_input_blocked:
		return Vector2.ZERO
	
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
	# block!输入
	if player_input_blocked:
		return false
		
	if valid_direction != Vector2.ZERO:
		return true
	else:
		return false
		
static func is_act() -> bool:
	# block!输入
	if player_input_blocked:
		return false
		
	if Input.is_action_pressed("act"):
		return true
	else:
		return false
		
static func is_running() -> bool:
	# block!输入
	if player_input_blocked:
		return false
		
	if Input.is_action_pressed("running"):
		return true
	else:
		return false

static func consume_once() -> bool:
	# block!输入
	if player_input_blocked:
		return false
		
	if Input.is_action_just_pressed("consume"):
		var now = Time.get_ticks_msec() / 1000.0
		if now - _last_consume_timestamp > CONSUME_COOLDOWN:
			_last_consume_timestamp = now
			return true
	return false
	
static func quit_once() -> bool:
	# block!输入
	if player_input_blocked:
		return false

	if Input.is_action_just_pressed("quit"):
		var now = Time.get_ticks_msec() / 1000.0
		if now - _last_consume_timestamp > QUIT_COOLDOWN:
			_last_consume_timestamp = now
			return true
	return false

static func to_tool() -> int:
	# block!输入
	if player_input_blocked:
		return -1	

	if Input.is_action_just_pressed("tool_1") :
		return 0
	elif Input.is_action_just_pressed("tool_2") :
		return 1
	elif Input.is_action_just_pressed("tool_3") :
		return 2	
	elif Input.is_action_just_pressed("tool_4") :
		return 3	
	elif Input.is_action_just_pressed("tool_5") :
		return 4	
	elif Input.is_action_just_pressed("tool_6") :
		return 5	
	else :
		return -1	


#============================================ 工具函数 ===============================================
# 新增：获取最后一个有效移动方向的函数
static func get_last_valid_direction() -> Vector2:
	if valid_last_direction == Vector2.ZERO:
		return valid_direction
	else:
		return valid_last_direction
