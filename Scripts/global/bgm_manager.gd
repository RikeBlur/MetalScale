class_name bgm_manager
extends Node

# ====================================================================================================
# ===================================== 配置 ========================================================
# ====================================================================================================

## BGM 列表：key 为名字，value 为 mp3 文件路径
## 在此处添加 BGM 条目，"default" 为启动时自动播放的 BGM
var bgm_list: Dictionary = {
	"default": "res://Assests/SFX/bgm/Rain_Medium_2.mp3",
	"arrgoing": "res://Assests/SFX/bgm/white-noise.mp3",
	"arrgoed": "res://Assests/SFX/bgm/scary-slam.mp3",
	# "battle":  "res://Assests/BGM/battle.mp3",
}

# ====================================================================================================
# ===================================== 运行时状态 ==================================================
# ====================================================================================================

var bgm_player: AudioStreamPlayer2D = null
var _current_key: String = ""
var _bgm_fade_tweens: Dictionary = {}
var _arrgoed_sfx_players: Array[AudioStreamPlayer2D] = []

@export var bgm_crossfade_duration: float = 0.75

# ====================================================================================================
# ===================================== 初始化 ======================================================
# ====================================================================================================

func _ready() -> void:
	_connect_arrgo_signals()
	_setup_bgm_player.call_deferred()

func _setup_bgm_player() -> void:
	"""创建 bgm_player 节点，加载 default BGM 并开始播放"""
	if bgm_player and is_instance_valid(bgm_player):
		return

	bgm_player = _create_audio_player("bgm_player")
	add_child(bgm_player)

	if bgm_list.has("default") and bgm_list["default"] != "":
		var stream: AudioStream = _load_stream("default", true)
		if stream:
			bgm_player.stream = stream
			_current_key = "default"
			_set_player_fade(0.0, bgm_player)
			bgm_player.play()
			_fade_player(bgm_player, 1.0, bgm_crossfade_duration)
			print("BGMManager: 开始播放 default BGM")
		else:
			push_warning("BGMManager: 无法加载 default BGM: %s" % bgm_list["default"])
	else:
		print("BGMManager: 未配置 default BGM，跳过自动播放")

# ====================================================================================================
# ===================================== 音量同步 ====================================================
# ====================================================================================================

func _process(_delta: float) -> void:
	_apply_volume()

func _apply_volume() -> void:
	"""将 GameManager.BGM_gain（0~100）同步到所有 BGMManager 管理的播放器"""
	if bgm_player and is_instance_valid(bgm_player):
		_apply_player_volume(bgm_player)

	for arrgoed_player in _arrgoed_sfx_players:
		if arrgoed_player and is_instance_valid(arrgoed_player):
			_apply_player_volume(arrgoed_player)

func _get_target_volume_db(fade: float = 1.0) -> float:
	var gain: float = clamp(GameManager.BGM_gain, 0.0, 100.0) / 100.0
	var linear_volume: float = clamp(gain * fade, 0.0, 1.0)
	if linear_volume <= 0.0:
		return -80.0
	return linear_to_db(linear_volume)

func _apply_player_volume(arrgoed_player: AudioStreamPlayer2D) -> void:
	if not arrgoed_player or not is_instance_valid(arrgoed_player):
		return
	var fade: float = float(arrgoed_player.get_meta("bgm_fade", 1.0))
	arrgoed_player.volume_db = _get_target_volume_db(fade)

func _set_player_fade(fade: float, arrgoed_player: AudioStreamPlayer2D) -> void:
	if not arrgoed_player or not is_instance_valid(arrgoed_player):
		return
	arrgoed_player.set_meta("bgm_fade", clamp(fade, 0.0, 1.0))
	_apply_player_volume(arrgoed_player)

# ====================================================================================================
# ===================================== 公开接口 ====================================================
# ====================================================================================================

func set_bgm(key: String) -> void:
	"""
	切换 BGM

	参数：
		key: bgm_list 中注册的 BGM 名字
	"""
	if not bgm_list.has(key):
		push_warning("BGMManager: 未找到 BGM '%s'" % key)
		return

	if _current_key == key and bgm_player and is_instance_valid(bgm_player) and bgm_player.playing:
		return

	var stream: AudioStream = _load_stream(key, true)
	if not stream:
		return

	var old_player: AudioStreamPlayer2D = bgm_player
	var new_player: AudioStreamPlayer2D = _create_audio_player("bgm_player_%s" % key)
	new_player.stream = stream
	_set_player_fade(0.0, new_player)
	add_child(new_player)
	new_player.play()

	bgm_player = new_player
	_current_key = key

	_fade_player(new_player, 1.0, bgm_crossfade_duration)
	if old_player and is_instance_valid(old_player):
		_fade_player(old_player, 0.0, bgm_crossfade_duration, true)

	print("BGMManager: 切换到 BGM '%s'" % key)

# ====================================================================================================
# ===================================== arrgo ====================================================
# ====================================================================================================

func _connect_arrgo_signals() -> void:
	if not GameManager.get_in_arrgo.is_connected(_on_get_in_arrgo):
		GameManager.get_in_arrgo.connect(_on_get_in_arrgo)
	if not GameManager.get_out_arrgo.is_connected(_on_get_out_arrgo):
		GameManager.get_out_arrgo.connect(_on_get_out_arrgo)
	if not GameManager.arrgoed.is_connected(_on_arrgoed):
		GameManager.arrgoed.connect(_on_arrgoed)

func _on_get_in_arrgo() -> void:
	set_bgm("arrgoing")

func _on_get_out_arrgo() -> void:
	set_bgm("default")

func _on_arrgoed() -> void:
	_play_arrgoed_one_shot()

func _play_arrgoed_one_shot() -> void:
	var stream: AudioStream = _load_stream("arrgoed", false)
	if not stream:
		return

	var sfx_player: AudioStreamPlayer2D = _create_audio_player("arrgoed_sfx_player")
	sfx_player.stream = stream
	_set_player_fade(1.0, sfx_player)
	add_child(sfx_player)
	_arrgoed_sfx_players.append(sfx_player)
	sfx_player.finished.connect(_on_arrgoed_sfx_finished.bind(sfx_player))
	sfx_player.play()

func _on_arrgoed_sfx_finished(sfx_player: AudioStreamPlayer2D) -> void:
	_arrgoed_sfx_players.erase(sfx_player)
	if sfx_player and is_instance_valid(sfx_player):
		sfx_player.queue_free()

func _create_audio_player(player_name: String) -> AudioStreamPlayer2D:
	var arrgoed_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	arrgoed_player.name = player_name
	arrgoed_player.set_meta("bgm_fade", 1.0)
	return arrgoed_player

func _load_stream(key: String, loop: bool) -> AudioStream:
	if not bgm_list.has(key):
		push_warning("BGMManager: 未找到 BGM '%s'" % key)
		return null

	var path: String = bgm_list[key]
	var loaded_stream: AudioStream = load(path)
	if not loaded_stream:
		push_warning("BGMManager: 无法加载 BGM '%s': %s" % [key, path])
		return null

	var stream: AudioStream = loaded_stream.duplicate() as AudioStream
	if not stream:
		stream = loaded_stream

	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop
	return stream

func _fade_player(arrgoed_player: AudioStreamPlayer2D, target_fade: float, duration: float, free_on_finish: bool = false) -> void:
	if not arrgoed_player or not is_instance_valid(arrgoed_player):
		return

	var tween: Tween = _get_valid_fade_tween(arrgoed_player)
	if tween and tween.is_valid():
		tween.kill()

	var start_fade: float = float(arrgoed_player.get_meta("bgm_fade", 1.0))
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_set_player_fade.bind(arrgoed_player), start_fade, clamp(target_fade, 0.0, 1.0), max(duration, 0.0))
	if free_on_finish:
		tween.finished.connect(_on_bgm_fade_out_finished.bind(arrgoed_player))
	_bgm_fade_tweens[arrgoed_player] = tween

func _get_valid_fade_tween(arrgoed_player: AudioStreamPlayer2D) -> Tween:
	var tween: Variant = _bgm_fade_tweens.get(arrgoed_player)
	if tween == null or not is_instance_valid(tween):
		return null
	return tween as Tween

func _on_bgm_fade_out_finished(arrgoed_player: Variant) -> void:
	_bgm_fade_tweens.erase(arrgoed_player)
	if arrgoed_player and is_instance_valid(arrgoed_player):
		arrgoed_player.stop()
		arrgoed_player.queue_free()

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
