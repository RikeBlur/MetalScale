class_name cutscene_manager
extends Node

signal cutscene_playback_finished

class SkipRingIndicator:
	extends Control

	var progress: float = 0.0

	func set_progress(value: float) -> void:
		progress = clamp(value, 0.0, 1.0)
		visible = progress > 0.0
		queue_redraw()

	func _draw() -> void:
		var center: Vector2 = size * 0.5
		var radius: float = min(size.x, size.y) * 0.36
		var start_angle: float = -PI * 0.5
		var end_angle: float = start_angle + TAU * progress
		draw_arc(center, radius, 0.0, TAU, 96, Color(0.0, 0.0, 0.0, 0.45), 7.0, true)
		if progress > 0.0:
			draw_arc(center, radius, start_angle, end_angle, 96, Color(1.0, 1.0, 1.0, 0.95), 5.0, true)

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================

# ====================================================================================================
# ===================================== 配置 ========================================================
# ====================================================================================================

## 过场动画层级（CanvasLayer.layer）
const CANVAS_LAYER_INDEX: int = 5
## 淡入/淡出时长（秒）
const FADE_DURATION: float = 0.5

@export var skipping_time_limit: float = 1.5

# ====================================================================================================
# ===================================== 数据表 ======================================================
# ====================================================================================================

# 过场动画场景注册表：key → PackedScene（preload）
# 在此处填写过场动画，例如：
#   "intro": preload("res://System/Cutscenes/intro.tscn"),
var cutscene_scenes: Dictionary = {
	"test": preload("res://System/RPG/cutscene/1_1/test.tscn")
}

# 过场动画信号注册表：key → Array[Callable]
# 通过 register_cutscene_signal / connect_cutscene_signal / emit_cutscene_signal 管理
var _cutscene_signal_map: Dictionary = {

}

# ====================================================================================================
# ===================================== 运行时状态 ==================================================
# ====================================================================================================

var _active_canvas_layer: CanvasLayer = null
var _active_cutscene_node: Node = null
var _active_tween: Tween = null
var _active_fade_duration: float = FADE_DURATION
var _skip_hold_time: float = 0.0
var _skip_indicator: SkipRingIndicator = null
var _is_finishing_cutscene: bool = false

# 播放前快照，用于恢复
var _prev_running_state: GameManager.RunningState = GameManager.RunningState.NOPE
var _prev_player_can_move: bool = true
var _prev_player_can_interact: bool = true

# ====================================================================================================
# ===================================== 过场动画播放 ================================================
# ====================================================================================================

func play_cutscene(key: String) -> void:
	"""
	实例化并播放一个过场动画

	参数：
		key: 在 cutscene_scenes 中注册的场景 key

	流程：
		1. 禁用 player 的 can_move / can_interact，RunningState → AUTO
		2. 在当前场景树下创建 CanvasLayer（layer=5，初始不可见）
		3. 实例化对应 PackedScene 并挂入 CanvasLayer
		4. CanvasLayer 变为可见，过场节点 modulate.a 从 0 平滑淡入到 1
		5. 收到 cutscene_finished 信号后平滑淡出，销毁，恢复状态
	"""
	if not cutscene_scenes.has(key):
		push_warning("CutsceneManager: 未找到过场动画 '%s'" % key)
		return

	if is_instance_valid(_active_canvas_layer):
		push_warning("CutsceneManager: 已有过场动画正在播放，忽略 '%s'" % key)
		return

	_is_finishing_cutscene = false
	_reset_skip_state()

	var packed: PackedScene = cutscene_scenes[key]
	if not packed:
		push_warning("CutsceneManager: 过场动画场景为 null: '%s'" % key)
		return

	# 记录并修改游戏状态
	_prev_running_state = GameManager.get_running_state()
	GameManager.set_running_state(GameManager.RunningState.AUTO)

	# 保存并禁用 player 输入
	var p: player = GameManager.get_player()
	if p and is_instance_valid(p):
		_prev_player_can_move = p.can_move
		_prev_player_can_interact = p.can_interact
		p.can_move = false
		p.can_interact = false

	# 创建 CanvasLayer（初始不可见，避免未就绪时的闪烁）
	_active_canvas_layer = CanvasLayer.new()
	_active_canvas_layer.layer = CANVAS_LAYER_INDEX
	_active_canvas_layer.visible = false
	get_tree().current_scene.add_child(_active_canvas_layer)

	# 实例化过场动画，modulate.a 初始为 0
	_active_cutscene_node = packed.instantiate()
	_active_cutscene_node.modulate.a = 0.0
	_active_canvas_layer.add_child(_active_cutscene_node)
	_active_fade_duration = _resolve_fade_duration(_active_cutscene_node)
	_create_skip_indicator()

	# 等一帧，确保 _ready 执行完毕后再连接信号和淡入
	await get_tree().process_frame

	# 连接 cutscene_finished 信号
	if _active_cutscene_node.has_signal("cutscene_finished"):
		_active_cutscene_node.cutscene_finished.connect(_on_cutscene_finished, CONNECT_ONE_SHOT)
	else:
		push_warning("CutsceneManager: 过场动画 '%s' 没有 cutscene_finished 信号，需手动调用 finish_cutscene()" % key)

	# 显示 CanvasLayer，过场节点 modulate.a 从 0 淡入到 1
	_active_canvas_layer.visible = true
	_kill_active_tween()
	_active_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_active_tween.tween_property(_active_cutscene_node, "modulate:a", 1.0, _active_fade_duration)

	print("CutsceneManager: 过场动画 '%s' 开始播放" % key)


func finish_cutscene() -> void:
	"""
	手动触发过场动画结束（当过场动画节点不发出 cutscene_finished 信号时，外部调用）
	"""
	_on_cutscene_finished()


func _on_cutscene_finished() -> void:
	"""接收到 cutscene_finished 后：淡出 → 销毁 → 恢复状态"""
	if not is_instance_valid(_active_canvas_layer):
		return
	if _is_finishing_cutscene:
		return

	_is_finishing_cutscene = true
	_reset_skip_state()

	# 淡出
	_kill_active_tween()
	_active_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if is_instance_valid(_active_cutscene_node):
		_active_tween.tween_property(_active_cutscene_node, "modulate:a", 0.0, _active_fade_duration)
	else:
		_active_tween.tween_interval(_active_fade_duration)

	var tween_ref: Tween = _active_tween
	await tween_ref.finished

	# 淡出完成后销毁（仅在 tween 未被中断时执行）
	if not is_instance_valid(tween_ref) or tween_ref != _active_tween:
		return

	if is_instance_valid(_active_canvas_layer):
		_active_canvas_layer.queue_free()
	_active_canvas_layer = null
	_active_cutscene_node = null
	_active_tween = null
	_active_fade_duration = FADE_DURATION
	_skip_indicator = null
	_is_finishing_cutscene = false

	# 恢复游戏状态
	GameManager.set_running_state(_prev_running_state)

	# 恢复 player 输入
	var p: player = GameManager.get_player()
	if p and is_instance_valid(p):
		p.can_move = _prev_player_can_move
		p.can_interact = _prev_player_can_interact

	print("CutsceneManager: 过场动画播放完毕，状态已恢复")
	cutscene_playback_finished.emit()


func _process(delta: float) -> void:
	_update_skip_input(delta)

# ====================================================================================================
# ===================================== 过场动画信号 ================================================
# ====================================================================================================

func register_cutscene_signal(key: String) -> void:
	"""
	注册一个过场动画信号 key（若已存在则跳过）

	参数：
		key: 信号 key
	"""
	if not _cutscene_signal_map.has(key):
		_cutscene_signal_map[key] = []
		print("CutsceneManager: 已注册过场动画信号 '%s'" % key)


func connect_cutscene_signal(key: String, callable: Callable) -> void:
	"""
	连接到某个 key 对应的过场动画信号（若 key 尚未注册则自动注册）

	参数：
		key:      信号 key
		callable: 触发时调用的函数
	"""
	if not _cutscene_signal_map.has(key):
		register_cutscene_signal(key)
	var listeners: Array = _cutscene_signal_map[key]
	if not listeners.has(callable):
		listeners.append(callable)


func disconnect_cutscene_signal(key: String, callable: Callable) -> void:
	"""
	断开某个 key 对应的过场动画信号连接

	参数：
		key:      信号 key
		callable: 要断开的函数
	"""
	if not _cutscene_signal_map.has(key):
		return
	_cutscene_signal_map[key].erase(callable)


func emit_cutscene_signal(key: String) -> void:
	"""
	发出某个 key 对应的过场动画信号，依次调用所有已连接的 Callable

	参数：
		key: 信号 key
	"""
	if not _cutscene_signal_map.has(key):
		push_warning("CutsceneManager: 信号 '%s' 未注册" % key)
		return
	for callable: Callable in _cutscene_signal_map[key]:
		if callable.is_valid():
			callable.call()
	print("CutsceneManager: 已发出过场动画信号 '%s'" % key)

# ====================================================================================================
# ===================================== 工具函数 ====================================================
# ====================================================================================================

func _update_skip_input(delta: float) -> void:
	if not is_instance_valid(_active_canvas_layer) or _is_finishing_cutscene:
		_reset_skip_state()
		return

	if not Input.is_key_pressed(KEY_ESCAPE):
		_reset_skip_state()
		return

	var limit: float = max(skipping_time_limit, 0.001)
	_skip_hold_time = min(_skip_hold_time + delta, limit)
	_set_skip_indicator_progress(_skip_hold_time / limit)

	if _skip_hold_time >= limit:
		finish_cutscene()


func _create_skip_indicator() -> void:
	if not is_instance_valid(_active_canvas_layer):
		return
	if is_instance_valid(_skip_indicator):
		return

	_skip_indicator = SkipRingIndicator.new()
	_skip_indicator.name = "CutsceneSkipIndicator"
	_skip_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_indicator.custom_minimum_size = Vector2(64.0, 64.0)
	_skip_indicator.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_skip_indicator.offset_left = 24.0
	_skip_indicator.offset_right = 88.0
	_skip_indicator.offset_top = -88.0
	_skip_indicator.offset_bottom = -24.0
	_skip_indicator.set_progress(0.0)
	_active_canvas_layer.add_child(_skip_indicator)


func _set_skip_indicator_progress(progress: float) -> void:
	if not is_instance_valid(_skip_indicator):
		_create_skip_indicator()
	if is_instance_valid(_skip_indicator):
		_skip_indicator.set_progress(progress)


func _reset_skip_state() -> void:
	_skip_hold_time = 0.0
	if is_instance_valid(_skip_indicator):
		_skip_indicator.set_progress(0.0)


func _kill_active_tween() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null


func _resolve_fade_duration(cutscene_node: Node) -> float:
	if not cutscene_node:
		return FADE_DURATION
	if "fadein_time" in cutscene_node:
		var fade_time: float = float(cutscene_node.fadein_time)
		if fade_time > 0.0:
			return fade_time
	return FADE_DURATION

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
