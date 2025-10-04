extends NodeState

#@export var player : player
@export var Character_body : CharacterBody2D
@export var Animated_Sprite : AnimatedSprite2D
@export var speed_min : int = 200
@export var speed_max : int = 450
@export var accelaration : int = 500

var speed : int = 100

var direction : Vector2
var last_direction : Vector2

static var last_time : float = 0.2
static var timer : float = 0

func _on_physics_process(delta : float) -> void:
	direction = InputEvents.movement_input()
	last_direction = InputEvents.get_last_valid_direction()
	speed = clamp(speed+delta*accelaration, speed_min, speed_max) * RPGTimeManager.time_scale
	if direction != Vector2.ZERO:
		Character_body.player_direction = direction
		Character_body.player_last_direction = last_direction
		
	# 播放动画（只在移动时播放 last_direction）
	if direction != Vector2.ZERO:
		_play_run_animation(direction)
	
	Character_body.velocity = Vector2.ZERO
	Character_body.velocity = speed*direction
	Character_body.move_and_slide()

# 新增：播放行走动画的函数
func _play_run_animation(anim_direction: Vector2) -> void:
	if anim_direction == Vector2.DOWN :
		Animated_Sprite.play("run_front")
	elif anim_direction == Vector2.UP :
		Animated_Sprite.play("run_back")
	elif anim_direction == Vector2.LEFT :
		Animated_Sprite.play("run_left")
	elif anim_direction == Vector2.RIGHT :
		Animated_Sprite.play("run_right")
	elif anim_direction.x > 0 and anim_direction.y > 0:
		Animated_Sprite.play("run_front_right")
	elif anim_direction.x > 0 and anim_direction.y < 0:
		Animated_Sprite.play("run_back_right")
	elif anim_direction.x < 0 and anim_direction.y > 0:
		Animated_Sprite.play("run_front_left")
	elif anim_direction.x < 0 and anim_direction.y < 0:
		Animated_Sprite.play("run_back_left")

func _on_next_transitions() -> void:
	InputEvents.movement_input()
	if InputEvents.is_movement() and Character_body.can_move :
		if InputEvents.is_running():
			return
		else:
			transition.emit("walk")
	else : transition.emit("idle")

func _on_enter() -> void:
	var state_machine: NodeStateMachine = get_parent()
	Character_body = state_machine.entity
	speed_min = Character_body.player_run_speed_min
	speed_max = Character_body.player_run_speed_max
	accelaration = Character_body.player_run_acceleration
	print("Now State : RUN")

func _on_exit() -> void:
	Character_body.velocity = Vector2.ZERO
	Animated_Sprite.stop()	
