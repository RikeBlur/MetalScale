# EnvironmentManager 操作说明

源文件：`res://Scripts/global/environment_manager.gd`  
Autoload 名称：`EnvironmentManager`

`EnvironmentManager` 管理场景环境资源和全局视觉滤镜。当前主要处理 `WorldEnvironment`、默认环境光，以及仇恨系统的 CRT/干扰视觉效果。

## 主要职责

- 在玩家进入新场景后，为当前场景设置统一 `Environment`。
- 设置当前场景 `CanvasModulate` 的默认颜色。
- 监听 `GameManager` 的仇恨信号。
- 创建和淡入淡出仇恨视觉效果。
- 根据玩家 `aggro_value` 动态调整 `arrgoing` shader 参数。
- 在换场后根据当前仇恨状态恢复视觉效果。
- 在玩家死亡回主菜单前，提供统一清理所有视觉效果的接口。

## 参与游戏管线的操作

### 场景切换后设置环境

`_ready()` 会连接：

```gdscript
SceneManager.player_reseted.connect(set_environment)
```

当玩家在新场景落位后，`set_environment()` 会：

1. 查找当前场景的 `WorldOfWonder` 节点。
2. 把 `environment_now.environment` 设置为 `world_of_wonder`。
3. 查找 `WorldOfWonder/CanvasModulate`。
4. 把颜色设置为 `GameManager.default_lighting`。
5. 清理无效的仇恨滤镜引用。
6. 根据 `GameManager.player_arrgo` 恢复当前应显示的滤镜。

这说明场景内必须有 `WorldOfWonder`，否则该场景不会被 EnvironmentManager 正常管理。

### 仇恨视觉管线

`EnvironmentManager` 监听：

- `GameManager.get_in_arrgo`
- `GameManager.get_out_arrgo`
- `GameManager.arrgoed`
- `GameManager.not_arrgoed`

行为：

- `get_in_arrgo`：淡入 `arrgoing` 效果。
- `get_out_arrgo`：淡出 `arrgoing` 效果。
- `arrgoed`：淡出 `arrgoing`，淡入 `arrgoed`。
- `not_arrgoed`：淡出 `arrgoed`。

视觉节点会挂到 `ArrgoEffectLayer`，默认层级为：

```gdscript
@export var arrgo_effect_layer: int = 4
```

当前 `CutsceneManager` 层级是 5，因此 cutscene 默认盖在仇恨滤镜上方。

### 动态 shader 参数

`_process()` 每帧调用 `_update_arrgoing_material_parameters()`。

当 `arrgoing` 效果存在时，它会读取：

```gdscript
GameManager.get_player().aggro_value
```

并把以下 shader 参数设置到 0 到 `ARRGOING_PARAMETER_MAX` 之间：

- `scanlines_opacity`
- `scanlines_width`
- `grille_opacity`

此外，如果 effect 的材质有 `effect_opacity` 参数，淡入淡出会优先使用 shader 参数控制透明度。

### 死亡回主菜单前清理视觉效果

`GameManager._on_player_died()` 在死亡 cutscene 完成后、回到 OpeningMenu 前会调用：

```gdscript
EnvironmentManager.clear_all_visual_effects()
```

该函数会杀掉当前效果 tween，释放 `ArrgoEffectLayer` 中的效果节点，并清空内部缓存字典。新增由 EnvironmentManager 主管的视觉效果时，也应该纳入这个清理范围，避免死亡回菜单或重新开始游戏后残留滤镜。

## 添加或修改内容

### 让新场景接入环境系统

每个 RPG 关卡场景建议添加：

```text
WorldOfWonder  WorldEnvironment
  CanvasModulate  CanvasModulate
```

`EnvironmentManager._get_world_environment()` 当前固定查找：

```gdscript
current_scene.get_node_or_null("WorldOfWonder")
```

所以节点名要保持 `WorldOfWonder`，除非同步修改代码。

### 修改默认环境

默认环境资源：

```gdscript
const world_of_wonder: Environment = preload("res://Style/environment/WorldOfWonder.tres")
```

默认环境光颜色：

```gdscript
GameManager.default_lighting
```

如果只是改整体色调，优先改 `GameManager.default_lighting`。如果要换环境资源，改 `world_of_wonder` 指向的新 `.tres`。

### 添加新的全局视觉效果

以新增 `"low_health"` 效果为例：

1. 创建效果场景，例如 `res://Effect/Shader/low_health/low_health.tscn`。
2. 场景中至少有一个 `ColorRect` 或其他 `CanvasItem`。
3. 如果材质需要淡入淡出，shader 中提供：

```glsl
uniform float effect_opacity = 0.0;
```

4. 在 `environment_manager.gd` 添加 key 和路径：

```gdscript
const LOW_HEALTH_EFFECT_KEY: String = "low_health"
@export_file("*.tscn") var low_health_scene_path: String = "res://Effect/Shader/low_health/low_health.tscn"
```

5. 更新 `_get_effect_scene_path(effect_key)`：

```gdscript
LOW_HEALTH_EFFECT_KEY:
	return low_health_scene_path
```

6. 在合适的信号回调中调用：

```gdscript
_fade_in_arrgo_effect(LOW_HEALTH_EFFECT_KEY)
_fade_out_arrgo_effect(LOW_HEALTH_EFFECT_KEY)
```

当前函数名带 `arrgo`，但内部实现是通用的 effect 管理，新增效果也可以复用。

### 添加随数值变化的 shader 参数

如果新效果需要随某个游戏数值变化：

1. 保存该效果 ColorRect 或材质引用。
2. 在 `_process()` 中增加更新函数。
3. 从 `GameManager`、玩家或其他管理器读取数值。
4. 调用 `material.set_shader_parameter()`。

仇恨效果可参考 `_update_arrgoing_material_parameters()`。

## 注意事项

- `EnvironmentManager` 只在 `SceneManager.player_reseted` 后设置环境。主菜单或非 RPG 场景如果没有走这个信号，不会自动设置。
- `WorldOfWonder` 节点名是硬编码。
- 效果场景路径会缓存到 `_arrgo_effect_scenes`，资源路径改动后需要重启或清缓存。
- 淡出完成会 `queue_free()` 效果节点，并清理字典引用。
- 死亡回主菜单前会调用 `clear_all_visual_effects()`，新增效果如果保存了额外引用，也要在该函数里清理。
- 如果 effect 场景里没有 `ColorRect`，会发出 warning 并销毁该效果节点。
- `arrgo_effect_layer` 默认低于 cutscene，高于普通 UI layer 1 到 3。若新增滤镜要覆盖 UI，需要谨慎调整层级。
