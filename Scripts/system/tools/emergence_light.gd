class_name EmergenceLight
extends Node2D

@export var light_fade_duration: float = 0.2

@onready var success_sfx: AudioStreamPlayer2D = $SuccessSFX
@onready var radial_light: PointLight2D = $PointLight2D

var state: int = ToolData.STATE_UNSELECTED
var tool_manager: ToolManager = null
var _light_tween: Tween = null

func _ready() -> void:
	tool_manager = get_parent() as ToolManager
	_sync_state_from_tool_manager()
	_apply_light_energy_for_state(false)

func _process(_delta: float) -> void:
	var previous_state := state
	_sync_state_from_tool_manager()
	if previous_state != state:
		_apply_light_energy_for_state(true)

	if _can_toggle() and InputEvents.consume_once():
		_toggle_light()

func _sync_state_from_tool_manager() -> void:
	if not tool_manager:
		return
	state = tool_manager.get_tool_state(ToolManager.Tool.EMERGENCELIGHT)

func _can_toggle() -> bool:
	if not tool_manager or not tool_manager.player_now:
		return false

	var player = tool_manager.player_now
	if player.tool < 0 or player.tool >= player.tool_available.size():
		return false

	return (
		player.tool_available[player.tool] == ToolManager.Tool.EMERGENCELIGHT
		and (state == ToolData.STATE_SELECTED or state == ToolData.STATE_ACTIVE)
	)

func _toggle_light() -> void:
	if state == ToolData.STATE_SELECTED:
		_set_state(ToolData.STATE_ACTIVE)
		_fade_light_energy(1.0)
	elif state == ToolData.STATE_ACTIVE:
		_set_state(ToolData.STATE_SELECTED)
		_fade_light_energy(0.0)

func _set_state(new_state: int) -> void:
	state = new_state
	if tool_manager:
		tool_manager.set_tool_state(ToolManager.Tool.EMERGENCELIGHT, new_state)

func _apply_light_energy_for_state(animated: bool) -> void:
	var target_energy := 1.0 if state == ToolData.STATE_ACTIVE else 0.0
	if animated:
		_fade_light_energy(target_energy)
	elif radial_light:
		radial_light.energy = target_energy

func _fade_light_energy(target_energy: float) -> void:
	if not radial_light:
		return
	if _light_tween and _light_tween.is_valid():
		_light_tween.kill()

	_light_tween = create_tween()
	_light_tween.tween_property(radial_light, "energy", target_energy, light_fade_duration)
