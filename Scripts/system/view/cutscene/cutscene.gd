class_name Cutscene
extends Control

## 当子树内所有带 cutscene_finished_partly 的 Control 各发出一次后触发
signal cutscene_finished

var _remaining_partly: int = 0
var _input_available_at_msec: int = 0
var _cutscene_finished_emitted: bool = false

@export var fadein_time : float = 0.5 

# 按任意键继续
@export var any_key_continue : bool = false
@export var buffer_time : float = 0.5


func _ready() -> void:
	_input_available_at_msec = Time.get_ticks_msec() + int(max(buffer_time, 0.0) * 1000.0)
	set_process_unhandled_input(any_key_continue)
	# 延后一帧，确保子节点脚本已注册信号
	call_deferred("_setup_cutscene_parts")


func _setup_cutscene_parts() -> void:
	var parts: Array[Control] = []
	_collect_controls_with_partly_signal(self, parts)

	for ctrl in parts:
		_remaining_partly += 1
		ctrl.cutscene_finished_partly.connect(_on_child_cutscene_finished_partly, CONNECT_ONE_SHOT)

	if _remaining_partly == 0 and not any_key_continue:
		_finish_cutscene()


func _collect_controls_with_partly_signal(node: Node, out: Array[Control]) -> void:
	for c in node.get_children():
		if c is Control:
			var ctrl: Control = c as Control
			if ctrl.has_signal("cutscene_finished_partly"):
				out.append(ctrl)
		_collect_controls_with_partly_signal(c, out)


func _on_child_cutscene_finished_partly() -> void:
	_remaining_partly -= 1
	if any_key_continue:
		return
	if _remaining_partly <= 0:
		_finish_cutscene()


func _unhandled_input(event: InputEvent) -> void:
	if not any_key_continue or _cutscene_finished_emitted:
		return
	if Time.get_ticks_msec() < _input_available_at_msec:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_finish_cutscene()
	elif event is InputEventJoypadButton and event.pressed:
		_finish_cutscene()


func _finish_cutscene() -> void:
	if _cutscene_finished_emitted:
		return
	_cutscene_finished_emitted = true
	cutscene_finished.emit()
	print("Cutscene: 过场动画播放完毕")
