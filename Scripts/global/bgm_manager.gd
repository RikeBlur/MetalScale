class_name bgm_manager
extends Node

# ====================================================================================================
# ===================================== 配置 ========================================================
# ====================================================================================================

## BGM 列表：key 为名字，value 为 mp3 文件路径
## 在此处添加 BGM 条目，"default" 为启动时自动播放的 BGM
var bgm_list: Dictionary = {
	"default": "res://Assests/SFX/bgm/Rain_Medium_2.mp3",
	# "battle":  "res://Assests/BGM/battle.mp3",
}

# ====================================================================================================
# ===================================== 运行时状态 ==================================================
# ====================================================================================================

var bgm_player: AudioStreamPlayer2D = null
var _current_key: String = ""

# ====================================================================================================
# ===================================== 初始化 ======================================================
# ====================================================================================================

func _ready() -> void:
	_setup_bgm_player.call_deferred()

func _setup_bgm_player() -> void:
	"""创建 bgm_player 节点，加载 default BGM 并开始播放"""
	bgm_player = AudioStreamPlayer2D.new()
	bgm_player.name = "bgm_player"
	add_child(bgm_player)

	if bgm_list.has("default") and bgm_list["default"] != "":
		var stream: AudioStream = load(bgm_list["default"])
		if stream:
			if stream is AudioStreamMP3:
				(stream as AudioStreamMP3).loop = true
			bgm_player.stream = stream
			_current_key = "default"
			_apply_volume()
			bgm_player.play()
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
	"""将 GameManager.BGM_gain（0~100）转换为线性 dB 并赋给 bgm_player"""
	if not bgm_player:
		return
	var gain: float = clamp(GameManager.BGM_gain, 0.0, 100.0)
	# gain 0 → -80dB（静音），100 → 0dB（最大）
	if gain <= 0.0:
		bgm_player.volume_db = -80.0
	else:
		bgm_player.volume_db = linear_to_db(gain / 100.0)

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

	if _current_key == key and bgm_player.playing:
		return

	var path: String = bgm_list[key]
	var stream: AudioStream = load(path)
	if not stream:
		push_warning("BGMManager: 无法加载 BGM '%s': %s" % [key, path])
		return

	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true

	bgm_player.stream = stream
	_current_key = key
	_apply_volume()
	bgm_player.play()
	print("BGMManager: 切换到 BGM '%s'" % key)

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
