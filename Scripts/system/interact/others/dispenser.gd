class_name Dispenser
extends Node2D

@export var interacted_com: interacted_component = null
@export var player_node: player = null
@export var sfx_player: SFXPlayer = null
@export var dialogue: DialogueComponent = null
@export var use_or_not: Control = null
@export var required_tool: ToolManager.Tool = ToolManager.Tool.SUICIDEKING
@export var reward_collectable: CollectableComponent = null

@onready var yes_button: Button = $CanvasLayer/use_or_not/Panel/Container/MarginContainer/VBoxContainer/choices/yes
@onready var no_button: Button = $CanvasLayer/use_or_not/Panel/Container/MarginContainer/VBoxContainer/choices/no
@onready var use_label: Label = $CanvasLayer/use_or_not/Panel/Container/MarginContainer/VBoxContainer/Label

var _use_or_not_opened: bool = false
var _dialogue_running: bool = false


func _ready() -> void:
	if not interacted_com:
		interacted_com = _find_interacted_component(self)
	if not sfx_player:
		sfx_player = get_node_or_null("SFXPlayer") as SFXPlayer
	if not dialogue:
		dialogue = get_node_or_null("dialogue") as DialogueComponent
	if not use_or_not:
		use_or_not = get_node_or_null("CanvasLayer/use_or_not") as Control
	if not player_node:
		player_node = GameManager.get_player()

	_connect_signals()
	_update_use_or_not_label()
	_hide_use_or_not()


func _process(_delta: float) -> void:
	if not _use_or_not_opened:
		return
	if Input.is_action_just_pressed("quit"):
		_close_use_or_not()


func _connect_signals() -> void:
	if interacted_com and not interacted_com.interacted.is_connected(_on_interacted):
		interacted_com.interacted.connect(_on_interacted)
	elif not interacted_com:
		push_warning("Dispenser: 未找到 interacted_component")

	if yes_button and not yes_button.pressed.is_connected(_on_yes_pressed):
		yes_button.pressed.connect(_on_yes_pressed)
	if no_button and not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)


func _on_interacted() -> void:
	if _use_or_not_opened or _dialogue_running:
		return
	if GameManager.player_arrgo != 0:
		return

	player_node = _get_player()
	if not player_node:
		push_warning("Dispenser: 找不到 player 节点")
		return

	if _is_have_required_tool():
		_show_use_or_not()
	else:
		_play_no_required_tool_dialogue()


func _on_yes_pressed() -> void:
	if not _use_or_not_opened:
		return

	if not _is_have_required_tool():
		_close_use_or_not(false)
		_play_no_required_tool_dialogue()
		return

	_close_use_or_not()
	dispenser_interact()


func _on_no_pressed() -> void:
	_close_use_or_not()


func dispenser_interact() -> bool:
	if not _is_have_required_tool():
		return false

	_play_sfx()
	return _consume_required_tool_and_trigger_reward()


func _show_use_or_not() -> void:
	_update_use_or_not_label()
	if use_or_not:
		use_or_not.visible = true

	_use_or_not_opened = true
	if player_node and is_instance_valid(player_node):
		player_node.can_move = false
		player_node.can_interact = false
	GameManager.set_running_state(GameManager.RunningState.MENU)
	InputEvents.show_mouse()


func _close_use_or_not(restore_control: bool = true) -> void:
	_hide_use_or_not()
	_use_or_not_opened = false

	if restore_control:
		_restore_player_control()


func _hide_use_or_not() -> void:
	if use_or_not:
		use_or_not.visible = false


func _restore_player_control() -> void:
	player_node = _get_player()
	if player_node and is_instance_valid(player_node):
		player_node.can_move = true
		player_node.can_interact = true
	GameManager.set_running_state(GameManager.RunningState.CONTROL)
	InputEvents.hide_mouse()


func _is_have_required_tool() -> bool:
	if required_tool == ToolManager.Tool.NONE:
		return true

	var current_player := _get_player()
	if not current_player:
		return false
	if not current_player.tool_available.has(required_tool):
		return false

	var tool_manager := current_player.get_node_or_null("ToolManager") as ToolManager
	if not tool_manager:
		return true

	var consumption := tool_manager.get_tool_consumption(required_tool)
	return consumption != 0


func _consume_required_tool_and_trigger_reward() -> bool:
	var current_player := _get_player()
	if not current_player:
		return false

	if not _can_trigger_reward_collectable():
		return false

	var consumed_slot_index := -1
	if required_tool != ToolManager.Tool.NONE:
		var tool_index := current_player.tool_available.find(required_tool)
		if tool_index < 0:
			return false
		current_player.tool_available[tool_index] = ToolManager.Tool.NONE
		consumed_slot_index = tool_index

	var reward_collected := _trigger_reward_collectable()
	if not reward_collected and consumed_slot_index >= 0 and current_player.tool_available[consumed_slot_index] == ToolManager.Tool.NONE:
		current_player.tool_available[consumed_slot_index] = required_tool
	return reward_collected


func _can_trigger_reward_collectable() -> bool:
	if not reward_collectable or not is_instance_valid(reward_collectable):
		push_warning("Dispenser: 未配置 reward_collectable，无法发放物品")
		return false
	if not reward_collectable.interacted_component_node and reward_collectable.has_method("_find_and_store_interacted_component"):
		reward_collectable.call("_find_and_store_interacted_component")
	if not reward_collectable.interacted_component_node:
		push_warning("Dispenser: reward_collectable 缺少 interacted_component_node")
		return false
	if reward_collectable.collectable_state == 0:
		push_warning("Dispenser: reward_collectable 已被领取或不可领取")
		return false
	if not reward_collectable.has_method("_on_collected"):
		push_warning("Dispenser: reward_collectable 缺少 _on_collected()")
		return false
	return true


func _trigger_reward_collectable() -> bool:
	if not _can_trigger_reward_collectable():
		return false

	reward_collectable.call("_on_collected")
	return reward_collectable.collectable_state == 0


func _play_no_required_tool_dialogue() -> void:
	if not dialogue or not is_instance_valid(dialogue):
		return
	_dialogue_running = true
	dialogue.trigger_dialogue()
	_wait_for_dialogue_finished()


func _wait_for_dialogue_finished() -> void:
	await get_tree().process_frame
	while dialogue and is_instance_valid(dialogue) and _dialogue_has_active_instance():
		await get_tree().process_frame
	_dialogue_running = false


func _dialogue_has_active_instance() -> bool:
	if not dialogue.canvas_layer or not is_instance_valid(dialogue.canvas_layer):
		return false
	return dialogue.canvas_layer.get_child_count() > 0


func _play_sfx() -> void:
	if sfx_player and sfx_player.has_method("play_once"):
		sfx_player.play_once()
	elif sfx_player:
		sfx_player.play()


func _update_use_or_not_label() -> void:
	if not use_label:
		return
	use_label.text = "是否使用 %s" % ToolManager.get_tool_display_name(required_tool)


func _get_player() -> player:
	if player_node and is_instance_valid(player_node):
		return player_node
	player_node = GameManager.get_player()
	return player_node


func _find_interacted_component(root: Node) -> interacted_component:
	if root is interacted_component:
		return root
	for child in root.get_children():
		var result := _find_interacted_component(child)
		if result:
			return result
	return null
