# Dialogue System
不位于 Canvas Layer 渲染层，z-index=9/10<br>

## 基本组件 Dialogue（Style）
res://Scripts/system/interact/dialogue_dual.gd<br>
res://Scripts/system/interact/dialogue_base.gd<br>

### 重要参数

current_dialogue_item ： 当前的 content 索引（从0开始）。<br>

which ： 当 A（0） 还是 B（1） 在对话。当 which 改变时，需要反转 dark/light。<br>

每个 Dialogue 包括一个 back_sprite(对话框)；dialogue_label（对话文本）；botton_container（HBoxContainer）；
speaker_sprite（立绘）；text_sound（单字音效）。<br>

### 核心功能
1. **Process** ： 当 next_item==1 时，处理新的 DialogueResource。<br>

2. **_funtion_resource** ： 从 目标节点  传入 目标参数 调用 目标函数 ；如果 wait_for_signal_to_continue！= null ，
将其作为 signal_name，如果 目标节点 存在对应的signal，在该 signal 触发之前保持等待。<br>

3. **_choice_resource** ： 将 resource 中的 text 传入 dialogue_label， botton_container 显示并将 choice_text 作为label
将选项按钮 button 实例化。每个 choice_text 会对应一个 choice_function_call，用来决定每个选项对应的结果 (可设无)。
需注意，这里的 button 的 pressed 信号需要连接两次，1、和 _funtion_resource 一样，调用 button 对应的特殊函数，
从 目标节点  传入 目标参数 调用 目标函数 ； 2、实现每个 button 公用的效果，包括等待信号wait_for_signal_to_continue<br>

4. **_text_resource** ： 将 resource 中的 text 传入 dialogue_label， 播放 sprite_animation_name 对应的立绘动画，
从0开始匀速显示文本字符，如果按下 skip ，直接显示全部字符；然后进入等待，直到再次按下 skip。

5. **反转 dark/light** ： 双人对话时，正在说话的人的立绘和对话框在上面，z-index=10，设置立绘和对话框的 material（对比度亮度）
同时 不显示（dark）的对话会往角落移动一个 offset，所以必须传入0/1来说明反转的对话是A还是B！（和which不一样，必须传入）<br>

### 现有 Dialogue
res://System/RPG/interact/dialogue/dialogue_ax_b.tscn AX右位<br>
res://System/RPG/interact/dialogue/dialogue_oni_a.tscn Oni左位<br>
res://System/RPG/interact/dialogue/dialogue_oni_b.tscn Oni右位<br>
res://System/RPG/interact/dialogue/dialogue_oni_ax.tscn Oni左AX右<br>


## 全局管理 DialogueManager
res://Scripts/system/interact/dialogue_manager.gd<br>
管理和存储这个场景中所有的对话 Dialogue 的内容和配置，在符合触发条件时生成对话，并进入对话状态（如玩家不能动）。<br>

### 数据结构

触发源 ***TriggerSource** ： 一般为 带有 InteractedComponent 的 area2D 节点；<br>

对话配置 ***TriggerFlag** ： 每个会被触发对话 Dialogue 的配置信息，包括 是否触发、双人/单人、单次触发、
使用模板（style）、起点终点、A/B对话索引（双人）；<br>

对话内容 **DialogueContent** ： 这个场景下的所有对话资源 DialogueResource 。<br>

### 主要方法

1. **_trigger_source_connect : ** <br>

将每个 TriggerSource 的 InteractedComponent 的信号和 DialogueManager 连接。
实现 在 TriggerSource 范围内时显示 DialogueReminder ；交互后消除 DialogueReminder 并触发 Dialogue。<br>

值得注意，在 _on_triggered 方法中需要确认单次触发的 TriggerSource 在触发后和 InteractedComponent 相关信号解绑。<br>

2. **_spawn(_dual)_dialogue ： ** <br>

在 process 过程中，遍历到 flag==1 的 TriggerFlag 时，通过提供的 模板（style）；
起点终点（从 DialogueContent 提取 DialogueResource）；A/B对话检索（双人） 生成对于的 Dialogue 实例。<br>

由于一开始把模板做成了 Node2D 节点，需要通过摄像机位置和准确的 offset 调整确保 Dialogue 实例在屏幕中央。<br>

## 数据资源 DialogueResource

### DialogueFunction

target_path： 目标节点的路径 <br>

function_name： 目标函数名 <br>

function_arguments： 需要传入目标函数的参数 <br>

hide_dialogue_box ： 是否需要隐藏对话框 <br>

wait_for_signal_to_continue： （String类）等待信号，是目标节点的信号，可设无 <br>

### DialogueChoice

speaker_entity：对话人id <br> 

sprite_animation_name： （String类）立绘动画名 <br> 

text： 题目/题面 <br>

choice_text： 字符串数组，表示选项 <br>

choice_function_call： DialogueFunction数组，表示每个选项对应的函数 <br>

### DialogueText

speaker_entity：对话人id <br> 

sprite_animation_name： （String类）立绘动画名 <br>

text: 对话文本 <br>

text_speed： 对话显示速度 <br>

text_sound ： 单字音效（音色）；text_volume_db（音量）；text_volume_pitch_min/max（随机音调） <br>
