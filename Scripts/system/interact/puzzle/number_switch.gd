class_name NumberSwitch
extends Control

signal number_changed(value: int)

@export var plus_button: BaseButton = null
@export var minus_button: BaseButton = null
@export var sink: RichTextLabel = null
@export var min_number: int = 0
@export var max_number: int = 9
@export var switch_number: int = 0:
	set(value):
		switch_number = _wrap_number(value)
		_update_sink()
		number_changed.emit(switch_number)


func _ready() -> void:
	_find_child_nodes()
	_connect_buttons()
	_update_sink()


func get_puzzle_value() -> int:
	return switch_number


func set_switch_number(value: int) -> void:
	switch_number = value


func step_up() -> void:
	switch_number += 1


func step_down() -> void:
	switch_number -= 1


func _find_child_nodes() -> void:
	if not plus_button:
		plus_button = get_node_or_null("plus_button") as BaseButton
	if not minus_button:
		minus_button = get_node_or_null("minus_button") as BaseButton
	if not sink:
		sink = get_node_or_null("sink") as RichTextLabel


func _connect_buttons() -> void:
	if plus_button and not plus_button.pressed.is_connected(step_up):
		plus_button.pressed.connect(step_up)
	if minus_button and not minus_button.pressed.is_connected(step_down):
		minus_button.pressed.connect(step_down)


func _wrap_number(value: int) -> int:
	if max_number < min_number:
		max_number = min_number

	var range_size := max_number - min_number + 1
	return min_number + posmod(value - min_number, range_size)


func _update_sink() -> void:
	if sink:
		sink.text = str(switch_number)
