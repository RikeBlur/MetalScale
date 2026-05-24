# BgmManager 操作说明

源文件：`res://Scripts/global/bgm_manager.gd`  
Autoload 名称：`BgmManager`

`BgmManager` 负责全局 BGM 播放、交叉淡入淡出、仇恨音频反馈和死亡音效。普通场景里的局部音效更适合使用 `SFXPlayer`。

## 主要职责

- 维护 `bgm_list`：音频 key 到资源路径的映射。
- 启动时自动播放 `"default"` BGM。
- 提供 `set_bgm(key)` 切换 BGM。
- 切换 BGM 时创建新播放器并淡入，同时淡出旧播放器。
- 每帧从 `GameManager.BGM_gain` 同步音量。
- 监听仇恨信号，切换 BGM 或播放一次性音效。
- 监听玩家死亡信号，播放死亡音效并恢复默认 BGM。

## 参与游戏管线的操作

### 初始化播放

`_ready()` 会：

1. 连接仇恨信号。
2. 连接 `GameManager.player_died`。
3. 延迟调用 `_setup_bgm_player()`。

`_setup_bgm_player()` 会创建 `AudioStreamPlayer2D`，读取 `bgm_list["default"]`，加载音频并设置循环，然后从静音淡入到目标音量。

### BGM 切换

入口：

```gdscript
BgmManager.set_bgm("arrgoing")
```

流程：

1. 检查 `bgm_list` 中是否存在 key。
2. 如果当前已经在播放同一个 key，则跳过。
3. 加载音频资源。
4. 创建新的 `AudioStreamPlayer2D`。
5. 新播放器从 0 淡入。
6. 旧播放器淡出，淡出完成后释放。
7. 更新 `_current_key`。

淡入淡出时长：

```gdscript
@export var bgm_crossfade_duration: float = 0.75
```

### 仇恨音频管线

监听：

- `GameManager.get_in_arrgo`
- `GameManager.get_out_arrgo`
- `GameManager.arrgoed`

行为：

- `get_in_arrgo`：`set_bgm("arrgoing")`
- `get_out_arrgo`：`set_bgm("default")`
- `arrgoed`：播放一次性 `"arrgoed"` 音效

当前 `arrgoed` 不会切走 BGM，只会播放 one-shot。

### 死亡音频管线

监听：

```gdscript
GameManager.player_died
```

行为：

1. 播放一次性 `"death"` 音效。
2. 调用 `set_bgm("default")`。

死亡 cutscene 本身由 `CutsceneManager` 管理，BgmManager 只负责声音。

### 音量同步

`_process()` 每帧调用 `_apply_volume()`。

所有由 BgmManager 管理的播放器都会读取：

```gdscript
GameManager.BGM_gain
```

并通过每个播放器的 `bgm_fade` meta 合成最终音量。

注意：这里使用的是 `BGM_gain`，包括 `arrgoed` 和 `death` 这两个一次性播放器。场景局部 SFX 用 `SFXPlayer` 时读取的是 `GameManager.SFX_gain`。

## 添加或修改内容

### 添加新的 BGM

1. 把音频资源放到项目中，例如：

```text
res://Assests/SFX/bgm/new_theme.mp3
```

2. 在 `bgm_list` 添加：

```gdscript
var bgm_list: Dictionary = {
	"new_theme": "res://Assests/SFX/bgm/new_theme.mp3",
}
```

3. 在需要的地方调用：

```gdscript
BgmManager.set_bgm("new_theme")
```

如果是 MP3，`_load_stream(key, true)` 会设置 `AudioStreamMP3.loop = true`。其他格式是否循环取决于 Godot 的音频资源设置。

### 添加新的 one-shot 音效

如果这个音效属于全局事件，可以沿用 BgmManager 的临时播放器模式：

1. 在 `bgm_list` 添加 key：

```gdscript
"boss_warning": "res://Assests/SFX/bin/warning.wav"
```

2. 新增方法，内部使用 `_load_stream("boss_warning", false)`、`_create_audio_player()`、`_set_player_fade(1.0, player)`，播放完成后 `queue_free()`。

如果是门、道具、UI、怪物等局部音效，推荐在对应场景中放 `SFXPlayer`，不要集中塞进 BgmManager。

### 添加新的信号响应

示例：进入某个 boss 状态时切 BGM。

1. 找到产生该状态的管理器或节点。
2. 在 `BgmManager._ready()` 中连接信号。
3. 在回调中调用 `set_bgm()` 或播放 one-shot。

```gdscript
func _ready() -> void:
	_connect_arrgo_signals()
	_connect_player_died_signal()
	BossManager.boss_started.connect(_on_boss_started)
	_setup_bgm_player.call_deferred()

func _on_boss_started() -> void:
	set_bgm("boss")
```

### 调整默认音乐

修改 `bgm_list["default"]`：

```gdscript
"default": "res://Assests/SFX/bgm/Rain_Medium_2.mp3"
```

启动后 `_setup_bgm_player()` 会自动播放它。

## 注意事项

- `set_bgm()` 对同一个 key 的重复调用会直接返回，不会重播。
- BgmManager 创建的是 `AudioStreamPlayer2D`，但它作为全局节点使用，不依赖空间位置衰减设置。
- `arrgoed` 和 `death` 当前放在 `bgm_list` 中，但实际作为一次性音效播放。
- BgmManager 使用 `GameManager.BGM_gain` 控制它管理的所有声音；普通 SFX 音量应使用 `SFXPlayer` 和 `GameManager.SFX_gain`。
- 如果音频路径错误，`_load_stream()` 会 warning 并跳过播放。
