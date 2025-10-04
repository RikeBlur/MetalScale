class_name dialogue_manager
extends Node2D

# 在编辑器里填充这些数组：
@export var trigger_source : Array = []
@export var trigger_flag : Array[dialogue_flag]
@export var dialogue_content : Array[DialogueResource]
@export var camera : Camera2D = null

var dialogue_style : Array = []
var dialogue_inst : Array = []
var camera_position : Vector2 = Vector2.ZERO
var camera_offset : Vector2 = Vector2(-576, -324)

# 一个示例预加载的对话场景（可移除/替换）
var dialogue_1 = preload("res://System/RPG/interact/dialogue/dialogue_ax_b.tscn")
var dialogue_2 = preload("res://System/RPG/interact/dialogue/dialogue_oni_a.tscn")
var dialogue_3 = preload("res://System/RPG/interact/dialogue/dialogue_oni_ax.tscn")

var dialogue_reminder = preload("res://System/RPG/interact/dialogue/dialogue_reminder.tscn")
var reminder_instances : Dictionary = {}  # 存储每个area对应的reminder实例

@export var player_node : CharacterBody2D = null 

func _ready() -> void:
	# 如果编辑器里没有填 dialogues，至少用示例占位，避免索引越界
	if dialogue_style.size() == 0:
		dialogue_style.append(dialogue_1)
		dialogue_style.append(dialogue_2)
		dialogue_style.append(dialogue_3)

	_ensure_array_lengths()
	
	for i in get_tree().get_nodes_in_group("player"):
		player_node = i
	
	# 连接每个 trigger_source 的 area_entered 信号，并把 index bind 到回调
	for i in range(trigger_source.size()):
		if trigger_source != null:
			# 绑定索引 i，回调签名为: func _on_trigger_area_entered(idx: int)
			var source = get_node(trigger_source[i])
			if source is Area2D:
				if source.get_child(0) is interacted_component :
					# 将interact组件和dialogue生成组件绑定
					source.get_child(0).connect("be_interactable", _spawn_reminder.bind(source))
					source.get_child(0).connect("be_not_interactable", _destory_reminder.bind(source))
					source.get_child(0).connect("interacted", _destory_reminder.bind(source))
					source.get_child(0).connect("interacted", _on_triggered.bind(source,i))
				else :
					print("I want to spawn dialogue but no interacted component ... ")
		else:
			push_warning("trigger_source[%d] is null" % i)


# 保证 trigger_flag 与 dialogues 长度至少与 trigger_source 一致
func _ensure_array_lengths() -> void:
	var n := trigger_source.size()
	while trigger_flag.size() < n:
		trigger_flag.append(0)
	while dialogue_style.size() < n:
		# 用第一个对话场景或空值填充以避免越界
		if dialogue_1:
			dialogue_style.append(dialogue_1)
		else:
			dialogue_style.append(null)


# 当某个触发区检测到进入时调用（被绑定的回调）
func _on_triggered(area: Area2D, idx: int) -> void:
	# 把对应标记置为 1（外部或其他逻辑也可直接修改 trigger_flag）
	if idx >= 0 and idx < trigger_flag.size():
		if trigger_flag[idx].only_once and !trigger_flag[idx].triggered:
			trigger_flag[idx].triggered = true
			# 解除reminder生成机制，避免重复产生reminder
			area.get_child(0).disconnect("be_interactable", _spawn_reminder)
			area.get_child(0).disconnect("be_not_interactable", _destory_reminder)
			area.get_child(0).disconnect("interacted", _destory_reminder)
		elif trigger_flag[idx].only_once and trigger_flag[idx].triggered:
			return
		trigger_flag[idx].flag = true
		# 可选：打印调试信息
		print("trigger set:", idx)


# 实时检查 trigger_flag 并在需要时实例化对话
func _process(delta: float) -> void:
	# 更新相机位置
	camera_position = camera.global_position
	# 执行对话生成
	for i in range(trigger_flag.size()):
		if trigger_flag[i].flag :
			if !trigger_flag[i].double: _spawn_dialogue(trigger_flag[i].style[0]-1, i, trigger_flag[i].start[0], trigger_flag[i].end[0])				
			if trigger_flag[i].double: _spawn_dual_dialogue(trigger_flag[i].style[0]-1, i, trigger_flag[i].start[0], trigger_flag[i].end[0], trigger_flag[i].a_index, trigger_flag[i].b_index)						
		trigger_flag[i].flag = false

# 实例化并添加对话场景到场景树
func _spawn_dual_dialogue(style: int, content: int, start: int, end: int, a_index: Array[int], b_index: Array[int]) -> void:
	print("生成对话")
	player_node.can_move = false
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

	# 将对话节点加入到当前 manager（可根据需要改为加入到 UI 层或专门容器）
	inst.global_position = camera_position + camera_offset
	inst.dialogue = dialogue_content.slice(start,end)
	inst.a_index = a_index
	inst.b_index = b_index
	add_child(inst)
	
	# 如果对话场景提供了 dialogue_finished 信号，连接它以便自动回收实例
	if inst.has_signal("dialogue_finished"):
		inst.connect("dialogue_finished", Callable(self, "_on_dialogue_finished"), [inst])
	# 否则可以根据需要设定自动回收或由对话场景自行回收
		

# 实例化并添加对话场景到场景树
func _spawn_dialogue(style: int, content: int, start: int, end: int) -> void:
	print("生成对话")
	player_node.can_move = false
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

	# 将对话节点加入到当前 manager（可根据需要改为加入到 UI 层或专门容器）
	inst.global_position = camera_position + camera_offset
	inst.dialogue = dialogue_content.slice(start,end)
	add_child(inst)

	# 如果对话场景提供了 dialogue_finished 信号，连接它以便自动回收实例
	if inst.has_signal("dialogue_finished"):
		inst.connect("dialogue_finished", Callable(self, "_on_dialogue_finished"), [inst])
	# 否则可以根据需要设定自动回收或由对话场景自行回收

# 当对话节点发出结束信号时回收
func _on_dialogue_finished(inst: Node) -> void:
	if is_instance_valid(inst):
		inst.queue_free()
		
func _spawn_reminder(area: Area2D) -> void:
	# 如果该area已经有reminder实例，先销毁
	if reminder_instances.has(area):
		_destory_reminder(area)
	
	var pos : Vector2 = area.global_position
	var inst = dialogue_reminder.instantiate()
	
	# 设置位置偏移（可以根据需要调整）
	var offset = Vector2(50, -150)  
	inst.global_position = pos + offset
	
	# 添加到场景树
	add_child(inst)
	
	# 播放动画
	var animated_sprite = inst.get_node("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.play()
	
	# 存储实例引用
	reminder_instances[area] = inst

func _destory_reminder(area: Area2D) -> void:
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
