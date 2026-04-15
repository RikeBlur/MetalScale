class_name ToolboxInfo
extends Container

signal hoven(toolbox_info: ToolboxInfo)
signal hover_exited(toolbox_info: ToolboxInfo)

var state: int = 0
var tool: ToolManager.Tool = ToolManager.Tool.NONE
var config: int = 0:
	set(value):
		if config != value:
			config = value
			update_children_based_on_config()

@export var icon: TextureRect = null
@export var durability: ProgressBar = null
@export var consumption: Label = null
@export var back: TextureRect = null
@export var button: Button = null

const DURABILITY_BAR_SCENE = preload("res://System/RPG/tools/toolbox_son/durability_bar.tscn")
const CONSUMPTION_LABEL_SCENE = preload("res://System/RPG/tools/toolbox_son/consumption_label.tscn")

func _ready() -> void:
	_cache_children()
	_connect_button_signals()
	update_children_based_on_config()

func set_tool_info(tool_type: ToolManager.Tool, tool_icon: Texture2D) -> void:
	tool = tool_type
	if not icon:
		icon = get_node_or_null("Icon") as TextureRect
	if icon:
		icon.texture = tool_icon

func toolbox_info_on_hoven() -> void:
	hoven.emit(self)

func toolbox_info_on_hover() -> void:
	toolbox_info_on_hoven()

func toolbox_info_on_exit() -> void:
	hover_exited.emit(self)

func update_children_based_on_config() -> void:
	_apply_config()

func _apply_config() -> void:
	_cache_children()
	match config:
		0:
			for child in get_children():
				if child != icon and child != back and child != button:
					child.queue_free()
			durability = null
			consumption = null
		1:
			var durability_bar_node = get_node_or_null("DurabilityBar")
			if not durability_bar_node:
				durability_bar_node = DURABILITY_BAR_SCENE.instantiate()
				durability_bar_node.name = "DurabilityBar"
				add_child(durability_bar_node)
				move_child(durability_bar_node, 0)

			durability = durability_bar_node
			consumption = null

			for child in get_children():
				if child != icon and child != durability_bar_node and child != back and child != button:
					child.queue_free()
		2:
			var consumption_label_node = get_node_or_null("ConsumptionLabel")
			if not consumption_label_node:
				consumption_label_node = CONSUMPTION_LABEL_SCENE.instantiate()
				consumption_label_node.name = "ConsumptionLabel"
				add_child(consumption_label_node)

			consumption = consumption_label_node
			durability = null

			for child in get_children():
				if child != icon and child != consumption_label_node and child != back and child != button:
					child.queue_free()

	_connect_button_signals()
	_raise_button()

func _cache_children() -> void:
	if not icon:
		icon = get_node_or_null("Icon") as TextureRect
	if not back:
		back = get_node_or_null("back") as TextureRect
	if not button:
		button = get_node_or_null("Button") as Button

func _connect_button_signals() -> void:
	if not button:
		return

	var entered_callable = Callable(self, "toolbox_info_on_hoven")
	if not button.mouse_entered.is_connected(entered_callable):
		button.mouse_entered.connect(entered_callable)

	var exited_callable = Callable(self, "toolbox_info_on_exit")
	if not button.mouse_exited.is_connected(exited_callable):
		button.mouse_exited.connect(exited_callable)

func _raise_button() -> void:
	if button and button.get_parent() == self:
		move_child(button, get_child_count() - 1)
