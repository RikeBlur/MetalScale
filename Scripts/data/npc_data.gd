class_name NPCData
extends Resource

# NPC对应的场景实例
@export var npc_node: PackedScene

#======================= 状态 ====================

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

func to_dict() -> Dictionary:
	return {
		"current_scene": current_scene,
		"npc_position":  {"x": npc_position.x,  "y": npc_position.y},
		"npc_direction": {"x": npc_direction.x, "y": npc_direction.y},
		"type":          int(type),
		"is_inscene":    false,   # 存档时统一视为离场
		"state":         state,
	}

func from_dict(d: Dictionary) -> void:
	if d.has("current_scene"): current_scene = d["current_scene"]
	if d.has("npc_position"):
		npc_position = Vector2(d["npc_position"]["x"], d["npc_position"]["y"])
	if d.has("npc_direction"):
		npc_direction = Vector2(d["npc_direction"]["x"], d["npc_direction"]["y"])
	if d.has("type"):
		type = int(d["type"]) as npc_manager.npc_type
	if d.has("state"):
		state = int(d["state"])
	is_inscene = false   # 读档时统一离场，由 _on_player_reseted 重新入场

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
