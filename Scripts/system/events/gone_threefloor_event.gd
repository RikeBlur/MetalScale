class_name GoneThreefloorEvent
extends GameEvents

@export var trigger_area : Area2D = null
@export var gone_instance : npc_gone = null
@export var gone_destination : Vector2 = Vector2.ZERO
@export var camera_offset : Vector2 = Vector2.ZERO
@export var last_time : float = 0.0
@export var camera_move_time : float = 0.8
@export var gone_stop_distance : float = 4.0

var _is_event_running: bool = false
var _camera_tween: Tween = null


func trigger_condition() -> bool:
	if triggered_already or _is_event_running:
		return false
	if trigger_area == null or not is_instance_valid(trigger_area):
		return false

	var player_node := GameManager.get_player()
	if player_node == null or not is_instance_valid(player_node):
		return false

	return trigger_area.get_overlapping_bodies().has(player_node)


func trigger_effect() -> void:
	if _is_event_running:
		return
	_run_event_flow.call_deferred()


func _run_event_flow() -> void:
	_is_event_running = true
	print("GoneThreeFloor 触发了！")

	var player_node := GameManager.get_player()
	var camera := GameManager.get_camera()
	var old_camera_target: Node2D = null
	var camera_start_offset := Vector2.ZERO

	GameManager.set_running_state(GameManager.RunningState.AUTO)

	if gone_instance and is_instance_valid(gone_instance):
		gone_instance.run_to_position(gone_destination, gone_stop_distance)
	else:
		push_warning("GoneThreefloorEvent: gone_instance is missing.")

	if camera and is_instance_valid(camera):
		old_camera_target = camera.target
		camera_start_offset = camera.offset
		camera.target = null
		_tween_camera_offset_to(camera, camera_start_offset + camera_offset)
	else:
		push_warning("GoneThreefloorEvent: camera is missing.")

	if last_time > 0.0:
		await get_tree().create_timer(last_time).timeout
	else:
		await get_tree().process_frame

	if camera and is_instance_valid(camera):
		await _tween_camera_offset_to(camera, camera_start_offset)
		camera.target = old_camera_target if old_camera_target != null and is_instance_valid(old_camera_target) else player_node

	if gone_instance and is_instance_valid(gone_instance):
		gone_instance.stop_movement()
		gone_instance.queue_free()

	_set_base_level_interactable_8_state(0)
	GameManager.set_running_state(GameManager.RunningState.CONTROL)
	_is_event_running = false


func _tween_camera_offset_to(camera: AdvancedCamera, target_offset: Vector2) -> void:
	if _camera_tween and _camera_tween.is_valid():
		_camera_tween.kill()
	_camera_tween = null

	var tween_time: float = max(camera_move_time, 0.0)
	if tween_time == 0.0:
		camera.offset = target_offset
		return

	_camera_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_property(camera, "offset", target_offset, tween_time)
	await _camera_tween.finished
	_camera_tween = null


func _set_base_level_interactable_8_state(new_state: int) -> void:
	var base_level := _find_base_level()
	if base_level == null:
		push_warning("GoneThreefloorEvent: BaseLevel not found, cannot update interactables[8].")
		return

	var interactable_data: InteractableData = null
	if base_level.interactables.size() > 8:
		interactable_data = base_level.interactables[8]
		if interactable_data:
			interactable_data.state = new_state

	if base_level.current_scene_data and base_level.current_scene_data.interactables.size() > 8:
		var scene_interactable: InteractableData = base_level.current_scene_data.interactables[8]
		if scene_interactable:
			scene_interactable.state = new_state
			if interactable_data == null:
				interactable_data = scene_interactable

	if interactable_data == null:
		push_warning("GoneThreefloorEvent: interactables[8] is missing.")
		return

	if base_level.has_method("update_interactable_state"):
		base_level.update_interactable_state(interactable_data.node_path, new_state)
	_apply_interactable_state_to_node(base_level, interactable_data, new_state)


func _apply_interactable_state_to_node(base_level: BaseLevel, interactable_data: InteractableData, new_state: int) -> void:
	var target_node := base_level.get_node_or_null(interactable_data.node_path)
	if target_node == null:
		return

	match interactable_data.type:
		0:
			base_level.call("_apply_door_state", target_node, new_state)
		1:
			base_level.call("_apply_collectible_state", target_node, new_state)
		2:
			base_level.call("_apply_dialogue_state", target_node, new_state)
		3:
			base_level.call("_apply_puzzle_state", target_node, new_state)
		4:
			base_level.call("_apply_other_state", target_node, new_state)


func _find_base_level() -> BaseLevel:
	var current: Node = self
	while current:
		if current is BaseLevel:
			return current as BaseLevel
		current = current.get_parent()

	var current_scene := get_tree().current_scene
	if current_scene is BaseLevel:
		return current_scene as BaseLevel
	return null
