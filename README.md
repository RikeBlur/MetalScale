# UPDATE
## 25.10.05
开始进行光照系统尝试，目前对于遮蔽的使用还有待探究

## 25.10.04
修复bug：配置了移动Camera后对话生成无法追随camera位置。已完成修复，通过实时更新camera位置和设置合适的offset
Oni的奔跑动画已完成

## 25.09.30
完成抽象类 interact component / interacted component
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
