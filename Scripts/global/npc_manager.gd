class_name npc_manager
extends Node

# ====================================================================================================
# ============================================ 枚举 ==================================================
# ====================================================================================================

enum npc_type { 
	EYE,
	melt
 }

# ====================================================================================================
# ============================================ 常量 ==================================================
# ====================================================================================================

# EYE游荡：每隔多少秒随机换一个当前场景
const EYE_WANDER_INTERVAL: float = 60.0
# EYE追杀：收到 state==1 后多少秒入场
const EYE_CHASE_DELAY: float = 1.5
const JUMPSCARE_LAYER_INDEX: int = 10


# ====================================================================================================
# ========================================= 数据结构 =================================================
# ====================================================================================================


# GameState != RUNNING 时为 true，所有NPC行为冻结
var not_running: bool = true
var jumpscare_player_paths: Dictionary = {
	npc_type.EYE: "res://Effect/Animation/eye_jumpscare.tscn",
	npc_type.melt: "res://Effect/Animation/melt_jumpscare.tscn"
}

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
	对于 EYE：0 -> patrol ; 1 -> pursue ; -1 -> 死亡。
	对于 melt:0 -> patrol ; 1 -> pursue ; -1 -> 死亡。
"""

var npc_dict: Dictionary = {
	"0-0": NPCData.new().setup(
		preload("res://System/RPG/entity/npc/Enemy/EYE/EYE.tscn"),
		npc_type.EYE, "1-1", Vector2(600,250), Vector2.DOWN, false, 0
	),
	"1-0": NPCData.new().setup(
		preload("res://System/RPG/entity/npc/Enemy/melt/melt.tscn"),
		npc_type.melt, "2-5", Vector2(600,250), Vector2.DOWN, false, -1
	),
}

func _create_default_npc_dict() -> Dictionary:
	return {
		"0-0": NPCData.new().setup(
			preload("res://System/RPG/entity/npc/Enemy/EYE/EYE.tscn"),
			npc_type.EYE, "1-1", Vector2(600,250), Vector2.DOWN, false, 0
		),
		"1-0": NPCData.new().setup(
			preload("res://System/RPG/entity/npc/Enemy/melt/melt.tscn"),
			npc_type.melt, "2-5", Vector2(600,250), Vector2.DOWN, false, 0
		),
	}

# ====================================================================================================

# 存储实际节点弱引用，随场景生命周期自动失效。key: npc编号，value: WeakRef
var _npc_instances: Dictionary = {}
var _jumpscare_canvas_layer: CanvasLayer = null
var _active_jumpscare_player: Node = null
var _connected_player_hurted_component: hurted_component = null

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
	# 仇恨系统：arrgoed → 所有EYE进入追杀；not_arrgoed → 所有EYE回到巡逻
	GameManager.arrgoed.connect(_on_arrgoed)
	GameManager.not_arrgoed.connect(_on_not_arrgoed)
	# 初始化 Debug UI
	if GameManager.debug and not _debug_canvas:
		_create_debug_ui()
	call_deferred("_connect_player_hurted_component")


func reset_to_default_state() -> void:
	for npc_id in _npc_instances.keys():
		var inst = _get_npc_instance(npc_id)
		if is_instance_valid(inst) and inst.is_inside_tree():
			inst.queue_free()

	_npc_instances.clear()
	_eye_wander_timers.clear()
	_eye_chase_timers.clear()
	npc_dict = _create_default_npc_dict()
	not_running = true
	_connected_player_hurted_component = null
	_clear_jumpscare_player()
	_connect_player_hurted_component()

	if GameManager.debug and _debug_label:
		_update_debug_ui()
	print("NpcManager: reset to default state")


func _process(delta: float) -> void:
	# 实时同步 not_running：GameState != RUNNING 时冻结所有NPC行为
	not_running = GameManager.get_game_state() != GameManager.GameState.RUNNING

	if not not_running:
		# 实时同步在场NPC的位置/朝向到data
		_update_inscene_npc_data()
		# EYE特有的离场行为（游荡/急速追杀）；state==-1的NPC在各自函数内已跳过
		_update_eye_behaviors(delta)

	# 更新 Debug UI
	if GameManager.debug and _debug_label:
		_update_debug_ui()

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

	if data.state == -1:
		data.is_inscene = false
		_npc_instances.erase(npc_id)
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

	_npc_instances[npc_id] = weakref(npc_instance)
	data.is_inscene    = true
	data.current_scene = SceneManager.get_current_scene_key()
	# 将 data.state 同步到节点，并发出对应的状态切换信号
	_apply_npc_initial_state(npc_instance, data)
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

		var inst = _get_npc_instance(npc_id)
		if is_instance_valid(inst):
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

		var inst = _get_npc_instance(npc_id)
		if is_instance_valid(inst):
			data.npc_position = inst.global_position
			if "npc_direction" in inst:
				data.npc_direction = inst.npc_direction
			if "state" in inst:
				data.state = inst.state
		else:
			_npc_instances.erase(npc_id)

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
	_connect_player_hurted_component()
	if current_key == "":
		return

	for npc_id in npc_dict:
		var data: NPCData = npc_dict[npc_id]
		if not data.is_inscene and data.current_scene == current_key:
			instantiate_npc(npc_id)  # scene_index = -1，使用data里保存的位置
			print("NpcManager: 场景 '%s' 出现NPC '%s'" % [current_key, npc_id])

# ====================================================================================================
# ====================================== 3.5. Jumpscare 触发 ========================================
# ====================================================================================================

func _connect_player_hurted_component() -> void:
	var player_node := GameManager.get_player()
	if not player_node or not is_instance_valid(player_node):
		return

	var hurted_comp := player_node.find_child("hurted_component", true, false) as hurted_component
	if not hurted_comp or not is_instance_valid(hurted_comp):
		return

	if _connected_player_hurted_component == hurted_comp and hurted_comp.npc_kill_player.is_connected(_on_npc_kill_player):
		return

	if _connected_player_hurted_component and is_instance_valid(_connected_player_hurted_component):
		if _connected_player_hurted_component.npc_kill_player.is_connected(_on_npc_kill_player):
			_connected_player_hurted_component.npc_kill_player.disconnect(_on_npc_kill_player)

	if not hurted_comp.npc_kill_player.is_connected(_on_npc_kill_player):
		hurted_comp.npc_kill_player.connect(_on_npc_kill_player)
	_connected_player_hurted_component = hurted_comp


func _on_npc_kill_player(damage_source: npc) -> void:
	_play_jumpscare_for_damage_source(damage_source)


func _play_jumpscare_for_damage_source(damage_source: npc) -> void:
	if not damage_source or not is_instance_valid(damage_source):
		return

	var jumpscare_type := _get_jumpscare_type_for_damage_source(damage_source)
	if jumpscare_type < 0:
		return

	var scene_path: String = jumpscare_player_paths.get(jumpscare_type, "")
	if scene_path == "":
		return

	var packed := load(scene_path) as PackedScene
	if not packed:
		push_warning("NpcManager: jumpscare_player scene not found: %s" % scene_path)
		return

	_clear_jumpscare_canvas_layer()
	var canvas_layer := _ensure_jumpscare_canvas_layer()
	if not canvas_layer:
		return

	_active_jumpscare_player = packed.instantiate()
	canvas_layer.add_child(_active_jumpscare_player)
	if _active_jumpscare_player.has_signal("oneshot_finished"):
		_active_jumpscare_player.connect("oneshot_finished", _on_jumpscare_player_finished, CONNECT_ONE_SHOT)
	if _active_jumpscare_player.has_method("play_oneshot"):
		_active_jumpscare_player.play_oneshot()
	elif _active_jumpscare_player.has_method("play_ontshot"):
		_active_jumpscare_player.play_ontshot()
	else:
		push_warning("NpcManager: jumpscare_player missing play_oneshot(): %s" % scene_path)


func _on_jumpscare_player_finished() -> void:
	_clear_jumpscare_canvas_layer()

# ================= 这里扩展！！！！===================

func _get_jumpscare_type_for_damage_source(damage_source: npc) -> int:
	if damage_source is EnemyEye:
		return npc_type.EYE
	if damage_source is EnemyMelt:
		return npc_type.melt
	return -1


func _ensure_jumpscare_canvas_layer() -> CanvasLayer:
	if _jumpscare_canvas_layer and is_instance_valid(_jumpscare_canvas_layer):
		return _jumpscare_canvas_layer

	_jumpscare_canvas_layer = CanvasLayer.new()
	_jumpscare_canvas_layer.name = "JumpscareCanvasLayer"
	_jumpscare_canvas_layer.layer = JUMPSCARE_LAYER_INDEX
	add_child(_jumpscare_canvas_layer)
	return _jumpscare_canvas_layer


func _clear_jumpscare_canvas_layer() -> void:
	_active_jumpscare_player = null
	if _jumpscare_canvas_layer and is_instance_valid(_jumpscare_canvas_layer):
		_jumpscare_canvas_layer.queue_free()
	_jumpscare_canvas_layer = null


func _clear_jumpscare_player() -> void:
	_clear_jumpscare_canvas_layer()


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
	从EYE上一所在场景的PackedScene里，找到 scene_to == 当前场景 的门，
	取其 scene_to_index（该值指向当前场景 BaseLevel 的 spawn 点），以此实例化EYE。
	若没有匹配门，则随机取一个合法 scene_index 实例化。
	"""
	var current_scene: Node = get_tree().current_scene
	if not current_scene:
		return

	var current_key: String = SceneManager.get_current_scene_key()

	# 去EYE上一场景中找连向当前场景的门，取其 scene_to_index（指向当前场景的spawn点）
	var matched_index: int = _find_entry_index_from_prev_scene(data.current_scene, current_key)

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

# 4.3 状态切换：EYE状态和 player arrgo 的关系 ──────────────────────────────────────────────────────────────────

func _apply_npc_initial_state(inst: Node, data: NPCData) -> void:
	"""将 data.state 写入 NPC 节点，并按类型发出对应的状态信号"""
	if "state" in inst:
		inst.state = data.state

	match data.type:
		npc_type.EYE:
			match data.state:
				0:
					if inst.has_signal("toPatrol"):
						inst.emit_signal("toPatrol")
				1:
					if inst.has_signal("toPursue"):
						inst.emit_signal("toPursue")


func _on_arrgoed() -> void:
	"""GameManager.arrgoed：所有EYE切换到追杀状态（state=1），并通知节点"""
	for npc_id in npc_dict:
		var data: NPCData = npc_dict[npc_id]
		if data.type != npc_type.EYE:
			continue
		if data.state == -1:
			continue
		data.state = 1
		# 若EYE节点在场，设置 arrgoing=true 并发出 toPursue 信号
		var inst = _get_npc_instance(npc_id)
		if is_instance_valid(inst):
			if "arrgoing" in inst:
				inst.arrgoing = true
			if inst.has_signal("toPursue"):
				inst.emit_signal("toPursue")
		else:
			_npc_instances.erase(npc_id)
	print("NpcManager: arrgoed — 所有EYE → state=1 (pursue), arrgoing=true")


func _on_not_arrgoed() -> void:
	"""GameManager.not_arrgoed：所有EYE切换到巡逻状态（state=0），并通知节点"""
	for npc_id in npc_dict:
		var data: NPCData = npc_dict[npc_id]
		if data.type != npc_type.EYE:
			continue
		if data.state == -1:
			continue
		data.state = 0
		# 若EYE节点在场，发出 toPatrol 信号
		var inst = _get_npc_instance(npc_id)
		if is_instance_valid(inst):
			if "arrgoing" in inst:
				inst.arrgoing = false
			#if inst.has_signal("toPatrol"):
			#	inst.emit_signal("toPatrol")
		else:
			_npc_instances.erase(npc_id)
	print("NpcManager: not_arrgoed — 所有EYE → state=0 (patrol)")


# ====================================================================================================
# =========================================== 工具函数 ===============================================
# ====================================================================================================

func release_npcs_by_type(target_type: int) -> void:
	for npc_id in npc_dict:
		var data: NPCData = npc_dict[npc_id]
		if not data or data.type != target_type:
			continue

		var inst = _get_npc_instance(npc_id)
		if inst and is_instance_valid(inst):
			inst.queue_free()

		data.state = -1
		data.is_inscene = false
		_npc_instances.erase(npc_id)
		_eye_wander_timers.erase(npc_id)
		_eye_chase_timers.erase(npc_id)

	if GameManager.debug and _debug_label:
		_update_debug_ui()


func release_eye_npcs() -> void:
	release_npcs_by_type(npc_type.EYE)


func _get_npc_instance(npc_id: String) -> Node:
	var ref = _npc_instances.get(npc_id)
	var inst: Node = null
	if ref is WeakRef:
		inst = ref.get_ref() as Node
	elif is_instance_valid(ref):
		inst = ref as Node

	if not inst:
		_npc_instances.erase(npc_id)
	return inst


func _find_door_index_recursive(node: Node, target_scene: String) -> int:
	"""递归查找 scene_to == target_scene 的第一个 BaseDoor，返回其 scene_to_index；未找到返回 -1。"""
	for child in node.get_children():
		if child is BaseDoor and child.scene_to == target_scene:
			return child.scene_to_index
		var result: int = _find_door_index_recursive(child, target_scene)
		if result >= 0:
			return result
	return -1


func _find_entry_index_from_prev_scene(prev_scene_key: String, current_key: String) -> int:
	"""
	从 prev_scene 的 PackedScene 里找到 scene_to == current_key 的门，
	返回其 scene_to_index（该值是 current_key 场景里的 spawn 点索引）；未找到返回 -1。
	临时实例化不加入场景树，不触发 _ready / @onready，读完立即释放。
	"""
	if not SceneManager.scene_dict.has(prev_scene_key):
		return -1
	var prev_path: String = SceneManager.get_scene_path(prev_scene_key)
	if prev_path == "":
		return -1

	var packed := load(prev_path) as PackedScene
	if not packed:
		return -1

	var temp: Node = packed.instantiate()
	if not temp:
		return -1

	# 按统一路径查找door容器，依次降级
	var door_root: Node = temp.get_node_or_null("ObjectAndCharacter/Interactable/door")
	if not door_root:
		door_root = temp.get_node_or_null("ObjectAndCharacter/Interactable")
	if not door_root:
		door_root = temp

	var idx: int = _find_door_index_recursive(door_root, current_key)

	# 不加入场景树，直接 free（@onready 未初始化，无副作用）
	temp.free()

	return idx

func _find_base_level(node: Node) -> BaseLevel:
	if node is BaseLevel:
		return node
	for child in node.get_children():
		var result = _find_base_level(child)
		if result:
			return result
	return null

# ====================================================================================================
# ============================================ Debug UI =============================================
# ====================================================================================================

var _debug_canvas: CanvasLayer = null
var _debug_label: Label = null

func _create_debug_ui() -> void:
	"""创建 Debug UI —— 左下角半透明面板，显示 npc_dict 中所有NPC的状态"""
	_debug_canvas = CanvasLayer.new()
	_debug_canvas.name = "NpcManagerDebugCanvas"
	_debug_canvas.layer = 102
	add_child(_debug_canvas)

	var panel := PanelContainer.new()
	panel.name = "NpcManagerDebugPanel"
	_debug_canvas.add_child(panel)

	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color(0.05, 0.2, 0.05, 0.75)
	style_box.border_color = Color(0.4, 1.0, 0.6, 0.9)
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(8)
	style_box.content_margin_left = 12
	style_box.content_margin_right = 12
	style_box.content_margin_top = 8
	style_box.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style_box)

	_debug_label = Label.new()
	_debug_label.name = "NpcManagerDebugLabel"
	_debug_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.85, 1.0))
	_debug_label.add_theme_font_size_override("font_size", 14)
	panel.add_child(_debug_label)

	# 固定左下角：左边缘贴屏幕左侧，向右向上增长
	panel.anchor_left   = 0.0
	panel.anchor_right  = 0.0
	panel.anchor_top    = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left   = 10.0
	panel.offset_bottom = -10.0
	panel.grow_horizontal = Control.GROW_DIRECTION_END    # 向右增长
	panel.grow_vertical   = Control.GROW_DIRECTION_BEGIN  # 向上增长

	print("NpcManager: Debug UI 已创建")
	_update_debug_ui()


func _update_debug_ui() -> void:
	"""刷新 Debug 面板内容"""
	if not _debug_label:
		return

	var text := "[NPC_manager Debug]\n"
	text += "\n[NPC Dict] (%d)\n" % npc_dict.size()

	if npc_dict.is_empty():
		text += "  (空)\n"
	else:
		for npc_id in npc_dict:
			var data: NPCData = npc_dict[npc_id]
			var type_name: String = npc_type.keys()[data.type] if data.type < npc_type.keys().size() else str(data.type)
			var inscene_str: String = "在场" if data.is_inscene else "离场"
			var state_str: String = _state_label(data.type, data.state)
			text += "  [%s] %s | %s | state:%d(%s)\n" % [npc_id, type_name, inscene_str, data.state, state_str]
			text += "    scene: %s\n" % data.current_scene
			text += "    pos: (%.0f, %.0f)  dir: (%.1f, %.1f)\n" % [
				data.npc_position.x, data.npc_position.y,
				data.npc_direction.x, data.npc_direction.y
			]

	_debug_label.text = text


func _state_label(type: npc_type, state: int) -> String:
	"""将state整数转成可读文字"""
	match type:
		npc_type.EYE:
			match state:
				0: return "patrol"
				1: return "pursue"
		npc_type.melt:
			match state:
				0: return "patrol"
				1: return "pursue"
	return "?"
