class_name lighting_manager
extends Node2D

@export var light_sources: Array[light_source] = []
@export var detecte_offset: float = 100.0
@export var update_rate : float = 1.0
@export var grid_size : float = 10.0

var occlusion_points: PackedVector2Array = []
var update_timer: Timer

func _ready():
	# 创建更新定时器
	update_timer = Timer.new()
	update_timer.wait_time = update_rate
	update_timer.timeout.connect(_on_update_timer_timeout)
	add_child(update_timer)
	update_timer.start()
	
	# 初始化
	update_light_sources()
	update_occlusion_points()
	assign_occlusion_to_lights()

func _on_update_timer_timeout():
	"""定时更新回调"""
	update_light_sources()
	update_occlusion_points()
	assign_occlusion_to_lights()

func update_light_sources():
	"""更新场景中的光源列表"""
	light_sources.clear()
	
	# 获取场景中所有light_source分组的节点
	var light_source_nodes = get_tree().get_nodes_in_group("light_source")
	
	for node in light_source_nodes:
		if node is light_source:
			light_sources.append(node)
	
	print("找到 ", light_sources.size(), " 个光源")

func update_occlusion_points():
	"""更新场景中的遮挡点列表"""
	occlusion_points.clear()
	
	# 获取场景中所有节点
	var all_nodes = get_tree().get_nodes_in_group("occlusion")
	
	for node in all_nodes:
		# 检查是否为LightOccluder2D类型
		if node is LightOccluder2D:
			# 检查OccluderLightMask是否为1
			if node.occluder_light_mask == 1:
				print("找到LightOccluder2D: ", node.name, " light_mask: ", node.occluder_light_mask)
				
				# 获取polygon中的所有点
				var polygon = node.occluder.polygon
				if polygon and polygon.size() > 0:
					# 生成多边形内部的所有点
					var internal_points = generate_polygon_internal_points(polygon, node.global_transform, grid_size)
					occlusion_points.append_array(internal_points)
					#print("添加 ", internal_points.size(), " 个内部遮挡点")
	
	print("找到 ", occlusion_points.size(), " 个遮挡点")

func generate_polygon_internal_points(polygon: PackedVector2Array, transform: Transform2D, grid_size: float) -> PackedVector2Array:
	"""生成多边形内部的所有点"""
	var points = PackedVector2Array()
	
	if polygon.size() < 3:
		return points
	
	# 计算多边形的边界框
	var min_x = polygon[0].x
	var max_x = polygon[0].x
	var min_y = polygon[0].y
	var max_y = polygon[0].y
	
	for point in polygon:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
	
	# 遍历边界框内的所有点
	var x = min_x
	while x <= max_x:
		var y = min_y
		while y <= max_y:
			var test_point = Vector2(x, y)
			
			# 检查点是否在多边形内部
			if is_point_in_polygon(test_point, polygon):
				# 转换为全局坐标
				var global_point = transform * test_point
				points.append(global_point)
			
			y += grid_size
		x += grid_size
	
	return points

func is_point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	"""使用射线投射算法判断点是否在多边形内部"""
	if polygon.size() < 3:
		return false
	
	var inside = false
	var j = polygon.size() - 1
	
	for i in range(polygon.size()):
		var pi = polygon[i]
		var pj = polygon[j]
		
		if ((pi.y > point.y) != (pj.y > point.y)) and (point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y) + pi.x):
			inside = !inside
		
		j = i
	
	return inside


func assign_occlusion_to_lights():
	"""为每个光源分配附近的遮挡点"""
	for light in light_sources:
		if not is_instance_valid(light):
			continue
			
		# 清空光源的现有遮挡点
		light.clear_occlusion_points()
		
		# 计算检测范围
		var detection_radius = light.radius + detecte_offset
		var light_pos = light.global_position
		
		# 检查每个遮挡点是否在范围内
		for occlusion_point in occlusion_points:
			var distance = light_pos.distance_to(occlusion_point)
			if distance <= detection_radius:
				light.add_occlusion_point(occlusion_point)
				print("光源 ", light.name, " 添加遮挡点: ", occlusion_point, " 距离: ", distance)

func add_light_source(light: light_source):
	"""手动添加光源"""
	if light not in light_sources:
		light_sources.append(light)
		print("手动添加光源: ", light.name)

func remove_light_source(light: light_source):
	"""手动移除光源"""
	var index = light_sources.find(light)
	if index != -1:
		light_sources.remove_at(index)
		print("移除光源: ", light.name)

func add_occlusion_point(point: Vector2):
	"""手动添加遮挡点"""
	occlusion_points.append(point)
	print("手动添加遮挡点: ", point)

func remove_occlusion_point(point: Vector2):
	"""手动移除遮挡点"""
	var index = occlusion_points.find(point)
	if index != -1:
		occlusion_points.remove_at(index)
		print("移除遮挡点: ", point)

func clear_all_occlusion_points():
	"""清空所有遮挡点"""
	occlusion_points.clear()
	for light in light_sources:
		if is_instance_valid(light):
			light.clear_occlusion_points()
	print("清空所有遮挡点")

func get_light_sources_count() -> int:
	"""获取光源数量"""
	return light_sources.size()

func get_occlusion_points_count() -> int:
	"""获取遮挡点数量"""
	return occlusion_points.size()

func get_light_source_by_name(name: String) -> light_source:
	"""根据名称获取光源"""
	for light in light_sources:
		if is_instance_valid(light) and light.name == name:
			return light
	return null

func force_update():
	"""强制更新所有数据"""
	print("=== 强制更新光照管理器 ===")
	update_light_sources()
	update_occlusion_points()
	assign_occlusion_to_lights()
	print("更新完成 - 光源: ", light_sources.size(), " 遮挡点: ", occlusion_points.size())

func debug_all_nodes():
	"""调试：显示所有节点的信息"""
	print("=== 调试所有节点 ===")
	var all_nodes = get_tree().get_nodes_in_group("")
	
	for node in all_nodes:
		# 检查LightOccluder2D节点
		if node is LightOccluder2D:
			print("LightOccluder2D: ", node.name, " light_mask: ", node.occluder_light_mask, " polygon_size: ", node.occluder_polygon.size())
		
		# 检查其他遮挡层节点
		var has_occlusion = false
		var occlusion_value = -1
		
		if node.has_method("get"):
			occlusion_value = node.get("occlusion_layer")
			has_occlusion = occlusion_value != -1
		elif node.has_method("has_meta") and node.has_meta("occlusion_layer"):
			occlusion_value = node.get_meta("occlusion_layer", -1)
			has_occlusion = true
		
		if has_occlusion:
			print("节点: ", node.name, " 类型: ", node.get_class(), " occlusion_layer: ", occlusion_value)

func set_light_occluder_mask(occluder_path: String, mask_value: int = 1):
	"""为指定路径的LightOccluder2D设置遮挡掩码"""
	var node = get_node_or_null(occluder_path)
	if node and node is LightOccluder2D:
		node.occluder_light_mask = mask_value
		print("设置 ", occluder_path, " 的遮挡掩码为: ", mask_value)
	else:
		print("未找到LightOccluder2D节点: ", occluder_path)

func set_all_light_occluders_mask(mask_value: int = 1):
	"""为场景中所有LightOccluder2D设置遮挡掩码"""
	var all_nodes = get_tree().get_nodes_in_group("")
	
	for node in all_nodes:
		if node is LightOccluder2D:
			node.occluder_light_mask = mask_value
			print("设置LightOccluder2D遮挡掩码: ", node.name, " 值: ", mask_value)

func get_light_occluders_count() -> int:
	"""获取LightOccluder2D节点数量"""
	var count = 0
	var all_nodes = get_tree().get_nodes_in_group("")
	
	for node in all_nodes:
		if node is LightOccluder2D:
			count += 1
	
	return count
