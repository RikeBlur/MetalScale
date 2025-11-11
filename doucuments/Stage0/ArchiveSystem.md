# 存档系统 ArchiveSystem

## 管理器：ArchiveManager

### 数据结构

1. **根目录** ROOT _DIR 存档json文件根目录 <br>

2. **存档名** save_path_dict: Dictionary 每个存档序号对应的json文件名 <br>

3. **存档状态** save_state_dict: Dictionary 每个存档序号对应的存档状态（空/有） <br>

### 核心方法

1. **检查存档状态：** check_save_state ： 通过 save_path_dict 是否有空文件，更新 save_state_dict <br>

2. **玩家数据序列化/反序列化**  <br>
_serialize_player_data(player_node: player) -> Dictionary  <br>
_deserialize_player_data(player_node: player, data: Dictionary) -> void <br>

通过 PlayerData 实例 作为中介，保存玩家的所有参数 <br>

3. **场景数据序列化/反序列化**  <br>
_serialize_scene_data(scene_data: SceneData) -> Dictionary <br>
_deserialize_scene_data(data: Dictionary) -> SceneData <br>

讲json文件中的数据转化为 SceneData 实例 <br>

4. **存档** game_save(index : int) -> bool <br>

从 /root/ 下读取 SceneManager；GlobalFunction （玩家节点） <br>

然后 通过上述**序列化**方法，将 **玩家** **场景** 数据转化为 json 格式；同时通过 Time 工具读取当前时间戳 <br>

5. **读档** game_load(index : int) -> bool <br>

从 /root/ 下读取 SceneManager；GlobalFunction （玩家节点） <br>

new 一个 JSON 变量，读取 存档file 中的 text 后，通过 parse 方法写入到 JSON 变量中 <br>

然后 通过上述**反序列化**方法，将 JSON变量后 中的 **玩家** **场景** 数据输入到实例中 <br>

如果不是初次加载，调用 SceneManager 的 change_scene(scene_now, 0) 其中 index 无所谓，后面还要设置玩家位置 <br>

change_scene 过程中，会发出一个信号 scene_mgr.player_reseted，等待这个信号 <br>

然后再设置一次玩家位置。这样可以避免玩家位置在 change_scene 被重置到 level 的初始位点

6. **删档** save_delete(index: int) -> bool: <br>

在确保对应序号的存档文件存在的前提下，删除文件，并将 save_state_dict 中对应的状态设置为 false <br>

## 存档 Archive 结构
