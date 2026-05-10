class_name PuzzleContent
extends Control

signal puzzle_done

@export var puzzle_component_path: NodePath = NodePath("")
@export var ui_fade_time := 0.2

var own_manager: UI_manager = null
var ui_type: UI_manager.UI_component = UI_manager.UI_component.PUZZLESWITCH
var puzzle_component: Node = null
var interactive_nodes: Array[Node] = []
var state_list: Array = []
var _ui_fade_tween: Tween = null
var _done_emitted := false


func _ready() -> void:
	if puzzle_component_path != NodePath(""):
		puzzle_component = _resolve_node(puzzle_component_path)


func _process(_delta: float) -> void:
	_refresh_state_list()
	if not visible or _done_emitted or not _is_component_interactable():
		return

	if judge_function(state_list):
		_emit_done_once()


# =========================== 核心函数 =============================

func judge_function(_states: Array) -> bool:
	return false

func reward_function() -> void:
	if puzzle_component and puzzle_component.has_method("set_puzzle_state"):
		puzzle_component.call("set_puzzle_state", 2, true)

func _get_control_state(node: Node) -> Variant:
	if node is BaseButton:
		return 1 if (node as BaseButton).button_pressed else 0
	if node is NumberSwitch and node.has_method("get_puzzle_value"):
		return node.call("get_puzzle_value")
	if node is Label:
		return (node as Label).text
	if node is RichTextLabel:
		return (node as RichTextLabel).text
	return null
	
# =========================== 工具函数 ============================

func attach_puzzle_component(component: Node) -> void:
	puzzle_component = component


func setup_puzzle(component: Node, _state: int = 1) -> void:
	attach_puzzle_component(component)


func set_reward_function(callable: Callable) -> void:
	if callable.is_valid():
		puzzle_done.connect(callable, CONNECT_ONE_SHOT)


func play_ui_enter() -> void:
	show()
	process_mode = Node.PROCESS_MODE_INHERIT
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 0.0
	_kill_ui_fade_tween()
	_ui_fade_tween = create_tween()
	_ui_fade_tween.set_trans(Tween.TRANS_CUBIC)
	_ui_fade_tween.set_ease(Tween.EASE_OUT)
	_ui_fade_tween.tween_property(self, "modulate:a", 1.0, max(ui_fade_time, 0.0))


func play_ui_exit(finished: Callable = Callable()) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kill_ui_fade_tween()
	_ui_fade_tween = create_tween()
	_ui_fade_tween.set_trans(Tween.TRANS_CUBIC)
	_ui_fade_tween.set_ease(Tween.EASE_IN)
	_ui_fade_tween.tween_property(self, "modulate:a", 0.0, max(ui_fade_time, 0.0))
	_ui_fade_tween.tween_callback(func() -> void:
		process_mode = Node.PROCESS_MODE_DISABLED
		_restore_player_control_after_close()
		if finished.is_valid():
			finished.call()
	)


func close_self() -> void:
	if own_manager:
		own_manager.remove_ui(ui_type)


func _kill_ui_fade_tween() -> void:
	if _ui_fade_tween and _ui_fade_tween.is_valid():
		_ui_fade_tween.kill()
	_ui_fade_tween = null


func _restore_player_control_after_close() -> void:
	GameManager.set_running_state(GameManager.RunningState.CONTROL)
	var player_node = GameManager.get_player()
	if player_node:
		player_node.can_move = true
		player_node.can_interact = true
		player_node.can_act = true
	InputEvents.hide_mouse()


func _emit_done_once() -> void:
	if _done_emitted:
		return
	_done_emitted = true
	reward_function()
	_set_all_controls_interactable(false)
	puzzle_done.emit()


func _refresh_state_list() -> void:
	interactive_nodes.clear()
	state_list.clear()
	_collect_interactive_controls(self)


func _collect_interactive_controls(node: Node) -> void:
	for child in node.get_children():
		if _is_recorded_control(child):
			interactive_nodes.append(child)
			state_list.append(_get_control_state(child))
		_collect_interactive_controls(child)


func _is_recorded_control(node: Node) -> bool:
	return node is BaseButton or node is NumberSwitch or node is Label or node is RichTextLabel


func _set_all_controls_interactable(interactable: bool) -> void:
	_set_controls_interactable_recursive(self, interactable)


func _set_controls_interactable_recursive(node: Node, interactable: bool) -> void:
	if node is Control:
		var control := node as Control
		control.mouse_filter = Control.MOUSE_FILTER_STOP if interactable else Control.MOUSE_FILTER_IGNORE
		control.focus_mode = Control.FOCUS_ALL if interactable else Control.FOCUS_NONE
	if node is BaseButton:
		(node as BaseButton).disabled = not interactable

	for child in node.get_children():
		_set_controls_interactable_recursive(child, interactable)


func _is_component_interactable() -> bool:
	if not puzzle_component or not is_instance_valid(puzzle_component):
		return true
	if "state" in puzzle_component:
		return puzzle_component.state == 1 or puzzle_component.state == 3
	return true


func _resolve_node(path: NodePath) -> Node:
	if path == NodePath(""):
		return null

	var node := get_node_or_null(path)
	if node:
		return node

	var root := get_tree().current_scene
	if root:
		return root.get_node_or_null(path)
	return null
