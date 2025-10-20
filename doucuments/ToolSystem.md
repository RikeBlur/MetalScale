# Tool System

## 逻辑核心：ToolManager
res://Scripts/system/tools/tool_manager.gd<br>
注意，Tool 是一个广义的 工具类，任何会被玩家获取且可以在某种情况下激活的实例都被称为 Tool 。 <br>

### 基本属性
枚举类 **Tool** ： 保存所有工具的名称。<br>
每个 Tool 对应一个 **preload 场景**。<br>
current_tool ： 用于保存现在使用的 Tool。<br>
所有 工具场景节点 均为该节点的子节点，该节点为玩家的子节点。<br>
	
### 工具分类
Tool 简单分为三类 ： 永久使用类（config == 0）;耐久使用类（config == 1）;消耗品类（config == 2）。比较令人
疑惑的：每个 Tool 对应的 config 并不存在与 ToolManager 中，而是存在于 ToolBar 中。<br>
config == 1 的 Tool 需要在字典类 durability 中设置耐久上限， 随时间消耗的话，需要设置
 durability_consumption 。<br>
config == 2 的 Tool 需要在字典类 consumption 中设置持有量。
	
###重要方法 
_on_tool_changed ： current_tool 变化时调用。清除掉当前的子节点（工具场景节点），实例化
 current_tool 对应的 工具场景节点 并设为子节点。如需要，播放特效、音效。需注意，**每个 Tool 对应一个代码段**<br>
_process : 每个 Tool 需要即时处理的逻辑， 如 每帧消耗耐久、使用消耗品； 切换 Tool 逻辑。目前通过数字切换，
读取玩家的可用工具列表，将对应的值赋给 current_tool （同时改变玩家的 tool）；需注意，**每个 Tool 对应一个代码段**<br>


## 渲染核心：ToolBar
res://Scripts/system/view/UI/toolbar/toolbar.gd<br>

### 基本属性
**TOOL_ICONS** 每个 Tool 对应的 icon 文件 <br>
**TOOL_CONFIG** 每个 Tool 对应的config（0、1、2） <br>
tool_boxes 用于存储 ToolBar 的组件 ToolBox <br>
	
### 组件 ToolBox
state ： 0 未激活、1 已激活、2 不可激活；
tool ： 对应的 Tool；
config ： 对应的 Tool 的 config；
icon ： 对应的图标；
durability ： 对应的耐久条（对应场景 DURABILITY_BAR_SCENE ）<br>
重要方法 update_children_based_on_config ： config == 0 时，清除 icon 外所有子节点；
config == 1 时，如果没有"DurabilityBar"子节点，则通过 DURABILITY_BAR_SCENE 加载，并清除
处 icon 和 DurabilityBar 外所有子节点；
config == 2 时，清除 icon 外所有子节点。<br>
需要注意，每次 Toolbox 的 config 发送变化时， 会自动调用方法。<br>
	
###重要方法 
_update_progressbar ： 遍历 toolboxes， 如果当前 ToolBox 有 durability，则根据 ToolManager 中对应的
数值更新  durability_progressbar。<br>
_update_toolbar ： 遍历玩家可用工具 tool_available ，根据 tool_available 更新每个 ToolBox 的
tool icon 和 config；并玩家的 tool 更新 ToolBox 的 state（同步 material 的 state parameter）。<br>


## 工具一览

### 0 空手 NONE

config 0
无对应场景，完全的无，不过后续考虑增添对应空场景避免边界问题。<br>

### 1 应急光源 EMERGENCELIGHT

res://System/RPG/tools/EmergenceLight.tscn<br>
config 1 每秒消耗 0.05 <br>
1.toolbody 工具本身的sprite，待设计 <br>
2.radial_light 辐射光源，详细设定见 LightingSystem <br>
3.SuccessSFX 激活音效 <br>

### 2 手电筒 FLASHLIGHT

res://System/RPG/tools/FlashLight.tscn<br>
config 1 每秒消耗 0.05 <br>
1.toolbody 工具本身的sprite，待设计 <br>
2.ParallelLight 锥形光源，详细设定见 LightingSystem <br>
3.SuccessSFX 激活音效 <br>
4.随鼠标转动：通过转动toolbody、ParallelLight 的渲染节点 和 给 ParallelLight增加 angle_offset 实现 <br>

### 3 肾上腺素 ADRENALINE

res://System/RPG/tools/Adrenaline.tscn<br>
config 2 持有上限 1 <br>
消耗时调用 adrenaline_release() <br>
