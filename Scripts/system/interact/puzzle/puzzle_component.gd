class_name PuzzleComponent
extends Node2D

signal puzzle_opened
signal puzzle_state_changed(state: int)

@export_range(0, 2, 1) var state: int = 1
@export var puzzle_ui_type: UI_manager.UI_component = UI_manager.UI_component.PUZZLESWITCH
@export var interactable_reminder: AnimatedSprite2D = null
@export var reminder_offset := Vector2(50, -80)

var can_collect_reminder = preload("res://System/RPG/interact/collectable/collectable_reminder.tscn")
var reminder_instance: Node = null

var interacted_component_node: interacted_component = null
var puzzle_content: Control = null
var _player_in_range := false


func _ready() -> void:
	_find_and_store_interacted_component()

	if interacted_component_node:
		_connect_signals()
	else:
		push_warning("PuzzleComponent: missing InteractedComponent child.")

	_apply_state_to_trigger()


func set_puzzle_state(new_state: int, from_content: bool = false) -> void:
	if new_state < 0 or new_state > 2:
		push_warning("PuzzleComponent: invalid puzzle state: %d" % new_state)
		return

	if state == new_state:
		_apply_state_to_trigger()
		_sync_open_puzzle_content_state(from_content)
		if from_content:
			_update_base_level_state()
		return

	var old_state := state
	state = new_state
	_apply_state_to_trigger()
	puzzle_state_changed.emit(state)
	_sync_open_puzzle_content_state(from_content)
	_update_base_level_state()

	if from_content and old_state != 2 and state == 2:
		print("谜题完成")


func set_puzzle_interactable(interactable: bool) -> void:
	set_puzzle_state(1 if interactable else 0)


func open_puzzle() -> void:
	if state != 1:
		return

	if not UIManager:
		push_warning("PuzzleComponent: missing UIManager.")
		return

	var ui_instance := UIManager.instantiate_ui(puzzle_ui_type)
	if not ui_instance:
		return

	puzzle_content = ui_instance as Control
	if ui_instance.has_method("setup_puzzle"):
		ui_instance.call("setup_puzzle", self, state)
	else:
		if ui_instance.has_method("attach_puzzle_component"):
			ui_instance.call("attach_puzzle_component", self)
		if ui_instance.has_method("set_puzzle_state"):
			ui_instance.call("set_puzzle_state", state)

	_lock_player_for_puzzle()
	InputEvents.show_mouse()
	puzzle_opened.emit()


func close_puzzle() -> void:
	if UIManager:
		UIManager.remove_ui(puzzle_ui_type)
	puzzle_content = null


func _connect_signals() -> void:
	if not interacted_component_node.be_interactable.is_connected(_on_be_interactable):
		interacted_component_node.be_interactable.connect(_on_be_interactable)
	if not interacted_component_node.be_not_interactable.is_connected(_on_be_not_interactable):
		interacted_component_node.be_not_interactable.connect(_on_be_not_interactable)
	if not interacted_component_node.interacted.is_connected(_on_interacted):
		interacted_component_node.interacted.connect(_on_interacted)


func _on_be_interactable() -> void:
	_player_in_range = true
	_spawn_reminder()


func _on_be_not_interactable() -> void:
	_player_in_range = false
	_destroy_reminder()


func _on_interacted() -> void:
	if state == 1:
		open_puzzle()


func _apply_state_to_trigger() -> void:
	var interactable := state == 1
	if not interactable:
		_player_in_range = false
		_destroy_reminder()

	if interacted_component_node and interacted_component_node.interacted_rage:
		interacted_component_node.interacted_rage.monitoring = interactable
		interacted_component_node.interacted_rage.monitorable = interactable

	if interactable and _player_in_range:
		_spawn_reminder()
	else:
		_destroy_reminder()

	_update_interactable_reminder()


func _spawn_reminder() -> void:
	if state != 1:
		_destroy_reminder()
		return

	if reminder_instance and is_instance_valid(reminder_instance):
		_destroy_reminder()

	reminder_instance = can_collect_reminder.instantiate()
	add_child(reminder_instance)
	reminder_instance.position = reminder_offset

	var animated_sprite = reminder_instance.get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.play()


func _destroy_reminder() -> void:
	if reminder_instance and is_instance_valid(reminder_instance):
		var animated_sprite = reminder_instance.get_node_or_null("AnimatedSprite2D")
		if animated_sprite:
			animated_sprite.pause()
		reminder_instance.queue_free()
		reminder_instance = null


func _update_interactable_reminder() -> void:
	if not interactable_reminder:
		return

	var should_show := state == 1
	interactable_reminder.visible = should_show
	if should_show:
		interactable_reminder.play()
	else:
		interactable_reminder.stop()


func _sync_open_puzzle_content_state(from_content: bool) -> void:
	if from_content:
		return
	if not puzzle_content or not is_instance_valid(puzzle_content):
		return
	if puzzle_content.has_method("set_puzzle_state"):
		puzzle_content.call("set_puzzle_state", state)


func _find_and_store_interacted_component() -> void:
	interacted_component_node = _find_interacted_component_recursive(self)


func _find_interacted_component_recursive(node: Node) -> interacted_component:
	for child in node.get_children():
		if child is interacted_component:
			return child
		var result := _find_interacted_component_recursive(child)
		if result:
			return result
	return null


func _update_base_level_state() -> void:
	var base_level = _find_base_level()
	if base_level:
		var target_path: Variant = get_path()
		if base_level.has_method("get_interactable_by_path") and not base_level.get_interactable_by_path(target_path):
			target_path = base_level.get_path_to(self)
		base_level.update_interactable_state(target_path, state)
	else:
		push_warning("PuzzleComponent: 未找到 BaseLevel，无法更新 interactables 状态")


func _lock_player_for_puzzle() -> void:
	GameManager.set_running_state(GameManager.RunningState.AUTO)
	var player_node = GameManager.get_player()
	if player_node:
		player_node.can_move = false
		player_node.can_interact = false
		player_node.can_act = false


func _find_base_level() -> BaseLevel:
	var current = get_parent()
	while current:
		if current is BaseLevel:
			return current
		current = current.get_parent()

	var root = get_tree().current_scene
	if root is BaseLevel:
		return root
	return _find_base_level_recursive(root)


func _find_base_level_recursive(node: Node) -> BaseLevel:
	if node is BaseLevel:
		return node

	for child in node.get_children():
		var result = _find_base_level_recursive(child)
		if result:
			return result

	return null
