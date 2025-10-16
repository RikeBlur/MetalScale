class_name Toolbox
extends HBoxContainer

var state : int = 0
var tool : ToolManager.Tool = ToolManager.Tool.NONE
var config : int = 0

@export var icon : TextureRect
@export var progressbar : ProgressBar

func _ready() -> void:
	icon = $Icon
	progressbar = $DurabilityBar
