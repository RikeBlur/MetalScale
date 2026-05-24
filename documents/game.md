# 游戏整体说明与运行时序

这是一个基于 Godot 4.6 的俯视角 RPG 项目。当前项目的运行时核心由 8 个 Autoload 管理器协作完成：`GameManager`、`SceneManager`、`ArchiveManager`、`CutsceneManager`、`UIManager`、`NPCManager`、`EnvironmentManager`、`BgmManager`。

## 管理器总览

1. `GameManager`：`res://Scripts/global/game_manager.gd`
   - 游戏总管线入口。
   - 维护 `GameState`、`RunningState`、玩家实例、相机实例、配置、死亡流程、仇恨状态信号。

2. `SceneManager`：`res://Scripts/global/scene_manager.gd`
   - 管理 `scene_dict`、`SceneData` 和普通场景切换。
   - 换场时移动全局 player/camera，玩家落位后发出 `player_reseted`。

3. `ArchiveManager`：`res://Scripts/global/archive_manager.gd`
   - 管理普通存档、快速存档、读档。
   - 读写 `PlayerData`、`SceneData`、`NPCData`、`ToolData`。

4. `CutsceneManager`：`res://Scripts/global/cutscene_manager.gd`
   - 管理 cutscene 注册、播放、跳过、死亡 cutscene。
   - 播放 cutscene 时会让 `RunningState` 进入 `AUTO`，玩家输入应被阻塞。

5. `UIManager`：`res://Scripts/global/ui_manager.gd`
   - 管理当前场景的 `UI_LAYERS`、HUD、菜单、弹窗、仇恨条、拾取提示。

6. `NPCManager`：`res://Scripts/global/npc_manager.gd`
   - 维护全局 `npc_dict`，保存 NPC 跨场景状态。
   - 场景切换前保存场上 NPC，玩家落位后实例化当前场景 NPC。
   - 新游戏会重置为默认 `npc_dict`。

7. `EnvironmentManager`：`res://Scripts/global/environment_manager.gd`
   - 管理场景环境、默认光照、仇恨视觉效果。
   - 死亡回菜单前会被 GameManager 要求清理所有视觉效果。

8. `BgmManager`：`res://Scripts/global/bgm_manager.gd`
   - 管理 BGM 平滑切换和部分 SFX。
   - 通过监听游戏状态、仇恨状态等信号改变音乐。

## 核心状态

`GameState` 表示游戏总阶段：

- `PRELOADING`：启动预加载中。
- `MENU`：主菜单。
- `RUNNING`：关卡正常运行。
- `LOADING`：场景切换、读档、新游戏准备、死亡回菜单等加载阶段。
- `OVER`：预留结束状态。

`RunningState` 表示运行中的玩家控制子状态：

- `NOPE`：没有可控游戏流程，例如主菜单。
- `CONTROL`：玩家可正常控制。
- `MENU`：游戏内菜单打开。
- `AUTO`：系统接管流程，例如 cutscene、死亡演出、自动事件。

重要原则：

- `GameState.LOADING` 用来通知各管理器保存或清理运行时状态。
- `GameManager.Loading` 是“旧场景即将切走”的关键广播。
- `SceneManager.player_reseted` 是“新场景已加载、玩家已落位”的关键广播。
- `GameManager.Loaded` 是“游戏可以恢复 RUNNING + CONTROL”的关键广播。

## 启动到主菜单

1. Godot 加载 Autoload 管理器。
2. `GameManager._ready()` 读取配置，创建全局后处理层，连接 `Loaded` 和 `player_died`。
3. `GameManager.preloading()` 确保 player/camera 实例可用，并检查主要管理器。
4. `ArchiveManager.check_save_state()` 检查存档槽。
5. `GameManager` 发出 `Preloaded`。
6. `GameManager.set_game_state(GameState.MENU)`。
7. OpeningMenu 的遮罩淡出，玩家停留在主菜单。

此时 player/camera 可能已经被 GameManager 实例化，但不一定在当前场景树中。需要拿 player 时应通过 `GameManager.get_player()`，不要假设它一定有 parent。

## 开始新游戏

入口：`GameManager.start_new_game()`

流程：

1. 只有当前为 `GameState.MENU` 时才允许开始。
2. 设置 `GameState.LOADING`。
3. 清空本局存档时间。
4. 取消死亡流程标记。
5. 确保 player/camera 实例存在。
6. `_reset_player_runtime_state()` 重置玩家血量、死亡状态、移动/交互/行动能力、速度、输入阻塞和 `aggro_value`。
7. `_reset_npc_manager_for_new_game()` 调用 `NPCManager.reset_to_default_state()`，把 NPC 状态恢复到默认 `npc_dict`。
8. 把 player/camera 临时挂到当前 OpeningMenu 场景，供后续 `SceneManager.change_scene()` 移动它们。
9. 淡入 OpeningMenu 遮罩。
10. `CutsceneManager.play_cutscene("test")` 播放开场 cutscene。
11. 等待 `cutscene_playback_finished`。
12. `SceneManager.change_scene(start_scene, 0, start_position)` 切到起始场景。
13. `UIManager.refresh_ui_manager()` 刷新 UI。
14. 触发默认开场对话。
15. `GameManager.Loaded.emit()`。
16. `_on_loaded()` 设置 `GameState.RUNNING` 和 `RunningState.CONTROL`，隐藏鼠标，并同步仇恨追踪状态。

注意：新游戏不复用上一次的 NPC 运行时状态。`NPCManager.reset_to_default_state()` 会清空 NPC 实例弱引用、EYE 计时器，并重新创建默认 `NPCData`。

## 普通场景切换

入口通常是门或脚本调用：

```gdscript
SceneManager.change_scene(scene_to, scene_to_index)
```

流程：

1. `SceneManager` 根据 `scene_key` 获取场景路径。
2. 从 `GameManager` 获取全局 player/camera。
3. 设置 `GameState.LOADING`。
4. 发出 `GameManager.Loading`。
5. `NPCManager._on_game_loading()` 保存场上 NPC 的位置、方向和状态，标记离场并清空实例弱引用。
6. 播放转场遮罩。
7. 从旧场景移除 player/camera，但不释放它们。
8. `change_scene_to_file()` 加载新场景。
9. 更新 `SceneManager.current_scene_key`。
10. 等待新场景准备完成。
11. 把 player 挂到新场景的 `ObjectAndCharacter`，并用 `BaseLevel` 设置出生点。
12. 把 camera 挂到新场景，设置 target 并 reset。
13. 发出 `SceneManager.player_reseted`。
14. `NPCManager` 根据当前场景实例化应出现的 NPC。
15. `EnvironmentManager` 设置 `WorldEnvironment`、`CanvasModulate` 和当前仇恨视觉效果。
16. `UIManager` 通常由 `BaseLevel._ready()` 或流程外显式刷新。
17. 转场淡出，恢复玩家行动。
18. 设置 `GameState.RUNNING`。

## 存档与读档

### 存档

入口：`ArchiveManager.game_save(index)` 或 `quick_save()`

保存内容：

- 玩家：`PlayerData`，包含位置、方向、生命、死亡状态、工具索引、`aggro_value` 等。
- 工具：`ToolData`。
- 场景：`SceneData` 和可交互物状态。
- NPC：`NPCData`，保存 `current_scene`、位置、方向、类型、状态和资源路径。

保存前 `ArchiveManager` 会让 `NPCManager` 刷新场上 NPC 数据。

### 读档

入口：`ArchiveManager.game_load(index)` 或 `quick_load()`

流程：

1. 设置 `GameState.LOADING`。
2. `GameManager.prepare_for_archive_load()` 打断可能残留的死亡流程，并清空仇恨追踪边沿状态。
3. 发出 `GameManager.Loading`，让 NPC 等系统保存并离场。
4. 读取 JSON。
5. 恢复 `SceneManager.scene_dict`。
6. 恢复 `NPCManager.npc_dict`。
7. 切换到存档场景。
8. 等待 `SceneManager.player_reseted`。
9. `NPCManager` 根据读档后的 `npc_dict` 实例化当前场景 NPC。
10. 恢复玩家数据和保存时的位置。
11. 恢复工具数据。
12. `GameManager.sync_player_arrgo_state()` 用恢复后的 `player.aggro_value` 对齐 `player_arrgo` 和 `_prev_aggro_value`，避免读档第一帧误触发仇恨边沿。
13. 发出 `GameManager.Loaded`。
14. `_on_loaded()` 恢复 `RUNNING + CONTROL`。

## Cutscene 与自动流程

普通 cutscene 由 `CutsceneManager.play_cutscene(key)` 播放：

1. 保存播放前 `RunningState`。
2. 设置 `RunningState.AUTO`。
3. 阻塞玩家移动和交互。
4. 实例化 cutscene 到 CanvasLayer。
5. 等待 cutscene 发出 `cutscene_finished`。
6. 淡出并释放 cutscene。
7. 恢复播放前 `RunningState` 和玩家控制状态。
8. 发出 `cutscene_playback_finished`。

如果 cutscene 根节点 `any_key_continue == true`，则只能通过按键在 `any_key_continue_time` 后触发结束，子控件的 partly finished 信号不会结束整体 cutscene。

## 玩家死亡流程

入口：

- 玩家脚本 `player_died()`。
- 或 NPC / 伤害逻辑最终调用 `GameManager.notify_player_died(player)`。

流程：

1. 玩家设置 `is_died = true`、`health_now = 0`。
2. 禁用移动、交互、行动。
3. `InputEvents.set_player_input_blocked(true)`。
4. `GameManager.notify_player_died()` 设置 `RunningState.AUTO`，发出 `player_died`。
5. `CutsceneManager` 播放 `"death"` cutscene，完成后发出 `death_cutscene_finished`。
6. `GameManager._on_player_died()` 等待死亡 cutscene。
7. 死亡流程 token 检查：如果期间发生读档或流程被打断，旧死亡流程不会继续执行。
8. `EnvironmentManager.clear_all_visual_effects()` 被调用，清理所有视觉效果。
9. `_return_to_opening_menu_after_death()` 设置 `GameState.LOADING` 并发出 `Loading`。
10. `NPCManager` 保存/清理旧场景 NPC，避免保留已释放实例。
11. 切换回 OpeningMenu。
12. 淡出主菜单遮罩。
13. 清空 player/camera 引用，重建干净实例。
14. 重置玩家运行时状态和仇恨追踪。
15. 设置 `GameState.MENU` 和 `RunningState.NOPE`。

死亡后的下一次新游戏会再次调用 `NPCManager.reset_to_default_state()`，确保 NPC 回到默认 `npc_dict`，不会继承死亡前的追逐、位置或计时器状态。

## 仇恨与视觉/BGM/UI 协作

`GameManager._update_player_arrgo()` 只在 `GameState.RUNNING` 时读取 `player.aggro_value`。

信号规则：

- 低于 `arrgo_in_threshold` 上升到阈值以上：`get_in_arrgo`
- 低于 100 上升到 100 或以上：`arrgoed`
- 大于 0 回到 0：`not_arrgoed` 和 `get_out_arrgo`

监听者：

- `UIManager`：显示/隐藏 `ARRGOBAR`。
- `NPCManager`：让 EYE 进入追逐或巡逻状态。
- `EnvironmentManager`：切换 `arrgoing`、`arrgoed` 视觉滤镜。
- `BgmManager`：切换 BGM 或播放 SFX。

读档后必须调用 `GameManager.sync_player_arrgo_state()`，因为这是把存档里的 `aggro_value` 和 GameManager 的边沿检测状态对齐的关键步骤。

## 添加内容时的管线注意事项

### 添加新场景

1. 在 `SceneManager.scene_dict` 注册 key 和路径。
2. 场景应有 `BaseLevel`、`ObjectAndCharacter`、`UI_LAYERS`。
3. 如果使用 NPC，建议有 `ObjectAndCharacter/NPC`。
4. 如果使用环境系统，添加 `WorldOfWonder/CanvasModulate`。
5. 门的 `scene_to` 必须指向注册过的 scene key。

### 添加新 NPC

1. 在 `NPCManager.npc_type` 添加类型。
2. 在默认 `npc_dict` 和 `_create_default_npc_dict()` 中添加同一份默认配置。
3. NPC 脚本需要跨场景保存的状态，应同步到 `NPCData`。
4. 如果会响应仇恨或其他全局信号，更新对应回调。

### 添加新玩家字段

如果字段需要存档：

1. 更新 `PlayerData` 字段。
2. 更新 `from_player_node()`、`apply_to_player_node()`、`to_dict()`、`from_dict()`。
3. 如果字段影响 GameManager 边沿检测或 UI，同步对应管理器状态。

### 添加新 UI

1. 在 `UIManager.UI_component` 和 `UI_DATA` 注册。
2. 确认目标场景有 `UI_LAYERS`。
3. 根据层级选择 layer 1/2/3。

### 添加新 cutscene

1. 在 `CutsceneManager.cutscene_scenes` 注册 key。
2. 根节点建议挂 `cutscene.gd`。
3. 播放时会进入 `RunningState.AUTO`，需要考虑输入阻塞和结束信号。

### 添加新视觉效果

1. 在 `EnvironmentManager` 注册效果 key 和场景路径。
2. 需要淡入淡出时提供 `effect_opacity` shader 参数。
3. 死亡回菜单前会统一清理 EnvironmentManager 管理的视觉效果。
