class_name DialogueComponent
extends Node2D

# 在编辑器里填充这些数组：
@export var trigger_source : Array = []
@export var trigger_flag : Array[dialogue_flag]
@export var dialogue_content : Array[DialogueResource]
@export var camera : Camera2D = null
@export var current_flag : int = 0

var dialogue_style : Array = []
var dialogue_inst : Array = []
var camera_position : Vector2 = Vector2.ZERO
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
	
	# 按 next_flag 推进到下一个触发标记
	var next_idx := trigger_flag[current_flag].next_flag
	if next_idx == -1:
		current_flag = -1
	elif next_idx >= 0 and next_idx < trigger_flag.size():
		current_flag = next_idx
	else:
		push_warning("DialogueComponent: next_flag(%d) 非法，已停用触发" % next_idx)
		current_flag = -1


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
				_spawn_dialogue(flag_data.style[0] - 1, flag_data.start[0], flag_data.end[0])
			if flag_data.double:
				_spawn_dual_dialogue(flag_data.style[0] - 1, flag_data.start[0], flag_data.end[0], flag_data.a_index, flag_data.b_index)
		trigger_flag[i].flag = false


# 实例化并添加对话场景到场景树
func _spawn_dual_dialogue(style: int, start: int, end: int, a_index: Array[int], b_index: Array[int]) -> void:
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
	inst.dialogue = dialogue_content.slice(start,end)
	inst.a_index = a_index
	inst.b_index = b_index
	# 设置 scene_root 引用，让对话框能正确解析相对路径
	inst.scene_root = self
	canvas_layer.add_child(inst)
	
	# 如果对话场景提供了 dialogue_finished 信号，连接它以便自动回收实例
	if inst.has_signal("dialogue_finished"):
		inst.connect("dialogue_finished", Callable(self, "_on_dialogue_finished"), [inst])
	# 否则可以根据需要设定自动回收或由对话场景自行回收


# 实例化并添加对话场景到场景树
func _spawn_dialogue(style: int, start: int, end: int) -> void:
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
	inst.dialogue = dialogue_content.slice(start,end)
	# 设置 scene_root 引用，让对话框能正确解析相对路径
	inst.scene_root = self
	canvas_layer.add_child(inst)

	# 如果对话场景提供了 dialogue_finished 信号，连接它以便自动回收实例
	if inst.has_signal("dialogue_finished"):
		inst.connect("dialogue_finished", Callable(self, "_on_dialogue_finished"), [inst])
	# 否则可以根据需要设定自动回收或由对话场景自行回收


# 当对话节点发出结束信号时回收
func _on_dialogue_finished(inst: Node) -> void:
	if is_instance_valid(inst):
		inst.queue_free()
		
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
	var offset = Vector2(30, -100)  
	
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
		push_warning("DialogueComponent: trigger_flag[%d] 为空" % idx)
		return false
	if flag_data.style.size() == 0:
		push_warning("DialogueComponent: trigger_flag[%d].style 为空" % idx)
		return false
	if flag_data.start.size() == 0:
		push_warning("DialogueComponent: trigger_flag[%d].start 为空" % idx)
		return false
	if flag_data.end.size() == 0:
		push_warning("DialogueComponent: trigger_flag[%d].end 为空" % idx)
		return false
	return true
