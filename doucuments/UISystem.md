# UI System

## 主场景UI管理 ： UI Manager
res://Scripts/system/view/UI/ui_manager.gd<br>
主要负责游戏场景的所有 UI 的 生成、显示、隐藏 <br>

### 数据结构
枚举类 UI_Component : 定义所有游戏场景UI <br>
每个 游戏场景UI 对应一个 preload场景 <br>
UI_CONFIG ： 字典类型，保存每个UI对应的配置，包括 layer（被实例化在哪个CanvasLayer下）；stage（在哪个阶段被自动生成） <br>
layers ： 字典类型，保存每个 layer 和 对应的 CanvasLayer 节点 <br>
ui_instances : 字典类型，保存每个 UI_Component 和 对应的节点 <br>

### 核心方法
_instantiate_ui(ui_type: UI_component) ： 在正确的 layer 下实例化对应 UI_Component对应的场景节点，并将实例化节点
保存到 ui_instances 中； 对于特殊的 UI_Component (如 TOOLBAR)，做一些 UI初始化特殊处理。 <br>
_toggle_settings ： 根据是否 is_settings_showing 判断是 显示settings 还是 隐藏settings。
切换显示隐藏的主要内容有：调用 control 节点的 hide\show 方法；鼠标过滤设置；process配置设置；shader设置。<br>

## UI设计
### TOOLBAR (layer==1)
玩家的工具栏UI，详见 ToolSystem.md。 目前做成常态，考虑到游戏氛围，可能增加隐藏 ToolBar 的功能。<br>

### Settings (layer==2)
设置栏UI，游戏过程中按下 Esc 触发，显示在最上层，内容一系列按钮（settingbox 内的 button ），指向特定功能。<br>
这些 button 大多会引入新的 UI层，指向游戏底层功能，包括：
游戏退出（4）； 游戏保存（3）； 玩家状态（0）； 游戏设置（2）； 申比玩意（1）<br>
