class_name PuzzleSwitchSpread
extends PuzzleSwitch

var _buttons: Array[BaseButton] = []
var _spreading := false


func _ready() -> void:
	_buttons = _get_buttons()
	for i in range(_buttons.size()):
		var button := _buttons[i]
		if button and not button.pressed.is_connected(_on_button_pressed.bind(i)):
			button.pressed.connect(_on_button_pressed.bind(i))


func _on_button_pressed(index: int) -> void:
	if _spreading or _buttons.is_empty():
		return

	_spreading = true
	if target_state.size() == 8:
		_toggle_spread_8(index)
	else:
		_toggle_button(_wrap_index(index - 1))
		_toggle_button(_wrap_index(index + 1))
	_spreading = false

# 两列
func _toggle_spread_8(index: int) -> void:
	if index < 0 or index >= 8 or _buttons.size() < 8:
		push_error("8按钮情况出错")
		return

	if index <= 3:
		_toggle_button(_wrap_index_in_range_8(index - 1, 0, 3))
		_toggle_button(_wrap_index_in_range_8(index + 1, 0, 3))
		_toggle_button(index + 4)
	else:
		_toggle_button(_wrap_index_in_range_8(index - 1, 4, 7))
		_toggle_button(_wrap_index_in_range_8(index + 1, 4, 7))
		_toggle_button(index - 4)

# 通用
func _toggle_button(index: int) -> void:
	if index < 0 or index >= _buttons.size():
		return
	var button := _buttons[index]
	if button:
		button.button_pressed = not button.button_pressed

# 两列
func _wrap_index_in_range_8(index: int, min_index: int, max_index: int) -> int:
	if index < min_index:
		#return max_index
		return -1
	if index > max_index:
		#return min_index
		return -1
	return index

# 一列
func _wrap_index(index: int) -> int:
	return posmod(index, _buttons.size())
