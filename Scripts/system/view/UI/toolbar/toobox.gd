class_name Toolbox
extends HBoxContainer

var state : int = 0
var tool : ToolManager.Tool = ToolManager.Tool.NONE
var config : int = 0

@export var icon : TextureRect
@export var durability : durability_process_bar

func _ready() -> void:
	icon = $Icon
	durability = $DurabilityBar
