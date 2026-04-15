class_name ToolManager
extends Node2D

@export var player_now : CharacterBody2D = null
# Enum for tools to make code more readable.
const max_durability : float = 100.0

enum Tool{
	NONE, #0
	EMERGENCELIGHT, #1
	FLASHLIGHT, #2
	ADRENALINE, #3
	KEYA, #4
	KEYB, #5
	KEYC #6
}

# 工具显示名字典
const TOOL_DISPLAY_NAMES = {
	Tool.NONE: "无",
	Tool.EMERGENCELIGHT: "应急光源",
	Tool.FLASHLIGHT: "手电筒",
	Tool.ADRENALINE: "肾上腺素",
	Tool.KEYA: "教师休息室钥匙"
}

# 工具显示名字典
const TOOL_DESCRIPTION = {
	Tool.NONE: "无",
	Tool.EMERGENCELIGHT: "提灯模样的备用光源，照明范围有限",
	Tool.FLASHLIGHT: "手电筒",
	Tool.ADRENALINE: "肾上腺素",
	Tool.KEYA: "教师休息室钥匙"
}

# NOTE: Please replace with the actual paths to your scenes.
const EMERGENCELIGHT_SCENE = preload("res://System/RPG/tools/Tool/EmergenceLight.tscn")
const ADRENALINE_SCENE = preload("res://System/RPG/tools/Tool/adrenaline.tscn")
const FLASHLIGHT_SCENE = preload("res://System/RPG/tools/Tool/FlashLight.tscn")
const KEYA_SCENE = preload("res://System/RPG/tools/Tool/Key1-1.tscn")

@export var current_tool: Tool = Tool.NONE

# Durability for each tool
var durability = {
	Tool.EMERGENCELIGHT: max_durability,
	Tool.FLASHLIGHT: max_durability
}

var consumption = {
	Tool.ADRENALINE: 0,
	Tool.KEYA: 0
}

# Durability consumption rate per second. Can be adjusted in the inspector.
@export var emergencelight_durability_consumption: float = 5.0
@export var flashlight_durability_consumption: float = 5.0

# 尝试使用耗尽耐久的道具时触发的音效！！
@export var failure_sfx: SFXPlayer = null

func _ready():
	current_tool = Tool.NONE
	player_now.tool = -1
	_on_tool_changed(0)

# 静态方法：根据工具类型获取显示名
static func get_tool_display_name(tool: Tool) -> String:
	return TOOL_DISPLAY_NAMES.get(tool, "未知工具")
	

func _process(delta):
	# Decrease durability of the currently active tool over time.
	match current_tool:
		# 应急光源
		Tool.EMERGENCELIGHT:
			durability[Tool.EMERGENCELIGHT] -= emergencelight_durability_consumption * delta
			if durability[Tool.EMERGENCELIGHT] <= 0:
				durability[Tool.EMERGENCELIGHT] = 0
				# Switch to NONE when durability runs out.
				current_tool = Tool.NONE
		# 手电筒
		Tool.FLASHLIGHT:
			durability[Tool.FLASHLIGHT] -= flashlight_durability_consumption * delta
			if durability[Tool.FLASHLIGHT] <= 0:
				durability[Tool.FLASHLIGHT] = 0
				# Switch to NONE when durability runs out.
				current_tool = Tool.NONE
		# 肾上腺素
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
		Tool.KEYA:
			pass
				
	# 如果按下数字键，切换到当前的tool
	var to_tool = InputEvents.to_tool()
	if to_tool >= 0 : 
		_on_tool_changed(to_tool)


func _on_tool_changed(new_tool: int):
	# When the tool changes, first clear any existing tool instances.
	for child in get_children():
		child.queue_free()

	# 更新当前工具
	var tool_now = player_now.tool_available[new_tool]
	
	current_tool = tool_now
	player_now.tool = new_tool
		
	match tool_now:
		Tool.NONE:
			# Do nothing if no tool is selected.
			pass
		Tool.EMERGENCELIGHT:
			var instance = EMERGENCELIGHT_SCENE.instantiate()
			if durability[Tool.EMERGENCELIGHT] > 0:
				add_child(instance)
				instance.success_sfx.play()
			else :
				failure_sfx.play_once()
		Tool.FLASHLIGHT:
			if durability[Tool.FLASHLIGHT] > 0:
				var instance = FLASHLIGHT_SCENE.instantiate()
				if durability[Tool.FLASHLIGHT] > 0:
					add_child(instance)
					instance.success_sfx.play()
				else :
					failure_sfx.play_once()
		Tool.ADRENALINE:
			var instance = ADRENALINE_SCENE.instantiate()
			if consumption[Tool.ADRENALINE] > 0:
				add_child(instance)
		Tool.KEYA:
			pass
