class_name DemoEndEvent
extends GameEvents

const DEMO_END_BLACKOUT_LAYER_INDEX: int = 4

@export var end_door: BaseDoor = null
@export var blackout_fade_time: float = 0.5

var _interaction_requested: bool = false
var _is_event_running: bool = false
var _connected_interacted_component: interacted_component = null
var _demo_end_blackout_layer: CanvasLayer = null
var _demo_end_blackout_rect: ColorRect = null
var _demo_end_blackout_tween: Tween = null


func _ready() -> void:
	one_shot = true
	if event_name.is_empty():
		event_name = "demo_end"
	super._ready()
	_connect_end_door_signal_deferred.call_deferred()


func trigger_condition() -> bool:
	if triggered_already or _is_event_running:
		return false
	if not _interaction_requested:
		return false

	_interaction_requested = false
	if not GameManager.state1_over:
		return false
	if end_door == null or not is_instance_valid(end_door):
		push_warning("DemoEndEvent: end_door is missing.")
		return false

	var player_node: player = GameManager.get_player()
	if player_node == null or not is_instance_valid(player_node):
		push_warning("DemoEndEvent: player is missing.")
		return false

	return true


func trigger_effect() -> void:
	if _is_event_running:
		return
	_run_event_flow.call_deferred()


func _on_end_door_interacted() -> void:
	if triggered_already or _is_event_running:
		return
	if not GameManager.state1_over:
		return

	_disconnect_base_door_interacted_handler()
	if end_door and is_instance_valid(end_door):
		end_door.state = 2
	_interaction_requested = true


func _run_event_flow() -> void:
	_is_event_running = true
	GameManager.set_running_state(GameManager.RunningState.AUTO)
	_lock_player_control()
	_mark_end_1_completed()
	await _fade_in_demo_end_blackout_mask()

	var played_cutscene: bool = _play_demo_end_cutscene()

	if played_cutscene and CutsceneManager.has_signal("cutscene_playback_finished"):
		await CutsceneManager.cutscene_playback_finished
	else:
		await get_tree().process_frame

	if GameManager.has_method("return_to_opening_menu_after_demo_end"):
		await GameManager.return_to_opening_menu_after_demo_end()
	else:
		push_error("DemoEndEvent: GameManager.return_to_opening_menu_after_demo_end() is missing.")

	_is_event_running = false


func _play_demo_end_cutscene() -> bool:
	if not CutsceneManager or not CutsceneManager.has_method("play_cutscene"):
		push_warning("DemoEndEvent: CutsceneManager is missing.")
		return false
	if not _has_demo_end_cutscene():
		push_warning("DemoEndEvent: CutsceneManager has no 'demo_end' cutscene.")
		return false

	CutsceneManager.play_cutscene("demo_end")
	return true


func _has_demo_end_cutscene() -> bool:
	var scenes_value: Variant = CutsceneManager.get("cutscene_scenes")
	if not (scenes_value is Dictionary):
		return false
	var scenes: Dictionary = scenes_value
	return scenes.has("demo_end")


func _mark_end_1_completed() -> void:
	if GameManager.has_method("set_end_1_completed"):
		GameManager.set_end_1_completed(true, true)
		return

	GameManager.end_1 = true
	if GameManager.config_data:
		GameManager.config_data.end_1 = true
	GameManager.save_config()


func _lock_player_control() -> void:
	var player_node: player = GameManager.get_player()
	if player_node == null or not is_instance_valid(player_node):
		return
	player_node.can_move = false
	player_node.can_interact = false
	player_node.can_act = false
	player_node.velocity = Vector2.ZERO


func _ensure_demo_end_blackout_mask() -> void:
	if _demo_end_blackout_layer and is_instance_valid(_demo_end_blackout_layer):
		_demo_end_blackout_layer.visible = true
		return
	if not get_tree().current_scene:
		return

	_demo_end_blackout_layer = CanvasLayer.new()
	_demo_end_blackout_layer.name = "DemoEndBlackoutLayer"
	_demo_end_blackout_layer.layer = DEMO_END_BLACKOUT_LAYER_INDEX

	var black_rect := ColorRect.new()
	black_rect.name = "Blackout"
	black_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	black_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_demo_end_blackout_layer.add_child(black_rect)
	black_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black_rect.position = Vector2.ZERO
	black_rect.size = get_viewport().get_visible_rect().size
	_demo_end_blackout_rect = black_rect

	get_tree().current_scene.add_child(_demo_end_blackout_layer)


func _fade_in_demo_end_blackout_mask() -> void:
	_ensure_demo_end_blackout_mask()
	if not _demo_end_blackout_rect or not is_instance_valid(_demo_end_blackout_rect):
		await get_tree().process_frame
		return

	if _demo_end_blackout_tween and is_instance_valid(_demo_end_blackout_tween):
		_demo_end_blackout_tween.kill()

	var fade_time: float = max(blackout_fade_time, 0.0)
	if fade_time <= 0.0:
		_demo_end_blackout_rect.color = Color.BLACK
		await get_tree().process_frame
		return

	_demo_end_blackout_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_demo_end_blackout_tween.tween_property(_demo_end_blackout_rect, "color:a", 1.0, fade_time)
	await _demo_end_blackout_tween.finished


func _connect_end_door_signal_deferred() -> void:
	for _i in range(8):
		if _connect_end_door_signal():
			return
		await get_tree().process_frame
	push_warning("DemoEndEvent: failed to connect end_door interaction signal.")


func _connect_end_door_signal() -> bool:
	if end_door == null or not is_instance_valid(end_door):
		return false

	var component: interacted_component = end_door.interacted_component_node
	if component == null or not is_instance_valid(component):
		return false

	var event_callable: Callable = Callable(self, "_on_end_door_interacted")
	var door_callable: Callable = Callable(end_door, "_on_door_interacted")
	var door_was_connected: bool = component.interacted.is_connected(door_callable)
	if door_was_connected:
		component.interacted.disconnect(door_callable)

	if not component.interacted.is_connected(event_callable):
		component.interacted.connect(event_callable)

	if door_was_connected and not component.interacted.is_connected(door_callable):
		component.interacted.connect(door_callable)

	_connected_interacted_component = component
	return true


func _disconnect_base_door_interacted_handler() -> void:
	if _connected_interacted_component == null or not is_instance_valid(_connected_interacted_component):
		return

	var door_callable: Callable = Callable(end_door, "_on_door_interacted")
	if _connected_interacted_component.interacted.is_connected(door_callable):
		_connected_interacted_component.interacted.disconnect(door_callable)
