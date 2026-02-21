extends NodeState

@export var animated_sprite: AnimatedSprite2D
@export var patrol_speed: float = 80.0
@export var min_move_time: float = 0.8
@export var max_move_time: float = 2.5
@export var ray_length: float = 80.0

const DIRECTIONS_8: Array = [
	Vector2.UP,
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2(1, 1),
	Vector2(1, -1),
	Vector2(-1, 1),
	Vector2(-1, -1),
]

var npc_node: CharacterBody2D
var current_direction: Vector2 = Vector2.ZERO
var move_timer: float = 0.0


func _on_enter() -> void:
	var state_machine: NodeStateMachine = get_parent()
	npc_node = state_machine.entity
	npc_node.toPursue.connect(_on_to_pursue)
	npc_node.state = 0
	patrol_speed = npc_node.walking_speed
	_pick_new_direction()
	print("Now State : PATROL")


func _on_exit() -> void:
	if npc_node.toPursue.is_connected(_on_to_pursue):
		npc_node.toPursue.disconnect(_on_to_pursue)
	npc_node.velocity = Vector2.ZERO
	if animated_sprite:
		animated_sprite.stop()


func _on_to_pursue() -> void:
	transition.emit("pursue")


func _on_physics_process(_delta: float) -> void:
	move_timer -= _delta
	if move_timer <= 0.0:
		_pick_new_direction()

	npc_node.velocity = current_direction * patrol_speed
	npc_node.move_and_slide()

	# 撞墙时立刻重选方向，防止卡死
	if npc_node.is_on_wall():
		_pick_new_direction()

	if current_direction != Vector2.ZERO:
		npc_node.npc_direction = current_direction
		if animated_sprite:
			_play_walk_animation(current_direction)


func _on_next_transitions() -> void:
	pass


func _pick_new_direction() -> void:
	var space_state = npc_node.get_world_2d().direct_space_state
	var valid_dirs: Array = []

	for raw_dir in DIRECTIONS_8:
		var dir: Vector2 = (raw_dir as Vector2).normalized()
		var from: Vector2 = npc_node.global_position
		var to: Vector2 = from + dir * ray_length
		var query := PhysicsRayQueryParameters2D.create(from, to)
		query.exclude = [npc_node.get_rid()]
		var result = space_state.intersect_ray(query)
		if result.is_empty():
			valid_dirs.append(dir)

	if valid_dirs.is_empty():
		current_direction = Vector2.ZERO
	else:
		current_direction = valid_dirs[randi() % valid_dirs.size()]

	move_timer = randf_range(min_move_time, max_move_time)


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


func _play_walk_animation(dir: Vector2) -> void:
	animated_sprite.play("walk_" + _get_8dir_suffix(dir))
