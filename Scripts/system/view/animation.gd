extends Control

@export var label_dissolve_duration: float = 0.3
@export var label_after_delay: float = 0.1
@export var texture_dissolve_duration: float = 0.3
@export var texture_after_delay: float = 0.1
@export var first_delay: float = 0.3
@export var fade_out_duration: float = 0.3

var _ready_msec: float = 0.0


func _ready() -> void:
	_ready_msec = Time.get_ticks_msec() / 1000.0
	_schedule_all_fadeouts()
	await _play_dissolve_sequence()


func _play_dissolve_sequence() -> void:
	var all_nodes := _collect_canvas_items(self)
	var target_nodes: Array[CanvasItem] = []

	for node in all_nodes:
		if node is Label or node is TextureRect:
			_ensure_unique_material(node)
			target_nodes.append(node)

	for node in target_nodes:
		node.visible = false
		_set_dissolve(node, 0.0)

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

		await _wait_after_node_before_next(node)


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
	for node in _collect_canvas_items(self):
		var fade_time := _get_fade_out_time(node)
		if fade_time < 0.0:
			continue
		_schedule_fadeout(node, fade_time)


func _schedule_fadeout(node: CanvasItem, fade_time: float) -> void:
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


func _get_extra_delay_after_show(node: Node) -> float:
	var timing := _get_name_timing(node)
	return timing["extra_delay"]


func _wait_after_node_before_next(node: Node) -> void:
	var extra_delay := _get_extra_delay_after_show(node)
	if extra_delay <= 0.0:
		return
	await get_tree().create_timer(extra_delay).timeout


func _get_fade_out_time(node: Node) -> float:
	var timing := _get_name_timing(node)
	return timing["fade_time"]


func _get_name_timing(node: Node) -> Dictionary:
	var result := {
		"extra_delay": 0.0,
		"fade_time": -1.0
	}
	var parts := String(node.name).split("_", false)
	if parts.size() < 2:
		return result

	var numeric_suffixes: Array[String] = []
	for i in range(1, parts.size()):
		var part := parts[i]
		if part.is_valid_float():
			numeric_suffixes.append(part)

	if numeric_suffixes.size() == 1:
		result["fade_time"] = numeric_suffixes[0].to_float()
	elif numeric_suffixes.size() >= 2:
		result["extra_delay"] = numeric_suffixes[0].to_float()
		result["fade_time"] = numeric_suffixes[1].to_float()

	return result


func _collect_canvas_items(root: Node) -> Array[CanvasItem]:
	var result: Array[CanvasItem] = []
	for child in root.get_children():
		if child is CanvasItem:
			result.append(child)
		result.append_array(_collect_canvas_items(child))
	return result
