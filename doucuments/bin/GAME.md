## STAGE

游戏的系统模块分为 ： 全局模块（Stage0）； 局部模块（Stage1） <br>

### Preloading：

1. **SceneManager** ： 定义每个 **场景** 场景id 和 SceneData 的一一对应 <br>

2. **ArchiveManager** : 定义每个 **存档**  存档序号 和 json文件名 的一一对应；每个存档的 存在状态 <br>

3. **GlobalFucntion** ： 存储 **玩家**节点 和 玩家追随**相机**节点 <br>

4. **RPGInputEvent** ： 初始化 stage1 中玩家**操作输入** 的所有方法 <br>

5. **UIManager** ： 定义每个 stage1 中的 **UI** ，包括 场景路径、层数、初始情况 <br>

6. **GameManager** ： 定义游戏状态 （STAGE0 STAGE1 MEUN LOADING OVER） 和 开启**新游戏** 方法 <br>

### MEUN：

1. **OpeningMeun** ： 开始新游戏、 读取存档、 游戏设置、 退出游戏 <br>

### LOADING：

目前还是在  **ArchiveManager**  中 load_game 方法实现的 <br>

### RUNNING ：

分三个子状态 CONTROL/AUTO/MENU <br>

1. **InteractSystem** : 玩家和场景中的**交互** <br>

2. **LightingSystem** ： 照明、遮挡、光强检测 <br>

3. **ToolManager** ： 玩家可主动使用的**工具** <br>

### OVER ：
