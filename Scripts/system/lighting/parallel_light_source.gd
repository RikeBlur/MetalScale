class_name parallel_light_source
extends LightSource

@export var radius : float = 1200.0
@export var range_offset : float = 1.0
@export var logic_energy : float = 1.0
@export var sampling_rate : int = 9:
	set(value):
		sampling_rate = int(max(value, 1))
		if is_inside_tree():
			initialize_sample_rays()

var threshold : float = 10.0

@export var angle_range : float = PI / 16 
@export_range(-360.0, 360.0, 0.1, "suffix:°") var angle_rotate : float = 0.0:
	set(value):
		angle_rotate = value
		# 当角度旋转改变时，重新初始化采样射线
		if is_inside_tree():
			initialize_sample_rays()

@export var debug_mode : bool = false

func _ready():
	initialize_sample_rays()
	#update_ray_collisions()
	if debug_mode:
		start_visual_debug()
		
func initialize_sample_rays():
	"""初始化采样射线，在 -angle_range 到 +angle_range 范围内均匀分布"""
	sample_rays.clear()
	var safe_sampling_rate: int = int(max(sampling_rate, 1))
	
	# 计算总角度范围：从 -angle_range 到 +angle_range
	var total_range = 2.0 * angle_range
	var angle_step = total_range / safe_sampling_rate
	var rotate_radians = _angle_rotate_radians()
	
	for i in range(safe_sampling_rate):
		# 从 -angle_range 开始分布
		var start_angle = -angle_range + rotate_radians + i * angle_step
		var end_angle = -angle_range + rotate_radians + (i + 1) * angle_step
		var ray = SampleRay.new(i, start_angle, end_angle)
		sample_rays.append(ray)
		
# -------------------------------------------------------------------------------------------------
# ---------------------------------- 逻辑光线 SampleRay 的仿真计算 -----------------------------------
# -------------------------------------------------------------------------------------------------
func update_ray_collisions():
	"""更新射线与遮挡物的碰撞检测"""
	# 重置所有射线状态
	for ray in sample_rays:
		ray.is_occluded = false
		ray.ray_length = 0.0

	if not use_occlusion or occlusion_points.is_empty():
		return
	
	# 对每个射线进行碰撞检测
	for ray in sample_rays:
		var ray_direction = Vector2(cos(ray.angle_start), sin(ray.angle_start))
		var closest_intersection_distance = radius + range_offset
		var has_intersection = false
		
		# 检查与所有遮挡点的交点（可优化！！！aw）
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
	if distance_to_ray <= threshold:
		return dot_product
	
	return -1.0
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------


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
	if sample_rays.is_empty():
		return null
	
	# 检查角度是否在有效范围内（考虑 angle_rotate）
	var normalized_angle = _normalize_angle(angle)
	var rotate_radians = _angle_rotate_radians()
	var local_angle = _normalize_angle(normalized_angle - rotate_radians)
	if abs(local_angle) > angle_range:
		return null  # 超出光源照射范围，返回null
	
	# 在有效射线中查找匹配的射线
	var sample_angle = rotate_radians + local_angle
	for ray in sample_rays:
		if _angle_in_ray(sample_angle, ray):
			return ray
	
	# 如果没找到但在范围内，返回最后一个射线（处理边界情况）
	return sample_rays[-1]

func calculate_intensity(angle: float, length: float) -> float:
	"""计算指定角度和距离的光照强度"""
	if radius <= 0.0 or length >= radius:
		return 0.0
	if length <= 0.0:
		return logic_energy

	# 如果角度超出光源范围，返回0强度
	var local_angle = _normalize_angle(angle - _angle_rotate_radians())
	if abs(local_angle) > angle_range:
		return 0.0
	
	var intensity = logic_energy
	if not use_occlusion:
		return intensity

	var ray = get_sample_ray_for_angle(angle)
	if ray == null:
		return 0.0
	
	if ray.is_occluded:
		# 如果射线被遮挡，检查距离是否小于遮挡距离
		if length < ray.ray_length:
			return intensity
		else:
			return 0.0
	else:
		# 如果射线未被遮挡，直接计算强度
		return intensity


func _normalize_angle(angle: float) -> float:
	var result: float = fmod(angle + PI, 2.0 * PI)
	if result < 0:
		result += 2.0 * PI
	return result - PI

func _angle_rotate_radians() -> float:
	return deg_to_rad(angle_rotate)


func _angle_in_ray(angle: float, ray: SampleRay) -> bool:
	var rotate_radians = _angle_rotate_radians()
	var local_angle = _normalize_angle(angle - rotate_radians)
	var local_start = _normalize_angle(ray.angle_start - rotate_radians)
	var local_end = _normalize_angle(ray.angle_end - rotate_radians)
	return local_angle >= local_start and local_angle < local_end


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
