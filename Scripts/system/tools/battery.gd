class_name Battery
extends Node2D

@onready var success_sfx: AudioStreamPlayer2D = $SuccessSFX

var state: int = ToolData.STATE_UNSELECTED
var tool_manager: ToolManager = null
var player_now: CharacterBody2D = null


func _ready() -> void:
	var parent = get_parent()
	if parent and "player_now" in parent:
		player_now = parent.player_now
	tool_manager = get_parent() as ToolManager
	_sync_state_from_tool_manager()


func _process(_delta: float) -> void:
	_sync_state_from_tool_manager()

	if _can_use() and InputEvents.consume_once():
		battery_release()


func battery_release() -> void:
	if not tool_manager or not tool_manager.player_now:
		return

	if not _player_has_emergence_light():
		_play_failure_sfx()
		return

	var light_data := tool_manager.get_tool_data(ToolManager.Tool.EMERGENCELIGHT)
	if not light_data or not light_data.has_durability():
		_play_failure_sfx()
		return

	light_data.durability = light_data.durability_max
	if light_data.state == ToolData.STATE_BROKEN:
		light_data.state = ToolData.STATE_UNSELECTED
	tool_manager._sync_runtime_lookup()
	tool_manager.consumption_changed(ToolManager.Tool.BATTERY, -1)


func _sync_state_from_tool_manager() -> void:
	if not tool_manager:
		return
	state = tool_manager.get_tool_state(ToolManager.Tool.BATTERY)


func _can_use() -> bool:
	if not tool_manager or not tool_manager.player_now:
		return false

	var player = tool_manager.player_now
	if player.tool < 0 or player.tool >= player.tool_available.size():
		return false

	return (
		player.tool_available[player.tool] == ToolManager.Tool.BATTERY
		and state == ToolData.STATE_SELECTED
		and tool_manager.get_tool_consumption(ToolManager.Tool.BATTERY) > 0
	)


func _player_has_emergence_light() -> bool:
	var player = tool_manager.player_now
	if not player:
		return false
	return player.tool_available.has(ToolManager.Tool.EMERGENCELIGHT)


func _play_failure_sfx() -> void:
	if tool_manager and tool_manager.failure_sfx:
		tool_manager.failure_sfx.play_once()
