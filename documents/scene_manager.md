# SceneManager 操作说明

源文件：`res://Scripts/global/scene_manager.gd`  
Autoload 名称：`SceneManager`

`SceneManager` 管理场景注册表和普通场景切换。它不创建玩家和相机，而是从 `GameManager` 取出已有实例，在换场时把它们从旧场景移走，再挂到新场景。

## 主要职责

- 维护 `scene_dict`：场景 key 到 `SceneData` 的映射。
- 维护 `current_scene_key`。
- 根据场景 key 获取 `SceneData` 或场景路径。
- 执行普通场景切换，包括转场动画、玩家落位、相机重置。
- 发出 `player_reseted` 信号，通知其他管理器玩家已经在新场景落位。
- 为存档系统提供场景数据和当前场景 key。

## 参与游戏管线的操作

### 场景注册

`scene_dict` 的结构：

```gdscript
var scene_dict: Dictionary = {
	"2-2": SceneData.new(
		"res://DEMO/AdiosToMe/Levels/2/ClassRoom201.tscn",
		"201教室",
		[]
	),
}
```

每个 key 是系统内部场景 ID。门、NPC、存档、新游戏起点都依赖这个 key，不建议随意改名。

### 普通换场流程

入口：`change_scene(scene_key, scene_to_index := 0, player_global_position_override := null)`

流程：

1. 用 `scene_key` 从 `scene_dict` 找到场景路径。
2. 从 `GameManager` 获取玩家和相机。
3. 设置 `GameManager.current_state = GameState.LOADING`。
4. 发出 `GameManager.Loading`。
5. 禁用玩家移动、行动、交互。
6. 在 root 下实例化 `transition_Mask.tscn`，播放 `appear`。
7. 从旧场景移除玩家和相机，但不释放它们。
8. `get_tree().change_scene_to_file(scene_path)` 加载新场景。
9. 更新 `current_scene_key`。
10. 等待两帧，确保新场景 `_ready()` 基本完成。
11. 优先把玩家挂到新场景的 `ObjectAndCharacter` 下；没有则挂到新场景根节点。
12. 查找 `BaseLevel` 并调用 `apply_initial_values_to_player(player, scene_to_index)`。
13. 如果传入了 `player_global_position_override`，再覆盖玩家位置。
14. 把相机挂到新场景根节点，设置 `target`，调用 `reset_camera()`。
15. 发出 `player_reseted`。
16. 等待两帧，播放转场 `disappear` 并释放转场节点。
17. 恢复玩家移动、行动、交互。
18. 设置 `GameManager.current_state = GameState.RUNNING`。

### `player_reseted` 的意义

`player_reseted` 是“场景已经切好、玩家已经落位”的关键同步点。

当前监听者：

- `NPCManager`：检查当前场景应该出现哪些 NPC，并实例化。
- `EnvironmentManager`：给当前场景设置 `WorldEnvironment` 和仇恨滤镜状态。
- `ArchiveManager`：读档时等待玩家落位后再恢复玩家数据。

如果新增系统需要在玩家位置确定后执行，不要只依赖场景 `_ready()`，建议监听 `SceneManager.player_reseted`。

## 添加或修改内容

### 添加新的场景

推荐步骤：

1. 创建新的 `.tscn` 场景。
2. 根节点或其子树中挂 `BaseLevel` 脚本。
3. 配置 `BaseLevel.player_initial_position` 和 `BaseLevel.player_initial_direction`，数组下标要与门的 `scene_to_index` 对应。
4. 添加 `UI_LAYERS` 节点，并在下面放 3 个 `CanvasLayer`：
   - `UI_layer1`，`layer = 1`
   - `UI_layer2`，`layer = 2`
   - `UI_layer3`，`layer = 3`
5. 添加 `ObjectAndCharacter` 节点。玩家会被优先挂到这里。
6. 如果场景有可交互物，建议在 `ObjectAndCharacter/Interactable` 下组织。
7. 如果场景允许 NPC 出现，建议添加 `ObjectAndCharacter/NPC`。
8. 如果需要环境滤镜，添加 `WorldOfWonder` 节点，并在其下添加 `CanvasModulate`。
9. 在 `SceneManager.scene_dict` 添加新 key：

```gdscript
"2-7": SceneData.new(
	"res://DEMO/AdiosToMe/Levels/2/NewRoom.tscn",
	"新房间",
	[]
),
```

### 添加新的门连接

门使用 `BaseDoor`，它会调用：

```gdscript
SceneManager.change_scene(scene_to, scene_to_index)
```

门上必须配置：

- `scene_from`：当前场景 key，主要用于阅读和管理。
- `scene_to`：目标场景 key，必须存在于 `SceneManager.scene_dict`。
- `scene_to_index`：进入目标场景时使用的 `BaseLevel.player_initial_position` 下标。
- `state`：`0` 可打开，`1` 上锁，`2` 不能从这一侧打开。
- `responding_key`：上锁门需要的钥匙工具，默认 `ToolManager.Tool.NONE`。

如果门状态要被存档，必须把门加入当前场景 `BaseLevel.interactables`。

### 添加可持久化的交互物

`BaseLevel.interactables` 中保存 `InteractableData`，运行时会同步到 `SceneData.interactables`，再由 `ArchiveManager` 写入存档。

`InteractableData` 字段：

- `node_path`：相对于 `BaseLevel` 的节点路径。
- `type`：
  - `0` 门
  - `1` 可拾取物
  - `2` 对话
  - `3` 谜题
  - `4` 其他
  - `5` 灯
- `state`：含义由 type 决定。

当前 `BaseLevel.apply_interactable_states()` 已处理：

- 门：调用 `BaseDoor.set_door_state(state)`。
- 可拾取物：写入 `collectable_state`。
- 对话：写入 `DialogueComponent.current_flag`。
- 谜题：优先调用 `set_puzzle_state()` 或 `set_puzzle_interactable()`。
- 其他：优先调用 `set_other_visibility_state()`，否则控制可见性和碰撞。
- 灯：要求 `node_path` 指向 `ElectronicScreen`，加载场景时把 `state` 映射到 `ElectronicScreen.turned_on`；`0` 表示关闭，`1` 表示开启。

`SceneData.to_dict()/from_dict()` 会保存和恢复 `node_path`、`type`、`state`，`ArchiveManager` 保存 `scene_dict` 时会一并写入这些数据。因此灯状态不需要额外存档字段，只要运行时状态变化后同步更新对应的 `InteractableData.state` 即可。

运行中改变状态时调用：

```gdscript
base_level.update_interactable_state(get_path(), new_state)
```

当前门解锁、可拾取物拾取、对话推进都已经这样做。

### 修改转场效果

当前使用：

```gdscript
const TRANSITION_SCENE_PATH: String = "res://System/RPG/view/transition_Mask.tscn"
```

新转场场景需要有：

- `ColorRect/TransitionPlayer`
- `AnimationPlayer` 中存在 `appear` 和 `disappear` 动画。

## 注意事项

- `scene_key` 是系统级 ID，门、NPC、存档都会引用它。删除或重命名 key 会影响旧存档。
- `change_scene()` 会发出 `GameManager.Loading`，会触发 `NPCManager` 把场上 NPC 标记为离场。
- 玩家默认挂到 `ObjectAndCharacter`，如果你的场景没有这个节点，玩家会挂到根节点，可能影响 y-sort 或导航组织。
- `BaseLevel.apply_initial_values_to_player()` 目前没有对 index 做边界保护。门的 `scene_to_index` 必须在数组范围内。
- `update_interactable_state()` 在 `SceneManager` 中还是空函数，真正可用的实现位于 `BaseLevel`。
