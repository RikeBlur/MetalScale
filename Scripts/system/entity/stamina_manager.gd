class_name StaminaManager
extends Node2D

@export var player_node: CharacterBody2D = null
@export var drain_rate: float = 20.0
@export var recover_rate: float = 15.0
@export var not_exhausted_threshold: float = 25.0

var state_machine: NodeStateMachine = null


func _ready() -> void:
	setup(player_node)


func _process(delta: float) -> void:
	if not _has_valid_player():
		return

	_update_stamina(delta)


func setup(target_player: CharacterBody2D) -> void:
	if target_player and is_instance_valid(target_player):
		player_node = target_player
	elif get_parent() is CharacterBody2D:
		player_node = get_parent() as CharacterBody2D

	if not _has_valid_player():
		return

	state_machine = player_node.get_node_or_null("StateMachine") as NodeStateMachine
	var max_stamina := max(_get_player_float("stamina_max", 0.0), 0.0)
	_set_player_value("stamina_max", max_stamina)
	_set_player_value("stamina_now", clamp(_get_player_float("stamina_now", max_stamina), 0.0, max_stamina))
	_update_exhausted_state()


func can_run() -> bool:
	if not _has_valid_player():
		return false
	if _get_player_bool("exhausted", false):
		return false
	return _get_player_float("stamina_now", 0.0) > 0.0


func is_running() -> bool:
	return state_machine != null and state_machine.current_node_state_name == "run"


func _update_stamina(delta: float) -> void:
	var max_stamina := max(_get_player_float("stamina_max", 0.0), 0.0)
	var stamina_now := _get_player_float("stamina_now", max_stamina)
	if is_running():
		stamina_now = max(stamina_now - max(drain_rate, 0.0) * delta, 0.0)
	else:
		stamina_now = min(stamina_now + max(recover_rate, 0.0) * delta, max_stamina)

	_set_player_value("stamina_now", stamina_now)
	_update_exhausted_state()


func _update_exhausted_state() -> void:
	var stamina_now := _get_player_float("stamina_now", 0.0)
	var max_stamina := max(_get_player_float("stamina_max", 0.0), 0.0)
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
	var value = player_node.get(property_name)
	if value == null:
		return default_value
	return float(value)


func _get_player_bool(property_name: String, default_value: bool) -> bool:
	if not _has_valid_player():
		return default_value
	var value = player_node.get(property_name)
	if value == null:
		return default_value
	return bool(value)


func _set_player_value(property_name: String, value: Variant) -> void:
	if _has_valid_player():
		player_node.set(property_name, value)
