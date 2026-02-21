class_name NPCData
extends Resource

#======================= 状态 ====================

# NPC对应的场景实例
@export var npc_node: PackedScene
# NPC所在场景
@export var current_scene: String
# NPC在对应场景的全局坐标
@export var npc_position: Vector2
@export var npc_direction: Vector2
# NPC类型
@export var type: npc_manager.npc_type
# 在场与否？
@export var is_inscene: bool = false 

#======================= 属性 ====================

# npc状态
@export var state: int = 0

#=================================================

func setup(
	p_npc_node: PackedScene,
	p_type: npc_manager.npc_type,
	p_current_scene: String,
	p_position: Vector2,
	p_direction: Vector2,
	p_is_inscene: bool = false,
	p_state: int = 0
) -> NPCData:
	npc_node      = p_npc_node
	type          = p_type
	current_scene = p_current_scene
	npc_position  = p_position
	npc_direction = p_direction
	is_inscene    = p_is_inscene
	state         = p_state
	return self
