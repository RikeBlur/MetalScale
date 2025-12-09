class_name ArrgoComponent
extends Node2D

@export var detector : light_detector = null
@export var get_caught_threshold : float = 0.05

var caught : bool = false
var _last_caught : bool = false

signal get_caught
signal get_uncaught


func _ready() -> void:
	if not detector:
		push_warning("ArrgoComponent: detector 未设置")
		return
	
	# 初始化状态
	_update_caught_state()
	_last_caught = caught


func _process(_delta: float) -> void:
	if not detector:
		return
	
	# 更新 caught 状态
	_update_caught_state()
	
	# 检测状态反转
	if caught != _last_caught:
		if caught:
			# 从 false 变为 true，被发现
			emit_signal("get_caught")
			print("ArrgoComponent: 被发现！intensity: %.3f > threshold: %.3f" % [detector.intensity_now, get_caught_threshold])
		else:
			# 从 true 变为 false，脱离视线
			emit_signal("get_uncaught")
			print("ArrgoComponent: 脱离视线。intensity: %.3f <= threshold: %.3f" % [detector.intensity_now, get_caught_threshold])
		
		_last_caught = caught


func _update_caught_state() -> void:
	"""根据 detector 的 intensity_now 更新 caught 状态"""
	if detector.intensity_now > get_caught_threshold:
		caught = true
	else:
		caught = false
