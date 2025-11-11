# UPDATE

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
