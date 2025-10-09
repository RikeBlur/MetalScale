class_name ToolManager
extends Node2D

@export var player_now : CharacterBody2D = null
# Enum for tools to make code more readable.
const max_durability : float = 100.0

enum Tool {
	NONE, # 0
	RADIUS_LIGHT, # 1
	PARALLEL_LIGHT # 2
}

# NOTE: Please replace with the actual paths to your scenes.
const RADIAL_LIGHT_SCENE = preload("res://System/RPG/lighting/radial_light.tscn")
#const PARALLEL_LIGHT_SCENE = preload("res://System/RPG/entity/item/parallel_light_source.tscn")

@export var current_tool: Tool = Tool.NONE:
	set(value):
		if current_tool == value:
			return
		current_tool = value
		_on_tool_changed(value)

# Durability for each tool
var durability = {
	Tool.RADIUS_LIGHT: max_durability,
	Tool.PARALLEL_LIGHT: max_durability
}

# Durability consumption rate per second. Can be adjusted in the inspector.
@export var radius_light_durability_consumption: float = 1.0
@export var parallel_light_durability_consumption: float = 1.0


func _ready():
	# Set the initial tool state based on the exported variable.
	_on_tool_changed(current_tool)


func _process(delta):
	# Decrease durability of the currently active tool over time.
	match current_tool:
		Tool.RADIUS_LIGHT:
			durability[Tool.RADIUS_LIGHT] -= radius_light_durability_consumption * delta
			if durability[Tool.RADIUS_LIGHT] <= 0:
				durability[Tool.RADIUS_LIGHT] = 0
				# Switch to NONE when durability runs out.
				current_tool = Tool.NONE
		Tool.PARALLEL_LIGHT:
			durability[Tool.PARALLEL_LIGHT] -= parallel_light_durability_consumption * delta
			if durability[Tool.PARALLEL_LIGHT] <= 0:
				durability[Tool.PARALLEL_LIGHT] = 0
				# Switch to NONE when durability runs out.
				current_tool = Tool.NONE
	# 如果按下数字键，切换到当前的tool
	var to_tool = InputEvents.to_tool()
	if to_tool >= 0 : current_tool = player_now.tool_available[InputEvents.to_tool()]


func _on_tool_changed(new_tool):
	# When the tool changes, first clear any existing tool instances.
	for child in get_children():
		child.queue_free()

	if player_now:
		player_now.tool = new_tool
	else:
		push_warning("ToolManager: player_now is not assigned in the inspector.")

	# Instantiate and add the new tool's scene as a child.
	match current_tool:
		Tool.NONE:
			# Do nothing if no tool is selected.
			pass
		Tool.RADIUS_LIGHT:
			if durability[Tool.RADIUS_LIGHT] > 0:
				var instance = RADIAL_LIGHT_SCENE.instantiate()
				add_child(instance)
		#Tool.PARALLEL_LIGHT:
		#	if durability[Tool.PARALLEL_LIGHT] > 0:
		#		var instance = PARALLEL_LIGHT_SCENE.instantiate()
		#		add_child(instance)
