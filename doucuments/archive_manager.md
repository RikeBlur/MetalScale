# ArchiveManager 操作说明

源文件：`res://Scripts/global/archive_manager.gd`  
Autoload 名称：`ArchiveManager`

`ArchiveManager` 负责存档槽状态、存档写入、存档读取和快速存档。当前存档格式是 JSON，写入 `user://save_*.json` 和 `user://quick_save.json`。

## 主要职责

- 检查 0 到 5 号存档槽是否存在。
- 保存玩家数据、工具数据、场景数据、NPC 数据。
- 读档时恢复 `SceneManager.scene_dict`、当前场景、NPC 状态、玩家状态和工具状态。
- 与 `GameManager` 的 `Loading`、`Loaded` 状态管线协作。

## 参与游戏管线的操作

### 存档槽检查

`GameManager.preloading()` 会调用：

```gdscript
ArchiveManager.check_save_state()
```

它遍历 `save_path_dict`，把每个槽位是否存在写入 `save_state_dict`。保存/读取窗口可以用这个字典显示槽位状态。

### 普通存档

入口：`game_save(index)`

流程：

1. 更新 `save_state_dict[index]`。
2. 获取 `/root/SceneManager`。
3. 通过 `GameManager.get_player()` 获取玩家。
4. 获取 `NPCManager`，并在序列化前调用 `_update_inscene_npc_data()`。
5. 构造 JSON：`version`、`timestamp`、`game_archive_msec`、`player`、`tool`、`scene`、`npc`。
6. 写入 `user://save_N.json`。

### 普通读档

入口：`game_load(index)`

流程：

1. 设置 `GameManager.GameState.LOADING`。
2. 调用 `GameManager.prepare_for_archive_load()`，打断可能残留的死亡流程，并清空仇恨边沿追踪。
3. 发出 `GameManager.Loading`。
4. 读取并解析 JSON。
5. 恢复 `GameManager.game_archive_msec`。
6. 恢复 `SceneManager.scene_dict`。
7. 恢复 `NPCManager.npc_dict` 中的 NPCData。
8. 根据 `scene.scene_now` 切换到存档场景。
9. 如果已有玩家，使用 `SceneManager.change_scene(scene_now, 0)` 并等待 `player_reseted`。
10. 调用 `_refresh_current_scene_npcs()`，让 NPCManager 按当前场景重新实例化 NPC。
11. 恢复玩家数据。
12. 显式恢复玩家保存时的位置。
13. 恢复玩家工具数据。
14. 调用 `GameManager.sync_player_arrgo_state()`，用恢复后的 `player.aggro_value` 对齐仇恨状态。
15. 发出 `GameManager.Loaded`，让 `GameManager` 恢复 `RUNNING + CONTROL`。

### 快速存档和快速读档

入口：

- `quick_save()`
- `quick_load()`

快速存档和普通存档的数据结构基本一致，但路径固定为：

```gdscript
const QUICK_SAVE_PATH: String = "user://quick_save.json"
```

当前实现中，`quick_load()` 与普通读档一样会进入 `GameState.LOADING`，发出 `GameManager.Loading`，恢复数据后发出 `GameManager.Loaded`。如果新增其他快速读档入口，保持这个管线一致。

## 当前会被保存的数据

### 玩家数据

由 `Scripts/data/player_data.gd` 负责，保存移动参数、交互状态、角色信息、方向、当前工具槽索引、生命值、死亡状态、`aggro_value` 和全局位置。

### 工具数据

由 `ArchiveManager` 直接序列化 `ToolData`：

- `display_name`
- `description`
- `packed_scene_path`
- `icon_path`
- `type`
- `durability`
- `durability_max`
- `consumption`
- `consumption_max`
- `state`
- `useable`

读档后会写回玩家子节点 `ToolManager.tool_data`，并调用 `_sync_runtime_lookup()`。

### 场景数据

由 `SceneData.to_dict()` 保存：

- `path`
- `display_name`
- `interactables`

`interactables` 中保存 `node_path`、`type`、`state`，用于恢复门、可拾取物、对话、谜题、其他可持久化对象。

### NPC 数据

由 `NPCData.to_dict()` 保存：

- `current_scene`
- `npc_position`
- `npc_direction`
- `type`
- `state`
- `npc_node_path` 由 `ArchiveManager` 额外写入

保存时统一把 `is_inscene` 写成 false。读档后由 `NPCManager._on_player_reseted()` 根据当前场景重新实例化。

## 添加或修改内容

### 添加玩家字段

如果新增玩家属性需要存档：

1. 在 `PlayerData` 添加 `@export var`。
2. 更新 `from_player_node(player_node)`。
3. 更新 `apply_to_player_node(player_node)`。
4. 更新 `to_dict()`。
5. 更新 `from_dict(data)`。

如果字段只在单局运行时使用，不需要写入 `PlayerData`。

### 添加工具字段

如果新增 `ToolData` 字段需要存档：

1. 在 `Scripts/data/tool_data.gd` 添加字段。
2. 更新 `ArchiveManager._serialize_tool_data()`。
3. 更新 `ArchiveManager._deserialize_tool_data()`。
4. 如果字段影响运行时缓存，读档后确认 `ToolManager._sync_runtime_lookup()` 是否要同步它。

### 添加 NPC 字段

如果新增 NPC 状态需要跨场景和存档保持：

1. 在 `NPCData` 添加字段。
2. 更新 `NPCData.to_dict()` 和 `NPCData.from_dict()`。
3. 如果字段只存在于 NPC 节点上，也要在 `NPCManager._update_inscene_npc_data()` 中从实例写回 `NPCData`。
4. 如果读档后要写入实例，更新 `NPCManager._apply_npc_initial_state()` 或实例化后的同步逻辑。

### 添加场景可交互状态

如果新增可持久化交互类型：

1. 在 `InteractableData` 的 `@export_enum` 中添加类型。
2. 在 `BaseLevel.apply_interactable_states()` 添加 match 分支。
3. 在对应交互脚本里，状态变化后调用 `base_level.update_interactable_state(get_path(), new_state)`。
4. 不需要改 `SceneData`，它已按 `node_path/type/state` 通用保存。

### 添加配置项

配置项不走 JSON 存档，而是由 `GameManager` 保存到 `user://config.tres`。新增设置时更新 `ConfigData`、`GameManager.load_config()`、`save_config()`、`apply_config()` 和对应 UI。

## 注意事项

- 存档中的 `scene.scene_dict` 会覆盖当前 `SceneManager.scene_dict`。如果更新项目后删除了旧场景 key，旧存档可能读不回来。
- 未知 NPC 只有在存档里有有效 `npc_node_path` 时才能被恢复。
- 工具场景和图标依赖 `resource_path`。如果资源移动路径，旧存档里的工具资源可能加载失败。
- `game_load()` 和 `quick_load()` 都会发出 `GameManager.Loaded`。新增读档入口时也要保持 `Loading -> 恢复数据 -> Loaded` 的顺序。
- 读档恢复玩家后必须同步 `GameManager.sync_player_arrgo_state()`，否则 `player_arrgo` 的边沿检测可能把存档中的 `aggro_value` 误判为新变化。
- `game_save()` 保存前会刷新场上 NPC 数据，普通交互状态则依赖各交互脚本主动调用 `BaseLevel.update_interactable_state()`。
