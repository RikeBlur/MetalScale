class_name GameEvents
extends Node

const DEFAULT_GAME_EVENT_LIST: Array[Dictionary] = [
	{
		"event_name": "switch_on",
		"triggered_already": false
	},
	{
		"event_name": "gone_threefloor",
		"triggered_already": false
	},
	{
		"event_name": "chasing_1_start",
		"triggered_already": false
	},
	{
		"event_name": "chasing_1_end",
		"triggered_already": false
	}
]

@export var one_shot: bool = true
@export var event_name: String = ""

var triggered_already: bool = false


static func get_default_game_event_list() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event_state in DEFAULT_GAME_EVENT_LIST:
		result.append(event_state.duplicate(true))
	return result


func _ready() -> void:
	_initialize_event_state()


func _process(_delta: float) -> void:
	try_trigger()


func trigger_condition() -> bool:
	return false


func trigger_effect() -> void:
	pass


func try_trigger() -> bool:
	if one_shot and triggered_already:
		return false
	if not trigger_condition():
		return false

	triggered_already = true
	_sync_event_state_to_manager()
	trigger_effect()
	return true


func _initialize_event_state() -> void:
	if event_name.is_empty():
		event_name = name

	if not _has_game_manager():
		push_warning("GameEvents: GameManager is missing, event state will only live on this node.")
		return

	triggered_already = GameManager.get_game_event_triggered_already(event_name, triggered_already)
	GameManager.set_game_event_triggered_already(event_name, triggered_already)


func _sync_event_state_to_manager() -> void:
	if not _has_game_manager():
		return
	GameManager.set_game_event_triggered_already(event_name, triggered_already)


func _has_game_manager() -> bool:
	return get_node_or_null("/root/GameManager") != null
