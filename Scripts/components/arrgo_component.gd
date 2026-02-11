class_name ArrgoComponent
extends Node2D

@export var detector : light_detector = null
@export var get_caught_threshold : float = 0.05
@export var aggro_increase_rate : float = 0.2
@export var aggro_decrease_rate : float = 0.15

var caught : bool = false
var _last_caught : bool = false
var _aggro_timer : float = 0.0
var _decay_timer : float = 0.0
@export var player_node: player = null

var intensity : float = 0.0

signal get_caught
signal get_uncaught


func _ready() -> void:
	if not detector:
		push_warning("ArrgoComponent: detector 未设置")
		return
	
	# 初始化状态
	_update_caught_state()
	_last_caught = caught
	
	# 连接信号
	get_caught.connect(on_into_arrgo)
	get_uncaught.connect(on_out_arrgo)


func _process(delta: float) -> void:
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
	
	# 持续仇恨增长
	if caught:
		intensity = detector.intensity_now
		on_durring_arrgo(delta, intensity)
	else:
		on_not_during_arrgo(delta)


func _update_caught_state() -> void:
	"""根据 detector 的 intensity_now 更新 caught 状态"""
	if detector.intensity_now > get_caught_threshold:
		caught = true
	else:
		caught = false


func on_into_arrgo() -> void:
	"""进入仇恨状态时调用"""
	_aggro_timer = 0.0


func on_out_arrgo() -> void:
	"""脱离仇恨状态时调用"""
	_aggro_timer = 0.0
	_decay_timer = 0.0


func on_durring_arrgo(delta: float, intensity_now:float) -> void:
	"""持续仇恨状态时调用（每帧）"""
	var target_player = _get_player()
	if not target_player:
		return
	
	# 增长速度随时间递增（平方曲线）
	_aggro_timer += delta
	var growth = aggro_increase_rate * (1.0 + _aggro_timer * _aggro_timer) * intensity_now
	target_player.aggro_value = clamp(target_player.aggro_value + growth * delta, 0.0, 100.0)

func on_not_during_arrgo(delta: float) -> void:
	"""非仇恨状态时调用（每帧），aggro_value 随时间平方衰减，不低于 0"""
	var target_player = _get_player()
	if not target_player:
		return
	
	# 衰减速度随时间平方递增（脱战越久减得越快）
	_decay_timer += delta
	var decay = aggro_decrease_rate * (1.0 + _decay_timer * _decay_timer) * 5
	target_player.aggro_value = clamp(target_player.aggro_value - decay * delta, 0.0, 100.0)


func _get_player() -> player:
	"""获取玩家引用"""
	if player_node and is_instance_valid(player_node):
		return player_node
	
	var parent = get_parent()
	if parent is player:
		player_node = parent
		return player_node
	
	return GameManager.get_player()
