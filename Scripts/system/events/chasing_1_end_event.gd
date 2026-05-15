class_name Chasing1EndEvent
extends GameEvents

const JUMPSCARE_LAYER_INDEX: int = 9
const DEFAULT_JUMPSCARE_PLAYER_SCENE_PATH: String = "res://Effect/Animation/eye_jumpscare.tscn"

@export var wait_time: float = 1.0
@export_file("*.tscn") var jumpscare_player_scene_path: String = DEFAULT_JUMPSCARE_PLAYER_SCENE_PATH
@export var target_interactable_indices: Array[int] = []
@export var target_interactable_paths: Array[NodePath] = []

var _is_event_running: bool = false
var _jumpscare_canvas_layer: CanvasLayer = null
var _active_jumpscare_player: Node = null


func _ready() -> void:
	one_shot = true
	super._ready()


func trigger_condition() -> bool:
	if triggered_already or _is_event_running:
		return false
	if not GameManager.chasing_1_prepare:
		return false
	if not GameManager.has_method("is_chasing_1_eye_caught_pending"):
		return false

	return GameManager.is_chasing_1_eye_caught_pending()


func trigger_effect() -> void:
	if _is_event_running:
		return
	_run_event_flow.call_deferred()


func _run_event_flow() -> void:
	_is_event_running = true
	var player_node := GameManager.get_player()
	var preserved_health: float = GameManager.get_chasing_1_preserved_player_health() if GameManager.has_method("get_chasing_1_preserved_player_health") else 0.0
	if GameManager.has_method("clear_chasing_1_eye_caught_pending"):
		GameManager.clear_chasing_1_eye_caught_pending()

	GameManager.set_running_state(GameManager.RunningState.AUTO)
	_set_player_control_enabled(player_node, false)
	_set_player_invincible(player_node, true)
	_restore_player_health(player_node, preserved_health)

	var release_timer := get_tree().create_timer(max(wait_time, 0.0))
	_play_special_jumpscare()
	if wait_time > 0.0:
		await release_timer.timeout
	else:
		await get_tree().process_frame

	_release_eye_npcs()
	_apply_configured_interactable_states()

	GameManager.chasing_1_prepare = false
	GameManager.set_running_state(GameManager.RunningState.CONTROL)
	_set_player_invincible(player_node, false)
	_set_player_control_enabled(player_node, true)
	GameManager.state1_over = true
	_is_event_running = false


func _play_special_jumpscare() -> void:
	var scene_path := jumpscare_player_scene_path
	if scene_path.is_empty():
		scene_path = DEFAULT_JUMPSCARE_PLAYER_SCENE_PATH

	var packed := load(scene_path) as PackedScene
	if not packed:
		push_warning("Chasing1EndEvent: jumpscare_player scene not found: %s" % scene_path)
		return

	_clear_jumpscare_canvas_layer()
	_jumpscare_canvas_layer = CanvasLayer.new()
	_jumpscare_canvas_layer.name = "Chasing1JumpscareCanvasLayer"
	_jumpscare_canvas_layer.layer = JUMPSCARE_LAYER_INDEX
	get_tree().root.add_child(_jumpscare_canvas_layer)

	_active_jumpscare_player = packed.instantiate()
	_jumpscare_canvas_layer.add_child(_active_jumpscare_player)
	if _active_jumpscare_player.has_signal("oneshot_finished"):
		_active_jumpscare_player.connect("oneshot_finished", _on_jumpscare_player_finished, CONNECT_ONE_SHOT)
	if _active_jumpscare_player.has_method("play_oneshot"):
		_active_jumpscare_player.play_oneshot()
	elif _active_jumpscare_player.has_method("play_ontshot"):
		_active_jumpscare_player.play_ontshot()
	else:
		push_warning("Chasing1EndEvent: jumpscare_player missing play_oneshot(): %s" % scene_path)


func _on_jumpscare_player_finished() -> void:
	_clear_jumpscare_canvas_layer()


func _clear_jumpscare_canvas_layer() -> void:
	_active_jumpscare_player = null
	if _jumpscare_canvas_layer and is_instance_valid(_jumpscare_canvas_layer):
		_jumpscare_canvas_layer.queue_free()
	_jumpscare_canvas_layer = null


func _release_eye_npcs() -> void:
	var npc_mgr := get_node_or_null("/root/NPCManager")
	if not npc_mgr:
		push_warning("Chasing1EndEvent: NPCManager is missing, cannot release Eye.")
		return

	if npc_mgr.has_method("release_eye_npcs"):
		npc_mgr.release_eye_npcs()
		return

	push_warning("Chasing1EndEvent: NPCManager has no release_eye_npcs().")


func _apply_configured_interactable_states() -> void:
	var base_level := _find_base_level()
	if not base_level:
		push_warning("Chasing1EndEvent: BaseLevel not found, cannot update interactables.")
		return

	for index in target_interactable_indices:
		_apply_interactable_by_index(base_level, index)

	for interactable_path in target_interactable_paths:
		_apply_interactable_by_path(base_level, interactable_path)


func _apply_interactable_by_index(base_level: BaseLevel, index: int) -> void:
	if index < 0:
		push_warning("Chasing1EndEvent: invalid interactable index: %d" % index)
		return

	var interactable_data: InteractableData = null
	if base_level.current_scene_data and index < base_level.current_scene_data.interactables.size():
		interactable_data = base_level.current_scene_data.interactables[index]
	elif index < base_level.interactables.size():
		interactable_data = base_level.interactables[index]

	if not interactable_data:
		push_warning("Chasing1EndEvent: interactables[%d] is missing." % index)
		return

	_apply_interactable_state(base_level, interactable_data)


func _apply_interactable_by_path(base_level: BaseLevel, interactable_path: NodePath) -> void:
	if interactable_path == NodePath(""):
		return

	var interactable_data := base_level.get_interactable_by_path(interactable_path)
	if not interactable_data:
		push_warning("Chasing1EndEvent: interactable path not found: %s" % String(interactable_path))
		return

	_apply_interactable_state(base_level, interactable_data)


func _apply_interactable_state(base_level: BaseLevel, interactable_data: InteractableData) -> void:
	var new_state := _get_target_interactable_state(interactable_data)
	if new_state == interactable_data.state:
		_apply_interactable_state_to_node(base_level, interactable_data, new_state)
		return

	interactable_data.state = new_state
	if base_level.has_method("update_interactable_state"):
		base_level.update_interactable_state(interactable_data.node_path, new_state)
	_sync_base_level_interactable_state(base_level, interactable_data.node_path, new_state)
	_apply_interactable_state_to_node(base_level, interactable_data, new_state)


func _get_target_interactable_state(interactable_data: InteractableData) -> int:
	match interactable_data.type:
		2:
			return 0
		4:
			return 1
		_:
			push_warning("Chasing1EndEvent: interactable type %d is not dialogue/other, keep current state." % interactable_data.type)
			return interactable_data.state


func _sync_base_level_interactable_state(base_level: BaseLevel, target_path: NodePath, new_state: int) -> void:
	for interactable in base_level.interactables:
		if interactable and String(interactable.node_path) == String(target_path):
			interactable.state = new_state
			return


func _apply_interactable_state_to_node(base_level: BaseLevel, interactable_data: InteractableData, new_state: int) -> void:
	var target_node := base_level.get_node_or_null(interactable_data.node_path)
	if not target_node:
		push_warning("Chasing1EndEvent: target node not found: %s" % String(interactable_data.node_path))
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
		5:
			base_level.call("_apply_light_state", target_node, new_state)


func _set_player_control_enabled(player_node: player, enabled: bool) -> void:
	if not player_node or not is_instance_valid(player_node):
		return
	player_node.can_move = enabled
	player_node.can_interact = enabled
	player_node.can_act = enabled
	if not enabled:
		player_node.velocity = Vector2.ZERO


func _set_player_invincible(player_node: player, enabled: bool) -> void:
	var hurted_comp := _get_player_hurted_component(player_node)
	if not hurted_comp:
		return
	hurted_comp.set_invincible(enabled)


func _restore_player_health(player_node: player, preserved_health: float) -> void:
	if not player_node or not is_instance_valid(player_node):
		return
	if preserved_health > 0.0:
		player_node.health_now = preserved_health
	player_node.is_died = false
	var hurted_comp := _get_player_hurted_component(player_node)
	if hurted_comp:
		hurted_comp.sync_health_from_entity()


func _get_player_hurted_component(player_node: player) -> hurted_component:
	if not player_node or not is_instance_valid(player_node):
		return null
	return player_node.find_child("hurted_component", true, false) as hurted_component


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
