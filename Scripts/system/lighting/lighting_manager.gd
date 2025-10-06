class_name lighting_manager
extends Node2D

@export var light_sources: Array[light_source] = []
@export var detecte_offset: float = 100.0
@export var update_rate : float = 0.2
@export var grid_size : float = 10.0

var occlusion_points: PackedVector2Array = []
var detectors: Array[light_detector] = []
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
	update_detectors()
	update_occlusion_points()
	assign_occlusion_to_lights()
	assign_lights_to_detectors()

func _on_update_timer_timeout():
	"""定时更新回调"""
	update_light_sources()
	update_detectors()
	update_occlusion_points()
	assign_occlusion_to_lights()
	assign_lights_to_detectors()

func update_light_sources():
	"""更新场景中的光源列表"""
	light_sources.clear()
	
	# 获取场景中所有light_source分组的节点
	var light_source_nodes = get_tree().get_nodes_in_group("light_source")
	
	for node in light_source_nodes:
		if node is light_source:
			light_sources.append(node)
	
	#print("找到 ", light_sources.size(), " 个光源")

func update_detectors():
	"""更新场景中的检测器列表"""
	detectors.clear()
	
	# 获取场景中所有detector分组的节点
	var detector_nodes = get_tree().get_nodes_in_group("light_detector")
	
	for node in detector_nodes:
		if node is light_detector:
			detectors.append(node)
	
	#print("找到 ", detectors.size(), " 个检测器")

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
				#print("找到LightOccluder2D: ", node.name, " light_mask: ", node.occluder_light_mask)
				
				# 获取polygon中的所有点
				var polygon = node.occluder.polygon
				if polygon and polygon.size() > 0:
					# 生成多边形边缘上的采样点
					var edge_points = generate_polygon_edge_points(polygon, node.global_transform, grid_size)
					occlusion_points.append_array(edge_points)
					#print("添加 ", edge_points.size(), " 个边缘遮挡点")
		
		# 检查是否为TileMapLayer类型
		elif node is TileMapLayer:
			# 检查是否有Occlusion layer和light_mask == 1的tile
			var _tilemap_layer = node as TileMapLayer
			#if tilemap_layer:
				#var tilemap_points = extract_tilemap_occlusion_points(tilemap_layer)
				#occlusion_points.append_array(tilemap_points)
				#if tilemap_points.size() > 0:
				#	print("从TileMapLayer ", node.name, " 提取了 ", tilemap_points.size(), " 个遮挡点")
	
	#print("找到 ", occlusion_points.size(), " 个遮挡点")

func generate_polygon_edge_points(polygon: PackedVector2Array, polygon_transform: Transform2D, sample_grid_size: float) -> PackedVector2Array:
	"""生成多边形边缘上的采样点"""
	var points = PackedVector2Array()
	
	if polygon.size() < 3:
		return points
	
	# 遍历多边形的每条边
	for i in range(polygon.size()):
		var start_point = polygon[i]
		var end_point = polygon[(i + 1) % polygon.size()]
		
		# 计算边的长度
		var edge_length = start_point.distance_to(end_point)
		
		# 计算这条边上需要采样的点数
		var sample_count = max(1, int(edge_length / sample_grid_size))
		
		# 在边上均匀采样点
		for j in range(sample_count + 1):
			var t = float(j) / float(sample_count) if sample_count > 0 else 0.0
			var edge_point = start_point.lerp(end_point, t)
			
			# 转换为全局坐标
			var global_point = polygon_transform * edge_point
			points.append(global_point)
	
	return points


func extract_tilemap_occlusion_points(tilemap_layer: TileMapLayer) -> PackedVector2Array:
	"""从TileMapLayer中提取遮挡点"""
	var points = PackedVector2Array()
	
	if not tilemap_layer:
		return points
	
	# 获取TileMapLayer的used_rect（已使用的区域）
	var used_rect = tilemap_layer.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return points
	
	# 遍历所有已使用的tile
	for x in range(used_rect.position.x, used_rect.position.x + used_rect.size.x):
		for y in range(used_rect.position.y, used_rect.position.y + used_rect.size.y):
			var cell_coord = Vector2i(x, y)
			
			# 获取该位置的tile数据
			var source_id = tilemap_layer.get_cell_source_id(cell_coord)
			if source_id == -1:  # 没有tile
				continue
			
			# 检查tile的occlusion layer和light_mask
			var tile_data = tilemap_layer.get_cell_tile_data(cell_coord)
			if tile_data:
				# 检查是否有occlusion layer
				var has_occlusion = tile_data.get_custom_data("occlusion_layer") != null
				var tile_light_mask = tile_data.get_custom_data("light_mask")
				
				# 如果满足条件：有occlusion layer且light_mask == 1
				if has_occlusion and tile_light_mask == 1:
					# 将tile坐标转换为世界坐标
					var world_pos = tilemap_layer.map_to_local(cell_coord)
					
					# 获取tile的尺寸
					var tile_size = tilemap_layer.tile_set.tile_size
					
					# 在tile区域内生成栅格化采样点
					var tile_points = generate_tile_internal_points(world_pos, tile_size, grid_size)
					points.append_array(tile_points)
	
	return points

func generate_tile_internal_points(tile_world_pos: Vector2, tile_size: Vector2, sample_grid_size: float) -> PackedVector2Array:
	"""在tile区域内生成栅格化采样点"""
	var points = PackedVector2Array()
	
	# 计算tile的边界
	var min_x = tile_world_pos.x
	var max_x = tile_world_pos.x + tile_size.x
	var min_y = tile_world_pos.y
	var max_y = tile_world_pos.y + tile_size.y
	
	# 在tile区域内进行栅格化采样
	var x = min_x
	while x < max_x:
		var y = min_y
		while y < max_y:
			var point = Vector2(x, y)
			points.append(point)
			y += sample_grid_size
		x += sample_grid_size
	
	return points


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
				#print("光源 ", light.name, " 添加遮挡点: ", occlusion_point, " 距离: ", distance)

func assign_lights_to_detectors():
	"""为每个检测器分配附近的光源"""
	for detector in detectors:
		if not is_instance_valid(detector):
			continue
		
		# 清空检测器的现有光源列表
		detector.nearby_light_sources.clear()
		
		# 获取检测器的检测范围
		var detect_range = detector.radius
		var detector_pos = detector.global_position
		
		# 检查每个光源是否在检测范围内
		for light in light_sources:
			if not is_instance_valid(light):
				continue
				
			var distance = detector_pos.distance_to(light.global_position)
			if distance <= detect_range:
				detector.nearby_light_sources.append(light)
				#print("检测器 ", detector.name, " 添加光源: ", light.name, " 距离: ", distance)

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

func get_light_source_by_name(light_name: String) -> light_source:
	"""根据名称获取光源"""
	for light in light_sources:
		if is_instance_valid(light) and light.name == light_name:
			return light
	return null

func force_update():
	"""强制更新所有数据"""
	print("=== 强制更新光照管理器 ===")
	update_light_sources()
	update_detectors()
	update_occlusion_points()
	assign_occlusion_to_lights()
	assign_lights_to_detectors()
	print("更新完成 - 光源: ", light_sources.size(), " 检测器: ", detectors.size(), " 遮挡点: ", occlusion_points.size())

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

func add_detector(detector: light_detector):
	"""手动添加检测器"""
	if detector not in detectors:
		detectors.append(detector)
		print("手动添加检测器: ", detector.name)

func remove_detector(detector: light_detector):
	"""手动移除检测器"""
	var index = detectors.find(detector)
	if index != -1:
		detectors.remove_at(index)
		print("移除检测器: ", detector.name)

func get_detectors_count() -> int:
	"""获取检测器数量"""
	return detectors.size()

func get_detector_by_name(detector_name: String) -> light_detector:
	"""根据名称获取检测器"""
	for detector in detectors:
		if is_instance_valid(detector) and detector.name == detector_name:
			return detector
	return null
