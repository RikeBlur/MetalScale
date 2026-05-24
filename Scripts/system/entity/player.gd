class_name player
extends CharacterBody2D

# 移动相关参数/状态
@export var player_walk_speed_max : int = 200
@export var player_run_speed_max : int = 450
@export var player_walk_speed_min : int = 100
@export var player_run_speed_min : int = 200
@export var player_walk_acceleration : int = 10
@export var player_run_acceleration : int = 30

@export_group("Stuck Recovery")
@export var stuck_recovery_enabled: bool = true
@export var stack_time: float = 0.55
@export var stuck_position_epsilon: float = 0.35
@export var extension_point: int = 2
@export var point_freq: float = 8.0
@export var go_through_threshold: float = 12.0
@export var go_through_length: float = 3.0
@export var debug_mode: bool = false
@export_group("")

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
@onready var body_collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var state_machine: NodeStateMachine = get_node_or_null("StateMachine") as NodeStateMachine

var _stuck_last_global_position: Vector2 = Vector2.ZERO
var _stuck_last_move_direction: Vector2 = Vector2.ZERO
var _stuck_timer: float = 0.0
var _stuck_recovery_running: bool = false
var _stuck_debug_probe_points: Array[Vector2] = []
var _stuck_debug_probe_blocked: Array[bool] = []


func _ready() -> void:
	_setup_self_talk_manager()
	_setup_stamina_manager()
	_stuck_last_global_position = global_position


func _process(_delta: float) -> void:
	if player_input_blocked != InputEvents.player_input_blocked:
		player_input_blocked = InputEvents.player_input_blocked

	if InputEvents.suicide():
		player_died()


func _physics_process(delta: float) -> void:
	_update_stuck_recovery(delta)


func _draw() -> void:
	if not debug_mode:
		return

	for point_index in range(_stuck_debug_probe_points.size()):
		var point := to_local(_stuck_debug_probe_points[point_index])
		var point_blocked := false
		if point_index < _stuck_debug_probe_blocked.size():
			point_blocked = _stuck_debug_probe_blocked[point_index]

		var point_color := Color(0.1, 1.0, 0.2, 0.9)
		if point_blocked:
			point_color = Color(1.0, 0.15, 0.1, 0.9)
		draw_circle(point, 3.0, point_color)


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


func _update_stuck_recovery(delta: float) -> void:
	var moved_distance := global_position.distance_to(_stuck_last_global_position)
	var move_direction := _get_stuck_recovery_move_direction()

	if not _can_track_stuck_recovery(move_direction):
		_reset_stuck_recovery_tracking()
		_clear_stuck_recovery_debug_points()
		_stuck_last_global_position = global_position
		return

	if _stuck_last_move_direction == Vector2.ZERO or _stuck_last_move_direction.dot(move_direction) < 0.999:
		_stuck_last_move_direction = move_direction
		_stuck_timer = 0.0
		_clear_stuck_recovery_debug_points()
		_stuck_last_global_position = global_position
		return

	if moved_distance <= stuck_position_epsilon:
		_stuck_timer += delta
		_update_stuck_recovery_debug_points(move_direction)
	else:
		_stuck_timer = 0.0
		_clear_stuck_recovery_debug_points()

	if _stuck_timer >= stack_time:
		_try_stuck_recovery(move_direction)
		_stuck_timer = 0.0

	_stuck_last_global_position = global_position


func _can_track_stuck_recovery(move_direction: Vector2) -> bool:
	if not stuck_recovery_enabled:
		return false
	if _stuck_recovery_running:
		return false
	if is_died or player_input_blocked or not can_move:
		return false
	if move_direction == Vector2.ZERO:
		return false
	if not InputEvents.is_movement():
		return false
	if not _is_stuck_recovery_movement_state():
		return false
	return true


func _get_stuck_recovery_move_direction() -> Vector2:
	if player_direction != Vector2.ZERO:
		return player_direction.normalized()
	if velocity != Vector2.ZERO:
		return velocity.normalized()
	return Vector2.ZERO


func _is_stuck_recovery_movement_state() -> bool:
	if not state_machine or not is_instance_valid(state_machine):
		state_machine = get_node_or_null("StateMachine") as NodeStateMachine
	if not state_machine:
		return false
	return state_machine.current_node_state_name == "walk" or state_machine.current_node_state_name == "run"


func _try_stuck_recovery(move_direction: Vector2) -> void:
	_stuck_recovery_running = true
	var recover_offset := move_direction * go_through_length
	var forward_clear := _is_stuck_recovery_forward_clear(move_direction)
	if forward_clear:
		print("Player stuck detected. direction=", move_direction, " position=", global_position, " recover_offset=", recover_offset)
		global_position += recover_offset
	_stuck_recovery_running = false


func _is_stuck_recovery_forward_clear(move_direction: Vector2) -> bool:
	if collision_mask == 0:
		return true

	var space_state := get_world_2d().direct_space_state
	var point_count: int = max(extension_point, 0)
	var point_distance: float = max(point_freq, 0.0)
	var probe_distance: float = max(go_through_threshold, 0.0)

	for point_index in range(-point_count, point_count + 1):
		var local_offset := Vector2(0.0, float(point_index) * point_distance)
		var probe_point := _get_stuck_recovery_probe_origin(local_offset) + move_direction * probe_distance
		if _is_stuck_recovery_point_blocked(space_state, probe_point):
			return false
	return true


func _get_stuck_recovery_probe_origin(local_offset: Vector2) -> Vector2:
	if body_collision_shape and is_instance_valid(body_collision_shape):
		return body_collision_shape.global_position + local_offset
	return global_position + local_offset


func _is_stuck_recovery_point_blocked(space_state: PhysicsDirectSpaceState2D, point: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false

	return not space_state.intersect_point(query, 1).is_empty()


func _update_stuck_recovery_debug_points(move_direction: Vector2) -> void:
	if not debug_mode:
		_clear_stuck_recovery_debug_points()
		return

	_stuck_debug_probe_points.clear()
	_stuck_debug_probe_blocked.clear()

	var space_state := get_world_2d().direct_space_state
	var point_count: int = max(extension_point, 0)
	var point_distance: float = max(point_freq, 0.0)
	var probe_distance: float = max(go_through_threshold, 0.0)

	for point_index in range(-point_count, point_count + 1):
		var local_offset := Vector2(0.0, float(point_index) * point_distance)
		var probe_point := _get_stuck_recovery_probe_origin(local_offset) + move_direction * probe_distance
		_stuck_debug_probe_points.append(probe_point)
		_stuck_debug_probe_blocked.append(_is_stuck_recovery_point_blocked(space_state, probe_point))

	queue_redraw()


func _clear_stuck_recovery_debug_points() -> void:
	if _stuck_debug_probe_points.is_empty() and _stuck_debug_probe_blocked.is_empty():
		return

	_stuck_debug_probe_points.clear()
	_stuck_debug_probe_blocked.clear()
	queue_redraw()


func _reset_stuck_recovery_tracking() -> void:
	_stuck_timer = 0.0
	_stuck_last_move_direction = Vector2.ZERO


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
 
