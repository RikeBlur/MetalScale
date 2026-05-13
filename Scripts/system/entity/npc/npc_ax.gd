class_name npc_ax
extends npc

enum MovementMode {
	IDLE,
	WALK,
	RUN
}

@export var player_walk_speed_max : int = 200
@export var player_run_speed_max : int = 450
@export var player_walk_speed_min : int = 100
@export var player_run_speed_min : int = 200
@export var player_walk_acceleration : int = 10
@export var player_run_acceleration : int = 30

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

var can_move : bool = true
var can_interact : bool = true
var can_act : bool = true

var player_direction : Vector2 = Vector2.DOWN
var player_last_direction : Vector2 = Vector2.DOWN

var movement_mode: int = MovementMode.IDLE
var _has_movement_target: bool = false
var _movement_target_position: Vector2 = Vector2.ZERO
var _movement_target_stop_distance: float = 4.0
var _movement_target_should_run: bool = false


func _physics_process(_delta: float) -> void:
	if not _has_movement_target:
		return

	var target_delta := _movement_target_position - global_position
	if target_delta.length() <= _movement_target_stop_distance:
		stop_movement()
		return

	_set_movement_direction(target_delta, _movement_target_should_run)


func walk_to_direction(direction: Vector2) -> void:
	clear_movement_target()
	set_movement_direction(direction, false)


func run_to_direction(direction: Vector2) -> void:
	clear_movement_target()
	set_movement_direction(direction, true)


func move(desired_velocity: Vector2) -> void:
	if desired_velocity == Vector2.ZERO:
		stop_movement()
		return

	set_movement_direction(desired_velocity, desired_velocity.length() >= player_run_speed_min)


func set_movement_direction(direction: Vector2, should_run: bool = false) -> void:
	clear_movement_target()
	_set_movement_direction(direction, should_run)


func walk_to_position(target_position: Vector2, stop_distance: float = 4.0) -> void:
	set_movement_target(target_position, false, stop_distance)


func run_to_position(target_position: Vector2, stop_distance: float = 4.0) -> void:
	set_movement_target(target_position, true, stop_distance)


func set_movement_target(target_position: Vector2, should_run: bool = false, stop_distance: float = 4.0) -> void:
	_has_movement_target = true
	_movement_target_position = target_position
	_movement_target_should_run = should_run
	_movement_target_stop_distance = max(stop_distance, 0.0)


func clear_movement_target() -> void:
	_has_movement_target = false


func _set_movement_direction(direction: Vector2, should_run: bool = false) -> void:
	if direction == Vector2.ZERO:
		stop_movement()
		return

	var normalized_direction := direction.normalized()
	player_direction = normalized_direction
	player_last_direction = normalized_direction
	npc_direction = normalized_direction
	movement_mode = MovementMode.RUN if should_run else MovementMode.WALK


func stop_movement() -> void:
	clear_movement_target()
	velocity = Vector2.ZERO
	player_direction = Vector2.ZERO
	movement_mode = MovementMode.IDLE


func face_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	var normalized_direction := direction.normalized()
	player_last_direction = normalized_direction
	npc_direction = normalized_direction
	if movement_mode == MovementMode.IDLE:
		player_direction = normalized_direction


func set_npc_can_move(value: bool) -> void:
	can_move = value
	if not can_move:
		stop_movement()


func get_movement_direction() -> Vector2:
	if not can_move or movement_mode == MovementMode.IDLE:
		return Vector2.ZERO
	return player_direction


func is_moving() -> bool:
	return can_move and movement_mode != MovementMode.IDLE and player_direction != Vector2.ZERO


func is_walking() -> bool:
	return is_moving() and movement_mode == MovementMode.WALK


func is_running() -> bool:
	return is_moving() and movement_mode == MovementMode.RUN
