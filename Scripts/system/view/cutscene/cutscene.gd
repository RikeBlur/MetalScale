class_name Cutscene
extends Control

## 当子树内所有带 cutscene_finished_partly 的 Control 各发出一次后触发
signal cutscene_finished

var _remaining_partly: int = 0

@export var fadein_time : float = 0.5 

func _ready() -> void:
	# 延后一帧，确保子节点脚本已注册信号
	call_deferred("_setup_cutscene_parts")


func _setup_cutscene_parts() -> void:
	var parts: Array[Control] = []
	_collect_controls_with_partly_signal(self, parts)

	for ctrl in parts:
		_remaining_partly += 1
		ctrl.cutscene_finished_partly.connect(_on_child_cutscene_finished_partly, CONNECT_ONE_SHOT)

	if _remaining_partly == 0:
		cutscene_finished.emit()


func _collect_controls_with_partly_signal(node: Node, out: Array[Control]) -> void:
	for c in node.get_children():
		if c is Control:
			var ctrl: Control = c as Control
			if ctrl.has_signal("cutscene_finished_partly"):
				out.append(ctrl)
		_collect_controls_with_partly_signal(c, out)


func _on_child_cutscene_finished_partly() -> void:
	_remaining_partly -= 1
	if _remaining_partly <= 0:
		cutscene_finished.emit()
		print("Cutscene: 过场动画播放完毕")
