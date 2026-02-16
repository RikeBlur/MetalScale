class_name ConfigBox
extends HBoxContainer

signal value_changed(new_value: float)

enum ConfigBoxType {
	HSLIDER
}

@export var box_type: ConfigBoxType = ConfigBoxType.HSLIDER
@export var value: float = 0.0

@onready var label: Label = get_node_or_null("label") if get_node_or_null("label") else get_node_or_null("Label")
@onready var control: Control = get_node_or_null("control") if get_node_or_null("control") else get_node_or_null("HSlider")

func _ready() -> void:
	_connect_control_signal()
	_apply_value_to_control()

func _connect_control_signal() -> void:
	match box_type:
		ConfigBoxType.HSLIDER:
			var slider := _get_hslider()
			if slider and not slider.value_changed.is_connected(_on_hslider_value_changed):
				slider.value_changed.connect(_on_hslider_value_changed)

func _on_hslider_value_changed(new_value: float) -> void:
	value = new_value
	value_changed.emit(new_value)

func _apply_value_to_control() -> void:
	match box_type:
		ConfigBoxType.HSLIDER:
			var slider := _get_hslider()
			if slider:
				slider.value = value

func set_value(new_value: float) -> void:
	value = new_value
	_apply_value_to_control()

func get_value() -> float:
	match box_type:
		ConfigBoxType.HSLIDER:
			var slider := _get_hslider()
			if slider:
				return slider.value
	return value

func _get_hslider() -> HSlider:
	if control is HSlider:
		return control as HSlider
	return null
