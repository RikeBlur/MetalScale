# CutsceneManager 操作说明

源文件：`res://Scripts/global/cutscene_manager.gd`

Autoload 名称：`CutsceneManager`

`CutsceneManager` 只负责播放“场景类过程动画”：注册 cutscene 场景、实例化播放、淡入淡出、跳过、死亡 cutscene，以及播放前后对玩家输入和 `GameManager.RunningState` 的管理。

需要在 cutscene 某个时间点触发外部逻辑时，应优先使用具体节点、事件脚本、Godot 原生 signal，或由 cutscene 场景自身脚本直接调用明确的系统 API。

## 主要职责

- 维护 `cutscene_scenes`：cutscene key 到 `PackedScene` 的映射。
- 播放指定 cutscene 场景。
- 播放时设置 `GameManager.RunningState.AUTO`。
- 播放时禁用玩家移动和交互，结束后恢复。
- 把 cutscene 实例挂到当前场景的 `CanvasLayer`。
- 控制 cutscene 节点淡入淡出。
- 支持长按 `ESC` 跳过当前 cutscene。
- 监听 `GameManager.player_died` 并播放死亡 cutscene。

## 普通播放流程

入口：`play_cutscene(key)`

1. 检查 `cutscene_scenes` 是否存在该 key。
2. 如果已有 cutscene 正在播放，则忽略新请求。
3. 保存当前 `RunningState`。
4. 设置 `GameManager.RunningState.AUTO`。
5. 保存并禁用玩家 `can_move` 和 `can_interact`。
6. 创建 `CanvasLayer`，层级为 `CANVAS_LAYER_INDEX`，当前为 `5`。
7. 实例化 cutscene 场景，并设置 `modulate.a = 0`。
8. 如果 cutscene 根节点有 `fadein_time`，使用它作为淡入淡出时长。
9. 等待一帧后连接 cutscene 根节点的 `cutscene_finished` 信号。
10. 淡入 cutscene。
11. 收到 `cutscene_finished` 后淡出、释放节点和层。
12. 恢复之前的 `RunningState`。
13. 恢复玩家移动和交互状态。
14. 发出 `cutscene_playback_finished`。

## 添加新的 cutscene

1. 创建新的 `.tscn`。
2. 根节点建议是 `Control`，挂 `Scripts/system/view/cutscene/cutscene.gd`。
3. 如果需要自定义淡入时间，设置根节点的 `fadein_time`。
4. 子节点播放完自己的部分后，发出 `cutscene_finished_partly`；`Cutscene` 会等待所有带这个信号的子 `Control` 完成后发出总的 `cutscene_finished`。
5. 在 `CutsceneManager.cutscene_scenes` 注册：

```gdscript
var cutscene_scenes: Dictionary = {
	"intro_2": preload("res://System/RPG/cutscene/2_1/intro_2.tscn"),
}
```

6. 外部播放：

```gdscript
CutsceneManager.play_cutscene("intro_2")
await CutsceneManager.cutscene_playback_finished
```

如果 cutscene 根节点没有 `cutscene_finished` 信号，需要在合适时机手动调用：

```gdscript
CutsceneManager.finish_cutscene()
```

## 跳过 cutscene

`_process()` 会调用 `_update_skip_input(delta)`。

- 只有 cutscene 正在播放且不在结束流程时生效。
- 长按 `ESC` 累积时间。
- 达到 `skipping_time_limit` 后调用 `finish_cutscene()`。
- 左下角会显示圆环进度。
- cutscene 根节点可通过 `buffer_time` 配置开始播放后多久允许跳过。

## 死亡 cutscene

`_ready()` 会连接 `GameManager.player_died`。玩家死亡后：

1. 设置 `RunningState.AUTO`。
2. 创建黑屏层 `DeathBlackoutLayer`。
3. 如果 `cutscene_scenes` 有 `"death"`，播放它。
4. 等待 `cutscene_playback_finished`。
5. 发出 `death_cutscene_finished`。

`GameManager` 会等待 `death_cutscene_finished` 后回到主菜单。

## 替换开场 cutscene

保持 key 不变，只替换资源：

```gdscript
"test": preload("res://System/RPG/cutscene/1_1/new_intro.tscn")
```

或者新增 key，然后修改调用处：

```gdscript
CutsceneManager.play_cutscene("new_intro")
```

## 替换死亡 cutscene

修改或新增：

```gdscript
"death": preload("res://System/RPG/cutscene/death/death.tscn")
```

死亡流程固定读取 `"death"` key，不需要改 `GameManager`。

## 注意事项

- 同一时间只允许一个 cutscene 播放；播放中再次调用 `play_cutscene()` 会被忽略。
- cutscene 结束后会恢复播放前的 `RunningState`。
- 播放 cutscene 时只保存和恢复 `can_move`、`can_interact`，当前没有保存 `can_act`。
- `any_key_continue == true` 的 cutscene 不能依赖子控件 `cutscene_finished_partly` 结束，只能等待按键。
- 死亡流程里会创建黑屏层，当前代码没有在 `CutsceneManager` 内主动释放它；回主菜单换场会清掉当前场景节点。
- 如果 cutscene 场景永远不发出 `cutscene_finished`，流程会卡住，除非玩家长按 `ESC` 或外部调用 `finish_cutscene()`。
