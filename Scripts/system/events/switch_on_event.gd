class_name SwitchOnEvent
extends GameEvents

@export var puzzle_component_path_1: NodePath = NodePath("")
@export var puzzle_component_path_2: NodePath = NodePath("")
@export var puzzle_component_path_3: NodePath = NodePath("")
@export var slay_melt_interactable_targets: Dictionary = {
	"1-8": [1],
	"1-7": [1],
	"1-0": [3],
	"1-1": [8, 9, 10, 11, 12, 13, 14, 15],
	"1-2": [1, 2],
	"1-4": [1],
}

var puzzle_component_1: PuzzleComponent = null
var puzzle_component_2: PuzzleComponent = null
var puzzle_component_3: PuzzleComponent = null


func _ready() -> void:
	one_shot = true
	super._ready()
	_resolve_puzzle_components()


func trigger_condition() -> bool:
	if triggered_already:
		return false
	if not _all_puzzle_components_valid():
		return false

	return (
		_is_puzzle_completed(puzzle_component_1)
		and _is_puzzle_completed(puzzle_component_2)
		and _is_puzzle_completed(puzzle_component_3)
	)


func trigger_effect() -> void:
	print("Switch ON!!!")
	# 开灯
	GameManager.default_lighting = GameManager.lighting_stage_1
	EnvironmentManager.set_environment()
	# 来人
	_show_ax_in_third_steproom_in_scene_data()
	_show_dialogue_in_third_steproom_in_scene_data()
	# 滚人
	_disappear_ax_in_teacher_rest_room_in_scene_data()
	_slay_all_melt_in_second_and_first_floor()
	# 开门
	_unlock_first_floor_corridor_door_in_scene_data()


func _show_ax_in_third_steproom_in_scene_data() -> void:
	if not SceneManager:
		push_warning("SwitchOnEvent: SceneManager is missing, cannot unlock 3-6 interactable 3.")
		return

	var scene_data: SceneData = SceneManager.get_scene_data("3-6")
	if not scene_data:
		push_warning("SwitchOnEvent: SceneData 3-6 is missing.")
		return

	if scene_data.interactables.size() <= 3:
		push_warning("SwitchOnEvent: SceneData 3-6 interactables size is %d, cannot access index 3." % scene_data.interactables.size())
		return

	var interactable: InteractableData = scene_data.interactables[3]
	if not interactable:
		push_warning("SwitchOnEvent: SceneData 3-6 interactables[3] is null.")
		return

	if interactable.type != 4:
		push_warning("SwitchOnEvent: SceneData 3-6 interactables[3] is not a others, type=%d." % interactable.type)
		return

	if interactable.state == 1:
		return

	interactable.state = 1
	print("SwitchOnEvent: SceneData 3-6 interactables[3] others state set to 1.")


func _show_dialogue_in_third_steproom_in_scene_data() -> void:
	if not SceneManager:
		push_warning("SwitchOnEvent: SceneManager is missing, cannot unlock 3-6 interactable 3.")
		return

	var scene_data: SceneData = SceneManager.get_scene_data("3-6")
	if not scene_data:
		push_warning("SwitchOnEvent: SceneData 3-6 is missing.")
		return

	if scene_data.interactables.size() <= 4:
		push_warning("SwitchOnEvent: SceneData 3-6 interactables size is %d, cannot access index 3." % scene_data.interactables.size())
		return

	var interactable: InteractableData = scene_data.interactables[4]
	if not interactable:
		push_warning("SwitchOnEvent: SceneData 3-6 interactables[4] is null.")
		return

	if interactable.type != 2:
		push_warning("SwitchOnEvent: SceneData 3-6 interactables[4] is not a others, type=%d." % interactable.type)
		return

	if interactable.state == 0:
		return

	interactable.state = 0
	print("SwitchOnEvent: SceneData 3-6 interactables[4] others state set to 0.")


func _disappear_ax_in_teacher_rest_room_in_scene_data() -> void:
	if not SceneManager:
		push_warning("SwitchOnEvent: SceneManager is missing, cannot unlock 2-0 interactable 2.")
		return

	var scene_data: SceneData = SceneManager.get_scene_data("2-0")
	if not scene_data:
		push_warning("SwitchOnEvent: SceneData 2-0 is missing.")
		return

	if scene_data.interactables.size() <= 2:
		push_warning("SwitchOnEvent: SceneData 2-0 interactables size is %d, cannot access index 2." % scene_data.interactables.size())
		return

	var interactable: InteractableData = scene_data.interactables[2]
	if not interactable:
		push_warning("SwitchOnEvent: SceneData 2-0 interactables[2] is null.")
		return

	if interactable.type != 4:
		push_warning("SwitchOnEvent: SceneData 2-0 interactables[2] is not a others, type=%d." % interactable.type)
		return

	if interactable.state == 0:
		return

	interactable.state = 0
	print("SwitchOnEvent: SceneData 2-0 interactables[2] others state set to 0.")


func _unlock_first_floor_corridor_door_in_scene_data() -> void:
	if not SceneManager:
		push_warning("SwitchOnEvent: SceneManager is missing, cannot unlock 1-1 interactable 7.")
		return

	var scene_data: SceneData = SceneManager.get_scene_data("1-1")
	if not scene_data:
		push_warning("SwitchOnEvent: SceneData 1-1 is missing.")
		return

	if scene_data.interactables.size() <= 7:
		push_warning("SwitchOnEvent: SceneData 1-1 interactables size is %d, cannot access index 7." % scene_data.interactables.size())
		return

	var interactable: InteractableData = scene_data.interactables[7]
	if not interactable:
		push_warning("SwitchOnEvent: SceneData 1-1 interactables[7] is null.")
		return

	if interactable.type != 0:
		push_warning("SwitchOnEvent: SceneData 1-1 interactables[7] is not a door, type=%d." % interactable.type)
		return

	if interactable.state == 0:
		return

	interactable.state = 0
	print("SwitchOnEvent: SceneData 1-1 interactables[7] door state set to 0.")


func _slay_all_melt_in_second_and_first_floor() -> void:
	var npc_mgr: Node = get_node_or_null("/root/NPCManager")
	if npc_mgr and npc_mgr.has_method("slay_npcs_by_numbered_prefix"):
		npc_mgr.call("slay_npcs_by_numbered_prefix", "1-")
	else:
		push_warning("SwitchOnEvent: NPCManager is missing, cannot slay 1-x NPCs.")

	_set_interactable_targets_state(slay_melt_interactable_targets, 1)


func _set_interactable_targets_state(targets: Dictionary, target_state: int) -> void:
	if not SceneManager:
		push_warning("SwitchOnEvent: SceneManager is missing, cannot update interactable targets.")
		return

	for scene_key_value in targets.keys():
		var scene_key: String = String(scene_key_value)
		var scene_data: SceneData = SceneManager.get_scene_data(scene_key)
		if not scene_data:
			push_warning("SwitchOnEvent: SceneData %s is missing." % scene_key)
			continue

		var indices: Array[int] = _get_interactable_indices(targets[scene_key_value])
		for index in indices:
			if index < 0 or index >= scene_data.interactables.size():
				push_warning("SwitchOnEvent: SceneData %s interactables size is %d, cannot access index %d." % [scene_key, scene_data.interactables.size(), index])
				continue

			var interactable: InteractableData = scene_data.interactables[index]
			if not interactable:
				push_warning("SwitchOnEvent: SceneData %s interactables[%d] is null." % [scene_key, index])
				continue

			if interactable.state == target_state:
				continue

			interactable.state = target_state
			print("SwitchOnEvent: SceneData %s interactables[%d] state set to %d." % [scene_key, index, target_state])


func _get_interactable_indices(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if value is Array:
		for raw_index in value:
			result.append(int(raw_index))
	else:
		result.append(int(value))
	return result


func _resolve_puzzle_components() -> void:
	puzzle_component_1 = _resolve_puzzle_component(puzzle_component_path_1, "puzzle_component_path_1")
	puzzle_component_2 = _resolve_puzzle_component(puzzle_component_path_2, "puzzle_component_path_2")
	puzzle_component_3 = _resolve_puzzle_component(puzzle_component_path_3, "puzzle_component_path_3")


func _resolve_puzzle_component(component_path: NodePath, path_name: String) -> PuzzleComponent:
	if component_path == NodePath(""):
		push_warning("SwitchOnEvent: %s is empty." % path_name)
		return null

	var component := get_node_or_null(component_path) as PuzzleComponent
	if component == null:
		push_warning("SwitchOnEvent: %s does not point to a PuzzleComponent: %s" % [path_name, component_path])
		return null

	return component


func _all_puzzle_components_valid() -> bool:
	return (
		puzzle_component_1 != null and is_instance_valid(puzzle_component_1)
		and puzzle_component_2 != null and is_instance_valid(puzzle_component_2)
		and puzzle_component_3 != null and is_instance_valid(puzzle_component_3)
	)


func _is_puzzle_completed(component: PuzzleComponent) -> bool:
	return component != null and is_instance_valid(component) and (component.state == 2 or component.state == 3)
