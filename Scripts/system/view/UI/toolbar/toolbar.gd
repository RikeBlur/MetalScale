class_name Toolbar
extends Control

@export var player_now: CharacterBody2D
@export var use_reminder: Control = null
@export var use_reminder_offset: Vector2 = Vector2(85, 0)

var tool_boxes: Array = []
var tool_bar: VBoxContainer = null
var tool_manager: ToolManager = null

func _ready() -> void:
	if not player_now:
		return

	tool_bar = $leftoffset/PanelContainer/MarginContainer/tool_bar
	tool_manager = player_now.get_node("ToolManager") as ToolManager
	if not use_reminder:
		use_reminder = find_child("use_reminder", true, false) as Control
	if use_reminder:
		use_reminder.hide()

	_initialize_tool_boxes()
	call_deferred("_update_toolbar")
	call_deferred("_update_use_reminder")

func _initialize_tool_boxes() -> void:
	tool_boxes.clear()
	for child in tool_bar.get_children():
		if child is Toolbox:
			tool_boxes.append(child)

func _process(_delta: float) -> void:
	if not player_now:
		return
	if not tool_manager:
		return

	call_deferred("_update_toolbar")
	call_deferred("_update_consumption")
	call_deferred("_update_progressbar")
	call_deferred("_update_use_reminder")

func _update_consumption() -> void:
	for toolbox in tool_boxes:
		if toolbox.consumption == null:
			continue

		var tool_type = toolbox.tool
		var tool_consumption = tool_manager.get_tool_consumption(tool_type)
		if tool_consumption >= 0:
			toolbox.consumption.text = str(tool_consumption)

func _update_progressbar() -> void:
	for toolbox in tool_boxes:
		if toolbox.durability == null:
			continue

		var tool_type = toolbox.tool
		var durability_max = tool_manager.get_tool_durability_max(tool_type)
		var durability_value = tool_manager.get_tool_durability(tool_type)
		if durability_max >= 0.0 and durability_value >= 0.0:
			toolbox.durability.max_value = durability_max
			toolbox.durability.value = durability_value
			toolbox.durability.update_color()

func _update_toolbar() -> void:
	if not player_now or tool_boxes.is_empty():
		return

	var box_count: int = min(player_now.tool_available.size(), tool_boxes.size())
	for i in range(box_count):
		var tool_type = player_now.tool_available[i]
		var toolbox: Toolbox = tool_boxes[i]
		var icon: TextureRect = toolbox.icon

		toolbox.tool = tool_type
		toolbox.config = tool_manager.get_tool_type(tool_type)
		if icon:
			icon.texture = tool_manager.get_tool_icon(tool_type)

		if toolbox.config == ToolData.TYPE_DURABILITY and toolbox.durability:
			var durability_max = tool_manager.get_tool_durability_max(tool_type)
			var durability_value = tool_manager.get_tool_durability(tool_type)
			if durability_max >= 0.0 and durability_value >= 0.0:
				toolbox.durability.max_value = durability_max
				toolbox.durability.value = durability_value
				toolbox.durability.update_color()

		var new_state = tool_manager.get_tool_state(tool_type)
		if tool_type == ToolManager.Tool.NONE:
			new_state = ToolData.STATE_UNSELECTED
		toolbox.state = new_state

		if icon and icon.material:
			icon.material.set_shader_parameter("state", new_state)

func _update_use_reminder() -> void:
	if not use_reminder or not player_now or not tool_manager:
		return
	if player_now.tool < 0 or player_now.tool >= tool_boxes.size():
		use_reminder.hide()
		return
	if player_now.tool >= player_now.tool_available.size():
		use_reminder.hide()
		return

	var selected_tool = player_now.tool_available[player_now.tool]
	if selected_tool == ToolManager.Tool.NONE:
		use_reminder.hide()
		return
	if not tool_manager.is_tool_useable(selected_tool):
		use_reminder.hide()
		return
	if tool_manager.get_tool_state(selected_tool) == ToolData.STATE_BROKEN:
		use_reminder.hide()
		return

	var selected_toolbox: Toolbox = tool_boxes[player_now.tool]
	use_reminder.global_position = selected_toolbox.global_position + use_reminder_offset
	use_reminder.show()
