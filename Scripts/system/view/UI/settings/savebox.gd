class_name SaveBox
extends MarginContainer

@onready var button: Button = $Button
@onready var label: Label = $Label
@onready var border: TextureRect = $border

@export_group("Border Shader Params")
@export var normal_base_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var normal_alpha_multiplier: float = 0.4
@export var normal_color_mix_strength: float = 0.5

@export var hover_base_color: Color = Color(1, 1, 1, 1)
@export var hover_alpha_multiplier: float = 1.0
@export var hover_color_mix_strength: float = 0.5

@export var focus_base_color: Color = Color(1, 1, 1, 1)
@export var focus_alpha_multiplier: float = 1.0
@export var focus_color_mix_strength: float = 0.5

@export var pressed_base_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var pressed_alpha_multiplier: float = 0.25
@export var pressed_color_mix_strength: float = 0.25

enum VisualState {
	NORMAL,
	HOVER,
	FOCUS,
	PRESSED
}

func _ready() -> void:
	_ensure_unique_border_material()
	_connect_button_signals()
	_update_border_visual()

func _connect_button_signals() -> void:
	button.mouse_entered.connect(_update_border_visual)
	button.mouse_exited.connect(_update_border_visual)
	button.focus_entered.connect(_update_border_visual)
	button.focus_exited.connect(_update_border_visual)
	button.toggled.connect(_on_button_toggled)
	button.button_down.connect(_update_border_visual)
	button.button_up.connect(_update_border_visual)

func _on_button_toggled(_toggled_on: bool) -> void:
	_update_border_visual()

func _update_border_visual() -> void:
	var state := _get_current_visual_state()
	match state:
		VisualState.PRESSED:
			_apply_border_params(pressed_base_color, pressed_alpha_multiplier, pressed_color_mix_strength)
		VisualState.HOVER:
			_apply_border_params(hover_base_color, hover_alpha_multiplier, hover_color_mix_strength)
		VisualState.FOCUS:
			_apply_border_params(focus_base_color, focus_alpha_multiplier, focus_color_mix_strength)
		_:
			_apply_border_params(normal_base_color, normal_alpha_multiplier, normal_color_mix_strength)

func _get_current_visual_state() -> VisualState:
	# Priority: pressed > hover > focus > normal
	if button.button_pressed or button.is_pressed():
		return VisualState.PRESSED
	if button.is_hovered():
		return VisualState.HOVER
	if button.has_focus():
		return VisualState.FOCUS
	return VisualState.NORMAL

func _apply_border_params(base_color: Color, alpha_multiplier: float, color_mix_strength: float) -> void:
	if not border or not border.material:
		return
	border.material.set("shader_parameter/base_color", base_color)
	border.material.set("shader_parameter/alpha_multiplier", alpha_multiplier)
	border.material.set("shader_parameter/color_mix_strength", color_mix_strength)

func _ensure_unique_border_material() -> void:
	if not border or not border.material:
		return
	border.material = border.material.duplicate(true)
