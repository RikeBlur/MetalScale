class_name BlinkSeq
extends Node2D

const MIN_BLINK_TIME := 0.001

@export var lighting_list: Array[ElectronicScreen] = []
@export var start_time: float = 0.0
@export var blink_time: float = 0.5
@export var blink_states: Array[Array] = []
@export var loop: bool = false

var _started := false
var _finished := false
var _elapsed := 0.0
var _blink_elapsed := 0.0
var _state_index := 0
var _warned_messages := {}


func _ready() -> void:
	_normalize_times()
	_validate_configuration()
	if is_zero_approx(start_time):
		_start_blink()


func _process(delta: float) -> void:
	if _finished:
		return

	if not _started:
		_elapsed += delta
		if _elapsed >= start_time:
			_start_blink()
		return

	if _is_sequence_empty():
		return

	_blink_elapsed += delta
	if _blink_elapsed < blink_time:
		return

	_blink_elapsed = 0.0
	_advance_state()


func restart() -> void:
	_normalize_times()
	_started = false
	_finished = false
	_elapsed = 0.0
	_blink_elapsed = 0.0
	_state_index = 0
	if is_zero_approx(start_time):
		_start_blink()


func stop() -> void:
	_finished = true


func _start_blink() -> void:
	_started = true
	_elapsed = start_time
	_blink_elapsed = 0.0
	_state_index = 0

	if _is_sequence_empty():
		_finished = true
		return

	_apply_state(_state_index)
	if blink_states.size() == 1 and not loop:
		_finished = true


func _advance_state() -> void:
	if blink_states.is_empty():
		_finished = true
		return

	if _state_index >= blink_states.size() - 1:
		if not loop:
			_finished = true
			return
		_state_index = 0
	else:
		_state_index += 1

	_apply_state(_state_index)
	if _state_index >= blink_states.size() - 1 and not loop:
		_finished = true


func _apply_state(index: int) -> void:
	if index < 0 or index >= blink_states.size():
		_warn_once("state_index_%d" % index, "BlinkSeq: blink_states 下标越界: %d" % index)
		return

	var state_row = blink_states[index]
	if not (state_row is Array):
		_warn_once("state_not_array_%d" % index, "BlinkSeq: blink_states[%d] 不是数组，已跳过" % index)
		return
	if state_row.size() != lighting_list.size():
		_warn_once(
			"state_size_%d" % index,
			"BlinkSeq: blink_states[%d] 长度为 %d，但 lighting_list 长度为 %d，已跳过该状态" % [index, state_row.size(), lighting_list.size()]
		)
		return

	for i in range(lighting_list.size()):
		var screen := lighting_list[i]
		if not screen or not is_instance_valid(screen):
			_warn_once("invalid_screen_%d" % i, "BlinkSeq: lighting_list[%d] 不是有效的 ElectronicScreen" % i)
			continue

		var next_turned_on := bool(state_row[i])
		if screen.turned_on != next_turned_on:
			screen.turned_on = next_turned_on


func _is_sequence_empty() -> bool:
	if lighting_list.is_empty():
		_warn_once("empty_lighting_list", "BlinkSeq: lighting_list 为空，无法 blink")
		return true
	if blink_states.is_empty():
		_warn_once("empty_blink_states", "BlinkSeq: blink_states 为空，无法 blink")
		return true
	return false


func _validate_configuration() -> void:
	for i in range(blink_states.size()):
		var state_row = blink_states[i]
		if not (state_row is Array):
			_warn_once("state_not_array_%d" % i, "BlinkSeq: blink_states[%d] 不是数组" % i)
			continue
		if state_row.size() != lighting_list.size():
			_warn_once(
				"state_size_%d" % i,
				"BlinkSeq: blink_states[%d] 长度为 %d，但 lighting_list 长度为 %d" % [i, state_row.size(), lighting_list.size()]
			)


func _normalize_times() -> void:
	start_time = max(start_time, 0.0)
	if blink_time <= 0.0:
		_warn_once("invalid_blink_time", "BlinkSeq: blink_time 应大于 0，已自动修正为 %f" % MIN_BLINK_TIME)
		blink_time = MIN_BLINK_TIME


func _warn_once(key: String, message: String) -> void:
	if _warned_messages.has(key):
		return
	_warned_messages[key] = true
	push_warning(message)
