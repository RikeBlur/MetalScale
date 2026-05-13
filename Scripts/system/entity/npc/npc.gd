class_name npc
extends CharacterBody2D

@export var running_speed: float = 200.0
@export var walking_speed: float = 100.0

@export var npc_direction : Vector2 = Vector2.DOWN

var health_max : float = 100.0
var health_now : float = 100.0

var state: int = 0
# 对于EYE ： 0 -> patrol ; 1 -> pursue


func _ready() -> void:
	apply_initial_npc_direction()


func apply_initial_npc_direction() -> void:
	var initial_direction: Vector2 = _normalize_npc_direction(npc_direction)
	_set_direction_property("player_direction", initial_direction)
	_set_direction_property("player_last_direction", initial_direction)
	npc_direction = initial_direction

	var animated_sprite: AnimatedSprite2D = _get_npc_animated_sprite()
	if animated_sprite:
		play_idle_animation_for_direction(animated_sprite, initial_direction)


func get_npc_idle_direction() -> Vector2:
	var direction: Vector2 = _get_direction_property("player_last_direction", npc_direction)
	return _normalize_npc_direction(direction)


func set_npc_facing_direction(direction: Vector2, update_player_direction: bool = false) -> void:
	var normalized_direction: Vector2 = _normalize_npc_direction(direction)
	npc_direction = normalized_direction
	_set_direction_property("player_last_direction", normalized_direction)
	if update_player_direction:
		_set_direction_property("player_direction", normalized_direction)


func can_npc_move() -> bool:
	if _has_property("can_move"):
		return bool(get("can_move"))
	return true


func get_npc_int_property(property_name: String, default_value: int) -> int:
	if not _has_property(property_name):
		return default_value
	return int(get(property_name))


func get_movement_direction() -> Vector2:
	return Vector2.ZERO


func is_moving() -> bool:
	return false


func is_running() -> bool:
	return false


func play_idle_animation_for_direction(animated_sprite: AnimatedSprite2D, direction: Vector2) -> void:
	if not animated_sprite:
		return

	var animation_name: String = "idle_%s" % _get_direction_suffix(direction)
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)


func _get_npc_animated_sprite() -> AnimatedSprite2D:
	var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite") as AnimatedSprite2D
	if not animated_sprite:
		animated_sprite = get_node_or_null("Animate") as AnimatedSprite2D
	return animated_sprite


func _get_direction_suffix(direction: Vector2) -> String:
	var normalized_direction: Vector2 = _normalize_npc_direction(direction)
	if normalized_direction == Vector2.DOWN:
		return "front"
	if normalized_direction == Vector2.UP:
		return "back"
	if normalized_direction == Vector2.LEFT:
		return "left"
	if normalized_direction == Vector2.RIGHT:
		return "right"
	if normalized_direction.x > 0 and normalized_direction.y > 0:
		return "front_right"
	if normalized_direction.x > 0 and normalized_direction.y < 0:
		return "back_right"
	if normalized_direction.x < 0 and normalized_direction.y > 0:
		return "front_left"
	if normalized_direction.x < 0 and normalized_direction.y < 0:
		return "back_left"
	return "front"


func _normalize_npc_direction(direction: Vector2) -> Vector2:
	if direction == Vector2.ZERO:
		return Vector2.DOWN

	var normalized_direction: Vector2 = direction.normalized()
	var snapped_x: float = signf(normalized_direction.x)
	var snapped_y: float = signf(normalized_direction.y)
	var snapped_direction: Vector2 = Vector2(snapped_x, snapped_y)
	if snapped_direction == Vector2.ZERO:
		return Vector2.DOWN
	return snapped_direction.normalized()


func _get_direction_property(property_name: String, default_value: Vector2) -> Vector2:
	if not _has_property(property_name):
		return default_value

	var value: Variant = get(property_name)
	if value is Vector2:
		return value
	return default_value


func _set_direction_property(property_name: String, value: Vector2) -> void:
	if _has_property(property_name):
		set(property_name, value)


func _has_property(property_name: String) -> bool:
	for property_info in get_property_list():
		var current_name: String = String(property_info.get("name", ""))
		if current_name == property_name:
			return true
	return false
