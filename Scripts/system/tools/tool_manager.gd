class_name ToolManager
extends Node2D

@export var player_now: CharacterBody2D = null
@export var current_tool: Tool = Tool.NONE

const max_durability: float = 100.0
const CONSUMABLE_STACK_LIMIT: int = 64
const DEFAULT_USE_COOLDOWN: float = 0.2

# ======================================================================
# ========================== Tool Data 信息 维护 ========================
# ======================================================================

enum Tool {
	NONE,
	EMERGENCELIGHT,
	FLASHLIGHT,
	ADRENALINE,
	KEYA,
	KEYB,
	KEYC,
	BOOLDYWATER,
	SUICIDEKING,
	BATTERY
}

const DEFAULT_TOOL_LIST = [
	{
		"tool": Tool.NONE,
		"display_name": "无",
		"description": "无",
		"icon": null,
		"packed_scene": null,
		"type": ToolData.TYPE_PERMANENT,
		"useable": ToolData.USEABLE_FALSE,
		"cooldown_time": -1.0,
		"durability_max": -1.0,
		"consumption_max": -1,
	},
	{
		"tool": Tool.EMERGENCELIGHT,
		"display_name": "应急光源",
		"description": "提灯模样的备用光源，可以遮蔽从电子屏幕中射来的视线。请留意电量。",
		"icon": preload("res://Assests/sprite/UI/TOOLBAR/toolicon/EmergenceLight_icon.png"),
		"packed_scene": preload("res://System/RPG/tools/Tool/EmergenceLight.tscn"),
		"type": ToolData.TYPE_DURABILITY,
		"useable": ToolData.USEABLE_TRUE,
		"cooldown_time": DEFAULT_USE_COOLDOWN,
		"durability_max": max_durability,
		"consumption_max": -1,
	},
	{
		"tool": Tool.FLASHLIGHT,
		"display_name": "手电筒",
		"description": "可以照亮前方的手电筒",
		"icon": preload("res://Assests/sprite/UI/TOOLBAR/toolicon/FlashLight_icon.png"),
		"packed_scene": preload("res://System/RPG/tools/Tool/FlashLight.tscn"),
		"type": ToolData.TYPE_DURABILITY,
		"useable": ToolData.USEABLE_TRUE,
		"cooldown_time": DEFAULT_USE_COOLDOWN,
		"durability_max": max_durability,
		"consumption_max": -1,
	},
	{
		"tool": Tool.ADRENALINE,
		"display_name": "肾上腺素",
		"description": "短时间激发身体机能的药剂，请按处方使用。",
		"icon": preload("res://Assests/sprite/UI/TOOLBAR/toolicon/Adrenaline_icon.png"),
		"packed_scene": preload("res://System/RPG/tools/Tool/adrenaline.tscn"),
		"type": ToolData.TYPE_CONSUMABLE,
		"useable": ToolData.USEABLE_TRUE,
		"cooldown_time": DEFAULT_USE_COOLDOWN,
		"durability_max": -1.0,
		"consumption_max": 0,
	},
	{
		"tool": Tool.KEYA,
		"display_name": "会议室钥匙",
		"description": "会议室的钥匙。旧教学楼除了大门之外没有上电子锁，每个房间都有着令人怀念实体钥匙。",
		"icon": preload("res://Assests/sprite/UI/TOOLBAR/toolicon/keyA_icon.png"),
		"packed_scene": preload("res://System/RPG/tools/Tool/KeyA.tscn"),
		"type": ToolData.TYPE_PERMANENT,
		"useable": ToolData.USEABLE_FALSE,
		"cooldown_time": -1.0,
		"durability_max": -1.0,
		"consumption_max": -1,
	},
	{
		"tool": Tool.KEYB,
		"display_name": "三层连廊钥匙",
		"description": "通向三层连廊钥匙。旧教学楼一共有三栋，三栋建筑的均在第三层通过空中连廊连接，方便学生在不同建筑间移动。",
		"icon": preload("res://Assests/sprite/UI/TOOLBAR/toolicon/keyB_icon.png"),
		"packed_scene": null,
		"type": ToolData.TYPE_PERMANENT,
		"useable": ToolData.USEABLE_FALSE,
		"cooldown_time": -1.0,
		"durability_max": -1.0,
		"consumption_max": -1,
	},
	{
		"tool": Tool.KEYC,
		"display_name": "配电室钥匙",
		"description": "三楼配电室的钥匙。为了打开一层的通向玄关的大门，必须先恢复电力来解开电子锁。",
		"icon": preload("res://Assests/sprite/UI/TOOLBAR/toolicon/keyC_icon.png"),
		"packed_scene": null,
		"type": ToolData.TYPE_PERMANENT,
		"useable": ToolData.USEABLE_FALSE,
		"cooldown_time": -1.0,
		"durability_max": -1.0,
		"consumption_max": -1,
	},
	{
		"tool": Tool.BOOLDYWATER,
		"display_name": "血水",
		"description": "血色的瓶装水。没有想象中的粘稠。",
		"icon": preload("res://Assests/sprite/UI/TOOLBAR/toolicon/bloodywater_icon.png"),
		"packed_scene": null,
		"type": ToolData.TYPE_CONSUMABLE,
		"useable": ToolData.USEABLE_FALSE,
		"cooldown_time": -1.0,
		"durability_max": -1.0,
		"consumption_max": 0,
	},
	{
		"tool": Tool.SUICIDEKING,
		"display_name": "自杀之王，红桃K",
		"description": "自杀之王，红桃K。查理曼大帝将头颅插入卡槽，流淌的血水恩泽了三个儿子。",
		"icon": preload("res://Assests/sprite/UI/TOOLBAR/toolicon/suicideking_icon.png"),
		"packed_scene": null,
		"type": ToolData.TYPE_CONSUMABLE,
		"useable": ToolData.USEABLE_FALSE,
		"cooldown_time": -1.0,
		"durability_max": -1.0,
		"consumption_max": 0,
	},
	{
		"tool": Tool.BATTERY,
		"display_name": "电池",
		"description": "9号电池，似乎可以装入应急光源中,可以在电量低时使用。",
		"icon": preload("res://Assests/sprite/UI/TOOLBAR/toolicon/Battery_icon.png"),
		"packed_scene": preload("res://System/RPG/tools/Tool/Battery.tscn"),
		"type": ToolData.TYPE_CONSUMABLE,
		"useable": ToolData.USEABLE_TRUE,
		"cooldown_time": DEFAULT_USE_COOLDOWN,
		"durability_max": -1.0,
		"consumption_max": 0,
	},
]

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
var _last_tool_use_time: Dictionary = {}

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
	return String(_get_default_tool_config(tool).get("display_name", "未知工具"))

static func get_tool_description(tool: Tool) -> String:
	return String(_get_default_tool_config(tool).get("description", ""))

static func get_tool_icon_static(tool: Tool) -> Texture2D:
	return _get_default_tool_config(tool).get("icon", null) as Texture2D

static func get_tool_type_static(tool: Tool) -> int:
	return int(_get_default_tool_config(tool).get("type", ToolData.TYPE_PERMANENT))

static func _get_default_tool_config(tool: Tool) -> Dictionary:
	for config in DEFAULT_TOOL_LIST:
		var default_config: Dictionary = config
		if default_config.get("tool", Tool.NONE) == tool:
			return default_config
	return {}

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

	data.consumption = clampi(data.consumption + count, 0, CONSUMABLE_STACK_LIMIT)
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
	return data.icon if data else get_tool_icon_static(tool)

func get_tool_type(tool: Tool) -> int:
	var data := get_tool_data(tool)
	return data.type if data else get_tool_type_static(tool)

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

func get_tool_cooldown_time(tool: Tool) -> float:
	var data := get_tool_data(tool)
	return data.cooldown_time if data else -1.0

func get_tool_cooldown_remaining(tool: Tool) -> float:
	var data := get_tool_data(tool)
	if not data or not data.is_useable() or data.cooldown_time <= 0.0:
		return 0.0

	var elapsed_time := Time.get_ticks_msec() / 1000.0 - float(_last_tool_use_time.get(tool, -INF))
	return max(data.cooldown_time - elapsed_time, 0.0)

func is_tool_useable(tool: Tool) -> bool:
	var data := get_tool_data(tool)
	return data.is_useable() if data else false

func is_tool_use_ready(tool: Tool) -> bool:
	var data := get_tool_data(tool)
	if not data or not data.is_useable():
		return false
	if _is_tool_broken(data):
		return false
	return get_tool_cooldown_remaining(tool) <= 0.0

func consume_tool_use_once(tool: Tool) -> bool:
	if not is_tool_use_ready(tool):
		return false
	if not InputEvents.consume_once():
		return false

	_last_tool_use_time[tool] = Time.get_ticks_msec() / 1000.0
	return true

func set_tool_state(tool: Tool, new_state: int) -> void:
	var data := get_tool_data(tool)
	if not data:
		return
	if data.state == ToolData.STATE_BROKEN and new_state != ToolData.STATE_BROKEN:
		return
	data.state = clampi(new_state, ToolData.STATE_UNSELECTED, ToolData.STATE_BROKEN)

func add_consumable_tool(tool: Tool, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	if not player_now:
		return false

	var data := get_tool_data(tool)
	if not data or data.type != ToolData.TYPE_CONSUMABLE:
		return false
	if data.consumption >= CONSUMABLE_STACK_LIMIT:
		return false

	if not player_now.tool_available.has(tool):
		var empty_slot_index := _find_empty_tool_slot()
		if empty_slot_index < 0:
			return false
		player_now.tool_available[empty_slot_index] = tool

	var added_amount: int = min(amount, CONSUMABLE_STACK_LIMIT - data.consumption)
	if added_amount <= 0:
		return false

	data.consumption += added_amount
	_sync_available_tool_changes()
	_sync_runtime_lookup()
	return true

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

	if data.state == ToolData.STATE_UNSELECTED:
		data.state = ToolData.STATE_SELECTED

	_ensure_tool_instance(new_tool, true)
	_sync_runtime_lookup()

func _initialize_tool_data() -> void:
	tool_data.clear()
	for tool in Tool.values():
		tool_data[tool] = _create_tool_data(tool)

func _create_tool_data(tool: Tool) -> ToolData:
	var default_config := _get_default_tool_config(tool)
	var data := ToolData.new()
	data.display_name = String(default_config.get("display_name", ""))
	data.description = String(default_config.get("description", ""))
	data.packed_scene = default_config.get("packed_scene", null) as PackedScene
	data.icon = default_config.get("icon", null) as Texture2D
	data.type = int(default_config.get("type", ToolData.TYPE_PERMANENT))
	data.useable = int(default_config.get("useable", ToolData.USEABLE_FALSE))
	data.cooldown_time = float(default_config.get("cooldown_time", -1.0))
	if data.useable == ToolData.USEABLE_FALSE:
		data.cooldown_time = -1.0
	data.durability_max = float(default_config.get("durability_max", -1.0))
	data.durability = data.durability_max
	data.consumption_max = int(default_config.get("consumption_max", -1))
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

		if old_count == 0 and new_count > 0 and data and data.type != ToolData.TYPE_CONSUMABLE and data.state != ToolData.STATE_ACTIVE and data.state != ToolData.STATE_BROKEN:
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

func _find_empty_tool_slot() -> int:
	if not player_now:
		return -1

	for i in range(player_now.tool_available.size()):
		if player_now.tool_available[i] == Tool.NONE:
			return i

	return -1

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
