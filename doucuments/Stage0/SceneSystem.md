# 场景系统 SceneSystem

## 管理器：SceneManager

### 数据结构

1. **scene_dict: Dictionary**  key：场景id  value：SceneData <br>

2. **current_scene_key: String**  当前场景id <br>

3. **player_reset: Signal** 当玩家位置被场景管理器重置后，发射信号 <br>

### 核心方法

**场景切换：** change_scene(scene_key: String, scene_to_index: int) -> void: <br>

step1: 禁止玩家操作（移动和交互）；播放当前场景的结束过场动画 <br>

step2: 切换场景；加载玩家和相机并根据 scene_to_index 初始化位置 <br>
	
step3: 播放当前场景的开始过场动画；解禁玩家操作 <br>

## 基本类：BaseLevel

### 数据结构

1. **player_initial_position: Array[Vector2]** 玩家在这个场景的初始位置。一个场景有多个入口，所以初始位置是一个数组 <br>

2. **player_initial_direction** 同上，记录初始玩家朝向 <br>

3. **transition_player： AnimationPlayer** 转场动画，包括 transition_begin 和 transition_end <br>

### 核心方法

1. 初始化时，refresh 一次 UIManager <br>

2. 根据 index **初始化玩家位置** apply_initial_values_to_player(target_player: player, index: int) -> void <br>

## 数据类：SceneData

### 场景文件路径
path: String <br>

### 场景显示名称
display_name: String <br>

### 其他自定义数据（可扩展）
custom_data: Dictionary = {} <br>
