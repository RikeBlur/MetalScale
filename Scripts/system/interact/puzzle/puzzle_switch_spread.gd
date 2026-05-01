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
	_toggle_button(_wrap_index(index - 1))
	_toggle_button(_wrap_index(index + 1))
	_spreading = false


func _toggle_button(index: int) -> void:
	var button := _buttons[index]
	if button:
		button.button_pressed = not button.button_pressed


func _wrap_index(index: int) -> int:
	return posmod(index, _buttons.size())
