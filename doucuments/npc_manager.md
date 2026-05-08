# NPCManager 操作说明

源文件：`res://Scripts/global/npc_manager.gd`  
Autoload 名称：`NPCManager`

`NPCManager` 维护全局 NPC 数据表，并负责 NPC 跨场景的保存、离场、入场和部分离场行为。每个 NPC 对应一个 `NPCData`。

## 主要职责

- 维护 `npc_type` 枚举。
- 维护 `npc_dict`：NPC ID 到 `NPCData` 的映射。
- 在场景切换前保存场上 NPC 状态并标记离场。
- 在玩家落位后，实例化属于当前场景的 NPC。
- 每帧同步场上 NPC 的位置、方向、状态到 `NPCData`。
- 根据 `GameManager` 仇恨信号切换 EYE 的状态。
- 处理 EYE 离场巡游和追杀入场逻辑。
- 根据 NPC 击杀玩家的伤害来源播放对应 jumpscare。
- 为 `ArchiveManager` 提供可序列化的 NPC 状态。
- 新游戏开始时把 `npc_dict` 重置为默认配置，避免继承上一局死亡前的状态。

## 参与游戏管线的操作

### 初始化连接

`_ready()` 会连接：

```gdscript
GameManager.Loading.connect(_on_game_loading)
SceneManager.player_reseted.connect(_on_player_reseted)
GameManager.arrgoed.connect(_on_arrgoed)
GameManager.not_arrgoed.connect(_on_not_arrgoed)
```

这些连接决定了 NPCManager 在场景管线中的位置。

`NPCManager` 还会在 `_ready()` 中延迟调用 `_connect_player_hurted_component()`，并在 `_on_player_reseted()` 中再次尝试连接玩家的 `hurted_component.npc_kill_player` 信号。这样玩家实例被场景流程重新创建或重新落位后，jumpscare 入口仍然能接到最新玩家组件。

### 场景切换前保存 NPC

当 `SceneManager.change_scene()`、`ArchiveManager.game_load()`、`ArchiveManager.quick_load()` 或死亡回主菜单流程发出 `GameManager.Loading` 时，`_on_game_loading()` 会：

1. 遍历所有 `npc_dict`。
2. 对场上的 NPC，读取实例的 `global_position`。
3. 如果有 `npc_direction` 属性，写回 `NPCData.npc_direction`。
4. 如果有 `state` 属性，写回 `NPCData.state`。
5. 设置 `data.is_inscene = false`。
6. 清空 `_npc_instances`。

旧场景随后会被 Godot 释放，所以这里是离场前保存 NPC 状态的关键点。

`_npc_instances` 当前保存的是 `WeakRef`，读取实例要走 `_get_npc_instance(npc_id)`。不要直接把字典值赋给 `Node`，否则旧场景释放后可能遇到 freed instance。

### 新游戏默认重置

`GameManager.start_new_game()` 会调用：

```gdscript
NPCManager.reset_to_default_state()
```

该函数会：

1. 释放仍在场景树中的旧 NPC 实例。
2. 清空 `_npc_instances`。
3. 清空 `_eye_wander_timers` 和 `_eye_chase_timers`。
4. 用 `_create_default_npc_dict()` 重新创建 `npc_dict`。
5. 设置 `not_running = true`。

这保证死亡后再次开始新游戏时，NPC 会回到默认场景、默认位置、默认朝向和默认 `state`。

### 玩家落位后实例化 NPC

当 `SceneManager` 完成玩家落位后会发出 `player_reseted`。

`_on_player_reseted()` 会：

1. 读取 `SceneManager.get_current_scene_key()`。
2. 遍历 `npc_dict`。
3. 找出 `data.current_scene == current_key` 且 `is_inscene == false` 的 NPC。
4. 调用 `instantiate_npc(npc_id)`。

`instantiate_npc()` 会优先把 NPC 挂到 `ObjectAndCharacter/NPC`，没有则降级到 `ObjectAndCharacter`，再没有则挂到当前场景根节点。

### 运行时冻结

`_process(delta)` 每帧同步：

```gdscript
not_running = GameManager.get_game_state() != GameManager.GameState.RUNNING
```

只有 `GameState.RUNNING` 时才会同步场上 NPC 数据和更新 EYE 离场行为。

### EYE 仇恨管线

`GameManager.arrgoed`：

- 所有 EYE 的 `NPCData.state = 1`。
- 如果 EYE 在场，设置 `arrgoing = true`，并发出 `toPursue` 信号。

`GameManager.not_arrgoed`：

- 所有 EYE 的 `NPCData.state = 0`。
- 如果 EYE 在场，设置 `arrgoing = false`。

EYE 离场行为：

- `state == 0` 时，每 `EYE_WANDER_INTERVAL` 秒随机换一个 `current_scene`。
- `state == 1` 时，等待 `EYE_CHASE_DELAY` 秒后尝试从门进入当前场景。
- 追杀入场会读取 EYE 上一个场景的 PackedScene，寻找 `BaseDoor.scene_to == 当前场景 key` 的门，并使用它的 `scene_to_index` 作为当前场景出生点。

### NPC jumpscare 管线

玩家被 NPC 伤害杀死时，流程如下：

1. `damage_component` 在命中时把自己的 `entity` 作为 `damage_source` 传给目标 `hurted_component._on_hurt(damage_amount, entity)`。
2. 玩家身上的 `hurted_component` 进入死亡分支后，如果 `damage_source is npc`，会在调用 `player.player_died()` 前发出：

```gdscript
signal npc_kill_player(damage_source: npc)
```

3. `NPCManager._connect_player_hurted_component()` 监听该信号，并在 `_on_npc_kill_player(damage_source)` 中根据伤害来源选择 jumpscare。
4. `_get_jumpscare_type_for_damage_source(damage_source)` 当前支持：

```gdscript
if damage_source is EnemyEye:
	return npc_type.EYE
```

5. `_play_jumpscare_for_damage_source()` 通过 `jumpscare_player_paths` 找到对应 PackedScene。当前配置为：

```gdscript
var jumpscare_player_paths: Dictionary = {
	npc_type.EYE: "res://Effect/Animation/eye_jumpscare.tscn",
}
```

6. 播放前会创建独立于当前场景的 `JumpscareCanvasLayer`：

```gdscript
_jumpscare_canvas_layer = CanvasLayer.new()
_jumpscare_canvas_layer.layer = JUMPSCARE_LAYER_INDEX # 10
add_child(_jumpscare_canvas_layer)
```

该节点挂在 Autoload `NPCManager` 下，不挂在 `get_tree().current_scene` 下。因此玩家死亡后即使触发场景切换，jumpscare 也不会随当前场景一起被释放。

7. jumpscare 场景实例化到该 layer 后，`NPCManager` 会连接 `oneshot_finished`：

```gdscript
_active_jumpscare_player.connect("oneshot_finished", _on_jumpscare_player_finished, CONNECT_ONE_SHOT)
```

8. `JumpScarePlayer.play_oneshot()` 播放完成后发出 `oneshot_finished`，`NPCManager._on_jumpscare_player_finished()` 调用 `_clear_jumpscare_canvas_layer()`，清理整个 jumpscare layer。

## 添加或修改内容

### 添加新的 NPC jumpscare

推荐步骤：

1. 创建 jumpscare PackedScene，例如：

```gdscript
res://Effect/Animation/new_enemy_jumpscare.tscn
```

2. 根节点挂 `JumpScarePlayer` 脚本：`res://Scripts/system/view/jumpscare_player.gd`。
3. 在该场景中添加一个或多个 `AnimatedSprite2D`。如果需要在 Inspector 中配置起止缩放、位置、旋转和时间，建议把 sprite 类型脚本换成：

```gdscript
res://Scripts/system/view/jumpscare_animated_sprite.gd
```

4. 在 `JumpScarePlayer.animation_array` 中加入这些 `AnimatedSprite2D`。
5. 每个 `JumpscareAnimatedSprite` 可配置：

- `start_scale` / `end_scale`
- `start_position` / `end_position`
- `start_rotate` / `end_rotate`，单位是 Godot `Node2D.rotation` 使用的弧度。
- `animate_time`
- `wait_time`
- `dissolve_time`
- `dissolved_paramater`，默认是 `DissolveValue`。

`JumpScarePlayer.play_oneshot()` 会让每个 sprite 在 `animate_time` 内从 start 值平滑过渡到 end 值，之后保持 `wait_time`，再在 `dissolve_time` 内把 material 的 `shader_parameter/<dissolved_paramater>` 从 `0.0` 变为 `1.0`。所有 sprite 完成后发出 `oneshot_finished`。

6. 在 `npc_type` 中加入新 NPC 类型，或复用已有类型。
7. 在 `jumpscare_player_paths` 中加入类型到 PackedScene 路径的映射：

```gdscript
var jumpscare_player_paths: Dictionary = {
	npc_type.EYE: "res://Effect/Animation/eye_jumpscare.tscn",
	npc_type.NEW_ENEMY: "res://Effect/Animation/new_enemy_jumpscare.tscn",
}
```

8. 在 `_get_jumpscare_type_for_damage_source(damage_source)` 中加入来源判断：

```gdscript
if damage_source is NewEnemy:
	return npc_type.NEW_ENEMY
```

如果某个 NPC 不需要 jumpscare，不要在 `_get_jumpscare_type_for_damage_source()` 中返回它的类型即可。

### 添加新的 NPC

推荐步骤：

1. 创建 NPC 场景，例如 `res://System/RPG/entity/npc/Enemy/NewEnemy/NewEnemy.tscn`。
2. NPC 根节点脚本建议提供这些属性：

```gdscript
var npc_direction: Vector2
var state: int
```

如果要接入 EYE 风格状态切换，提供信号：

```gdscript
signal toPatrol
signal toPursue
```

3. 如果是新的 NPC 类型，在 `npc_type` 中添加：

```gdscript
enum npc_type {
	EYE,
	melt,
	NEW_ENEMY
}
```

4. 在 `npc_dict` 添加数据，并在 `_create_default_npc_dict()` 中添加同一份默认数据：

```gdscript
"2-0": NPCData.new().setup(
	preload("res://System/RPG/entity/npc/Enemy/NewEnemy/NewEnemy.tscn"),
	npc_type.NEW_ENEMY,
	"2-2",
	Vector2(500, 300),
	Vector2.DOWN,
	false,
	0
),
```

字段含义：

- 第 1 个参数：NPC PackedScene。
- 第 2 个参数：NPC 类型。
- 第 3 个参数：当前所在场景 key。
- 第 4 个参数：场景内全局坐标。
- 第 5 个参数：朝向。
- 第 6 个参数：是否正在场上，通常填 false。
- 第 7 个参数：初始状态。

5. 确认目标场景已经在 `SceneManager.scene_dict` 中注册。
6. 确认目标场景有 `ObjectAndCharacter/NPC` 节点，方便组织和 y-sort。

### 添加新的 NPC 行为类型

如果新类型需要离场行为：

1. 在 `npc_type` 添加枚举。
2. 在 `_process()` 中增加更新入口，例如 `_update_new_enemy_behaviors(delta)`。
3. 在新函数中只处理 `not data.is_inscene` 的离场逻辑，场内行为仍交给 NPC 场景自己的脚本。
4. 如果它会响应全局信号，在 `_ready()` 里连接对应信号。
5. 如果状态切换要写入实例，更新 `_apply_npc_initial_state()`。

### 让 NPC 数据可存档

基础字段已经由 `NPCData` 存档。如果新增字段：

1. 更新 `NPCData` 字段。
2. 更新 `NPCData.to_dict()` 和 `from_dict()`。
3. 在 `NPCManager._update_inscene_npc_data()` 中从实例同步到 data。
4. 在 `NPCManager.instantiate_npc()` 或 `_apply_npc_initial_state()` 中把 data 写回实例。

### 给 EYE 追杀配置门

EYE 追杀入场依赖门配置：

- 在 EYE 之前所在场景里，必须有 `BaseDoor`。
- 该门的 `scene_to` 要等于当前场景 key。
- 该门的 `scene_to_index` 要指向当前场景 `BaseLevel.player_initial_position` 的正确下标。

如果找不到匹配门，NPCManager 会随机选择当前场景一个合法出生点。

## 注意事项

- `npc_id` 用字符串，例如 `"0-0"`。存档会使用这个 ID，改 ID 会影响旧存档。
- 场内 NPC 行为由 NPC 自己的脚本负责；NPCManager 只做跨场景数据和少量全局行为。
- `NPCData.is_inscene` 保存时统一视为 false，读档后由 `player_reseted` 重新入场。
- 新游戏不读取旧 `NPCData`，而是通过 `reset_to_default_state()` 重建默认 `npc_dict`。
- `_npc_instances` 保存弱引用。新增代码需要访问 NPC 实例时，优先使用 `_get_npc_instance()`。
- 如果 NPC 场景没有 `npc_direction` 或 `state` 属性，NPCManager 会跳过对应字段同步。
- EYE 的随机游荡从 `SceneManager.scene_dict.keys()` 中选场景，所以没有注册的场景不会成为游荡目标。
- jumpscare layer 必须挂在 `NPCManager` 下，不能挂在当前场景下，否则死亡回主菜单时会随场景切换被释放。
- `JumpScarePlayer` 播放完成后由 `oneshot_finished` 通知 `NPCManager` 清理整个 `JumpscareCanvasLayer`；jumpscare 场景本身不要自行依赖当前场景节点。
