class_name SwitchLight
extends Sprite2D

@export var button_path: NodePath = NodePath("")
@export var green_light: Texture2D = null
@export var red_light: Texture2D = null
@export_range(0, 1, 1) var state: int = 0:
	set(value):
		state = clampi(value, 0, 1)
		_apply_texture()


func _ready() -> void:
	_update_from_button()
	_apply_texture()


func _process(_delta: float) -> void:
	_update_from_button()


func set_state(new_state: int) -> void:
	state = new_state


func _update_from_button() -> void:
	if button_path == NodePath(""):
		return

	var button := get_node_or_null(button_path)
	if button is BaseButton:
		state = 1 if (button as BaseButton).button_pressed else 0


func _apply_texture() -> void:
	if state == 1 and green_light:
		texture = green_light
	elif state == 0 and red_light:
		texture = red_light
