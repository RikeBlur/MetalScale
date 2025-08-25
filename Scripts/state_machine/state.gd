class_name State
extends Node

# 状态所属的状态机
var state_machine: StateMachine = null

# 状态所属的实体（玩家或敌人）
var entity: CharacterBody2D = null

# 当进入该状态时调用
func enter() -> void:
	pass

# 当退出该状态时调用
func exit() -> void:
	pass

# 在 _process 中调用的更新函数
func update(delta: float) -> void:
	pass

# 在 _physics_process 中调用的物理更新函数
func physics_update(delta: float) -> void:
	pass

# 处理输入事件
func handle_input(event: InputEvent) -> void:
	pass 
