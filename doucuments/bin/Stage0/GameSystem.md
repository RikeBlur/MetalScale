# 游戏系统 GameSystem
Stage1 setup

## 全局功能 GlobalFunction

保存和维护游戏过程中的核心节点 ： **玩家** ； **相机** <br>

通过 get_player() 和 get_camera() 获取相应节点 <br>

## 游戏状态 GameManager

### 预设状态

1. PRELOADING 所有全局节点的加载 <br>

2. MEUN 主菜单界面 <br>

3. RUNNING 实际游戏运行的状态 <br>

4. LOADING 读档切换的状态 <br>

5. OVER 游戏结束的状态，可以退回 MEUN 或者 退出 <br>

### 核心方法

1. **开启新游戏** start_new_game() -> void  <br>

值得一提的是，GlobalFunction只负责存储玩家、相机节点，并不负责玩家、相机节点的初始化，初始实例化由 GameManager 完成 <br>

2. **退出游戏** quit_game() -> void:  <br>

直接退出场景树 <br>

## 游戏输入 RPGInputEvent

### 关键参数

player_input_blocked ： 如果为 true ， 所有输入均无返回 <br>

### 功能块

1. **八向移动** 通过暂存 有效方向、暂时方向、上一有效方向、上一暂时方向 确保正确实现八向移动，
不会出现 walk/run 转入 idle 状态时方向突变 ； 维护是否在 running 来切换 walk/run <br>

2. **交互** 按 E（act） 和场景交互； 按 R（consume） 使用 TOOL <br>

3. **UI操作** 按 TAB 切换出 toolbar；按 ESC（quit） 切换出 settings；ESC（quit）还可以自动删除第三层的UI <br>
