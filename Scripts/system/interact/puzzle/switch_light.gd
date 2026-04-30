class_name SwitchLight
extends Sprite2D

@export var button_path: NodePath = NodePath("")
@export var green_light: Texture2D = null
@export var red_light: Texture2D = null
@export var normal_modulate: Color = Color.WHITE
@export var hoven_modulate: Color = Color(1.4, 1.4, 1.4, 1.0)
@export var hover_transition_speed := 12.0
@export_range(0, 1, 1) var state: int = 0:
	set(value):
		state = clampi(value, 0, 1)
		_apply_texture()


func _ready() -> void:
	self_modulate = normal_modulate
	_update_from_button()
	_apply_texture()


func _process(_delta: float) -> void:
	_update_from_button()
	_update_hover_modulate(_delta)


func set_state(new_state: int) -> void:
	state = new_state


func _update_from_button() -> void:
	var button := _get_bound_button()
	if button:
		state = 1 if button.button_pressed else 0


func _update_hover_modulate(delta: float) -> void:
	var button := _get_bound_button()
	var target_modulate := hoven_modulate if button and button.is_hovered() else normal_modulate
	var weight := clampf(delta * hover_transition_speed, 0.0, 1.0)
	self_modulate = self_modulate.lerp(target_modulate, weight)


func _get_bound_button() -> BaseButton:
	if button_path == NodePath(""):
		return null

	var button := get_node_or_null(button_path)
	if button is BaseButton:
		return button
	return null


func _apply_texture() -> void:
	if state == 1 and green_light:
		texture = green_light
	elif state == 0 and red_light:
		texture = red_light
