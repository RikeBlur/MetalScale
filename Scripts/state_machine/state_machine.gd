class_name StateMachine
extends Node

# 当前状态
var current_state: State = null

# 所有可用状态的字典
var states: Dictionary = {}

# 状态机所属的实体（玩家或敌人）
@export var entity: CharacterBody2D

# 初始状态的名称
@export var initial_state: String = ""

func _ready() -> void:
	# 等待一帧以确保所有子节点都准备就绪
	await get_tree().process_frame
	
	# 设置所有状态的引用
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.entity = entity
	
	# 如果设置了初始状态，则切换到该状态
	if initial_state:
		change_state(initial_state)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

# 切换到新状态
func change_state(new_state_name: String) -> void:
	var from_state = "无" if not current_state else current_state.name
	
	if current_state:
		current_state.exit()
	
	if new_state_name in states:
		current_state = states[new_state_name]
		current_state.enter()
		print("状态切换：%s -> %s" % [from_state, current_state.name])
	else:
		push_warning("尝试切换到不存在的状态：" + new_state_name)

# 获取指定名称的状态
func get_state(state_name: String) -> State:
	var lower_name = state_name.to_lower()
	if lower_name in states:
		return states[lower_name]
	return null 
