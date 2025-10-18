class_name ToolManager
extends Node2D

@export var player_now : CharacterBody2D = null
# Enum for tools to make code more readable.
const max_durability : float = 100.0

enum Tool{
	NONE, #0
	EMERGENCELIGHT, #1
	FLASHLIGHT, #2
	ADRENALINE #3
}

# NOTE: Please replace with the actual paths to your scenes.
const EMERGENCELIGHT_SCENE = preload("res://System/RPG/tools/EmergenceLight.tscn")
const ADRENALINE_SCENE = preload("res://System/RPG/tools/adrenaline.tscn")
const FLASHLIGHT_SCENE = preload("res://System/RPG/tools/FlashLight.tscn")

@export var current_tool: Tool = Tool.NONE:
	set(value):
		if current_tool == value:
			return
		current_tool = value
		_on_tool_changed()

# Durability for each tool
var durability = {
	Tool.EMERGENCELIGHT: max_durability,
	Tool.FLASHLIGHT: max_durability
}

var consumption = {
	Tool.ADRENALINE: 1
}

# Durability consumption rate per second. Can be adjusted in the inspector.
@export var emergencelight_durability_consumption: float = 5.0
@export var flashlight_durability_consumption: float = 5.0

@export var failure_sfx: AudioStreamPlayer2D

func _ready():
	current_tool = player_now.tool_available[0]
	player_now.tool = 0
	_on_tool_changed()
	

func _process(delta):
	# Decrease durability of the currently active tool over time.
	match current_tool:
		Tool.EMERGENCELIGHT:
			durability[Tool.EMERGENCELIGHT] -= emergencelight_durability_consumption * delta
			if durability[Tool.EMERGENCELIGHT] <= 0:
				durability[Tool.EMERGENCELIGHT] = 0
				# Switch to NONE when durability runs out.
				current_tool = Tool.NONE
		Tool.FLASHLIGHT:
			durability[Tool.FLASHLIGHT] -= flashlight_durability_consumption * delta
			if durability[Tool.FLASHLIGHT] <= 0:
				durability[Tool.FLASHLIGHT] = 0
				# Switch to NONE when durability runs out.
				current_tool = Tool.NONE
		Tool.ADRENALINE:
			if InputEvents.consume_once():
				if get_child_count() > 0:
					var adrenaline_node = get_child(0)
					if adrenaline_node and adrenaline_node.has_method("adrenaline_release"):
						adrenaline_node.adrenaline_release()
						consumption[Tool.ADRENALINE] -= 1
			if consumption[Tool.ADRENALINE] <= 0:
				consumption[Tool.ADRENALINE] = 0
				current_tool = Tool.NONE
				player_now.tool_available[player_now.tool] = Tool.NONE
	# 如果按下数字键，切换到当前的tool
	var to_tool = InputEvents.to_tool()
	if to_tool >= 0 : 
		current_tool = player_now.tool_available[to_tool]
		player_now.tool = to_tool


func _on_tool_changed():
	# When the tool changes, first clear any existing tool instances.
	for child in get_children():
		child.queue_free()

	match current_tool:
		Tool.NONE:
			# Do nothing if no tool is selected.
			pass
		Tool.EMERGENCELIGHT:
			var instance = EMERGENCELIGHT_SCENE.instantiate()
			if durability[Tool.EMERGENCELIGHT] > 0:
				add_child(instance)
				instance.success_sfx.play()
			else :
				failure_sfx.play()
		Tool.FLASHLIGHT:
			if durability[Tool.FLASHLIGHT] > 0:
				var instance = FLASHLIGHT_SCENE.instantiate()
				if durability[Tool.FLASHLIGHT] > 0:
					add_child(instance)
					instance.success_sfx.play()
				else :
					failure_sfx.play()
		Tool.ADRENALINE:
			var instance = ADRENALINE_SCENE.instantiate()
			if consumption[Tool.ADRENALINE] > 0:
				add_child(instance)
