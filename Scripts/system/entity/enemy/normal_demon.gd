class_name normal_demon
extends CharacterBody2D
## Base agent script that is shared by all agents.

var summon_count: int = 0

var _moved_this_frame: bool = false

@onready var animation_player: AnimatedSprite2D = $AnimatedSprite
@onready var health: Health = $Health
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@onready var hsm: LimboHSM = $LimboHSM
@onready var PatrolState: LimboState = $LimboHSM/PatrolState
@onready var PursueState: LimboState = $LimboHSM/PursueState
@onready var FleeState: LimboState = $LimboHSM/FleeState

func _ready() -> void:
	_init_state_machine()

func _physics_process(_delta: float) -> void:
	_post_physics_process.call_deferred()


func _post_physics_process() -> void:
	if not _moved_this_frame:
		velocity = lerp(velocity, Vector2.ZERO, 0.5)
	_moved_this_frame = false


func move(p_velocity: Vector2) -> void:
	velocity = lerp(velocity, p_velocity, 0.2)
	move_and_slide()
	_moved_this_frame = true


## Is specified position inside the arena (not inside an obstacle)?
func is_good_position(p_position: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = p_position
	params.collision_mask = 1 # Obstacle layer has value 1
	var collision := space_state.intersect_point(params)
	return collision.is_empty()

func _init_state_machine() -> void:
	# 添加状态转换
	hsm.add_transition(PatrolState, PursueState, "target_detected")
	hsm.add_transition(PursueState, PatrolState, "target_lost")
	hsm.add_transition(PursueState, FleeState, "light_detected")
	hsm.add_transition(PatrolState, FleeState, "light_detected")
	hsm.add_transition(FleeState, PatrolState, "light_lost")	
	
	# 初始化状态机
	hsm.initialize(self)
	hsm.set_active(true)
