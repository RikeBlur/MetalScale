class_name ToolManager
extends Node2D

@export var player_now: CharacterBody2D = null
@export var current_tool: Tool = Tool.NONE

const max_durability: float = 100.0

# ===================================================================
# ========================== Tool Data 信息 维护 ======================
# ===================================================================

enum Tool {
	NONE,
	EMERGENCELIGHT,
	FLASHLIGHT,
	ADRENALINE,
	KEYA,
	KEYB,
	KEYC
}

const TOOL_DISPLAY_NAMES = {
	Tool.NONE: "无",
	Tool.EMERGENCELIGHT: "应急光源",
	Tool.FLASHLIGHT: "手电筒",
	Tool.ADRENALINE: "肾上腺素",
	Tool.KEYA: "教师休息室钥匙",
	Tool.KEYB: "钥匙B",
	Tool.KEYC: "钥匙C"
}

const TOOL_DESCRIPTION = {
	Tool.NONE: "无",
	Tool.EMERGENCELIGHT: "提灯模样的备用光源，照明范围有限",
	Tool.FLASHLIGHT: "可以照亮前方的手电筒",
	Tool.ADRENALINE: "短时间激发身体机能的消耗品",
	Tool.KEYA: "教师休息室钥匙",
	Tool.KEYB: "钥匙B",
	Tool.KEYC: "钥匙C"
}

const TOOL_ICONS = {
	Tool.NONE: null,
	Tool.EMERGENCELIGHT: preload("res://Assests/sprite/UI/TOOLBAR/toolicon/EmergenceLight_icon.png"),
	Tool.FLASHLIGHT: preload("res://Assests/sprite/UI/TOOLBAR/toolicon/FlashLight_icon.png"),
	Tool.ADRENALINE: preload("res://Assests/sprite/UI/TOOLBAR/toolicon/Adrenaline_icon.png"),
	Tool.KEYA: preload("res://Assests/sprite/UI/TOOLBAR/toolicon/key1-1_icon.png"),
	Tool.KEYB: null,
	Tool.KEYC: null
}

const TOOL_PACKED_SCENES = {
	Tool.NONE: null,
	Tool.EMERGENCELIGHT: preload("res://System/RPG/tools/Tool/EmergenceLight.tscn"),
	Tool.FLASHLIGHT: preload("res://System/RPG/tools/Tool/FlashLight.tscn"),
	Tool.ADRENALINE: preload("res://System/RPG/tools/Tool/adrenaline.tscn"),
	Tool.KEYA: preload("res://System/RPG/tools/Tool/Key1-1.tscn"),
	Tool.KEYB: null,
	Tool.KEYC: null
}

const TOOL_TYPES = {
	Tool.NONE: ToolData.TYPE_PERMANENT,
	Tool.EMERGENCELIGHT: ToolData.TYPE_DURABILITY,
	Tool.FLASHLIGHT: ToolData.TYPE_DURABILITY,
	Tool.ADRENALINE: ToolData.TYPE_CONSUMABLE,
	Tool.KEYA: ToolData.TYPE_PERMANENT,
	Tool.KEYB: ToolData.TYPE_PERMANENT,
	Tool.KEYC: ToolData.TYPE_PERMANENT
}

const TOOL_USEABLE = {
	Tool.NONE: ToolData.USEABLE_FALSE,
	Tool.EMERGENCELIGHT: ToolData.USEABLE_TRUE,
	Tool.FLASHLIGHT: ToolData.USEABLE_TRUE,
	Tool.ADRENALINE: ToolData.USEABLE_TRUE,
	Tool.KEYA: ToolData.USEABLE_FALSE,
	Tool.KEYB: ToolData.USEABLE_FALSE,
	Tool.KEYC: ToolData.USEABLE_FALSE
}

const TOOL_DURABILITY_MAX = {
	Tool.EMERGENCELIGHT: max_durability,
	Tool.FLASHLIGHT: max_durability
}

const TOOL_CONSUMPTION_MAX = {
	Tool.ADRENALINE: 1
}

# ===================================================================
# ===================================================================
# ===================================================================

@export var emergencelight_durability_consumption: float = 5.0
@export var flashlight_durability_consumption: float = 5.0
@export var failure_sfx: SFXPlayer = null

var tool_data: Dictionary = {}
var tool_instances: Dictionary = {}
var durability: Dictionary = {}
var consumption: Dictionary = {}

var _current_tool_index: int = -1
var _available_tool_counts: Dictionary = {}

func _ready() -> void:
	if not player_now:
		player_now = get_parent() as CharacterBody2D

	_initialize_tool_data()
	_sync_runtime_lookup()

	if not player_now:
		return

	player_now.tool = -1
	_sync_available_tool_changes()
	if player_now.tool_available.size() > 0:
		_on_tool_changed(0)

static func get_tool_display_name(tool: Tool) -> String:
	return TOOL_DISPLAY_NAMES.get(tool, "未知工具")

static func get_tool_description(tool: Tool) -> String:
	return TOOL_DESCRIPTION.get(tool, "")

static func get_tool_icon_static(tool: Tool) -> Texture2D:
	return TOOL_ICONS.get(tool, null)

static func get_tool_type_static(tool: Tool) -> int:
	return TOOL_TYPES.get(tool, ToolData.TYPE_PERMANENT)

func _process(_delta: float) -> void:
	if not player_now:
		return

	_sync_available_tool_changes()

	var to_tool = InputEvents.to_tool()
	if to_tool >= 0:
		_on_tool_changed(to_tool)

	_sync_runtime_lookup()

# ============================== 消耗 ============================

func consumption_changed(tool_used: Tool, count: int) -> void:
	var data := get_tool_data(tool_used)
	if not data or data.type != ToolData.TYPE_CONSUMABLE:
		return

	data.consumption = max(data.consumption + count, 0)
	if data.consumption == 0:
		_remove_consumed_tool_from_available(tool_used)

	_sync_runtime_lookup()


func durability_changed(tool_used: Tool, amount: float) -> void:
	var data := get_tool_data(tool_used)
	if not data or data.type != ToolData.TYPE_DURABILITY:
		return

	data.durability = max(data.durability + amount, 0.0)
	if data.durability <= 0.0:
		data.state = ToolData.STATE_BROKEN

	_sync_runtime_lookup()

# ==============================================================
# =========================== 工具函数 ===========================
# ==============================================================


func get_tool_data(tool: Tool) -> ToolData:
	return tool_data.get(tool, null)

func get_tool_icon(tool: Tool) -> Texture2D:
	var data := get_tool_data(tool)
	return data.icon if data else TOOL_ICONS.get(tool, null)

func get_tool_type(tool: Tool) -> int:
	var data := get_tool_data(tool)
	return data.type if data else TOOL_TYPES.get(tool, ToolData.TYPE_PERMANENT)

func get_tool_state(tool: Tool) -> int:
	var data := get_tool_data(tool)
	return data.state if data else ToolData.STATE_UNSELECTED

func get_tool_durability(tool: Tool) -> float:
	var data := get_tool_data(tool)
	return data.durability if data and data.has_durability() else -1.0

func get_tool_durability_max(tool: Tool) -> float:
	var data := get_tool_data(tool)
	return data.durability_max if data and data.has_durability() else -1.0

func get_tool_consumption(tool: Tool) -> int:
	var data := get_tool_data(tool)
	return data.consumption if data and data.has_consumption() else -1

func is_tool_useable(tool: Tool) -> bool:
	var data := get_tool_data(tool)
	return data.is_useable() if data else false

func set_tool_state(tool: Tool, new_state: int) -> void:
	var data := get_tool_data(tool)
	if not data:
		return
	if data.state == ToolData.STATE_BROKEN and new_state != ToolData.STATE_BROKEN:
		return
	data.state = clampi(new_state, ToolData.STATE_UNSELECTED, ToolData.STATE_BROKEN)

func _on_tool_changed(new_tool_index: int) -> void:
	if not player_now:
		return
	if new_tool_index < 0 or new_tool_index >= player_now.tool_available.size():
		return

	var old_tool: Tool = current_tool
	var new_tool: Tool = player_now.tool_available[new_tool_index]

	if new_tool == Tool.NONE:
		if old_tool != new_tool:
			_release_tool_after_switch(old_tool)
		current_tool = new_tool
		_current_tool_index = new_tool_index
		player_now.tool = new_tool_index
		_sync_runtime_lookup()
		return

	var data := get_tool_data(new_tool)
	if not data:
		return

	if _is_tool_broken(data):
		data.state = ToolData.STATE_BROKEN
		_play_failure_sfx()
		_sync_runtime_lookup()
		return

	if old_tool != new_tool:
		_release_tool_after_switch(old_tool)

	current_tool = new_tool
	_current_tool_index = new_tool_index
	player_now.tool = new_tool_index

	if data.state != ToolData.STATE_ACTIVE:
		data.state = ToolData.STATE_SELECTED

	_ensure_tool_instance(new_tool, true)
	_sync_runtime_lookup()

func _initialize_tool_data() -> void:
	tool_data.clear()
	for tool in Tool.values():
		tool_data[tool] = _create_tool_data(tool)

func _create_tool_data(tool: Tool) -> ToolData:
	var data := ToolData.new()
	data.display_name = TOOL_DISPLAY_NAMES.get(tool, "")
	data.description = TOOL_DESCRIPTION.get(tool, "")
	data.packed_scene = TOOL_PACKED_SCENES.get(tool, null)
	data.icon = TOOL_ICONS.get(tool, null)
	data.type = TOOL_TYPES.get(tool, ToolData.TYPE_PERMANENT)
	data.useable = TOOL_USEABLE.get(tool, ToolData.USEABLE_FALSE)
	data.durability_max = TOOL_DURABILITY_MAX.get(tool, -1.0)
	data.durability = data.durability_max
	data.consumption_max = TOOL_CONSUMPTION_MAX.get(tool, -1)
	data.consumption = data.consumption_max
	data.state = ToolData.STATE_UNSELECTED
	return data

func _sync_available_tool_changes() -> void:
	var new_counts := _count_available_tools()

	for tool in tool_data.keys():
		if tool == Tool.NONE:
			continue

		var old_count: int = _available_tool_counts.get(tool, 0)
		var new_count: int = new_counts.get(tool, 0)
		var data := get_tool_data(tool)

		if old_count == 0 and new_count > 0 and data and data.state != ToolData.STATE_ACTIVE and data.state != ToolData.STATE_BROKEN:
			data.reset_runtime_values()

		if new_count == 0 and data and data.state != ToolData.STATE_ACTIVE and data.state != ToolData.STATE_BROKEN:
			data.state = ToolData.STATE_UNSELECTED
			_free_tool_instance(tool)

	_available_tool_counts = new_counts

	if _current_tool_index >= 0 and _current_tool_index < player_now.tool_available.size():
		var slot_tool: Tool = player_now.tool_available[_current_tool_index]
		if slot_tool != current_tool:
			_on_tool_changed(_current_tool_index)

func _count_available_tools() -> Dictionary:
	var counts := {}
	if not player_now:
		return counts

	for tool in player_now.tool_available:
		if tool == Tool.NONE:
			continue
		counts[tool] = counts.get(tool, 0) + 1

	return counts

func _remove_consumed_tool_from_available(tool_used: Tool) -> void:
	if not player_now:
		return

	var changed_current_slot_index := -1
	for i in range(player_now.tool_available.size()):
		if player_now.tool_available[i] != tool_used:
			continue

		player_now.tool_available[i] = Tool.NONE
		if i == _current_tool_index or i == player_now.tool:
			changed_current_slot_index = i

	if changed_current_slot_index >= 0:
		_on_tool_changed(changed_current_slot_index)
	else:
		_sync_available_tool_changes()

func _release_tool_after_switch(tool: Tool) -> void:
	if tool == Tool.NONE:
		return

	var data := get_tool_data(tool)
	if not data:
		return

	if data.state == ToolData.STATE_SELECTED:
		data.state = ToolData.STATE_UNSELECTED

	if data.state != ToolData.STATE_ACTIVE:
		_free_tool_instance(tool)

func _ensure_tool_instance(tool: Tool, play_success_sfx: bool) -> Node:
	if tool == Tool.NONE:
		return null

	if tool_instances.has(tool):
		var existing_instance: Node = tool_instances[tool]
		if existing_instance and is_instance_valid(existing_instance):
			return existing_instance
		tool_instances.erase(tool)

	var data := get_tool_data(tool)
	if not data or not data.packed_scene:
		return null

	var instance := data.packed_scene.instantiate()
	instance.name = Tool.keys()[tool]
	add_child(instance)
	tool_instances[tool] = instance

	if play_success_sfx:
		_play_success_sfx(instance)

	return instance

func _free_tool_instance(tool: Tool) -> void:
	if not tool_instances.has(tool):
		return

	var instance: Node = tool_instances[tool]
	tool_instances.erase(tool)
	if instance and is_instance_valid(instance):
		instance.queue_free()

func _play_success_sfx(instance: Node) -> void:
	if "success_sfx" in instance and instance.success_sfx:
		instance.success_sfx.play()

func _play_failure_sfx() -> void:
	if failure_sfx:
		failure_sfx.play_once()

func _is_tool_broken(data: ToolData) -> bool:
	if data.state == ToolData.STATE_BROKEN:
		return true
	return data.has_durability() and data.durability <= 0.0

func _sync_runtime_lookup() -> void:
	durability.clear()
	consumption.clear()

	for tool in tool_data.keys():
		var data := get_tool_data(tool)
		if not data:
			continue
		if data.has_durability():
			durability[tool] = data.durability
		if data.has_consumption():
			consumption[tool] = data.consumption
