class_name safebox
extends PuzzleContent

@export var target_number: Array[int] = [1, 1, 1]
@export var number_switch_paths: Array[NodePath] = []
@export var current_number: Array[int] = []
@export var success_sfx: SFXPlayer = null
@export var reward_collectable: CollectableComponent = null
@export var reward_collectable_path: NodePath = NodePath("")


func _ready() -> void:
	super._ready()
	_sync_current_number()


func judge_function(_states: Array) -> bool:
	_sync_current_number()

	if target_number.is_empty():
		return false
	if current_number.size() != target_number.size():
		return false

	for i in range(target_number.size()):
		if current_number[i] != target_number[i]:
			return false
	return true


func reward_function() -> void:
	if success_sfx:
		success_sfx.play_once()
	super.reward_function()
	_trigger_reward_collectable()


func _sync_current_number() -> void:
	current_number.clear()
	for number_switch in _get_number_switches():
		current_number.append(number_switch.switch_number)


func _get_number_switches() -> Array[NumberSwitch]:
	var number_switches: Array[NumberSwitch] = []
	if not number_switch_paths.is_empty():
		for path in number_switch_paths:
			var node := get_node_or_null(path)
			if node is NumberSwitch:
				number_switches.append(node)
		return number_switches

	_collect_number_switches_recursive(self, number_switches)
	return number_switches


func _collect_number_switches_recursive(node: Node, out: Array[NumberSwitch]) -> void:
	for child in node.get_children():
		if child is NumberSwitch:
			out.append(child)
		_collect_number_switches_recursive(child, out)


func _trigger_reward_collectable() -> void:
	var target_collectable := _get_reward_collectable()
	if not target_collectable:
		push_warning("Safebox: 未配置 reward_collectable，无法发放奖励")
		return
	if not target_collectable.interacted_component_node and target_collectable.has_method("_find_and_store_interacted_component"):
		target_collectable.call("_find_and_store_interacted_component")
	if not target_collectable.interacted_component_node:
		push_warning("Safebox: reward_collectable 缺少 interacted_component_node")
		return
	if target_collectable.collectable_state == 0:
		push_warning("Safebox: reward_collectable 已被领取或不可领取")
		return
	if not target_collectable.has_method("_on_collected"):
		push_warning("Safebox: reward_collectable 缺少 _on_collected()")
		return

	target_collectable.call("_on_collected")


func _get_reward_collectable() -> CollectableComponent:
	if reward_collectable and is_instance_valid(reward_collectable):
		return reward_collectable
	if reward_collectable_path == NodePath(""):
		return null

	var node := get_node_or_null(reward_collectable_path)
	if not node and get_tree().current_scene:
		node = get_tree().current_scene.get_node_or_null(reward_collectable_path)
	return node as CollectableComponent
