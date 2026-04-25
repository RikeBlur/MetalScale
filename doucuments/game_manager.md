# GameManager 操作说明

源文件：`res://Scripts/global/game_manager.gd`  
Autoload 名称：`GameManager`

`GameManager` 是当前 RPG 系统的总管线入口。它保存游戏总状态、运行子状态、玩家实例、相机实例、配置数据，并向其他管理器广播加载、死亡、仇恨等关键事件。

## 主要职责

- 维护 `GameState`：`PRELOADING`、`MENU`、`RUNNING`、`LOADING`、`OVER`。
- 维护 `RunningState`：`NOPE`、`CONTROL`、`MENU`、`AUTO`。
- 在启动时加载配置、玩家、相机和主要全局管理器。
- 启动新游戏，播放开场 cutscene，然后进入起始场景。
- 保存全局玩家实例和全局相机实例，供 `SceneManager`、`ArchiveManager`、`UIManager` 等访问。
- 每帧读取 `player.aggro_value`，发出仇恨状态信号。
- 统一处理玩家死亡流程，切到死亡 cutscene，再回到主菜单。
- 保存并应用 `ConfigData` 中的 BGM、SFX、Gamma 配置。

## 参与游戏管线的操作

### 启动预加载

`_ready()` 会读取配置、创建 Gamma 后处理层、延迟调用 `preloading()`，并连接 `Loaded`、`player_died` 信号。

`preloading()` 是 `PRELOADING -> MENU` 的主流程：

1. `_ensure_player_and_camera_instances()` 加载玩家和相机。
2. `_install_manager()` 确保 `SceneManager`、`ArchiveManager`、`UIManager`、`LightingManager`、`BgmManager` 挂到 `/root`。
3. 调用 `ArchiveManager.check_save_state()` 初始化存档槽状态。
4. 等待一帧，发出 `Preloaded` 信号。
5. 调用 `set_game_state(GameState.MENU)`。
6. 淡出主菜单遮罩。

注意：这些管理器也在 `project.godot` 的 `[autoload]` 中注册。`_install_manager()` 会先检查 `/root/Name`，已有则跳过，避免重复挂载。

### 开始新游戏

入口：`start_new_game()`  
触发条件：当前必须是 `GameState.MENU`。

流程：

1. 切到 `GameState.LOADING`。
2. 清空本局存档时间，重置死亡流程标记。
3. 确保玩家和相机存在，并重置玩家血量、移动、交互、行为状态、输入阻塞和 `aggro_value`。
4. 调用 `_reset_npc_manager_for_new_game()`，让 `NPCManager` 恢复默认 `npc_dict`，清空上一次游戏留下的 NPC 实例弱引用和 EYE 计时器。
5. 把玩家和相机临时挂到当前场景下。
6. 设置玩家起点为 `start_position`。
7. 淡入主菜单遮罩。
8. 调用 `CutsceneManager.play_cutscene("test")` 播放开场 cutscene。
9. 等待 `CutsceneManager.cutscene_playback_finished`。
10. 调用 `SceneManager.change_scene(start_scene, 0, start_position)` 切到起始场景。
11. 调用 `UIManager.refresh_ui_manager()`。
12. 发出 `Loaded` 信号。

`Loaded` 会触发 `_on_loaded()`：设置 `RUNNING + CONTROL`，解除输入阻塞，隐藏鼠标，并重置仇恨追踪状态。

### 场景切换中的状态协作

普通换场由 `SceneManager.change_scene()` 完成。它会写入：

```gdscript
GameManager.current_state = GameManager.GameState.LOADING
GameManager.Loading.emit()
```

换场结束后会恢复为 `GameState.RUNNING`。因此任何需要在换场前保存状态的系统，应监听 `GameManager.Loading`。当前 `NPCManager` 就依赖这个信号保存场上 NPC 状态。

### 玩家死亡流程

入口：`notify_player_died(dead_player := null)`

流程：

1. 找到玩家实例。
2. 设置 `is_died = true`、`health_now = 0`。
3. 禁用移动、交互、行动和输入。
4. 设置 `RunningState.AUTO`。
5. 发出 `player_died` 信号。

`GameManager._on_player_died()` 会等待 `CutsceneManager.death_cutscene_finished`。等待期间使用 `_death_flow_token` 做时序保护：如果读档或其他流程打断死亡流程，旧的死亡协程不会继续执行。

确认死亡 cutscene 完成后，流程会：

1. 调用 `EnvironmentManager.clear_all_visual_effects()` 清理全局视觉效果。
2. 进入 `_return_to_opening_menu_after_death()`。
3. 设置 `GameState.LOADING` 并发出 `Loading`，让 `NPCManager` 保存并清空旧场景 NPC 引用。
4. 切回 `OPENING_MENU_SCENE_PATH`。
5. 清空玩家和相机引用。
6. 重置仇恨状态，重新创建玩家与相机。
7. 重置玩家运行时状态。
8. 设置为 `MENU + NOPE`。

### 仇恨状态信号

`_process()` 只在 `GameState.RUNNING` 时读取玩家的 `aggro_value`。

信号规则：

- 从低于 `arrgo_in_threshold` 上升到阈值以上：`get_in_arrgo`
- 从低于 100 上升到 100 或以上：`arrgoed`
- 从大于 0 回到 0：`not_arrgoed` 和 `get_out_arrgo`

当前监听者：

- `UIManager`：显示或隐藏 `ARRGOBAR`。
- `NPCManager`：切换 EYE 的追逐或巡逻状态。
- `EnvironmentManager`：切换仇恨视觉滤镜。
- `BgmManager`：切换 BGM 或播放一次性 SFX。

## 添加或修改内容

### 修改新游戏起点

改 `game_manager.gd`：

```gdscript
var start_scene: String = "2-2"
var start_position: Vector2 = Vector2(870, 290)
```

同时确认：

- `start_scene` 必须存在于 `SceneManager.scene_dict`。
- 起始场景最好是 `BaseLevel`，并且有 `UI_LAYERS`、`ObjectAndCharacter`、`WorldOfWonder` 等项目约定节点。
- 如果希望用 `BaseLevel.player_initial_position` 决定位置，可以不传 `start_position` override，或调整 `SceneManager.change_scene()` 的调用方式。

### 替换玩家或相机

改常量：

```gdscript
const PLAYER_SCENE_PATH = "res://System/RPG/entity/controllable/player_Oni.tscn"
const CAMERA_SCENE_PATH = "res://System/RPG/entity/camera.tscn"
```

新玩家至少要满足：

- 脚本类型可被 `GameManager.get_player()` 返回为 `player`。
- 加入 `player` group，或能被 `GameManager` 直接保存引用。
- 提供 `can_move`、`can_interact`、`can_act`、`health_now`、`health_max`、`is_died`、`aggro_value` 等当前管线会访问的属性。
- 拥有 `ToolManager` 子节点时，存档系统才能恢复工具数据。

新相机至少要满足：

- 脚本类型可被返回为 `AdvancedCamera`。
- 有 `target` 属性。
- 有 `reset_camera()` 方法，因为 `SceneManager.change_scene()` 会调用。

### 添加新的全局管理器

推荐步骤：

1. 新建脚本，例如 `res://Scripts/global/foo_manager.gd`。
2. 在 `project.godot` 的 `[autoload]` 中注册，例如 `FooManager="*res://Scripts/global/foo_manager.gd"`。
3. 如果它必须参与预加载顺序，再在 `GameManager.preloading()` 中调用 `_install_manager(path, "FooManager")`。
4. 如果它需要响应管线，连接 `GameManager.Preloaded`、`GameManager.Loading`、`GameManager.Loaded`、`GameManager.player_died` 或 `SceneManager.player_reseted`。

如果只依赖 Godot Autoload，不需要在 `preloading()` 中重复安装。

### 添加新的配置项

1. 在 `Scripts/data/config_data.gd` 添加字段。
2. 在 `GameManager` 中添加运行时变量。
3. 更新 `load_config()`、`save_config()`、`apply_config()`。
4. 如果有 UI，更新配置界面脚本和场景。
5. 如果配置会影响其他系统，提供 setter 或信号，避免只改变量但不应用效果。

当前已有配置：`BGM_gain`、`SFX_gain`、`Gamma`。

## 注意事项

- `current_runnnig_state` 变量名当前拼写就是三连 `n`，使用代码时保持一致。
- `GameManager.current_state = ...` 在部分代码中被直接赋值；新增逻辑建议优先使用 `set_game_state()`，除非要完全复刻当前换场流程。
- `RunningState.AUTO` 表示玩家输入应被系统流程接管，例如 cutscene、死亡、自动演出。
- `Loaded` 信号会进入 `_on_loaded()`，它会把游戏恢复到 `RUNNING + CONTROL`。读档、快速读档、新游戏完成时都应该发出它。
- `prepare_for_archive_load()` 用于读档开始时打断可能残留的死亡流程，并清空仇恨边沿追踪。
- `sync_player_arrgo_state()` 用于读档恢复 `player.aggro_value` 后同步 `player_arrgo` 和 `_prev_aggro_value`，避免读档第一帧误触发仇恨信号。
- `Gamma` 后处理层挂在 root，层级为 999，会覆盖整个视口。
