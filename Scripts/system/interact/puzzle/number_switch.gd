class_name NumberSwitch
extends Control

signal value_changed(value: int)

@export var min_value := 0
@export var max_value := 9
@export var wrap := true
@export var value := 0:
	set(new_value):
		value = _normalize_value(new_value)
		value_changed.emit(value)


func get_puzzle_value() -> int:
	return value


func set_value(new_value: int) -> void:
	value = new_value


func step_up() -> void:
	set_value(value + 1)


func step_down() -> void:
	set_value(value - 1)


func _normalize_value(new_value: int) -> int:
	if max_value < min_value:
		max_value = min_value

	if wrap:
		var span := max_value - min_value + 1
		return min_value + posmod(new_value - min_value, span)

	return clampi(new_value, min_value, max_value)
