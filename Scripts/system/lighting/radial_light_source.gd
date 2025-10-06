class_name radial_light_source
extends light_source

@export var radius : float = 200.0
@export var range_offset : float = 1.0
@export var logic_energy : float = 1.0
@export var sampling_rate : int = 72
@export var debug_mode : bool = false

func _ready():
	initialize_sample_rays()
	#update_ray_collisions()
	if debug_mode:
		start_visual_debug()

func initialize_sample_rays():
	"""初始化采样射线"""
	sample_rays.clear()
	var angle_step = 2.0 * PI / sampling_rate
	
	for i in range(sampling_rate):
		var start_angle = i * angle_step
		var end_angle = (i + 1) * angle_step
		var ray = SampleRay.new(i, start_angle, end_angle)
		sample_rays.append(ray)

func update_ray_collisions():
	"""更新射线与遮挡物的碰撞检测"""
	# 重置所有射线状态
	for ray in sample_rays:
		ray.is_occluded = false
		ray.ray_length = 0.0
	
	# 对每个射线进行碰撞检测
	for ray in sample_rays:
		var ray_direction = Vector2(cos(ray.angle_start), sin(ray.angle_start))
		var closest_intersection_distance = radius + range_offset
		var has_intersection = false
		
		# 检查与所有遮挡点的交点
		for point in occlusion_points:
			var intersection_distance = calculate_ray_point_intersection(ray_direction, point)
			if intersection_distance > 0 and intersection_distance < closest_intersection_distance:
				closest_intersection_distance = intersection_distance
				has_intersection = true
		
		if has_intersection:
			ray.is_occluded = true
			ray.ray_length = closest_intersection_distance

func calculate_ray_point_intersection(ray_direction: Vector2, point: Vector2) -> float:
	"""计算射线与点的交点距离"""
	# 将点转换到射线坐标系
	var point_in_ray_space = point - global_position
	
	# 计算射线方向与点到射线起点的向量的点积
	var dot_product = ray_direction.dot(point_in_ray_space)
	
	# 如果点积为负，说明点在射线后方，无交点
	if dot_product <= 0:
		return -1.0
	
	# 计算射线上的最近点
	var closest_point_on_ray = ray_direction * dot_product
	
	# 计算点到射线的距离
	var distance_to_ray = point_in_ray_space.distance_to(closest_point_on_ray)
	
	# 如果距离小于某个阈值，认为有交点
	var threshold = 5.0  # 可以根据需要调整
	if distance_to_ray <= threshold:
		return dot_product
	
	return -1.0

func add_occlusion_point(point: Vector2):
	"""添加遮挡点"""
	occlusion_points.append(point)
	update_ray_collisions()

func remove_occlusion_point(point: Vector2):
	"""移除遮挡点"""
	var index = occlusion_points.find(point)
	if index != -1:
		occlusion_points.remove_at(index)
		update_ray_collisions()

func clear_occlusion_points():
	"""清空所有遮挡点"""
	occlusion_points.clear()
	update_ray_collisions()

func get_sample_ray_for_angle(angle: float) -> SampleRay:
	"""根据角度获取对应的采样射线"""
	# 将角度标准化到0-2π范围
	var normalized_angle = fmod(angle + 2.0 * PI, 2.0 * PI)
	
	for ray in sample_rays:
		if normalized_angle >= ray.angle_start and normalized_angle < ray.angle_end:
			return ray
	
	# 如果没找到，返回第一个射线（处理边界情况）
	return sample_rays[0]

func calculate_intensity(angle: float, length: float) -> float:
	"""计算指定角度和距离的光照强度"""
	var ray = get_sample_ray_for_angle(angle)
	var rlr = radius / length
	
	if ray.is_occluded:
		# 如果射线被遮挡，检查距离是否小于遮挡距离
		if length < ray.ray_length:
			return (1 - 1 / rlr) * logic_energy
		else:
			return 0.0
	else:
		# 如果射线未被遮挡，直接计算强度
		return (1 - 1 / rlr) * logic_energy

#------------------------------------------------------------------------------------------------
#-------------------------------------------测试用------------------------------------------------
#-------------------------------------------------------------------------------------------------
func test_occlusion_detection():
	"""测试遮挡检测功能"""
	#print("=== 开始测试遮挡检测 ===")
	#print("光源位置: ", global_position)
	#print("半径: ", radius)
	#print("采样率: ", sampling_rate)

	# 检查每个射线的状态
	#for ray in sample_rays:
	#	if ray.is_occluded:
	#		print("射线 ", ray.ray_id, " 被遮挡，遮挡距离: ", ray.ray_length)
	#	else:
	#		print("射线 ", ray.ray_id, " 未被遮挡")
	
	#print("=== 测试完成 ===")

func _draw():
	if debug_mode:
		"""绘制可视化元素"""
		if not is_inside_tree():
			return
		
		# 绘制光源中心点
		draw_circle(Vector2.ZERO, 3.0, Color.YELLOW)
		
		# 绘制光源范围圆
		draw_arc(Vector2.ZERO, radius, 0, 2.0 * PI, 64, Color.WHITE, 2.0)
		
		# 绘制遮挡点
		for point in occlusion_points:
			var local_point = point - global_position
			draw_circle(local_point, 1.0, Color.RED)
		
		# 绘制射线（仅显示被遮挡的射线）
		for ray in sample_rays:
			if ray.is_occluded:
				var ray_direction = Vector2(cos(ray.angle_start), sin(ray.angle_start))
				var ray_end = ray_direction * ray.ray_length
				draw_line(Vector2.ZERO, ray_end, Color.ORANGE, 1.0)
				
				# 在射线终点绘制小圆点
				draw_circle(ray_end, 1.5, Color.ORANGE)
		
		# 绘制未被遮挡的射线（较短，表示光线能到达的范围）
		for ray in sample_rays:
			if not ray.is_occluded:
				var ray_direction = Vector2(cos(ray.angle_start), sin(ray.angle_start))
				var ray_end = ray_direction * radius
				draw_line(Vector2.ZERO, ray_end, Color.CYAN, 0.5)
	else:
		return

func start_visual_debug():
	"""开始可视化调试模式"""
	print("开始可视化调试模式")
	test_occlusion_detection()
	# 请求重绘
	queue_redraw()
	
	# 设置定时器定期重绘
	if not has_node("DebugTimer"):
		var timer = Timer.new()
		timer.name = "DebugTimer"
		timer.wait_time = 0.1
		timer.timeout.connect(_on_debug_timer_timeout)
		add_child(timer)
		timer.start()

func stop_visual_debug():
	"""停止可视化调试模式"""
	print("停止可视化调试模式")
	if has_node("DebugTimer"):
		get_node("DebugTimer").queue_free()
	queue_redraw()

func _on_debug_timer_timeout():
	"""调试定时器回调"""
	queue_redraw()
