extends NodeState

# 追逐状态：通过 NavigationAgent2D 寻路追踪玩家。
#
# 【Navigation 场景配置说明】
# 1. 在关卡根节点添加 NavigationRegion2D，绘制覆盖可行走区域的 NavigationPolygon，
#    然后点击"Bake NavigationPolygon"烘焙——场景中的 StaticBody2D 碰撞形状会被
#    自动识别为障碍物从可行走区域中剔除。
# 2. 若障碍物在运行时动态移动/出现，可在每个 StaticBody2D 下添加
#    NavigationObstacle2D 子节点以实现运行时动态规避。
# 3. 在 EYE 场景的根节点（CharacterBody2D）下添加 NavigationAgent2D 子节点，
#    脚本会自动获取并使用它进行寻路。若未找到 NavigationAgent2D 则退化为
#    直线追踪模式（可能在障碍物前卡住，建议完成 Navigation 配置）。

@export var animated_sprite: AnimatedSprite2D

var npc_node: CharacterBody2D
var speed: float = 200.0
var nav_agent: NavigationAgent2D
var player: Node2D


func _on_enter() -> void:
	var state_machine: NodeStateMachine = get_parent()
	npc_node = state_machine.entity
	speed = npc_node.running_speed
	nav_agent = npc_node.get_node_or_null("NavigationAgent2D")
	player = GameManager.player_instance
	npc_node.toPatrol.connect(_on_to_patrol)
	npc_node.state = 1
	print("Now State : PURSUE")


func _on_exit() -> void:
	if npc_node.toPatrol.is_connected(_on_to_patrol):
		npc_node.toPatrol.disconnect(_on_to_patrol)
	npc_node.velocity = Vector2.ZERO
	if animated_sprite:
		animated_sprite.stop()


func _on_to_patrol() -> void:
	transition.emit("patrol")


func _on_physics_process(_delta: float) -> void:
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
		# 无 NavigationAgent2D 时退化为直线追踪
		direction = (player.global_position - npc_node.global_position).normalized()

	npc_node.velocity = direction * speed
	npc_node.move_and_slide()

	if direction != Vector2.ZERO:
		npc_node.npc_direction = direction
		if animated_sprite:
			_play_run_animation(direction)


func _on_next_transitions() -> void:
	pass


func _get_8dir_suffix(dir: Vector2) -> String:
	var snapped_angle: float = snappedf(dir.angle(), PI / 4.0)
	match snapped_angle:
		0.0:
			return "right"
		PI / 4.0:
			return "front_right"
		PI / 2.0:
			return "front"
		3.0 * PI / 4.0:
			return "front_left"
		-PI / 4.0:
			return "back_right"
		-PI / 2.0:
			return "back"
		-3.0 * PI / 4.0:
			return "back_left"
		_:
			return "left"


func _play_run_animation(dir: Vector2) -> void:
	animated_sprite.play("run_" + _get_8dir_suffix(dir))
