class_name light_detector
extends Node2D

# 检测半径
@export var radius: float = 300.0
# 更新频率（秒）
@export var update_rate: float = 1.0
# 附近的光源数组
@export var nearby_light_sources: Array[light_source] = []

@export var debug_mode : bool = false
var debug_label: Label = null

var update_timer: Timer

func _ready():
	# 创建更新定时器
	update_timer = Timer.new()
	update_timer.wait_time = update_rate
	update_timer.timeout.connect(_on_update_timer_timeout)
	add_child(update_timer)
	update_timer.start()
	if debug_mode:
		debug_label = $Label

func _on_update_timer_timeout():
	calculate_and_print_intensities()

func calculate_and_print_intensities() -> float:
	"""计算并打印所有附近光源的光强"""
	var total_intensity: float = 0.0
	for light in nearby_light_sources:
		if not is_instance_valid(light):
			continue			
		# 计算到光源的距离
		var distance = global_position.distance_to(light.global_position)
		if distance <= light.radius:
			# 计算角度（从光源到检测器的角度，以光源为坐标原点）
			var direction = (global_position - light.global_position).normalized()
			var angle = atan2(direction.y, direction.x)			
			# 调用光源的calculate_intensity方法
			var intensity = light.calculate_intensity(angle, distance)
			# 打印光强信息
			print("光源: ", light.name, " 距离: ", distance, " 角度: ", rad_to_deg(angle), " 光强: ", intensity)
			total_intensity += intensity
			if debug_mode : _update_visualize(intensity)
		else:
			print("NoLight")
	return total_intensity

func set_radius(new_radius: float):
	"""设置检测半径"""
	radius = new_radius
	print("检测半径设置为: ", radius)

func set_update_rate(new_rate: float):
	"""设置更新频率"""
	update_rate = new_rate
	if update_timer:
		update_timer.wait_time = update_rate
	print("更新频率设置为: ", update_rate, " 秒")

func get_nearby_lights_count() -> int:
	"""获取附近光源数量"""
	return nearby_light_sources.size()

func get_nearby_lights() -> Array[light_source]:
	"""获取附近光源列表"""
	return nearby_light_sources

func _update_visualize(intensity: float) -> void:
	var value = snappedf(intensity, 0.01)
	debug_label.text = str(value)
	
	
