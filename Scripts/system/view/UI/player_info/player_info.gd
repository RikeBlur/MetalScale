class_name PlayerInfo
extends Control

const TOOL_INFO_WINDOW_SCENE = preload("res://System/RPG/UI/windows/tool_info_window.tscn")
const TOOL_INFO_WINDOW_FADE_DURATION: float = 0.15

@export var player_now: CharacterBody2D = null
@export var tool_info : Control = null
@export var name_info : RichTextLabel = null
@export var state_info : RichTextLabel = null
@export var self_talk : RichTextLabel = null

var tool_boxes: Array[ToolboxInfo] = []
var tool_info_window: ToolInfoWindow = null
var _tool_info_window_tween: Tween = null
var _hovered_toolbox_info: ToolboxInfo = null
var _name_info_prefix: String = ""
var _state_info_prefix: String = ""

func _ready() -> void:
	_initialize_player()
	_initialize_nodes()
	_initialize_label_prefixes()
	_initialize_tool_info_window()
	_initialize_tool_boxes()
	_update_player_info()
	_update_tool_info()

func _process(_delta: float) -> void:
	if not player_now:
		_initialize_player()
		if not player_now:
			return

	_update_player_info()
	_update_tool_info()

func toolbox_info_on_hoven(toolbox_info_node: ToolboxInfo) -> void:
	if not toolbox_info_node or not tool_info_window:
		return

	_hovered_toolbox_info = toolbox_info_node
	var tool_type: ToolManager.Tool = toolbox_info_node.tool
	if tool_type == ToolManager.Tool.NONE:
		_hovered_toolbox_info = null
		_fade_out_tool_info_window()
		return

	tool_info_window.global_position = toolbox_info_node.global_position

	if tool_info_window.name_info:
		tool_info_window.name_info.text = ToolManager.get_tool_display_name(tool_type)
	if tool_info_window.description_info:
		tool_info_window.description_info.text = ToolManager.get_tool_description(tool_type)

	_fade_in_tool_info_window()

func toolbox_info_on_exit(toolbox_info_node: ToolboxInfo) -> void:
	if toolbox_info_node != _hovered_toolbox_info:
		return

	_hovered_toolbox_info = null
	_fade_out_tool_info_window()

func _initialize_player() -> void:
	if player_now:
		return
	player_now = GameManager.get_player() as CharacterBody2D

func _initialize_nodes() -> void:
	if not tool_info:
		tool_info = get_node_or_null("tool_info") as Control
	if not name_info:
		name_info = get_node_or_null("player_data/Name") as RichTextLabel
	if not state_info:
		state_info = get_node_or_null("player_data/State") as RichTextLabel
	if not self_talk:
		self_talk = get_node_or_null("self_talk/talk/label") as RichTextLabel

func _initialize_label_prefixes() -> void:
	if name_info:
		_name_info_prefix = _get_label_prefix(name_info.text)
	if state_info:
		_state_info_prefix = _get_label_prefix(state_info.text)

func _initialize_tool_info_window() -> void:
	tool_info_window = get_node_or_null("ToolInfoWindow") as ToolInfoWindow
	if not tool_info_window:
		tool_info_window = TOOL_INFO_WINDOW_SCENE.instantiate() as ToolInfoWindow
		tool_info_window.name = "ToolInfoWindow"
		add_child(tool_info_window)

	tool_info_window.hide()
	tool_info_window.modulate.a = 0.0
	_set_mouse_filter_recursive(tool_info_window, Control.MOUSE_FILTER_IGNORE)

func _initialize_tool_boxes() -> void:
	tool_boxes.clear()
	if not tool_info:
		return

	_collect_tool_boxes(tool_info)
	for toolbox_info_node in tool_boxes:
		var hoven_callable = Callable(self, "toolbox_info_on_hoven")
		if not toolbox_info_node.hoven.is_connected(hoven_callable):
			toolbox_info_node.hoven.connect(hoven_callable)
		var exit_callable = Callable(self, "toolbox_info_on_exit")
		if not toolbox_info_node.hover_exited.is_connected(exit_callable):
			toolbox_info_node.hover_exited.connect(exit_callable)

func _collect_tool_boxes(root: Node) -> void:
	for child in root.get_children():
		if child is ToolboxInfo:
			tool_boxes.append(child)
		_collect_tool_boxes(child)

func _set_mouse_filter_recursive(root: Node, mouse_filter_value: int) -> void:
	if root is Control:
		root.mouse_filter = mouse_filter_value
	for child in root.get_children():
		_set_mouse_filter_recursive(child, mouse_filter_value)

func _get_label_prefix(label_text: String) -> String:
	var chinese_colon_index = label_text.find("：")
	if chinese_colon_index >= 0:
		return label_text.substr(0, chinese_colon_index + 1)

	var colon_index = label_text.find(":")
	if colon_index >= 0:
		return label_text.substr(0, colon_index + 1)

	return ""

func _update_player_info() -> void:
	if not player_now:
		return

	if name_info:
		name_info.text = _name_info_prefix + player_now.character_name
	if state_info:
		state_info.text = _state_info_prefix + player_now.player_state_info
	if self_talk:
		self_talk.text = player_now.self_talk

func _update_tool_info() -> void:
	if not player_now or tool_boxes.is_empty():
		return

	for i in range(tool_boxes.size()):
		var tool_type: ToolManager.Tool = ToolManager.Tool.NONE
		if i < player_now.tool_available.size():
			tool_type = player_now.tool_available[i]

		var toolbox_info_node = tool_boxes[i]
		toolbox_info_node.set_tool_info(tool_type, ToolManager.get_tool_icon_static(tool_type))

func _fade_in_tool_info_window() -> void:
	if _tool_info_window_tween and _tool_info_window_tween.is_valid():
		_tool_info_window_tween.kill()

	tool_info_window.show()
	_tool_info_window_tween = create_tween()
	_tool_info_window_tween.tween_property(tool_info_window, "modulate:a", 1.0, TOOL_INFO_WINDOW_FADE_DURATION)

func _fade_out_tool_info_window() -> void:
	if not tool_info_window:
		return
	if _tool_info_window_tween and _tool_info_window_tween.is_valid():
		_tool_info_window_tween.kill()

	_tool_info_window_tween = create_tween()
	_tool_info_window_tween.tween_property(tool_info_window, "modulate:a", 0.0, TOOL_INFO_WINDOW_FADE_DURATION)
	_tool_info_window_tween.tween_callback(Callable(tool_info_window, "hide"))
