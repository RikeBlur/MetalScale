extends Control

@export var label_dissolve_duration: float = 0.3
@export var label_after_delay: float = 0.1
@export var texture_dissolve_duration: float = 0.3
@export var texture_after_delay: float = 0.1
@export var first_delay: float = 0.3
@export var fade_out_duration: float = 0.3  # 名字含_N的子节点淡出持续时间

var _ready_msec: float = 0.0  # _ready调用时的时间戳（秒）

func _ready() -> void:
	_ready_msec = Time.get_ticks_msec() / 1000.0
	_schedule_all_fadeouts()
	await _play_dissolve_sequence()

func _play_dissolve_sequence() -> void:
	var all_nodes := _collect_canvas_items(self)
	var target_nodes: Array[CanvasItem] = []

	# 仅收集参与动画的节点，并确保每个节点材质独立
	for node in all_nodes:
		if node is Label or node is TextureRect:
			_ensure_unique_material(node)
			target_nodes.append(node)

	# 初始化参与动画的节点 DissolveValue 为 0.0
	for node in target_nodes:
		node.visible = false
		_set_dissolve(node, 0.0)

	# 严格按顺序：每个节点 tween 完再等待，再到下一个节点
	if first_delay > 0.0:
		await get_tree().create_timer(first_delay).timeout

	for node in target_nodes:
		node.visible = true
		if node is Label:
			await _tween_dissolve(node, label_dissolve_duration)
			if label_after_delay > 0.0:
				await get_tree().create_timer(label_after_delay).timeout
		elif node is TextureRect:
			await _tween_dissolve(node, texture_dissolve_duration)
			if texture_after_delay > 0.0:
				await get_tree().create_timer(texture_after_delay).timeout

func _tween_dissolve(node: CanvasItem, duration: float) -> void:
	if duration <= 0.0:
		_set_dissolve(node, 1.0)
		return

	var tween := create_tween()
	tween.tween_method(
		func(value: float): _set_dissolve(node, value),
		0.0,
		1.0,
		duration
	)
	await tween.finished

func _schedule_all_fadeouts() -> void:
	"""扫描所有子节点，名字含'_'且后缀为合法浮点数的节点将在fade_time秒时淡出消失"""
	for node in _collect_canvas_items(self):
		var idx: int = node.name.rfind("_")
		if idx < 0:
			continue
		var suffix: String = node.name.substr(idx + 1)
		if not suffix.is_valid_float():
			continue
		_schedule_fadeout(node, suffix.to_float())  # 不 await，独立并发协程

func _schedule_fadeout(node: CanvasItem, fade_time: float) -> void:
	"""等到 fade_time 秒（从_ready起算）后，将节点 dissolve 从1→0 并隐藏"""
	var elapsed: float = Time.get_ticks_msec() / 1000.0 - _ready_msec
	var wait: float = maxf(0.0, fade_time - elapsed)
	await get_tree().create_timer(wait).timeout
	if not is_instance_valid(node):
		return
	_ensure_unique_material(node)
	node.visible = true
	await _tween_dissolve_out(node, fade_out_duration)
	if is_instance_valid(node):
		node.visible = false

func _tween_dissolve_out(node: CanvasItem, duration: float) -> void:
	"""将节点 dissolve 从1.0 tween 到0.0"""
	_set_dissolve(node, 1.0)
	if duration <= 0.0:
		_set_dissolve(node, 0.0)
		return
	var tween := create_tween()
	tween.tween_method(
		func(value: float): _set_dissolve(node, value),
		1.0,
		0.0,
		duration
	)
	await tween.finished

func _set_dissolve(node: CanvasItem, value: float) -> void:
	if not node or not node.material:
		return
	node.material.set("shader_parameter/DissolveValue", value)

func _ensure_unique_material(node: CanvasItem) -> void:
	if not node or not node.material:
		return
	node.material = node.material.duplicate(true)

func _collect_canvas_items(root: Node) -> Array[CanvasItem]:
	var result: Array[CanvasItem] = []
	for child in root.get_children():
		if child is CanvasItem:
			result.append(child)
		result.append_array(_collect_canvas_items(child))
	return result
