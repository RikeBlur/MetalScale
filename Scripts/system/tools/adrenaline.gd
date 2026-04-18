class_name Adrenaline
extends Node2D

@onready var success_sfx: AudioStreamPlayer2D = $SuccessSFX

var state: int = ToolData.STATE_UNSELECTED

var tool_manager: ToolManager = null
var player_now : CharacterBody2D = null

func _ready() -> void:
	var parent = get_parent()
	if parent and "player_now" in parent:
		player_now = parent.player_now
	tool_manager = get_parent() as ToolManager
	_sync_state_from_tool_manager()
	
func _process(_delta: float) -> void:
	_sync_state_from_tool_manager()

	if _can_use() and InputEvents.consume_once():
		adrenaline_release()
		tool_manager.consumption_changed(ToolManager.Tool.ADRENALINE, -1)

func adrenaline_release() -> void:
	if not player_now:
		push_warning("Adrenaline could not find a player reference.")
		return
	print("Adrenaline effect activated!")
	# Implement adrenaline effects here, e.g., temporary speed boost.

func _sync_state_from_tool_manager() -> void:
	if not tool_manager:
		return
	state = tool_manager.get_tool_state(ToolManager.Tool.ADRENALINE)

func _can_use() -> bool:
	if not tool_manager or not tool_manager.player_now:
		return false

	var player = tool_manager.player_now
	if player.tool < 0 or player.tool >= player.tool_available.size():
		return false

	return (
		player.tool_available[player.tool] == ToolManager.Tool.ADRENALINE
		and state == ToolData.STATE_SELECTED
		and tool_manager.get_tool_consumption(ToolManager.Tool.ADRENALINE) > 0
	)
