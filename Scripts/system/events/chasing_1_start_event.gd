class_name Chasing1StartEvent
extends GameEvents

@export var trigger_area: Area2D = null
@export var blink_seq: Node = null
@export var lock_time: float = 1.0

var _player_entered: bool = false
var _is_event_running: bool = false


func _ready() -> void:
	one_shot = true
	super._ready()
	if trigger_area:
		if not trigger_area.body_entered.is_connected(_on_trigger_area_body_entered):
			trigger_area.body_entered.connect(_on_trigger_area_body_entered)


func trigger_condition() -> bool:
	if triggered_already or _is_event_running:
		return false
	if not trigger_area or not is_instance_valid(trigger_area):
		return false

	var player_node := GameManager.get_player()
	if not player_node or not is_instance_valid(player_node):
		return false

	return _player_entered or trigger_area.get_overlapping_bodies().has(player_node)


func trigger_effect() -> void:
	if _is_event_running:
		return
	_run_event_flow.call_deferred()


func _run_event_flow() -> void:
	_is_event_running = true
	var player_node := GameManager.get_player()

	GameManager.set_running_state(GameManager.RunningState.AUTO)
	_set_player_control_enabled(player_node, false)
	_emit_blink_seq_start()
	GameManager.chasing_1_prepare = true

	if lock_time > 0.0:
		await get_tree().create_timer(lock_time).timeout
	else:
		await get_tree().process_frame

	GameManager.set_running_state(GameManager.RunningState.CONTROL)
	_set_player_control_enabled(player_node, true)

	_is_event_running = false


func _on_trigger_area_body_entered(body: Node2D) -> void:
	var player_node := GameManager.get_player()
	if player_node and is_instance_valid(player_node) and body == player_node:
		_player_entered = true


func _emit_blink_seq_start() -> void:
	if not blink_seq or not is_instance_valid(blink_seq):
		push_warning("Chasing1StartEvent: blink_seq is missing.")
		return
	if not blink_seq.has_signal("blink_seq_start"):
		push_warning("Chasing1StartEvent: blink_seq has no blink_seq_start signal.")
		return

	blink_seq.emit_signal("blink_seq_start")


func _set_player_control_enabled(player_node: player, enabled: bool) -> void:
	if not player_node or not is_instance_valid(player_node):
		return
	player_node.can_move = enabled
	player_node.can_interact = enabled
	player_node.can_act = enabled
	if not enabled:
		player_node.velocity = Vector2.ZERO
