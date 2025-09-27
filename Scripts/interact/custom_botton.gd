class_name custom_botton
extends Control

@export var text: String

var choice_label: Label
var choice_area: Area2D
signal pressed

func _ready() -> void:
	choice_label = $A1
	choice_area = $A2
	choice_label.text = text
	choice_area.clicked_signal.connect(_on_clicked)

func _on_clicked() -> void:
	pressed.emit()
