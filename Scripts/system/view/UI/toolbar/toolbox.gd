class_name Toolbox
extends Container

var state: int = ToolData.STATE_UNSELECTED
var tool: ToolManager.Tool = ToolManager.Tool.NONE
var config: int = ToolData.TYPE_PERMANENT:
	set(value):
		if config != value:
			config = value
			update_children_based_on_config()

@export var icon: TextureRect = null
@export var durability: ProgressBar = null
@export var consumption: Label = null
@export var back: TextureRect = null

const DURABILITY_BAR_SCENE = preload("res://System/RPG/tools/toolbox_son/durability_bar.tscn")
const CONSUMPTION_LABEL_SCENE = preload("res://System/RPG/tools/toolbox_son/consumption_label.tscn")

func _ready() -> void:
	if not icon:
		icon = get_node_or_null("Icon") as TextureRect
	if not back:
		back = get_node_or_null("back") as TextureRect
	update_children_based_on_config()

func update_children_based_on_config() -> void:
	_apply_config()

func _apply_config() -> void:
	match config:
		ToolData.TYPE_PERMANENT:
			for child in get_children():
				if child != icon and child != back:
					child.queue_free()
			durability = null
			consumption = null
		ToolData.TYPE_DURABILITY:
			var durability_bar_node = get_node_or_null("DurabilityBar")
			if not durability_bar_node:
				durability_bar_node = DURABILITY_BAR_SCENE.instantiate()
				durability_bar_node.name = "DurabilityBar"
				add_child(durability_bar_node)
				move_child(durability_bar_node, 0)

			durability = durability_bar_node
			consumption = null

			for child in get_children():
				if child != icon and child != durability_bar_node and child != back:
					child.queue_free()
		ToolData.TYPE_CONSUMABLE:
			var consumption_label_node = get_node_or_null("ConsumptionLabel")
			if not consumption_label_node:
				consumption_label_node = CONSUMPTION_LABEL_SCENE.instantiate()
				consumption_label_node.name = "ConsumptionLabel"
				add_child(consumption_label_node)

			consumption = consumption_label_node
			durability = null

			for child in get_children():
				if child != icon and child != consumption_label_node and child != back:
					child.queue_free()
