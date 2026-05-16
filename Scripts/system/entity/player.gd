class_name player
extends CharacterBody2D

# 移动相关参数/状态
@export var player_walk_speed_max : int = 200
@export var player_run_speed_max : int = 450
@export var player_walk_speed_min : int = 100
@export var player_run_speed_min : int = 200
@export var player_walk_acceleration : int = 10
@export var player_run_acceleration : int = 30

# 输入控制
var player_input_blocked : bool = false
var can_move : bool = true
var can_interact : bool = true
var can_act : bool = true

# 方向控制
var player_direction : Vector2 = Vector2.DOWN
var player_last_direction : Vector2 = Vector2.DOWN

# player info 展示信息
@export var character_name : String = "On_i_______"
@export var self_talk : String = "“空气太浑浊了...”"
var self_talk_index : int = -1
@export var player_state_info : String = "健康"

# tool
@export var tool_available : Array[ToolManager.Tool]
@export var tool : int = -1

# Arrgo
var aggro_value : float = 0.0

# 战斗系统 ———— 受伤
@export var health_max : float = 100.0
var health_now : float = 100.0
var is_died : bool = false

signal player_hurted

# 战斗系统 ———— 精力
@export var stamina_max : float = 100.0
var stamina_now : float = 100.0
var exhausted : bool = false
@onready var stamina_manager: StaminaManager = get_node_or_null("StaminaManager") as StaminaManager

# 自言自语系统
@onready var self_talk_manager: SelfTalkManager = get_node_or_null("SelfTalkManager") as SelfTalkManager


func _ready() -> void:
	_setup_self_talk_manager()
	_setup_stamina_manager()


func _process(_delta: float) -> void:
	if player_input_blocked != InputEvents.player_input_blocked:
		player_input_blocked = InputEvents.player_input_blocked

	if InputEvents.suicide():
		player_died()


func _setup_self_talk_manager() -> void:
	if not self_talk_manager or not is_instance_valid(self_talk_manager):
		self_talk_manager = get_node_or_null("SelfTalkManager") as SelfTalkManager

	if not self_talk_manager:
		self_talk_manager = SelfTalkManager.new()
		self_talk_manager.name = "SelfTalkManager"
		add_child(self_talk_manager)

	self_talk_manager.setup(self)


func _setup_stamina_manager() -> void:
	if not stamina_manager or not is_instance_valid(stamina_manager):
		stamina_manager = get_node_or_null("StaminaManager") as StaminaManager

	if not stamina_manager:
		stamina_manager = StaminaManager.new()
		stamina_manager.name = "StaminaManager"
		add_child(stamina_manager)

	stamina_manager.setup(self)


func can_run() -> bool:
	if not can_move:
		return false
	if stamina_manager and is_instance_valid(stamina_manager):
		return stamina_manager.can_run()
	return not exhausted and stamina_now > 0.0


# ============================= 死了 ==========================

func player_died() -> void:
	if is_died:
		return

	is_died = true
	health_now = 0.0
	can_move = false
	can_interact = false
	can_act = false
	velocity = Vector2.ZERO
	InputEvents.set_player_input_blocked(true)

	GameManager.notify_player_died(self)
 
