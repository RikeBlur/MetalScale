class_name SFXPlayer
extends AudioStreamPlayer2D

# ====================================================================================================
# ============================================ 配置参数 ================================================
# ====================================================================================================

# 是否为单次播放模式
# - true: 使用play_once()，每次播放一次
# - false: 使用play_start()/play_stop()，循环播放（带淡入淡出）
@export var one_shot: bool = true

# 基础音量（dB），在此基础上应用BGM_gain
@export var base_volume_db: float = 0.0

# 淡入淡出时间（秒），仅用于Loop模式
@export var fade_duration: float = 0.5

# ====================================================================================================
# ============================================ 内部变量 ================================================
# ====================================================================================================

# 是否正在播放
var is_playing: bool = false

# 淡入淡出状态（仅Loop模式使用）
var is_fading: bool = false
var fade_start_volume: float = 0.0
var fade_target_volume: float = 0.0
var fade_progress: float = 0.0

# ====================================================================================================
# ============================================ 生命周期 ================================================
# ====================================================================================================

func _ready() -> void:
	# 初始化音量
	_update_volume()
	
	# 连接播放完成信号
	finished.connect(_on_finished)

func _process(delta: float) -> void:
	# 处理淡入淡出（仅Loop模式）
	if not one_shot and is_fading:
		_process_fade(delta)

# ====================================================================================================
# ========================================== OneShot模式 ===============================================
# ====================================================================================================

func play_once() -> void:
	"""
	单次播放模式：播放一次音效
	如果正在播放，则从头开始重新播放
	"""
	if not one_shot:
		push_warning("SFXPlayer: play_once() 只能在 one_shot=true 时使用")
		return
	
	# 更新音量
	_update_volume()
	
	# 停止当前播放并从头开始
	stop()
	play()
	is_playing = true

# ====================================================================================================
# ========================================== Loop模式 =================================================
# ====================================================================================================

func play_start() -> void:
	"""
	循环播放模式：开始播放（带淡入效果）
	"""
	if one_shot:
		push_warning("SFXPlayer: play_start() 只能在 one_shot=false 时使用")
		return
	
	# 如果正在淡入中，不重复开始
	if is_playing and is_fading and fade_target_volume > -70.0:
		return
	
	# 获取目标音量
	var target_volume = _get_target_volume()
	
	# 如果正在淡出，从当前音量淡入（更平滑）
	var start_volume = -80.0
	if is_fading and fade_target_volume <= -79.0:
		# 正在淡出，从当前音量开始淡入
		start_volume = volume_db
	else:
		# 从静音开始
		volume_db = -80.0
	
	# 如果还没开始播放，启动播放
	if not playing:
		play()
	
	is_playing = true
	
	# 开始淡入
	_start_fade(start_volume, target_volume)

func play_stop() -> void:
	"""
	循环播放模式：停止播放（带淡出效果）
	"""
	if one_shot:
		push_warning("SFXPlayer: play_stop() 只能在 one_shot=false 时使用")
		return
	
	# 如果没在播放，直接返回
	if not is_playing:
		return
	
	# 开始淡出到静音
	_start_fade(volume_db, -80.0)

# ====================================================================================================
# ========================================== 音量控制 =================================================
# ====================================================================================================

func _update_volume() -> void:
	"""从GameManager读取BGM_gain并更新音量"""
	volume_db = _get_target_volume()

func _get_target_volume() -> float:
	"""获取目标音量（dB）"""
	var gain = 1.0
	if GameManager and is_instance_valid(GameManager):
		gain = GameManager.BGM_gain / 100.0
	return base_volume_db + linear_to_db(gain)

func _start_fade(from_vol: float, to_vol: float) -> void:
	"""开始淡入淡出"""
	is_fading = true
	fade_start_volume = from_vol
	fade_target_volume = to_vol
	fade_progress = 0.0
	volume_db = from_vol

func _process_fade(delta: float) -> void:
	"""处理淡入淡出进度"""
	# 边界检查
	if fade_duration <= 0.0:
		# 如果淡入淡出时间为0，立即完成
		is_fading = false
		volume_db = fade_target_volume
		if fade_target_volume <= -79.0:
			stop()
			is_playing = false
		return
	
	# 更新进度
	fade_progress += delta / fade_duration
	fade_progress = clamp(fade_progress, 0.0, 1.0)
	
	# 平滑插值
	var t = ease(fade_progress, -2.0)  # ease-out
	volume_db = lerp(fade_start_volume, fade_target_volume, t)
	
	# 完成淡入淡出
	if fade_progress >= 1.0:
		is_fading = false
		volume_db = fade_target_volume
		
		# 如果淡出到静音，停止播放
		if fade_target_volume <= -79.0:
			stop()
			is_playing = false

# ====================================================================================================
# ========================================== 信号回调 =================================================
# ====================================================================================================

func _on_finished() -> void:
	"""播放完成回调"""
	if one_shot:
		is_playing = false
	else:
		# Loop模式下如果音频结束，说明循环可能没设置好
		if not is_fading or fade_target_volume > -70.0:
			push_warning("SFXPlayer [%s]: Loop模式下音频意外结束，可能循环未设置" % name)
			is_playing = false
			is_fading = false

# ====================================================================================================
# ========================================== 公共方法 =================================================
# ====================================================================================================

func force_stop() -> void:
	"""立即停止播放（无淡出效果）"""
	stop()
	is_playing = false
	is_fading = false

func is_currently_playing() -> bool:
	"""返回当前是否正在播放"""
	return is_playing

func set_base_volume(volume: float) -> void:
	"""设置基础音量（dB）"""
	base_volume_db = volume
	_update_volume()

func set_fade_duration(duration: float) -> void:
	"""设置淡入淡出时间（秒）"""
	fade_duration = max(0.0, duration)
