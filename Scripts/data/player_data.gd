class_name PlayerData
extends Resource

## 玩家数据资源类
## 用于存储玩家的所有属性和状态

# 移动速度参数
@export var player_walk_speed_max: int = 200
@export var player_run_speed_max: int = 450
@export var player_walk_speed_min: int = 100
@export var player_run_speed_min: int = 200
@export var player_walk_acceleration: int = 10
@export var player_run_acceleration: int = 30

# 玩家状态
@export var can_move: bool = true
@export var can_interact: bool = true

# 角色类型
@export var character_name: String = "Oni"
@export var self_talk: String = ""
@export var player_state_info: String = ""

# 方向信息
@export var player_direction: Vector2 = Vector2.DOWN
@export var player_last_direction: Vector2 = Vector2.DOWN

# 工具相关
@export var tool: int = -1
# 注意：tool_available 是复杂类型，暂时用 Array 存储
@export var tool_available: Array = []
var _has_tool_available_data: bool = false

# 生命值
@export var health_max: float = 100.0
@export var health_now: float = 100.0
@export var is_died: bool = false
@export var aggro_value: float = 0.0
@export var stamina_max: float = 100.0
@export var stamina_now: float = 100.0
@export var exhausted: bool = false

# 位置信息（用于存档）
@export var global_position: Vector2 = Vector2.ZERO


func _init(
	p_walk_speed_max: int = 200,
	p_run_speed_max: int = 450,
	p_walk_speed_min: int = 100,
	p_run_speed_min: int = 200,
	p_walk_acceleration: int = 10,
	p_run_acceleration: int = 30,
	p_can_move: bool = true,
	p_can_interact: bool = true,
	p_character: String = "Oni",
	p_player_direction: Vector2 = Vector2.DOWN,
	p_player_last_direction: Vector2 = Vector2.DOWN,
	p_tool: int = -1,
	p_health_max: float = 100.0,
	p_health_now: float = 100.0,
	p_is_died: bool = false,
	p_aggro_value: float = 0.0,
	p_stamina_max: float = 100.0,
	p_stamina_now: float = 100.0,
	p_exhausted: bool = false,
	p_global_position: Vector2 = Vector2.ZERO
):
	"""
	初始化玩家数据
	
	参数:
		p_walk_speed_max: 最大行走速度
		p_run_speed_max: 最大奔跑速度
		p_walk_speed_min: 最小行走速度
		p_run_speed_min: 最小奔跑速度
		p_walk_acceleration: 行走加速度
		p_run_acceleration: 奔跑加速度
		p_can_move: 是否可以移动
		p_can_interact: 是否可以交互
		p_character: 角色类型
		p_player_direction: 当前方向
		p_player_last_direction: 上次方向
		p_tool: 当前工具索引
		p_health_max: 最大生命值
		p_health_now: 当前生命值
		p_is_died: 是否死亡
		p_global_position: 全局位置
	"""
	player_walk_speed_max = p_walk_speed_max
	player_run_speed_max = p_run_speed_max
	player_walk_speed_min = p_walk_speed_min
	player_run_speed_min = p_run_speed_min
	player_walk_acceleration = p_walk_acceleration
	player_run_acceleration = p_run_acceleration
	can_move = p_can_move
	can_interact = p_can_interact
	character_name = p_character
	player_direction = p_player_direction
	player_last_direction = p_player_last_direction
	tool = p_tool
	health_max = p_health_max
	health_now = p_health_now
	is_died = p_is_died
	aggro_value = p_aggro_value
	stamina_max = p_stamina_max
	stamina_now = p_stamina_now
	exhausted = p_exhausted
	global_position = p_global_position

func from_player_node(player_node: player) -> void:
	"""
	从玩家节点读取数据
	
	参数:
		player_node: player节点实例
	"""
	if not player_node:
		push_error("PlayerData: player节点为空")
		return
	
	player_walk_speed_max = player_node.player_walk_speed_max
	player_run_speed_max = player_node.player_run_speed_max
	player_walk_speed_min = player_node.player_walk_speed_min
	player_run_speed_min = player_node.player_run_speed_min
	player_walk_acceleration = player_node.player_walk_acceleration
	player_run_acceleration = player_node.player_run_acceleration
	can_move = player_node.can_move
	can_interact = player_node.can_interact
	character_name = player_node.character_name
	self_talk = player_node.self_talk
	player_state_info = player_node.player_state_info
	player_direction = player_node.player_direction
	player_last_direction = player_node.player_last_direction
	tool = player_node.tool
	tool_available = _serialize_tool_available(player_node.tool_available)
	_has_tool_available_data = true
	health_max = player_node.health_max
	health_now = player_node.health_now
	is_died = player_node.is_died
	aggro_value = player_node.aggro_value
	stamina_max = player_node.stamina_max
	stamina_now = player_node.stamina_now
	exhausted = player_node.exhausted
	global_position = player_node.global_position

func apply_to_player_node(player_node: player) -> void:
	"""
	将数据应用到玩家节点
	
	参数:
		player_node: player节点实例
	"""
	if not player_node:
		push_error("PlayerData: player节点为空")
		return
	
	player_node.player_walk_speed_max = player_walk_speed_max
	player_node.player_run_speed_max = player_run_speed_max
	player_node.player_walk_speed_min = player_walk_speed_min
	player_node.player_run_speed_min = player_run_speed_min
	player_node.player_walk_acceleration = player_walk_acceleration
	player_node.player_run_acceleration = player_run_acceleration
	player_node.can_move = can_move
	player_node.can_interact = can_interact
	player_node.character_name = character_name
	player_node.self_talk = self_talk
	player_node.player_state_info = player_state_info
	player_node.player_direction = player_direction
	player_node.player_last_direction = player_last_direction
	player_node.tool = tool
	if _has_tool_available_data:
		player_node.tool_available = _deserialize_tool_available(tool_available)
	player_node.health_max = health_max
	player_node.health_now = health_now
	player_node.is_died = is_died
	player_node.aggro_value = aggro_value
	player_node.stamina_max = stamina_max
	player_node.stamina_now = clamp(stamina_now, 0.0, stamina_max)
	player_node.exhausted = exhausted
	if player_node.stamina_manager and is_instance_valid(player_node.stamina_manager):
		player_node.stamina_manager.setup(player_node)
	player_node.global_position = global_position
	var tool_manager := player_node.get_node_or_null("ToolManager") as ToolManager
	if tool_manager:
		tool_manager._sync_available_tool_changes()
		tool_manager._sync_runtime_lookup()

func to_dict() -> Dictionary:
	"""
	将玩家数据序列化为字典
	
	返回:
		包含所有玩家数据的字典
	"""
	return {
		"player_walk_speed_max": player_walk_speed_max,
		"player_run_speed_max": player_run_speed_max,
		"player_walk_speed_min": player_walk_speed_min,
		"player_run_speed_min": player_run_speed_min,
		"player_walk_acceleration": player_walk_acceleration,
		"player_run_acceleration": player_run_acceleration,
		"can_move": can_move,
		"can_interact": can_interact,
		"character_name": character_name,
		"character": character_name,
		"self_talk": self_talk,
		"player_state_info": player_state_info,
		"player_direction": {"x": player_direction.x, "y": player_direction.y},
		"player_last_direction": {"x": player_last_direction.x, "y": player_last_direction.y},
		"tool": tool,
		"tool_available": tool_available,
		"health_max": health_max,
		"health_now": health_now,
		"is_died": is_died,
		"aggro_value": aggro_value,
		"stamina_max": stamina_max,
		"stamina_now": stamina_now,
		"exhausted": exhausted,
		"global_position": {"x": global_position.x, "y": global_position.y}
	}

func from_dict(data: Dictionary) -> void:
	"""
	从字典反序列化玩家数据
	
	参数:
		data: 玩家数据字典
	"""
	if data.is_empty():
		return

	_has_tool_available_data = false
	
	# 恢复所有变量
	if data.has("player_walk_speed_max"):
		player_walk_speed_max = data["player_walk_speed_max"]
	if data.has("player_run_speed_max"):
		player_run_speed_max = data["player_run_speed_max"]
	if data.has("player_walk_speed_min"):
		player_walk_speed_min = data["player_walk_speed_min"]
	if data.has("player_run_speed_min"):
		player_run_speed_min = data["player_run_speed_min"]
	if data.has("player_walk_acceleration"):
		player_walk_acceleration = data["player_walk_acceleration"]
	if data.has("player_run_acceleration"):
		player_run_acceleration = data["player_run_acceleration"]
	if data.has("can_move"):
		can_move = data["can_move"]
	if data.has("can_interact"):
		can_interact = data["can_interact"]
	if data.has("character_name"):
		character_name = data["character_name"]
	elif data.has("character"):
		character_name = data["character"]
	if data.has("self_talk"):
		self_talk = data["self_talk"]
	if data.has("player_state_info"):
		player_state_info = data["player_state_info"]
	if data.has("player_direction"):
		player_direction = Vector2(data["player_direction"]["x"], data["player_direction"]["y"])
	if data.has("player_last_direction"):
		player_last_direction = Vector2(data["player_last_direction"]["x"], data["player_last_direction"]["y"])
	if data.has("tool"):
		tool = data["tool"]
	if data.has("tool_available") and data["tool_available"] is Array:
		tool_available = _serialize_tool_available(data["tool_available"])
		_has_tool_available_data = true
	if data.has("health_max"):
		health_max = data["health_max"]
	if data.has("health_now"):
		health_now = data["health_now"]
	if data.has("is_died"):
		is_died = data["is_died"]
	aggro_value = data.get("aggro_value", 0.0)
	stamina_max = float(data.get("stamina_max", stamina_max))
	stamina_now = clamp(float(data.get("stamina_now", stamina_max)), 0.0, stamina_max)
	exhausted = bool(data.get("exhausted", stamina_now <= 0.0))
	if data.has("global_position"):
		global_position = Vector2(data["global_position"]["x"], data["global_position"]["y"])

func _serialize_tool_available(source_tools: Array) -> Array:
	var result: Array = []
	for tool_value in source_tools:
		result.append(_normalize_tool_id(tool_value))
	return result

func _deserialize_tool_available(source_tools: Array) -> Array[ToolManager.Tool]:
	var result: Array[ToolManager.Tool] = []
	for tool_value in source_tools:
		result.append(_normalize_tool_id(tool_value))
	return result

func _normalize_tool_id(tool_value: Variant) -> int:
	var tool_id := int(tool_value)
	if not ToolManager.Tool.values().has(tool_id):
		return ToolManager.Tool.NONE
	return tool_id
