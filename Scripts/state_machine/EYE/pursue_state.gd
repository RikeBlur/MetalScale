extends NodeState

# 追逐状态：
# - 有 NavigationAgent2D 时：使用寻路系统追踪玩家。
# - 无 NavigationAgent2D 时：8方向 + 碰撞预测递归回退，参考 Scripts/system/ai/tasks/pursue.gd 思路。
#
# 【Navigation 场景配置说明】
# 1. 在关卡根节点添加 NavigationRegion2D，绘制覆盖可行走区域的 NavigationPolygon，
#    然后点击"Bake NavigationPolygon"烘焙——场景中的 StaticBody2D 碰撞形状会被
#    自动识别为障碍物从可行走区域中剔除。
# 2. 若障碍物在运行时动态移动/出现，可在每个 StaticBody2D 下添加
#    NavigationObstacle2D 子节点以实现运行时动态规避。
# 3. 在 EYE 场景的根节点（CharacterBody2D）下添加 NavigationAgent2D 子节点，
#    脚本会自动获取并使用它进行寻路。

@export var animated_sprite: AnimatedSprite2D
@export var sfx: SFXPlayer = null

# ── 8方向表（无Navigation fallback 用）────────────────────────────────────────

const PURSUE_DIRECTIONS: Dictionary = {
	"right":       Vector2(1.0, 0.0),
	"left":        Vector2(-1.0, 0.0),
	"front":       Vector2(0.0, 1.0),
	"back":        Vector2(0.0, -1.0),
	"front_right": Vector2(0.7071067811865476,  0.7071067811865476),
	"back_right":  Vector2(0.7071067811865476, -0.7071067811865476),
	"front_left":  Vector2(-0.7071067811865476, 0.7071067811865476),
	"back_left":   Vector2(-0.7071067811865476,-0.7071067811865476),
}

# 每个方向碰撞时优先尝试的相邻方向
const ADJACENT_DIRECTIONS: Dictionary = {
	"right":       ["front_right", "back_right"],
	"left":        ["front_left",  "back_left"],
	"front":       ["front_right", "front_left"],
	"back":        ["back_right",  "back_left"],
	"front_right": ["right",  "front"],
	"back_right":  ["right",  "back"],
	"front_left":  ["left",   "front"],
	"back_left":   ["left",   "back"],
}

# 方向重评估间隔（秒）。同时决定碰撞预测距离 = speed × interval
const DIRECTION_REFRESH_INTERVAL: float = 0.4

# ── 状态变量 ──────────────────────────────────────────────────────────────────

var npc_node: CharacterBody2D
var speed: float = 200.0
var nav_agent: NavigationAgent2D
var player: Node2D

var _move_direction: Vector2 = Vector2.DOWN
var _direction_timer: float = 0.0
var _tried_directions: Array[String] = []


func _on_enter() -> void:
	var state_machine: NodeStateMachine = get_parent()
	npc_node = state_machine.entity
	speed = npc_node.running_speed
	nav_agent = npc_node.get_node_or_null("NavigationAgent2D")
	player = GameManager.player_instance
	npc_node.toPatrol.connect(_on_to_patrol)
	npc_node.state = 1
	# 让第一个物理帧立即触发方向评估
	_direction_timer = DIRECTION_REFRESH_INTERVAL
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
		# ── 无 NavigationAgent2D：8方向碰撞回避 ──────────────────────────────
		_direction_timer += delta
		if _direction_timer >= DIRECTION_REFRESH_INTERVAL:
			_direction_timer = 0.0
			_tried_directions.clear()
			var to_player: Vector2 = (player.global_position - npc_node.global_position).normalized()
			_move_direction = _select_safe_direction(to_player)
		direction = _move_direction

	npc_node.velocity = direction * speed
	npc_node.move_and_slide()

	if direction != Vector2.ZERO:
		npc_node.npc_direction = direction
		if animated_sprite:
			_play_run_animation(direction)


func _on_next_transitions() -> void:
	pass


# ── 8方向碰撞回避核心 ─────────────────────────────────────────────────────────

func _get_closest_direction_name(target_dir: Vector2) -> String:
	"""点积最大的方向即为最接近目标向量的8方向。"""
	var best: String = "right"
	var max_dot: float = -2.0
	for dir_name in PURSUE_DIRECTIONS:
		var d: float = target_dir.dot(PURSUE_DIRECTIONS[dir_name])
		if d > max_dot:
			max_dot = d
			best = dir_name
	return best


func _select_safe_direction(target_dir: Vector2, preferred: String = "") -> Vector2:
	"""
	递归选择安全方向：
	  1. 从最接近目标的方向开始；
	  2. 若预测位置有碰撞，依次尝试相邻方向；
	  3. 所有相邻方向均有碰撞时，返回原方向（让 move_and_slide 自行处理）。
	"""
	if preferred == "":
		preferred = _get_closest_direction_name(target_dir)

	# 已尝试过此方向，跳到相邻
	if preferred in _tried_directions:
		for adj: String in ADJACENT_DIRECTIONS[preferred]:
			if adj not in _tried_directions:
				return _select_safe_direction(target_dir, adj)
		return PURSUE_DIRECTIONS[preferred]

	_tried_directions.append(preferred)

	var dir_vec: Vector2 = PURSUE_DIRECTIONS[preferred]
	# 预测 DIRECTION_REFRESH_INTERVAL 秒后的位置
	var predicted: Vector2 = npc_node.global_position + dir_vec * speed * DIRECTION_REFRESH_INTERVAL

	if _has_collision_at(predicted):
		for adj: String in ADJACENT_DIRECTIONS[preferred]:
			if adj not in _tried_directions:
				return _select_safe_direction(target_dir, adj)
		return dir_vec

	return dir_vec


func _has_collision_at(pos: Vector2) -> bool:
	var space_state = npc_node.get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 1
	query.exclude = [npc_node.get_rid()]
	return space_state.intersect_point(query, 1).size() > 0


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
