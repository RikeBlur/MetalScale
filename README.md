# UPDATE

## 26.02.07

完成 ArrgoComponent 里 get_caught / get uncaught 信号和各种东西
（UIManager/GameManager/ElectronicScreen）的绑定
【用信号而不是用变量控制，这样方便在开始和结束时触发不对称的效果】

GlobalFucntion / GlobalFunction ??

## 26.01.26

ElectronicScreen ： 新增了 ScreenContent（WavingNoise）；JIU（汉字） <br>
解决了无法正常遮挡逻辑光线的问题 <br>

## 26.01.25

完善了消融效果（neo_dissolve）；解决了 transition 的黑噪点问题 <br>
请！！ 完成 ElectronicScreen ！ 和 ArrgoBar！ <br>

## 26.01.17

请！！ 完成 ElectronicScreen ！ <br>

## 25.12.09

完成 ElectronicScreen ！ 似乎 RUNNING 过程中没有自动挂载 LightingSystem <br>

## 25.12.07

做 ElectronicScreen ！

## 25.12.04

1.游戏总线 （剩余困难）： <br>
为什么 PreloadingAnimate 作为 CanvasLayer 会遮盖输入？ <br>
场景加载 Loading 实现过程 还在构思 <br>

2.声音系统： <br>
需要的音效汇总： <br>
player 脚步 ；  <br>
切换道具；  <br>
拾取可收集物； <br>
开门； <br>
开锁； <br>
开门失败； <br>
点击 settingbox； <br>
点击 normalUI； <br>
BGM； <br>

3.死亡动画： <br>
构想 jump scare 动画 <br>
死亡后的 menu （回到菜单、退出、读取最近存档） <br>

4.NPC数据 <br>

重构尝试： 在 load game 时不直接调用切换场景的 change scene，而是单独再写一个实现！！ <br>

新增 RUNNING 内部的三种状态 CONTROL/AUTO/MENU <br>

## 25.12.03

检查 锁门/开门 能否 跨存档 正常运作！ <br>

目前 锁门/开门 和 拾取物品后形式消失 都可以 跨存档 正常运作 <br>

值得注意的是，可拾取物形式上消失后，交互节点本身并没有消失，所以还是会触发 INTERACTED 只不过没有实际逻辑效果 <br>

## 25.12.02

CollectableReminder 更新！ <br>

完善 baselevel 类：每次加载场景，都需要更新可交互位点状态！！每次改变可交互位点状态，也要更新到 SceneData里！！ <br>

新建数据结构 InteractableData  <br>

每个 BaseLevel 有一个 Interactables （InteractableData数组） <br>
SceneData 也 由 SceneManager 维护一个 Interactables，用于全局信息维持！ <br>

现在门开了之后不会关上了！ <br>

后续要想办法在 preloading 阶段为 每个 SceneData 初始化 Interactables！ <br>

## 25.12.01

Loading ： 只在加载存档时候进入 loading 状态（目前）。 <br>

SceneData目前没啥内容，我认为关于场景的信息参数（每个可交互位点的状态）可以写到 BaseLevel 里，当参数变动时，调用 SceneManager 重写对应 SceneData 里对应的参数，这样确保全局的SceneData 动态变化，存档时可以保存每个场景的实际状态无误。 <br>

完成以下 情景（用于检查存档和SceneData）： <br>
房间1-1、1-2、1-3 <br>
1-1 to 1-2 门 开； <br>
1-1 to 1-3 门 关； <br>
1-2 内 存在 collectable_key 用于打开 1-1 to 1-3 门; <br>

BaseLevel 构造 InteractableDict，目前分为三类：门、收集物、机关 <br>

目前完成了门的三种状态（0，1，2），确保每种状态有对应的 reminder 生成 <br>
所有 reminder z_index==7 !!!
每个门对应一个 key（Tool类），如果门是锁着的且玩家的 tool_available 中有对应的 key，则开锁（不开门）且移除这个key<br>

## 25.11.30

设计 Pipeline： <br>

preloading 完成，确保 ArchiveManager、SceneManager、UIManager、GF加载完成， <br>
包括一些初始化操作（管理器脚本不需要_ready） <br>
preloading 期间需要 PreloadingAnimate，Preloaded 信号 emit 时 淡出 <br>

为什么 PreloadingAnimate 作为 CanvasLayer 会遮盖输入？ <br>

场景加载 Loading 实现过程 还在构思 <br>

## 25.11.29

Reboot  <br>
12月必须完成： <br>
1.游戏总线； <br>
2.声音系统； <br>
3.死亡动画； <br>
4.SceneData的真实实现（场景的所有可交互实体）； <br>
5.NPC数据的保存； <br>
6.Collectble 完善 <br>

完成后上述功能后，基本的游戏demo就可以搭建了 <br>

## 25.11.14

需要实现游戏总线 ：  <br>
加载 Loading 状态的 进入 和 退出 ，通过 **信号** 判断，这个信号包括多个方面 <br>

loading 分为 preloading 和 loading！  <br>
preloading 加载 stage0 的系统（全局一致的） <br>
loading 加载 stage1 的系统（游戏局部的） <br>

通过 GameManager 逐个按顺序初始化 Stage0 系统 来实现 preloading ； <br>
通过 GameManager 逐个 refresh/初始化 Stage1 系统 来实现 loading ； <br>

loading、preloading 都有单独 scene <br>

void --> preloading --> menu --> loading --> running --> over <br>

12月之前完成： <br>
游戏总线；声音系统；死亡动画；SceneData的真实实现（场景的所有可交互实体）；NPC数据的保存；Collectble 完善<br>

需要的音效汇总： <br>
player 脚步 ；  <br>
切换道具；  <br>
开关光源； <br>
开门； <br>
点击settingbox； <br>
点击normalUI； <br>
BGM； <br>

## 25.11.13

更新blur shader， 更新 UIManager 使得打开settings （layer==2） 时 layer==1 和 viewpoint 施加 blur shader<br>

优先级： Collectble 完善；声音系统；死亡动画；SceneData的真实实现（场景的所有可交互实体）；NPC数据的保存；重构代码<br>

## 25.11.11

修补 ToolSystem ： config2（消耗品）的消耗数量显示问题  <br>

我的 ToolManager 每个 Tool 都是独立的实例，不存在 EMERGENCELIGHT_A 、 EMERGENCELIGHT_B .
所以对于可能复数个的东西（消耗品），严格按照增加这个 Tool 的 consumption 来实现 <br>

完成子类 Collectable， 由 interacted 扩展，交互后消失且对玩家的 tool_available 产生影响 <br>

优先级 ： 重构代码；声音系统；SceneData的真实实现（场景的所有可交互实体）；NPC数据的保存。 <br>

## 25.11.10

重构代码!!!!!  <br>
一周内完成  <br>

## 25.11.09

存档系统和多level游戏初步完成  <br>

每个 baselevel 有多个初始位点（对应不同入口） <br>

优先级：整理项目；做死亡画面 <br>

## 25.11.08

通过维护 每层的可视化UI字典 来实现 ESC 退出当前窗口（ESC不止用来控制settings！） <br>

给场景切换增加信号 player_reseted， 用于提示初始位置已设置完成
确保reload游戏时，不会完全加载完成后才移动玩家位置。 <br>

## 25.11.07

opening初步完成，需要存档界面 <br>

目前存档界面缺少信息显示；读档有问题，会出现瞬移。 <br>

需要优化场景切换的实现 <br>

## 25.11.06
开始制作 OPENING  进行中...<br>

全局游戏管理器 ： GameManager <br>

优先级：构建多level游戏；做opening；做死亡画面；整理项目

## 25.11.05
完成 存档系统（ArchiveManager） 保存三种数据： <br>
1. 玩家信息：@player.gd 中的每个变量 <br>
2. 场景信息：当前场景的 key（scene_now） ，以及每个SceneManager中每个场景的 SceneData <br>
3. NPC信息：这个暂时空着，没想好 <br>

目前只能快速存档和读档，三种数据的序列化和反序列化，保存的数据格式为 JSON 。 <br>

完成场景管理器（SceneManager） <br>
每个场景（Scene）对应一个 Resource 类 SceneData 变量，记录场景信息 <br>
切换场景方法。 <br>

优先级：构建多level游戏；做opening；做死亡画面；整理项目

## 25.11.04
转场动画完成。存档系统设计。 <br>

优先级：构建多level游戏；做opening；做死亡画面；做存档读档系统；整理项目 <br>

## 25.11.03
UI优化中。。。 <br>
暂时使用 test_tileset_3 制作场景 <br>
完成 BaseLevel 类 ： 游戏有多个场景组成，每个配置节点 BaseLevel，记录玩家被加载时的位置和朝向 <br>
GLOBAL_FUNCTION : 游戏全局信息和方法，比如场景切换、存储玩家节点。后续可能考虑分到多个脚本 <br>
优先级：构建多level游戏；学习完整架构；做opening <br>

## 25.11.01
优化UI中。。。 <br>
优先级：找tileset；学习完整架构；做opening <br>

## 25.10.30
完成 normal_demon 的动画 <br>

## 25.10.29
完成了exit_window <br>

## 25.10.27
给 normal_demon 增加动画（暂用AX）发现没什么问题，不过可以给 LimboAI 增一个 idle 脚本。 <br>
现有系统的 Docs 已经完成，有待完善。 <br>

**11.18之前计划**（不做完自杀（在日本也可也做一点））（做完第一个demo就出来了！！） ： <br>
1、 UI设计，基本上就是把 Toolbar 和 settings 的 style 整一下； <br>
2、 NormalDemon设计 ， 设计稿 和 idle walk run 动画画完； <br>
3、 第一版 SFX 确定一下，需要花点时间； <br>
4、 找 tileset（实在不行直接通过shader风格化，学yumenikki）做一个小关卡。 <br>

## 25.10.26
按Esc切换settings显示的功能完成。 <br>

## 25.10.20
setting类基本完成，需要填充功能，目前预计功能：存档、结束。 <br>
UISystem：控制场景中所有UI。 <br>

## 25.10.19
开始制作 ESC settings<br>

## 25.10.18
完成 ToolSystem 更新； config=2 的消耗品可以正常使用了； player类的属性tool现在只存储int，用于在tool_available里检索。<br>
完成 ToolSystem 文档，指导新 Tool 的扩展。<br>
设置 ToolBar 的 Style（等板子）；设置不同 config 对应的 ToolBox 的 Style（等板子）；画 NormalDemon 的动画（等板子）。<br>

## 25.10.17
做两个新 Tool 类， ParallelLight 和 Adrenaline。<br>
实现光源的 逻辑层 和 渲染层 实际分离！分到不同节点！<br>

## 25.10.16
完善 ToolSystem 系统， Toolbox 会自动加载 DurabilityBar 等子场景。<br>

## 25.10.15
准备开始配置音效和音乐。<br>

每个entity有独立的SFX_manager。<br>
值得注意的是 ToolManager 也有音效管理：<br>
对于选用了可以选用的 Tool ，会有 success_sfx，这个 stream_player 保存在 Tool 的场景下。<br>
对于试图选用不可使用的 Tool ，会有 failure_sfx， 这个 stream_player 会保存在持有的这个 ToolManager 的 entity 场景下。<br>

计划：完善工具系统（0、1、2三种工具，以及对于消耗品的处理、对于耗尽 Tool 的处理、对于耐久耗尽 Tool 的处理）并给出详细文档

## 25.10.14
NormalDemon的Pursue、Flee、Patrol都按照 八向 8-direction 来移动了。<br>

要补充 run、walk 动画<br>

## 25.10.13
完成hurted-damage（layer5-layer6）配置。目前角色死亡时一些地方处理的不鲁棒。<br>

NormalDemon的行动逻辑还存在很大问题。<br>

hit_flash效果被写入 player.animate 的 material 里，还是用 animation player 控制 hit flash internsity.<br>

所有ShaderMaterial都需要经过唯一化，才可以被配置参数！重点！<br>

## 25.10.12
ToolSystem系统 完成：<br>
### 系统介绍
	1.枚举类 ToolManager.Tool 作为工作名
	2.ToolManager 管理所有 Tool 的场景、耐久（config==1 有耐久工具）、数量（config==2 有数量消耗品）
	3.ToolManager 会清理子节点并实例化 player 当前激活的 Tool
	4.Player 的 tool_available 和 tool 表示玩家具有哪些工具、正在激活哪个工具
	5.ToolBar 控制节点用于渲染工具栏UI， ToolBox控制单个栏的属性
	6.ToolBar完全根据 Player 的 tool_available 来更新需要显示的 Tool； 根据 ToolManager 的属性来更新需要显示的ProcessBar
	7.总体而言：ToolManager负责所有工具的实际属性管理；Player负责玩家可调用和已调用工具的管理；ToolBar负责UI渲染。

## 25.10.11
工具栏ToolBar完成：<br>
	1. 读取player的tool_available来配置icon、processbar<br>
	2. 读取player的tool_now 来高亮显示（待完成）<br>
	3. 读取ToolManager中每个tool的durability来更新processbar<br>

Tilemap不太好处理，寻找替代方案

## 25.10.10
预定：完成normal_demon三状态动画；选取demon音效、脚步；完成hurt/damage配置；道具耐久UI设计；单一bgm，bgm切换机制。

## 25.10.08
normal_demon类实现：三种state（Patrol、Pursue、FLee），范围追踪玩家且惧光，目前会在光线边缘折返是个问题，需要改善<br>

工具系统 初步完成：有统一的tool_manager管理所有tool的生成、切换、耐久；player具有 tool_available 属性，可以确保只能调用玩家具备的工具。<br>

光探测器加入 intensity_future 变量，确保多层次感知。

## 25.10.07
换godot4.5之后帧率明显提升<br>

完成敌人类 entity/enemy/normal_demon ： 在一定范围内自动索敌玩家追击、检测到光照后会逃离。<br>

使用LimboAI实现，有待完善

## 25.10.07
光照系统优化问题：
	1.occlusion_points的采用多边形边缘采样，同时 gird_size 设为20，降低点数<br>
	2.radius_light_source 采样光线设置为36个，intersection阈值设为10<br>
	3.光探测器衍生4个点计算平均 （保存变量intensity_now）<br>
	4.目前单光源和4个实体交互可以60帧，有待进一步优化<br>

## 25.10.06
光照检测系统 完成：
### 系统介绍（light_mask == 1）
	1.系统由 LightingManager、LightSource、LightDetector三部分组成
	2.系统的基本功能：实现光照系统的渲染层、逻辑层分离。对于每个实体，都可以检测到实体所在位置的光照强度（Intensity）
### 光照管理器（LightingManager）
	1.实时更新场景中所有LightSource、LightDetector、OcclusionPoints
	2.将附近的 OcclusionPoints 分配给 LightSource
	3.将附近的 LightSource 分配给 LightDetector
	4.对 Occluder 进行栅格化采样，得到 OcclusionPoints（PackedVector2Array）
### 光源（LightSource）
	1.分多种类型，如径向光（Radial_light_source）
	2.本身是一个PointLight2D节点，具有光照渲染的基本属性
	3.将光纤栅格化为 SampleRay 变量
	4.通过射线检测 SampleRay 是否与 Occlusion 相交，按照极坐标思路计算每个 SampleRay 对应的角度和有效长度
	5.设计函数 calculate_intensity ，传入一个位置（到光源的距离和角度）， 计算 Intensity
### 光探测器（LightDetector）
	1.单纯的Node2D节点，只检查一个点的Intensity
	2.如果有距离内的LightSource，则挨个计算Intensity并求和
	
	
## 25.10.05
开始进行光照系统尝试，目前对于遮蔽的使用还有待探究

## 25.10.04
修复bug：配置了移动Camera后对话生成无法追随camera位置。已完成修复，通过实时更新camera位置和设置合适的offset<br>

Oni的奔跑动画已完成

## 25.09.30
完成抽象类 interact component / interacted component<br>

可以用于表达所有player和环境的交互，用 E键 输入

## 25.09.29
interact system -- dialogue 完成：
### 系统介绍（z-index 10 9）
	1./System/interact.dialogue/ 每个角色/双人角色组合对应一个tscn，称为一个“dialogue”（dialogue style）
	2.每个dialogue可以包含多个DialogueResource（DialogueText、DialogueChoice、DialogueFunction）
	3.dual_dialogue(双人角色组合对话)，需要a_index和b_index表示每个DialogueResource属于哪个角色（左a右b）
	4.在实际关卡场景中，存在dialogue_manager类Node2D节点，用于整个场景中的dialogue生成和触发

### 对话管理器（DialogueManager）
	1.主要配置内容：trigger_source(触发源，默认area2D)、trigger_flag（对话内容配置）、dialogue_content（所有DialogueResource）.
	2.trigger_source若为area2D，则以area_entered为触发信号，但有待完善！！
	3.trigger_flag（对应一个独立的dialogue）需配置内容：内容（在dialogue_content中的起止点）；是否单次触发；style；a/b_index（dual dialogue）。

### 对话资源（DialogueResource）
	1.DialogueText： 自动播放的文本，自行设置theme override。目前只能播放单音音效，无法配置配音
	2.DialogueChoice： 文本（text）+choices；每个choice会对应一个DialogueFucntion
	3.DialogueFucntion： 配置target_path（指定function的节点）；function_name；function_arguments；hide_dialogue_box（需要隐藏对话框）；wait_for_signal_to_continue（是否需要节点对应的信号来推进）

## 25.09.27
仿制对话系统已完成，后续修正点：speaker_img逻辑全部替换成animated_sprite_2d的逻辑；完成自定义类custom_botton

## 25.09.15
八向移动系统完成，手感待调试

## 25.08.25
QA系统基本完成，接下来完成30题

## SYSTEM
### interact
处理所有场景交互内容，包括所有实体间的交互，如道具拾取、伤害、位置改变、状态施加
### terrain
地图逻辑，包括地图切换、地图生成、小地图、寻路、光照系统逻辑等
### attribute
属性逻辑，包括实体所有属性的计算和buff、奖励系统
