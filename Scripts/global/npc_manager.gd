class_name npc_manager
extends Node

# ====================================================================================================
# ============================================ 枚举 ==================================================
# ====================================================================================================

enum npc_type { EYE }

# ====================================================================================================
# ============================================ 常量 ==================================================
# ====================================================================================================

# EYE游荡：每隔多少秒随机换一个当前场景
const EYE_WANDER_INTERVAL: float = 30.0
# EYE追杀：收到 state==1 后多少秒入场
const EYE_CHASE_DELAY: float = 3.0
# ====================================================================================================
# ========================================= 数据结构 =================================================
# ====================================================================================================


# ====================================================================================================
# NPC数据字典。key: npc编号（如 "0-0"），value: NPCData
"""
# NPC对应的场景实例
npc_node: PackedScene
# NPC类型
type: npc_type
# NPC所在场景
current_scene: String
# NPC在对应场景的全局坐标和朝向
npc_position: Vector2
npc_direction: Vector2
# 在场与否？
is_inscene: bool = false 
# npc状态
state: int = 0
	对于EYE：0 -> patrol ; 1 -> pursue 。
"""

var npc_dict: Dictionary = {
	"0-0": NPCData.new().setup(
		preload("res://System/RPG/entity/npc/Enemy/EYE/EYE.tscn"),
		npc_type.EYE, "0-1", Vector2(600,250), Vector2.DOWN, false, 1
	),
}
# ====================================================================================================

# 存储实际节点引用，随场景生命周期自动失效。key: npc编号，value: Node
var _npc_instances: Dictionary = {}

# EYE游荡计时器。key: npc编号，value: 剩余秒数
var _eye_wander_timers: Dictionary = {}

# EYE追杀倒计时器。key: npc编号，value: 剩余秒数（初始化后才存在）
var _eye_chase_timers: Dictionary = {}


# ====================================================================================================
# ========================================== 初始化 =================================================
# ====================================================================================================

func _ready() -> void:
	GameManager.Loading.connect(_on_game_loading)
	# player_reseted 在新场景加载完成、玩家落位后才发出，是出场检测的正确时机
	SceneManager.player_reseted.connect(_on_player_reseted)


func _process(delta: float) -> void:
	# 实时同步在场NPC的位置/朝向到data
	_update_inscene_npc_data()

	# EYE特有的离场行为（游荡/急速追杀）
	_update_eye_behaviors(delta)

# ====================================================================================================
# ======================================== 1. 实例化NPC =============================================
# ====================================================================================================

func instantiate_npc(npc_id: String, scene_index: int = -1) -> void:
	"""
	将NPC实例化到当前场景的 ObjectAndCharacter/NPC 节点下。

	参数：
		npc_id     : npc_dict中的key
		scene_index: >=0 时使用BaseLevel的player_initial_position[index]决定位置和朝向；
		             -1  时使用NPCData中保存的npc_position/npc_direction。
	"""
	var data: NPCData = npc_dict.get(npc_id)
	if not data:
		push_error("NpcManager: NPC '%s' 不存在于npc_dict" % npc_id)
		return

	if data.is_inscene:
		push_warning("NpcManager: NPC '%s' 已在场景中，跳过实例化" % npc_id)
		return

	var current_scene: Node = get_tree().current_scene
	if not current_scene:
		push_error("NpcManager: 当前场景为空，无法实例化NPC '%s'" % npc_id)
		return

	# 找挂载父节点：优先 ObjectAndCharacter/NPC，依次降级
	var npc_parent: Node = current_scene.get_node_or_null("ObjectAndCharacter/NPC")
	if not npc_parent:
		npc_parent = current_scene.get_node_or_null("ObjectAndCharacter")
	if not npc_parent:
		npc_parent = current_scene

	var npc_instance: Node = (data.npc_node as PackedScene).instantiate()
	npc_instance.name = npc_id  # 以npc_id命名，方便后续查找
	npc_parent.add_child(npc_instance)

	# 设置位置和朝向
	if scene_index >= 0:
		var base_level: BaseLevel = _find_base_level(current_scene)
		if base_level and scene_index < base_level.player_initial_position.size():
			npc_instance.global_position = base_level.player_initial_position[scene_index]
			npc_instance.npc_direction   = base_level.player_initial_direction[scene_index]
		else:
			push_warning("NpcManager: scene_index %d 超出范围，回退到data位置" % scene_index)
			npc_instance.global_position = data.npc_position
			npc_instance.npc_direction   = data.npc_direction
	else:
		npc_instance.global_position = data.npc_position
		npc_instance.npc_direction   = data.npc_direction

	_npc_instances[npc_id] = npc_instance
	data.is_inscene    = true
	data.current_scene = SceneManager.get_current_scene_key()
	print("NpcManager: 已实例化 '%s' 至场景 '%s'" % [npc_id, data.current_scene])

# ====================================================================================================
# =================================== 2. 同步在场NPC数据 ============================================
# ====================================================================================================

func _update_inscene_npc_data() -> void:
	"""每帧将在场NPC的实时位置/朝向写回NPCData。节点失效时自动标记离场。"""
	for npc_id in npc_dict:
		var data: NPCData = npc_dict[npc_id]
		if not data.is_inscene:
			continue

		var inst: Node = _npc_instances.get(npc_id)
		if inst and is_instance_valid(inst):
			data.npc_position = inst.global_position
			if "npc_direction" in inst:
				data.npc_direction = inst.npc_direction
			if "state" in inst:
				data.state = inst.state
		else:
			# 节点已被销毁（如场景切换），标记离场并清理引用
			data.is_inscene = false
			_npc_instances.erase(npc_id)

# ====================================================================================================
# ====================== 3. Loading信号：保存状态 + 新场景NPC出现检测 ==================================
# ====================================================================================================

func _on_game_loading() -> void:
	"""
	场景切换开始前：将所有在场NPC的最新位置/朝向/state写入data，并标记离场。
	节点将随旧场景一起销毁，此处是销毁前最后一次读取的机会。
	"""
	for npc_id in npc_dict:
		var data: NPCData = npc_dict[npc_id]
		if not data.is_inscene:
			continue

		var inst: Node = _npc_instances.get(npc_id)
		if inst and is_instance_valid(inst):
			data.npc_position = inst.global_position
			if "npc_direction" in inst:
				data.npc_direction = inst.npc_direction
			if "state" in inst:
				data.state = inst.state

		data.is_inscene = false

	_npc_instances.clear()
	print("NpcManager: Loading — 已保存所有NPC状态并标记离场")


func _on_player_reseted() -> void:
	"""
	新场景加载完成、玩家落位后触发。
	此时 current_scene_key 和 get_tree().current_scene 均已就绪，
	是检测并实例化应出场NPC的正确时机。
	"""
	var current_key: String = SceneManager.get_current_scene_key()
	if current_key == "":
		return

	for npc_id in npc_dict:
		var data: NPCData = npc_dict[npc_id]
		if not data.is_inscene and data.current_scene == current_key:
			instantiate_npc(npc_id)  # scene_index = -1，使用data里保存的位置
			print("NpcManager: 场景 '%s' 出现NPC '%s'" % [current_key, npc_id])

# ====================================================================================================
# ============================== 4. EYE特有行为 =====================================================
# ====================================================================================================

func _update_eye_behaviors(delta: float) -> void:
	for npc_id in npc_dict:
		var data: NPCData = npc_dict[npc_id]
		if data.type != npc_type.EYE:
			continue
		if data.is_inscene:
			continue

		match data.state:
			0: #patrol
				_update_eye_wander(npc_id, data, delta)
			1: #pursue
				_update_eye_chase(npc_id, data, delta)


# 4.1 游荡：每30s在所有场景中随机选一个作为current_scene ────────────────────────────────────────────

func _update_eye_wander(npc_id: String, data: NPCData, delta: float) -> void:
	if not _eye_wander_timers.has(npc_id):
		_eye_wander_timers[npc_id] = EYE_WANDER_INTERVAL

	_eye_wander_timers[npc_id] -= delta
	if _eye_wander_timers[npc_id] > 0.0:
		return

	_eye_wander_timers[npc_id] = EYE_WANDER_INTERVAL

	var scene_keys: Array = SceneManager.scene_dict.keys()
	if scene_keys.is_empty():
		return

	data.current_scene = scene_keys[randi() % scene_keys.size()]
	print("NpcManager [EYE '%s'] 游荡 → %s" % [npc_id, data.current_scene])


# 4.2 急速追杀：一段时间后通过door入场 ──────────────────────────────────────────────────────────────────

func _update_eye_chase(npc_id: String, data: NPCData, delta: float) -> void:
	if not _eye_chase_timers.has(npc_id):
		_eye_chase_timers[npc_id] = EYE_CHASE_DELAY

	_eye_chase_timers[npc_id] -= delta
	if _eye_chase_timers[npc_id] > 0.0:
		return

	# 倒计时结束，清除timer防止重复触发，然后执行入场
	_eye_chase_timers.erase(npc_id)
	_spawn_eye_via_door(npc_id, data)


func _spawn_eye_via_door(npc_id: String, data: NPCData) -> void:
	"""
	遍历当前场景 ObjectAndCharacter/Interactable/door 下的所有 BaseDoor，
	找到 scene_to == EYE.current_scene 的门，取其 scene_to_index 实例化EYE；
	若没有匹配的门，则随机取一个合法 scene_index 实例化。
	"""
	var current_scene: Node = get_tree().current_scene
	if not current_scene:
		return

	# 按用户描述的路径查找door容器，依次降级
	var door_root: Node = current_scene.get_node_or_null("ObjectAndCharacter/Interactable/door")
	if not door_root:
		door_root = current_scene.get_node_or_null("ObjectAndCharacter/Interactable")
	if not door_root:
		door_root = current_scene

	var matched_index: int = _find_door_index_recursive(door_root, data.current_scene)

	if matched_index >= 0:
		instantiate_npc(npc_id, matched_index)
	else:
		# 没有匹配door，随机一个合法index
		var base_level: BaseLevel = _find_base_level(current_scene)
		var fallback: int = 0
		if base_level and base_level.player_initial_position.size() > 1:
			fallback = randi() % base_level.player_initial_position.size()
		print("NpcManager [EYE '%s'] 追杀未找到匹配door，使用随机index %d" % [npc_id, fallback])
		instantiate_npc(npc_id, fallback)

# ====================================================================================================
# =========================================== 工具函数 ===============================================
# ====================================================================================================

func _find_door_index_recursive(node: Node, target_scene: String) -> int:
	"""递归查找 scene_to == target_scene 的第一个 BaseDoor，返回其 scene_to_index；未找到返回 -1。"""
	for child in node.get_children():
		if child is BaseDoor and child.scene_to == target_scene:
			return child.scene_to_index
		var result: int = _find_door_index_recursive(child, target_scene)
		if result >= 0:
			return result
	return -1


func _find_base_level(node: Node) -> BaseLevel:
	if node is BaseLevel:
		return node
	for child in node.get_children():
		var result = _find_base_level(child)
		if result:
			return result
	return null
