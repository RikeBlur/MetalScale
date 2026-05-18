class_name DialogueComponent
extends Node2D

# 在编辑器里填充这些数组：
@export var trigger_source : Array = []
@export var trigger_flag : Array[dialogue_flag]
@export var dialogue_content : Array[DialogueResource]
@export var camera : Camera2D = null
@export var current_flag : int = 0
@export var dialogue_fade_time: float = 0.2

var dialogue_style : Array = []
var dialogue_inst : Array = []
var camera_position : Vector2 = Vector2.ZERO
var _dialogue_fade_tweens: Dictionary = {}
var _dialogues_finishing: Dictionary = {}
#var camera_offset : Vector2 = Vector2(-576, -324)

# 一个示例预加载的对话场景（可移除/替换）
var dialogue_1 = preload("res://System/RPG/interact/dialogue/template/dialogue_ax_b.tscn")
var dialogue_2 = preload("res://System/RPG/interact/dialogue/template/dialogue_ax_a.tscn")
var dialogue_3 = preload("res://System/RPG/interact/dialogue/template/dialogue_oni_a.tscn")
var dialogue_4 = preload("res://System/RPG/interact/dialogue/template/dialogue_oni_ax.tscn")

var dialogue_reminder = preload("res://System/RPG/interact/dialogue/dialogue_reminder.tscn")
var reminder_instances : Dictionary = {}  # 存储每个area对应的reminder实例

@export var player_node : CharacterBody2D = null 
@onready var canvas_layer : CanvasLayer = $CanvasLayer

func _ready() -> void:
	# 确保有 CanvasLayer 子节点
	if not canvas_layer:
		canvas_layer = CanvasLayer.new()
		add_child(canvas_layer)
		print("DialogueManager: 自动创建 CanvasLayer")
	# 如果编辑器里没有填 dialogues，至少用示例占位，避免索引越界
	if dialogue_style.size() == 0:
		dialogue_style.append(dialogue_1)
		dialogue_style.append(dialogue_2)
		dialogue_style.append(dialogue_3)
		dialogue_style.append(dialogue_4)

	_ensure_array_lengths()
	
	# 从 GameManager 获取 player 节点
	if not player_node:
		player_node = GameManager.get_player()
		if player_node:
			print("DialogueManager: 从 GameManager 获取到 player 节点")
		else:
			push_warning("DialogueManager: 未从 GameManager 获取到 player 节点")
	
	# 从 GameManager 获取 camera 节点
	if not camera:
		camera = GameManager.get_camera()
		if camera:
			print("DialogueManager: 从 GameManager 获取到 camera 节点")
		else:
			push_warning("DialogueManager: 未从 GameManager 获取到 camera 节点")
		
	_trigger_source_connect()


# 保证 trigger_flag 与 dialogues 长度至少与 trigger_source 一致
func _ensure_array_lengths() -> void:
	var n := trigger_flag.size()
	while dialogue_style.size() < n:
		# 用第一个对话场景或空值填充以避免越界
		if dialogue_1:
			dialogue_style.append(dialogue_1)
		else:
			dialogue_style.append(null)
	
	# 没有任何flag时直接停用
	if trigger_flag.size() == 0:
		current_flag = -1
		return
	
	# current_flag 越界时兜底回到0
	if current_flag >= trigger_flag.size() or current_flag < -1:
		push_warning("DialogueComponent: current_flag 越界，已重置为 0")
		current_flag = 0


func _trigger_source_connect() -> void:	
	# 触发源固定为一个；若编辑器里填了多个，只使用第一个
	if trigger_source == null or trigger_source.size() == 0:
		push_warning("DialogueComponent: trigger_source 为空")
		return
	
	var source = get_node_or_null(trigger_source[0])
	if not source or not (source is Area2D):
		push_warning("DialogueComponent: trigger_source[0] 不是有效的 Area2D")
		return
	
	if source.get_child_count() <= 0 or not (source.get_child(0) is interacted_component):
		print("I want to spawn dialogue but no interacted component ... ")
		return
	
	var inter_comp: interacted_component = source.get_child(0)
	# 将interact组件和dialogue生成组件绑定
	inter_comp.connect("be_interactable", _spawn_reminder.bind(source))
	inter_comp.connect("be_not_interactable", _destory_reminder.bind(source))
	inter_comp.connect("interacted", _destory_reminder.bind(source))
	inter_comp.connect("interacted", _on_triggered.bind(source))


# ==================================================================
# ============================== 触发 ============================
# ==================================================================

# ============================== 内部触发 ============================
func _on_triggered(area: Area2D) -> void:
	# current_flag == -1 代表该对话已停用
	if current_flag == -1:
		_destory_reminder(area)
		return
	
	# 越界/空配置兜底：直接停用
	if trigger_flag.size() == 0 or current_flag < 0 or current_flag >= trigger_flag.size():
		push_warning("DialogueComponent: current_flag 非法，已停用触发")
		current_flag = -1
		_destory_reminder(area)
		return
	
	# 当前触发生效
	trigger_flag[current_flag].flag = true
	print("trigger set:", current_flag)
	_apply_next_flag(trigger_flag[current_flag].next_flag)
# ============================= 外部触发 =============================
func trigger_dialogue(area: Area2D = null) -> void:
	var trigger_area := area
	if trigger_area == null and trigger_source != null and trigger_source.size() > 0:
		var source = get_node_or_null(trigger_source[0])
		if source is Area2D:
			trigger_area = source
	_on_triggered(trigger_area)

# ==================================================================
# ==================================================================
# ==================================================================


# 实时检查 trigger_flag 并在需要时实例化对话
func _process(_delta: float) -> void:
	# 更新相机位置
	if camera:
		camera_position = camera.global_position
	# 执行对话生成
	for i in range(trigger_flag.size()):
		if trigger_flag[i].flag :
			var flag_data := trigger_flag[i]
			if not _is_flag_data_valid(flag_data, i):
				flag_data.flag = false
				continue
			if !flag_data.double:
				_spawn_dialogue(flag_data.style - 1, flag_data.start, flag_data.end, i)
			if flag_data.double:
				_spawn_dual_dialogue(flag_data.style - 1, flag_data.start, flag_data.end, flag_data.a_index, flag_data.b_index, i)
		trigger_flag[i].flag = false


# 实例化并添加对话场景到场景树
func _spawn_dual_dialogue(style: int, start: int, end: int, a_index: Array[int], b_index: Array[int], source_flag_index: int = -1) -> void:
	print("生成对话")
	player_node.can_move = false
	player_node.can_interact = false
	if style < 0 or style >= dialogue_style.size():
		push_error("dialogue style index out of range: %d" % style)
		return
	var scene = dialogue_style[style]
	if scene == null:
		push_error("dialogue style[%d] is null" % style)
		return
	var inst = scene.instantiate()
	if inst == null:
		push_error("failed to instantiate dialogue style at index %d" % style)
		return

	# 将对话节点加入到 CanvasLayer（固定在屏幕空间）
	inst.dialogue = _get_dialogue_content_slice(start, end)
	inst.a_index = _global_indices_to_local_indices(a_index, start, inst.dialogue.size())
	inst.b_index = _global_indices_to_local_indices(b_index, start, inst.dialogue.size())
	inst.set_meta("source_trigger_flag_index", source_flag_index)
	# 设置 scene_root 引用，让对话框能正确解析相对路径
	inst.scene_root = self
	inst.modulate.a = 0.0
	canvas_layer.add_child(inst)
	_fade_in_dialogue(inst)
	GameManager.set_running_state(GameManager.RunningState.AUTO)
	inst.tree_exited.connect(_on_dialogue_node_exited.bind(inst), CONNECT_ONE_SHOT)
	
	# 如果对话场景提供了 dialogue_finished 信号，连接它以便自动回收实例
	if inst.has_signal("dialogue_finished"):
		inst.connect("dialogue_finished", Callable(self, "_on_dialogue_finished").bind(inst), CONNECT_ONE_SHOT)
	# 否则可以根据需要设定自动回收或由对话场景自行回收


# 实例化并添加对话场景到场景树
func _spawn_dialogue(style: int, start: int, end: int, source_flag_index: int = -1) -> void:
	print("生成对话")
	# 不能移动、互动
	player_node.can_move = false
	player_node.can_interact = false
	if style < 0 or style >= dialogue_style.size():
		push_error("dialogue style index out of range: %d" % style)
		return
	var scene = dialogue_style[style]
	if scene == null:
		push_error("dialogue style[%d] is null" % style)
		return
	var inst = scene.instantiate()
	if inst == null:
		push_error("failed to instantiate dialogue style at index %d" % style)
		return

	# 将对话节点加入到 CanvasLayer（固定在屏幕空间）
	inst.dialogue = _get_dialogue_content_slice(start, end)
	inst.set_meta("source_trigger_flag_index", source_flag_index)
	# 设置 scene_root 引用，让对话框能正确解析相对路径
	inst.scene_root = self
	inst.modulate.a = 0.0
	canvas_layer.add_child(inst)
	_fade_in_dialogue(inst)
	GameManager.set_running_state(GameManager.RunningState.AUTO)
	inst.tree_exited.connect(_on_dialogue_node_exited.bind(inst), CONNECT_ONE_SHOT)

	# 如果对话场景提供了 dialogue_finished 信号，连接它以便自动回收实例
	if inst.has_signal("dialogue_finished"):
		inst.connect("dialogue_finished", Callable(self, "_on_dialogue_finished").bind(inst), CONNECT_ONE_SHOT)
	# 否则可以根据需要设定自动回收或由对话场景自行回收


# 当对话节点发出结束信号时回收
func apply_dialogue_choice_next_index(dialogue_node: Node, next_index: int) -> void:
	if next_index < 0:
		return
	if next_index >= trigger_flag.size():
		push_warning("DialogueComponent: choice next_index(%d) 越界" % next_index)
		return

	var flag_data: dialogue_flag = trigger_flag[next_index]
	if not _is_flag_data_valid(flag_data, next_index):
		return
	if not _is_choice_branch_compatible(dialogue_node, flag_data, next_index):
		return

	var branch_dialogue: Array = _get_dialogue_content_slice(flag_data.start, flag_data.end)
	_insert_dialogue_after_current(dialogue_node, branch_dialogue)
	_extend_dual_dialogue_indices(dialogue_node, flag_data, branch_dialogue.size())
	_apply_next_flag(flag_data.next_flag)


func _insert_dialogue_after_current(dialogue_node: Node, branch_dialogue: Array) -> void:
	if dialogue_node == null or not is_instance_valid(dialogue_node):
		return
	if branch_dialogue.is_empty():
		return
	if not ("dialogue" in dialogue_node):
		push_warning("DialogueComponent: dialogue_node has no dialogue property.")
		return

	var active_dialogue: Array = dialogue_node.dialogue
	var insert_index: int = active_dialogue.size()
	if "current_dialogue_item" in dialogue_node:
		insert_index = clamp(int(dialogue_node.current_dialogue_item) + 1, 0, active_dialogue.size())

	for i in range(branch_dialogue.size() - 1, -1, -1):
		active_dialogue.insert(insert_index, branch_dialogue[i])
	dialogue_node.dialogue = active_dialogue


func _extend_dual_dialogue_indices(dialogue_node: Node, flag_data: dialogue_flag, inserted_count: int) -> void:
	if inserted_count <= 0:
		return
	if dialogue_node == null or not is_instance_valid(dialogue_node):
		return
	if not ("a_index" in dialogue_node and "b_index" in dialogue_node):
		return

	var insert_index: int = 0
	if "current_dialogue_item" in dialogue_node:
		insert_index = int(dialogue_node.current_dialogue_item) + 1

	dialogue_node.a_index = _shift_indices_after_insert(dialogue_node.a_index, insert_index, inserted_count)
	dialogue_node.b_index = _shift_indices_after_insert(dialogue_node.b_index, insert_index, inserted_count)

	if flag_data.double:
		var local_a_indices: Array[int] = _global_indices_to_local_indices(flag_data.a_index, flag_data.start, inserted_count)
		var local_b_indices: Array[int] = _global_indices_to_local_indices(flag_data.b_index, flag_data.start, inserted_count)
		for local_index in local_a_indices:
			dialogue_node.a_index.append(insert_index + local_index)
		for local_index in local_b_indices:
			dialogue_node.b_index.append(insert_index + local_index)
	else:
		var which_index: int = 0
		if "which" in dialogue_node:
			which_index = int(dialogue_node.which)
		for i in range(inserted_count):
			if which_index == 1:
				dialogue_node.b_index.append(insert_index + i)
			else:
				dialogue_node.a_index.append(insert_index + i)


func _shift_indices_after_insert(indices: Array, insert_index: int, inserted_count: int) -> Array[int]:
	var result: Array[int] = []
	for raw_index in indices:
		var index: int = int(raw_index)
		if index >= insert_index:
			index += inserted_count
		result.append(index)
	return result


func _global_indices_to_local_indices(indices: Array, global_start: int, content_count: int) -> Array[int]:
	var result: Array[int] = []
	for raw_index in indices:
		var local_index: int = int(raw_index) - global_start
		if local_index >= 0 and local_index < content_count:
			result.append(local_index)
		else:
			push_warning("DialogueComponent: dual index %d is outside dialogue range %d-%d" % [int(raw_index), global_start, global_start + content_count - 1])
	return result


func _get_dialogue_node_source_flag_index(dialogue_node: Node) -> int:
	if dialogue_node == null or not is_instance_valid(dialogue_node):
		return -1
	if not dialogue_node.has_meta("source_trigger_flag_index"):
		return -1
	return int(dialogue_node.get_meta("source_trigger_flag_index"))


func _is_choice_branch_compatible(dialogue_node: Node, branch_flag: dialogue_flag, branch_index: int) -> bool:
	if branch_flag.double and (dialogue_node == null or not is_instance_valid(dialogue_node) or not ("a_index" in dialogue_node and "b_index" in dialogue_node)):
		push_error("DialogueComponent: choice next_index trigger_flag[%d] is double, but active dialogue node is not dialogue_dual." % branch_index)
		return false

	var source_index: int = _get_dialogue_node_source_flag_index(dialogue_node)
	if source_index < 0 or source_index >= trigger_flag.size():
		return true

	var source_flag: dialogue_flag = trigger_flag[source_index]
	if not source_flag:
		return true

	if source_flag.double and not branch_flag.double:
		push_error("DialogueComponent: current trigger_flag[%d] is double, but choice next_index trigger_flag[%d] is not double." % [source_index, branch_index])
		return false

	if source_flag.double and branch_flag.double and source_flag.style != branch_flag.style:
		push_warning("DialogueComponent: current trigger_flag[%d] and choice next_index trigger_flag[%d] are both double but style differs." % [source_index, branch_index])

	return true


func _get_dialogue_content_slice(start: int, end: int) -> Array:
	if dialogue_content.is_empty():
		return []

	var safe_start: int = clamp(start, 0, dialogue_content.size() - 1)
	var safe_end: int = clamp(end, 0, dialogue_content.size() - 1)
	if safe_end < safe_start:
		push_warning("DialogueComponent: invalid dialogue range start=%d end=%d" % [start, end])
		return []

	return dialogue_content.slice(safe_start, safe_end + 1)


func _apply_next_flag(next_idx: int) -> void:
	if next_idx == -1:
		current_flag = -1
	elif next_idx >= 0 and next_idx < trigger_flag.size():
		current_flag = next_idx
	else:
		push_warning("DialogueComponent: next_flag(%d) 非法，已停用触发" % next_idx)
		current_flag = -1

	_sync_current_flag_to_base_level()


func _sync_current_flag_to_base_level() -> void:
	var base_level = _find_base_level()
	if base_level:
		base_level.update_interactable_state(get_path(), current_flag)
	else:
		push_warning("DialogueComponent: 未找到 BaseLevel，无法更新 interactables 状态")


func _on_dialogue_finished(inst: Node) -> void:
	await _fade_out_and_free_dialogue(inst)

func _on_dialogue_node_exited(inst: Node = null) -> void:
	if inst:
		_dialogues_finishing.erase(inst)
		if inst is CanvasItem:
			_dialogue_fade_tweens.erase(inst)
	_restore_running_state_after_dialogue()

func _restore_running_state_after_dialogue() -> void:
	GameManager.set_running_state(GameManager.RunningState.CONTROL)

func _fade_in_dialogue(inst: CanvasItem) -> void:
	if not is_instance_valid(inst):
		return
	_kill_dialogue_fade_tween(inst)
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_dialogue_fade_tweens[inst] = tween
	tween.tween_property(inst, "modulate:a", 1.0, max(dialogue_fade_time, 0.0))
	await tween.finished
	if _dialogue_fade_tweens.get(inst) == tween:
		_dialogue_fade_tweens.erase(inst)

func _fade_out_and_free_dialogue(inst: Node) -> void:
	if not inst or not is_instance_valid(inst):
		_restore_running_state_after_dialogue()
		return
	if _dialogues_finishing.has(inst):
		return

	_dialogues_finishing[inst] = true
	inst.process_mode = Node.PROCESS_MODE_DISABLED
	if inst is CanvasItem:
		var canvas_item := inst as CanvasItem
		_kill_dialogue_fade_tween(canvas_item)
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_dialogue_fade_tweens[canvas_item] = tween
		tween.tween_property(canvas_item, "modulate:a", 0.0, max(dialogue_fade_time, 0.0))
		await tween.finished
		if _dialogue_fade_tweens.get(canvas_item) == tween:
			_dialogue_fade_tweens.erase(canvas_item)

	if is_instance_valid(inst):
		inst.queue_free()

func _kill_dialogue_fade_tween(inst: CanvasItem) -> void:
	var tween = _dialogue_fade_tweens.get(inst)
	if tween and tween.is_valid():
		tween.kill()
	_dialogue_fade_tweens.erase(inst)
		
func _spawn_reminder(area: Area2D) -> void:
	# current_flag == -1 时表示该对话已停用：不再显示reminder
	if current_flag == -1:
		_destory_reminder(area)
		return

	# 如果该area已经有reminder实例，先销毁
	if reminder_instances.has(area):
		_destory_reminder(area)
	
	var pos : Vector2 = area.global_position
	var inst = dialogue_reminder.instantiate()
	
	# 设置位置偏移（可以根据需要调整）
	var offset = Vector2(30, -80)  
	
	# 添加到场景树
	add_child(inst)
	# 先入树再设置global_position，避免父节点变换导致位置偏差
	inst.global_position = pos + offset
	# 提高显示层级，避免被场景元素遮挡
	inst.z_as_relative = false
	inst.z_index = 100
	
	# 播放动画
	var animated_sprite = inst.get_node("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.play()
	
	# 存储实例引用
	reminder_instances[area] = inst

func _destory_reminder(area: Area2D) -> void:
	if not reminder_instances:
		return
	
	if reminder_instances.has(area):
		var inst = reminder_instances[area]
		
		# 暂停动画
		var animated_sprite = inst.get_node("AnimatedSprite2D")
		if animated_sprite:
			animated_sprite.pause()
		
		# 销毁实例
		if is_instance_valid(inst):
			inst.queue_free()
		
		# 从字典中移除
		reminder_instances.erase(area)

func _is_flag_data_valid(flag_data: dialogue_flag, idx: int) -> bool:
	if not flag_data:
		push_warning("DialogueComponent: trigger_flag[%d] is null" % idx)
		return false
	if flag_data.style <= 0:
		push_warning("DialogueComponent: trigger_flag[%d].style must be >= 1" % idx)
		return false
	if flag_data.start < 0:
		push_warning("DialogueComponent: trigger_flag[%d].start must be >= 0" % idx)
		return false
	if flag_data.end < 0:
		push_warning("DialogueComponent: trigger_flag[%d].end must be >= 0" % idx)
		return false
	return true


func _find_base_level() -> BaseLevel:
	"""
	查找场景树中的 BaseLevel 节点
	
	返回:
		BaseLevel 节点，如果未找到则返回 null
	"""
	# 从当前节点向上查找
	var current = get_parent()
	while current:
		if current is BaseLevel:
			return current
		current = current.get_parent()
	
	# 如果向上没找到，尝试从根场景查找
	var root = get_tree().current_scene
	if root is BaseLevel:
		return root
	
	# 递归查找子节点
	return _find_base_level_recursive(root)

func _find_base_level_recursive(node: Node) -> BaseLevel:
	"""递归查找 BaseLevel 节点"""
	if node is BaseLevel:
		return node
	
	for child in node.get_children():
		var result = _find_base_level_recursive(child)
		if result:
			return result
	
	return null
