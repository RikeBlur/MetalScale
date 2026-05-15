class_name FlashLight
extends Node2D

@export var light_source : parallel_light_source = null
@export var flash_light_body : Node2D = null

@export var rotation_speed : float = 10.0  # 旋转速度，用于平滑跟踪
@export var smooth_rotation : bool = true  # 是否使用平滑旋转

# 内部变量：当前的目标角度
var current_target_angle : float = 0.0

@onready var success_sfx: AudioStreamPlayer2D = $SuccessSFX

func _ready() -> void:
	# 如果没有指定光源，尝试从子节点获取
	if not light_source:
		light_source = get_node_or_null("ParallelLight")
		if not light_source:
			push_warning("FlashLight: 未找到 ParallelLight 节点")
	if not flash_light_body:
		flash_light_body = get_node_or_null("toolbody")
		if not flash_light_body:
			push_warning("FlashLight: 未找到 flash_light_body 节点")

func _process(delta: float) -> void:
	# 获取鼠标的全局位置
	var mouse_position = get_global_mouse_position()
	
	# 计算从节点位置到鼠标位置的向量
	var direction_to_mouse = mouse_position - global_position
	
	# 计算目标角度（使用 atan2 获取向量角度）
	var target_angle = direction_to_mouse.angle()
	
	# 根据平滑模式计算实际应用的角度
	var applied_angle : float
	
	if smooth_rotation:
		# 平滑旋转：使用插值
		var angle_diff = _angle_difference(current_target_angle, target_angle)
		
		# 使用固定角速度旋转
		var rotation_step = rotation_speed * delta
		if abs(angle_diff) < rotation_step:
			current_target_angle = target_angle
		else:
			current_target_angle += sign(angle_diff) * rotation_step
		
		applied_angle = current_target_angle
	else:
		# 直接设置角度（瞬间跟踪）
		current_target_angle = target_angle
		applied_angle = target_angle
	
	# 应用旋转到各个组件
	_apply_rotation(applied_angle)
	

func _apply_rotation(angle: float) -> void:
	"""应用旋转到手电筒的各个组件"""
	
	# 1. 旋转手电筒本体（视觉表现）
	if flash_light_body:
		flash_light_body.rotation = angle
	
	# 2. 旋转光源节点本身（这会旋转纹理）
	if light_source.point_light_2d:
		# 直接旋转光源节点来旋转纹理
		light_source.point_light_2d.rotation = angle
	
	# 3. 设置光源的角度旋转（控制光线检测方向）
	if light_source and light_source is parallel_light_source:
		light_source.angle_rotate = rad_to_deg(angle)

func _angle_difference(from: float, to: float) -> float:
	"""计算两个角度之间的最短差值（考虑角度环绕）"""
	var diff = fmod(to - from, TAU)
	if diff > PI:
		diff -= TAU
	elif diff < -PI:
		diff += TAU
	return diff
