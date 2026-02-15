class_name SavePoint
extends Node2D

@export var interacted_com: interacted_component = null
@export var player_node: CharacterBody2D = null
@export var sfx: SFXPlayer = null

var save_window_inst: Node = null
var _window_opened: bool = false

func _ready() -> void:
	if not interacted_com:
		interacted_com = _find_interacted_component(self)
	if interacted_com and not interacted_com.interacted.is_connected(_on_interacted):
		interacted_com.interacted.connect(_on_interacted)
	else:
		push_warning("SavePoint: 未找到 interacted_component")

	if not player_node:
		player_node = GameManager.get_player()

func _process(_delta: float) -> void:
	if not _window_opened:
		return

	# 窗口已被其他逻辑关闭（例如窗口内按钮关闭）时，自动恢复玩家控制
	if not is_instance_valid(save_window_inst):
		_restore_player_control()
		return

	# 允许使用 quit 键关闭存档窗口
	if Input.is_action_just_pressed("quit"):
		UIManager.remove_ui(UI_manager.UI_component.SAVEGAMEWINDOW)
		_restore_player_control()

func _on_interacted() -> void:
	if not player_node:
		player_node = GameManager.get_player()
	if not player_node:
		push_error("SavePoint: 找不到 player 节点")
		return

	# 防止重复创建
	if _window_opened and is_instance_valid(save_window_inst):
		return

	player_node.can_move = false
	player_node.can_interact = false
	GameManager.set_running_state(GameManager.RunningState.MENU)
	InputEvents.show_mouse()

	save_window_inst = UIManager.instantiate_ui(UI_manager.UI_component.SAVEGAMEWINDOW)
	_window_opened = is_instance_valid(save_window_inst)
	if not _window_opened:
		_restore_player_control()
		return

	sfx.play_once()

func _restore_player_control() -> void:
	if player_node and is_instance_valid(player_node):
		player_node.can_move = true
		player_node.can_interact = true
	GameManager.set_running_state(GameManager.RunningState.CONTROL)
	InputEvents.hide_mouse()
	save_window_inst = null
	_window_opened = false

func _find_interacted_component(root: Node) -> interacted_component:
	if root is interacted_component:
		return root
	for child in root.get_children():
		var result := _find_interacted_component(child)
		if result:
			return result
	return null
