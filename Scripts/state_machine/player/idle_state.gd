extends NodeState

@export var Character_body : CharacterBody2D
@export var Animated_Sprite : AnimatedSprite2D

var direction : Vector2 = Vector2.ZERO
var last_direction : Vector2 = Vector2.ZERO

static var last_time : float = 0.2
static var timer : float = 0

func _on_process(_delta : float) -> void:
	pass

func _on_physics_process(delta : float) -> void:
	direction = Character_body.player_direction
	last_direction = Character_body.player_last_direction
	# 播放动画（只在移动时播放 last_direction）
	if direction != Vector2.ZERO:
		_play_idle_animation(direction)

# 新增：播放待机动画的函数，与walk_state保持一致的方向判断逻辑
func _play_idle_animation(anim_direction: Vector2) -> void:
	if anim_direction == Vector2.DOWN :
		Animated_Sprite.play("idle_front")
	elif anim_direction == Vector2.UP :
		Animated_Sprite.play("idle_back")
	elif anim_direction == Vector2.LEFT :
		Animated_Sprite.play("idle_left")
	elif anim_direction == Vector2.RIGHT :
		Animated_Sprite.play("idle_right")
	elif anim_direction.x > 0 and anim_direction.y > 0:
		Animated_Sprite.play("idle_front_right")
	elif anim_direction.x > 0 and anim_direction.y < 0:
		Animated_Sprite.play("idle_back_right")
	elif anim_direction.x < 0 and anim_direction.y > 0:
		Animated_Sprite.play("idle_front_left")
	elif anim_direction.x < 0 and anim_direction.y < 0:
		Animated_Sprite.play("idle_back_left")
	else :
		Animated_Sprite.play("idle_front")

func _on_next_transitions() -> void:
	InputEvents.movement_input()
	if InputEvents.is_movement() :
		transition.emit("walk")
	elif  InputEvents.is_act() :
		return

func _on_enter() -> void:
	var state_machine: NodeStateMachine = get_parent()
	Character_body = state_machine.entity

func _on_exit() -> void:
	Animated_Sprite.stop()
