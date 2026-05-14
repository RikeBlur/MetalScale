# 场景系统 SceneSystem

## 管理器：SceneManager

### 数据结构

1. **scene_dict: Dictionary**  key：场景id  value：SceneData <br>

2. **current_scene_key: String**  当前场景id <br>

3. **player_reset: Signal** 当玩家位置被场景管理器重置后，发射信号 <br>

### 核心方法

**场景切换：** change_scene(scene_key: String, scene_to_index: int) -> void: <br>

step1: 禁止玩家操作（移动和交互）；播放当前场景的结束过场动画 <br>

step2: 切换场景；加载玩家和相机并根据 scene_to_index 初始化位置 <br>
	
step3: 播放当前场景的开始过场动画；解禁玩家操作 <br>

## 基本类：BaseLevel

### 数据结构

1. **player_initial_position: Array[Vector2]** 玩家在这个场景的初始位置。一个场景有多个入口，所以初始位置是一个数组 <br>

2. **player_initial_direction** 同上，记录初始玩家朝向 <br>

3. **transition_player： AnimationPlayer** 转场动画，包括 transition_begin 和 transition_end <br>

### 核心方法

1. 初始化时，refresh 一次 UIManager <br>

2. 根据 index **初始化玩家位置** apply_initial_values_to_player(target_player: player, index: int) -> void <br>

## 数据类：SceneData

### 场景文件路径
path: String <br>

### 场景显示名称
display_name: String <br>

### 可交互位数据
interactables: Array[InteractableData] <br>

## 近期更新：SceneData 默认 interactables 预初始化

`SceneManager` 现在负责在新游戏真正加载起始场景前，预先读取 `res://DEMO/AdiosToMe/Levels` 下的关卡场景，并把每个 `BaseLevel.interactables` 的默认配置写入对应的 `SceneData.interactables`。

入口方法：

```gdscript
SceneManager.start_initialize_scene_data_interactables_from_level_files()
```

该方法本身不是协程，会用 `call_deferred()` 启动内部异步流程，避免 `GameManager` 直接调用协程时报错。初始化完成后发出：

```gdscript
signal scene_data_interactables_initialized(success: bool)
```

相关查询接口：

- `is_scene_data_interactables_initializing() -> bool`
- `get_scene_data_interactables_initialization_success() -> bool`

初始化流程：

1. 递归扫描 `res://DEMO/AdiosToMe/Levels` 下的 `.tscn`。
2. 只处理已经登记在 `scene_dict` 中的场景路径。
3. 加载 `PackedScene` 并实例化到内存读取 `BaseLevel.interactables`。
4. 深拷贝 `InteractableData` 到对应 `SceneData.interactables`。
5. 每处理一个场景后等待一帧，降低一次性初始化卡顿。
6. 验证 `scene_dict` 中所有场景是否都完成初始化。

注意：这个流程不会调用 `change_scene()`，也不会把被读取的关卡加入当前场景树。它只读取数据并更新 `SceneManager.scene_dict`。

`GameManager.start_new_game()` 会在播放开场 cutscene 的同时启动该初始化，并在切换到起始场景前等待结果。初始化失败时不会继续加载游戏场景。

`BaseLevel._ready()` 中 “当 SceneData.interactables 为空时从当前 BaseLevel 同步” 的逻辑仍可作为兜底，但新游戏的主流程应依赖 SceneManager 的预初始化结果。
