# UIManager 操作说明

源文件：`res://Scripts/global/ui_manager.gd`  
Autoload 名称：`UIManager`

`UIManager` 负责实例化、分层、显示、隐藏和关闭游戏 UI。它依赖每个场景中存在 `UI_LAYERS` 节点，并按 `CanvasLayer.layer` 把 UI 放入对应层。

## 主要职责

- 维护 `UI_component` 枚举。
- 维护 `UI_DATA`，记录 UI 场景、层级、初始化阶段、是否可退出、是否谜题 UI。
- 扫描当前场景的 `UI_LAYERS`，缓存 CanvasLayer。
- 初始化 stage 0 UI。
- 管理 UI 实例缓存。
- 维护每层当前可见 UI 列表。
- 响应 ESC 关闭窗口或打开设置菜单。
- 响应 Tab 显示或隐藏工具栏。
- 响应仇恨信号显示或隐藏 `ARRGOBAR`。
- 显示拾取物品窗口。

## 参与游戏管线的操作

### UI 刷新时机

`refresh_ui_manager()` 会在两个地方被调用：

- `GameManager.start_new_game()` 切入起始场景后。
- `BaseLevel._ready()` 每次新场景加载时。

刷新流程：

1. 从当前场景查找 `UI_LAYERS`。
2. 从 `GameManager.get_player()` 获取玩家。
3. `_initialize_layers()` 扫描 CanvasLayer。
4. `_initialize_stage0_ui()` 实例化 `stage == 0` 的 UI。
5. 隐藏 settings 和 toolbar。
6. 连接 `GameManager` 的仇恨信号。
7. 根据 `GameManager.player_arrgo` 恢复 `ARRGOBAR` 可见性。
8. 如果开启 debug，创建 UIManager debug 面板。

### ESC 管线

`_process()` 中会检测 `InputEvents.quit_once()`。

处理顺序：

1. 优先关闭 layer 3 的顶部可见 UI。
2. 再关闭 layer 2 的顶部可见 UI。
3. 如果 settings 正在显示，则关闭 settings。
4. 如果当前是 `GameState.RUNNING + RunningState.CONTROL`，则打开 settings。

打开 settings 时设置 `GameManager.RunningState.MENU` 并显示鼠标。关闭 settings 时设置 `GameManager.RunningState.CONTROL` 并隐藏鼠标。

### Tab 工具栏

`Input.is_action_just_pressed("tab")` 会调用 `_toggle_toolbar()`。

工具栏 UI 是 stage 0 自动实例化，但默认会被 `_hide_toolbar()` 隐藏。显示或隐藏只移动位置并更新可见列表，不释放工具栏实例。

### 仇恨条

`refresh_ui_manager()` 会连接：

- `GameManager.get_in_arrgo -> _show_arrgobar`
- `GameManager.get_out_arrgo -> _hide_arrgobar`

如果刷新时 `GameManager.player_arrgo > 0`，会直接显示 `ARRGOBAR`，用于跨场景保持仇恨 UI。

### 拾取提示窗口

入口：

```gdscript
UIManager.show_collect_window(tool_name)
```

当前由 `collectable_component.gd` 在成功拾取工具后调用。

## 添加或修改内容

### 添加新的 UI 组件

推荐步骤：

1. 创建 UI 场景，例如 `res://System/RPG/UI/my_window.tscn`。
2. 如果 UI 需要关闭自己，脚本里暴露 `own_manager`，关闭时调用：

```gdscript
own_manager.remove_ui(UI_manager.UI_component.MY_WINDOW)
```

3. 在 `UI_component` 中添加枚举。
4. 在 `UI_DATA` 添加配置：

```gdscript
UI_component.MY_WINDOW: {
	"name": UI_component.MY_WINDOW,
	"scene": preload("res://System/RPG/UI/my_window.tscn"),
	"layer": 2,
	"stage": -1,
	"can_be_quit": true,
	"is_puzzle": false
}
```

`can_be_quit` 表示实例化后是否加入可见队列。设为 `true` 时，ESC/quit 会按 layer 从高到低的顺序逐个关闭它。

`is_puzzle` 表示该 UI 是否属于谜题界面。设为 `true` 时会沿用谜题退出检测逻辑。

如果 UI 脚本里声明了 `own_manager`、`player_now` 或 `ui_type`，`instantiate_ui()` 会自动注入，不需要再为每个 UI 写单独分支。

5. 外部打开：

```gdscript
UIManager.instantiate_ui(UI_manager.UI_component.MY_WINDOW)
```

6. 外部关闭：

```gdscript
UIManager.remove_ui(UI_manager.UI_component.MY_WINDOW)
```

### 选择 UI 层级

当前约定：

- layer 1：常驻 HUD，例如 toolbar、settings、arrgobar。
- layer 2：菜单页或功能面板，例如设置详情、玩家信息、保存、读取。
- layer 3：弹窗，例如退出确认、拾取提示。

ESC 会优先关闭最高 layer 的 `can_be_quit == true` UI，最后才处理 settings。因此新弹窗一般放 layer 3。

### 设置 UI 是否自动创建

`UI_DATA.stage` 当前含义：

- `0`：`refresh_ui_manager()` 时自动实例化。
- `-1`：按需实例化。

如果一个 UI 是每个场景都应存在但默认隐藏，可以设为 `0`，然后在刷新流程里隐藏或禁用。

### 场景必须提供 UI_LAYERS

每个参与 RPG 管线的场景都应有：

```text
UI_LAYERS
  UI_layer1  CanvasLayer layer = 1
  UI_layer2  CanvasLayer layer = 2
  UI_layer3  CanvasLayer layer = 3
```

否则 `UIManager.instantiate_ui()` 会找不到目标 layer。

### 给 UI 传玩家引用

`instantiate_ui()` 会统一检查 UI 实例是否暴露了以下字段，并自动注入：

- `own_manager`：注入当前 `UIManager`。
- `player_now`：注入当前玩家引用。
- `ui_type`：注入当前 `UI_component`，谜题 UI 关闭自身时会用到。

新 UI 如果需要这些引用，只要在脚本中声明对应变量即可。推荐需要长期刷新玩家状态的 UI 使用 `player_now` 注入，弹窗类 UI 也可以直接调用 `GameManager.get_player()`。

## 注意事项

- `ui_instances` 保证同一 UI 类型通常只有一个实例。重复实例化会返回已有实例。
- `remove_ui()` 会 `queue_free()` 并从可见列表移除。
- 如果某个 UI 被手动隐藏但没有从 `layer_visible_uis` 移除，ESC 的关闭顺序会不准确。
- `safe_remove_all_ui()` 会遍历移除所有 UI；普通换场主要依赖新场景 `refresh_ui_manager()` 重新绑定层级。
- Settings 打开时会把 `RunningState` 切到 `MENU`，新增菜单 UI 如果会暂停玩家，也应遵守这个状态约定。
