这是一个基于 godot4.6 的 俯视角rpg游戏 <br>

目前这个项目作为一个完整的 rpg 系统, 主要由如下系统组成(8个管理器): <br>

1. game_manager: @res://Scripts/global/game_manager.gd 
维护游戏管线，如游戏运行状态等，同时保存玩家和 camera 两个关键全局节点
，游戏 config <br>

2. scene_manager: @res://Scripts/global/cutscene_manager.gd
维护游戏所有场景和场景数据(SceneData)，包括不同场景的切换，以及场景
中的动态节点(Interactable)维护 <br>

3. archive_manager: @res://Scripts/global/archive_manager.gd
维护游戏存档，包括存档读写功能，所有 
Resource(SceneData/ConfigData/PlayerData/NPCData/ToolData) 
都需要读写 <br>

4. cutscene_manager: res://Scripts/global/cutscene_manager.gd
过场动画列表维护和播放过场动画的功能，过场动画分两种
场景类过场动画和信号类过场动画, 播放时 RunningState 应该设为 Auto <br>

5. ui_manager: res://Scripts/global/ui_manager.gd
维护所有 UI 节点，包括 3 层的 canvaslayer 结构和 UI 实例化和管理 <br>

6. npc_manager: res://Scripts/global/npc_manager.gd
维护游戏全局中所有 npc 实例，每个 npc 对应一个 NPCData，同时执行 npc 的场景外行为
npc 场景内行为取决于 npc 场景自己的逻辑 <br>

7. environment_manager: res://Scripts/global/environment_manager.gd
主要维护视觉滤镜，如场景压暗、arrgoed情况下的特殊视觉效果 <br>

8. bgm_manager: res://Scripts/global/bgm_manager.gd
维护 bgm 播放期，通过接收信号的方式切换 bgm 且确保 bgm 的平滑切换
有时也需要单独实例化 sfx_player 来播放 sfx <br>
