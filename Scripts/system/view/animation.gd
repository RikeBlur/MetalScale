extends Control

@export var n1: float = 0.3
@export var m1: float = 0.1
@export var n2: float = 0.3
@export var m2: float = 0.1
@export var first_delay: float = 0.3

func _ready() -> void:
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
			await _tween_dissolve(node, n1)
			if m1 > 0.0:
				await get_tree().create_timer(m1).timeout
		elif node is TextureRect:
			await _tween_dissolve(node, n2)
			if m2 > 0.0:
				await get_tree().create_timer(m2).timeout

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
