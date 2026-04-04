extends NodeState

# 追逐状态：
# - 有 NavigationAgent2D 时：使用寻路系统追踪玩家。
# - 无 NavigationAgent2D 时：势场法（Potential Field）+ 卡住检测恢复。
#
# 【势场法说明】
# 对多个探测方向同时采样距离，障碍越近斥力越大，player 方向引力固定，
# 合力方向即为移动方向。天然连续、无局部锯齿，配合卡住检测处理 U 形陷阱。
#
# 【Navigation 场景配置说明】
# 1. 在关卡根节点添加 NavigationRegion2D，绘制覆盖可行走区域的 NavigationPolygon，
#    然后点击"Bake NavigationPolygon"烘焙。
# 2. 在 EYE 场景根节点下添加 NavigationAgent2D，脚本会自动使用它进行寻路。

@export var animated_sprite: AnimatedSprite2D
@export var sfx: SFXPlayer = null

# ── 势场法参数 ────────────────────────────────────────────────────────────────

## 探测射线数量（均匀分布在 360°）
const PROBE_COUNT: int = 16
## 探测射线长度（px）—— 需大于碰撞体半径，给足反应距离
const PROBE_DISTANCE: float = 50.0
## 斥力衰减指数：障碍越近斥力越大（distance^-REPULSE_POWER）
const REPULSE_POWER: float = 5.0
## 斥力权重相对于引力的比例
const REPULSE_WEIGHT: float = 1.0
## 方向平滑系数（0=无平滑, 1=完全平滑不动）
const DIRECTION_SMOOTH: float = 0.85

# ── 卡住检测参数 ──────────────────────────────────────────────────────────────

## 判定"卡住"的位移阈值（px/s）—— 低于此值认为卡住
const STUCK_SPEED_THRESHOLD: float = 15.0
## 连续卡住多久后触发扰动（秒）
const STUCK_DURATION: float = 0.5
## 随机扰动持续时间（秒）
const JITTER_DURATION: float = 0.5
## 随机扰动力度（0~1，叠加到合力方向上的随机偏转幅度）
const JITTER_STRENGTH: float = 1.0

# ── 状态变量 ──────────────────────────────────────────────────────────────────

var npc_node: CharacterBody2D
var speed: float = 200.0
var nav_agent: NavigationAgent2D
var player: Node2D

var _smooth_direction: Vector2 = Vector2.DOWN
var _collision_shape: Shape2D = null

# 卡住检测
var _prev_position: Vector2 = Vector2.ZERO
var _stuck_timer: float = 0.0
var _jitter_timer: float = 0.0
var _jitter_direction: Vector2 = Vector2.ZERO


func _on_enter() -> void:
	var state_machine: NodeStateMachine = get_parent()
	npc_node = state_machine.entity
	speed = npc_node.running_speed
	nav_agent = npc_node.get_node_or_null("NavigationAgent2D")
	player = GameManager.player_instance
	npc_node.toPatrol.connect(_on_to_patrol)
	npc_node.state = 1
	_smooth_direction = Vector2.DOWN
	_prev_position = npc_node.global_position
	_stuck_timer = 0.0
	_jitter_timer = 0.0
	# 获取碰撞形状用于形状查询
	_collision_shape = _get_collision_shape()
	print("Now State : PURSUE")


func _on_exit() -> void:
	if npc_node.toPatrol.is_connected(_on_to_patrol):
		npc_node.toPatrol.disconnect(_on_to_patrol)
	npc_node.velocity = Vector2.ZERO
	if animated_sprite:
		animated_sprite.stop()


func _on_to_patrol() -> void:
	transition.emit("patrol")


func _on_physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return

	var direction: Vector2

	if nav_agent:
		nav_agent.target_position = player.global_position
		if nav_agent.is_navigation_finished():
			npc_node.velocity = Vector2.ZERO
			return
		var next_pos: Vector2 = nav_agent.get_next_path_position()
		direction = (next_pos - npc_node.global_position).normalized()
	else:
		direction = _compute_potential_field_direction(delta)

	npc_node.velocity = direction * speed
	npc_node.move_and_slide()

	if direction != Vector2.ZERO:
		npc_node.npc_direction = direction
		if animated_sprite:
			_play_run_animation(direction)


func _on_next_transitions() -> void:
	pass


# ── 势场法核心 ────────────────────────────────────────────────────────────────

func _compute_potential_field_direction(delta: float) -> Vector2:
	"""
	势场法计算移动方向：
	  - 引力：朝向 player 的单位向量
	  - 斥力：来自各探测方向上检测到的障碍，距离越近斥力越强
	  - 合力归一化后做指数平滑，再进行卡住检测
	"""
	var to_player: Vector2 = (player.global_position - npc_node.global_position).normalized()

	# 计算斥力合向量
	var repulse: Vector2 = Vector2.ZERO
	var space_state = npc_node.get_world_2d().direct_space_state

	for i in PROBE_COUNT:
		var angle: float = (TAU / PROBE_COUNT) * i
		var probe_dir: Vector2 = Vector2(cos(angle), sin(angle))
		var dist: float = _probe_distance(space_state, probe_dir)
		if dist < PROBE_DISTANCE:
			# 越近斥力越大，方向为远离障碍
			var strength: float = pow(PROBE_DISTANCE / max(dist, 1.0), REPULSE_POWER)
			repulse -= probe_dir * strength

	# 合力 = 引力 + 加权斥力
	var desired: Vector2 = to_player + repulse.normalized() * REPULSE_WEIGHT * (repulse.length() / PROBE_COUNT)
	if desired == Vector2.ZERO:
		desired = to_player

	desired = desired.normalized()

	# 卡住时叠加随机扰动
	desired = _apply_stuck_recovery(desired, delta)

	# 指数平滑，避免方向剧烈抖动
	_smooth_direction = _smooth_direction.lerp(desired, 1.0 - DIRECTION_SMOOTH)
	if _smooth_direction == Vector2.ZERO:
		_smooth_direction = to_player
	return _smooth_direction.normalized()


func _probe_distance(space_state: PhysicsDirectSpaceState2D, probe_dir: Vector2) -> float:
	"""沿 probe_dir 方向投射射线，返回最近碰撞距离（未命中返回 PROBE_DISTANCE）"""
	var origin: Vector2 = npc_node.global_position
	var target: Vector2 = origin + probe_dir * PROBE_DISTANCE
	var query := PhysicsRayQueryParameters2D.create(origin, target)
	query.exclude = [npc_node.get_rid()]
	query.collision_mask = npc_node.collision_mask & ~(1 << 1)  # 排除 layer 2（通常为 NPC 层）
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return PROBE_DISTANCE
	return origin.distance_to(result["position"])


# ── 卡住检测与恢复 ────────────────────────────────────────────────────────────

func _apply_stuck_recovery(desired: Vector2, delta: float) -> Vector2:
	"""检测 EYE 是否卡住，卡住时施加随机扰动方向破解局部最优"""
	var current_pos: Vector2 = npc_node.global_position
	var actual_speed: float = current_pos.distance_to(_prev_position) / max(delta, 0.001)
	_prev_position = current_pos

	# 正在扰动倒计时
	if _jitter_timer > 0.0:
		_jitter_timer -= delta
		return desired.lerp(_jitter_direction, JITTER_STRENGTH).normalized()

	# 判定是否卡住
	if actual_speed < STUCK_SPEED_THRESHOLD:
		_stuck_timer += delta
		if _stuck_timer >= STUCK_DURATION:
			_stuck_timer = 0.0
			_jitter_timer = JITTER_DURATION
			# 随机选一个偏转角（避开与期望方向相同）
			var perp: Vector2 = desired.rotated(PI * 0.5 * (1.0 if randf() > 0.5 else -1.0))
			_jitter_direction = desired.lerp(perp, 0.7).normalized()
	else:
		_stuck_timer = 0.0

	return desired


# ── 工具函数 ──────────────────────────────────────────────────────────────────

func _get_collision_shape() -> Shape2D:
	"""获取 npc_node 的第一个碰撞形状"""
	for child in npc_node.get_children():
		if child is CollisionShape2D and child.shape:
			return child.shape
	return null


# ── 动画 ─────────────────────────────────────────────────────────────────────

func _get_8dir_suffix(dir: Vector2) -> String:
	var snapped_angle: float = snappedf(dir.angle(), PI / 4.0)
	match snapped_angle:
		0.0:             return "right"
		PI / 4.0:        return "front_right"
		PI / 2.0:        return "front"
		3.0 * PI / 4.0:  return "front_left"
		-PI / 4.0:       return "back_right"
		-PI / 2.0:       return "back"
		-3.0 * PI / 4.0: return "back_left"
		_:               return "left"


func _play_run_animation(dir: Vector2) -> void:
	animated_sprite.play("run_" + _get_8dir_suffix(dir))
