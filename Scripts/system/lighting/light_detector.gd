class_name light_detector
extends Node2D

# 检测半径
@export var radius: float = 500.0
# 更新频率（秒）
@export var update_rate: float = 1.0
# 扩展长度（十字形检测点的距离）
@export var extension_length: float = 10.0
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
	if debug_mode:
		queue_redraw()

func get_detection_points() -> PackedVector2Array:
	"""获取5个检测点：中心点 + 十字形4个点"""
	var points = PackedVector2Array()
	
	# 中心点
	points.append(global_position)
	
	# 十字形4个点：上、下、左、右
	points.append(global_position + Vector2(0, -extension_length))  # 上
	points.append(global_position + Vector2(0, extension_length))   # 下
	points.append(global_position + Vector2(-extension_length, 0))  # 左
	points.append(global_position + Vector2(extension_length, 0))   # 右
	
	return points

func calculate_and_print_intensities() -> float:
	"""计算并打印所有附近光源的光强（5点平均）"""
	var total_intensity: float = 0.0
	for light in nearby_light_sources:
		if not is_instance_valid(light):
			continue
		
		# 获取5个检测点
		var detection_points = get_detection_points()
		var light_intensity_sum: float = 0.0
		var valid_points: int = 0
		
		# 计算每个检测点的光强
		for point in detection_points:
			var distance = point.distance_to(light.global_position)
			if distance <= light.radius:
				# 计算角度（从光源到检测点的角度，以光源为坐标原点）
				var direction = (point - light.global_position).normalized()
				var angle = atan2(direction.y, direction.x)
				# 调用光源的calculate_intensity方法
				var intensity = light.calculate_intensity(angle, distance)
				light_intensity_sum += intensity
				valid_points += 1
		
		# 计算平均光强
		if valid_points > 0:
			var average_intensity = light_intensity_sum / float(valid_points)
			print("光源: ", light.name, " 有效检测点: ", valid_points, " 平均光强: ", average_intensity)
			total_intensity += average_intensity
			if debug_mode: _update_visualize(average_intensity)
		else:
			print("光源: ", light.name, " 无有效检测点")
	
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

func set_extension_length(new_length: float):
	"""设置扩展长度"""
	extension_length = new_length
	print("扩展长度设置为: ", extension_length)

func get_nearby_lights_count() -> int:
	"""获取附近光源数量"""
	return nearby_light_sources.size()

func get_nearby_lights() -> Array[light_source]:
	"""获取附近光源列表"""
	return nearby_light_sources

func _update_visualize(intensity: float) -> void:
	var value = snappedf(intensity, 0.01) * 100
	debug_label.text = "Intensity:" + str(value)
	

func _draw():
	if not debug_mode:
		return
	var points = get_detection_points()
	var color = Color(1, 0, 0, 0.8)
	var r = 3.0
	for p in points:
		var lp = to_local(p)
		draw_circle(lp, r, color)
