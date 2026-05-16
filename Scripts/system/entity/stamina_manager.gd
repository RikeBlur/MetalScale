class_name StaminaManager
extends Node2D

class StaminaRingIndicator:
	extends Control

	var progress: float = 1.0
	var radius: float = 23.0
	var background_width: float = 7.0
	var foreground_width: float = 5.0
	var background_color: Color = Color(0.0, 0.0, 0.0, 0.45)
	var foreground_color: Color = Color(0.74, 0.92, 0.88, 0.95)
	var draw_alpha: float = 0.0

	func set_progress(value: float) -> void:
		progress = clamp(value, 0.0, 1.0)
		queue_redraw()

	func set_draw_alpha(value: float) -> void:
		draw_alpha = clamp(value, 0.0, 1.0)
		queue_redraw()

	func setup_visual(
		new_radius: float,
		new_background_width: float,
		new_foreground_width: float,
		new_background_color: Color,
		new_foreground_color: Color
	) -> void:
		radius = max(new_radius, 0.0)
		background_width = max(new_background_width, 0.0)
		foreground_width = max(new_foreground_width, 0.0)
		background_color = new_background_color
		foreground_color = new_foreground_color
		var diameter: float = (radius + max(background_width, foreground_width)) * 2.0
		custom_minimum_size = Vector2(diameter, diameter)
		size = custom_minimum_size
		pivot_offset = size * 0.5
		queue_redraw()

	func _draw() -> void:
		if draw_alpha <= 0.0:
			return

		var center: Vector2 = size * 0.5
		var start_angle: float = -PI * 0.5
		var end_angle: float = start_angle + TAU * progress
		var current_background_color: Color = background_color
		var current_foreground_color: Color = foreground_color
		current_background_color.a *= draw_alpha
		current_foreground_color.a *= draw_alpha
		draw_arc(center, radius, 0.0, TAU, 96, current_background_color, background_width, true)
		if progress > 0.0:
			draw_arc(center, radius, start_angle, end_angle, 96, current_foreground_color, foreground_width, true)


@export var player_node: CharacterBody2D = null
@export var drain_rate: float = 20.0
@export var recover_rate: float = 15.0
@export var not_exhausted_threshold: float = 25.0
@export_group("Stamina Ring")
@export var ring_local_position: Vector2 = Vector2(0.0, -56.0)
@export var ring_radius: float = 23.0
@export var ring_background_width: float = 7.0
@export var ring_foreground_width: float = 5.0
@export var ring_background_color: Color = Color(0.0, 0.0, 0.0, 0.45)
@export var ring_foreground_color: Color = Color(0.74, 0.92, 0.88, 0.95)
@export var ring_fade_in_time: float = 0.35
@export var ring_fade_out_time: float = 0.35
@export var ring_hide_after_run_time: float = 0.8

var state_machine: NodeStateMachine = null
var stamina_ring: StaminaRingIndicator = null
var _time_since_running: float = 999.0
var _ring_alpha: float = 0.0


func _ready() -> void:
	setup(player_node)


func _process(delta: float) -> void:
	if not _has_valid_player():
		return

	_update_stamina(delta)
	_update_stamina_ring(delta)


func setup(target_player: CharacterBody2D) -> void:
	if target_player and is_instance_valid(target_player):
		player_node = target_player
	elif get_parent() is CharacterBody2D:
		player_node = get_parent() as CharacterBody2D

	if not _has_valid_player():
		return

	state_machine = player_node.get_node_or_null("StateMachine") as NodeStateMachine
	var max_stamina: float = max(_get_player_float("stamina_max", 0.0), 0.0)
	_set_player_value("stamina_max", max_stamina)
	_set_player_value("stamina_now", clamp(_get_player_float("stamina_now", max_stamina), 0.0, max_stamina))
	_update_exhausted_state()
	_ensure_stamina_ring()
	_update_stamina_ring_progress()


func can_run() -> bool:
	if not _has_valid_player():
		return false
	if _get_player_bool("exhausted", false):
		return false
	return _get_player_float("stamina_now", 0.0) > 0.0


func is_running() -> bool:
	return state_machine != null and state_machine.current_node_state_name == "run"


func _update_stamina(delta: float) -> void:
	var max_stamina: float = max(_get_player_float("stamina_max", 0.0), 0.0)
	var stamina_now: float = _get_player_float("stamina_now", max_stamina)
	if is_running():
		stamina_now = max(stamina_now - max(drain_rate, 0.0) * delta, 0.0)
	else:
		stamina_now = min(stamina_now + max(recover_rate, 0.0) * delta, max_stamina)

	_set_player_value("stamina_now", stamina_now)
	_update_exhausted_state()


func _update_stamina_ring(delta: float) -> void:
	_ensure_stamina_ring()
	if not stamina_ring or not is_instance_valid(stamina_ring):
		return

	stamina_ring.position = ring_local_position - stamina_ring.size * 0.5
	_update_stamina_ring_progress()

	if is_running():
		_time_since_running = 0.0
		_update_ring_visibility(true, delta)
	else:
		_time_since_running += delta
		_update_ring_visibility(_time_since_running < max(ring_hide_after_run_time, 0.0), delta)


func _ensure_stamina_ring() -> void:
	if stamina_ring and is_instance_valid(stamina_ring):
		stamina_ring.setup_visual(
			ring_radius,
			ring_background_width,
			ring_foreground_width,
			ring_background_color,
			ring_foreground_color
		)
		return

	stamina_ring = StaminaRingIndicator.new()
	stamina_ring.name = "StaminaRingIndicator"
	stamina_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamina_ring.set_draw_alpha(0.0)
	stamina_ring.visible = false
	add_child(stamina_ring)
	stamina_ring.setup_visual(
		ring_radius,
		ring_background_width,
		ring_foreground_width,
		ring_background_color,
		ring_foreground_color
	)
	stamina_ring.position = ring_local_position - stamina_ring.size * 0.5


func _update_stamina_ring_progress() -> void:
	var max_stamina: float = max(_get_player_float("stamina_max", 0.0), 0.001)
	var stamina_now: float = clamp(_get_player_float("stamina_now", max_stamina), 0.0, max_stamina)
	stamina_ring.set_progress(stamina_now / max_stamina)


func _update_ring_visibility(should_show: bool, delta: float) -> void:
	var fade_time: float = max(ring_fade_in_time if should_show else ring_fade_out_time, 0.0)
	var target_alpha: float = 1.0 if should_show else 0.0
	if should_show:
		stamina_ring.visible = true

	if fade_time <= 0.0:
		_ring_alpha = target_alpha
	else:
		_ring_alpha = move_toward(_ring_alpha, target_alpha, delta / fade_time)

	stamina_ring.set_draw_alpha(_ring_alpha)
	if _ring_alpha <= 0.001 and not should_show:
		stamina_ring.visible = false
	elif _ring_alpha > 0.001:
		stamina_ring.visible = true


func _set_ring_visible(should_show: bool) -> void:
	if not stamina_ring or not is_instance_valid(stamina_ring):
		return

	_ring_alpha = 1.0 if should_show else 0.0
	stamina_ring.set_draw_alpha(_ring_alpha)
	stamina_ring.visible = should_show


func _update_exhausted_state() -> void:
	var stamina_now: float = _get_player_float("stamina_now", 0.0)
	var max_stamina: float = max(_get_player_float("stamina_max", 0.0), 0.0)
	if stamina_now <= 0.0:
		_set_player_value("exhausted", true)
	elif stamina_now >= min(not_exhausted_threshold, max_stamina):
		_set_player_value("exhausted", false)


func _has_valid_player() -> bool:
	return (
		player_node != null
		and is_instance_valid(player_node)
		and _has_player_property("stamina_max")
		and _has_player_property("stamina_now")
		and _has_player_property("exhausted")
	)


func _has_player_property(property_name: String) -> bool:
	if player_node == null or not is_instance_valid(player_node):
		return false
	for property in player_node.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false


func _get_player_float(property_name: String, default_value: float) -> float:
	if not _has_valid_player():
		return default_value
	var value: Variant = player_node.get(property_name)
	if value == null:
		return default_value
	return float(value)


func _get_player_bool(property_name: String, default_value: bool) -> bool:
	if not _has_valid_player():
		return default_value
	var value: Variant = player_node.get(property_name)
	if value == null:
		return default_value
	return bool(value)


func _set_player_value(property_name: String, value: Variant) -> void:
	if _has_valid_player():
		player_node.set(property_name, value)
