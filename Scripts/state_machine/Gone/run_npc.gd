extends NodeState

@export var Character_body : npc_gone
@export var Animated_Sprite : AnimatedSprite2D
@export var speed_min : int = 200
@export var speed_max : int = 450
@export var accelaration : int = 500
@export var sfx : SFXPlayer = null

var speed : float = 0.0
var direction : Vector2 = Vector2.ZERO
var last_direction : Vector2 = Vector2.DOWN


func _on_physics_process(delta : float) -> void:
	if Character_body == null:
		return

	direction = Character_body.get_movement_direction()
	last_direction = Character_body.player_last_direction
	speed = clamp(speed + delta * accelaration, speed_min, speed_max)
	if direction != Vector2.ZERO:
		Character_body.player_direction = direction
		Character_body.player_last_direction = direction
		Character_body.npc_direction = direction
		_play_run_animation(direction)

	Character_body.velocity = speed * direction
	Character_body.move_and_slide()


func _play_run_animation(anim_direction: Vector2) -> void:
	if Animated_Sprite == null:
		return

	if anim_direction == Vector2.DOWN:
		Animated_Sprite.play("run_front")
	elif anim_direction == Vector2.UP:
		Animated_Sprite.play("run_back")
	elif anim_direction == Vector2.LEFT:
		Animated_Sprite.play("run_left")
	elif anim_direction == Vector2.RIGHT:
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
	if Character_body == null:
		return
	if Character_body.is_moving() and Character_body.can_move:
		if Character_body.is_running():
			return
		else:
			transition.emit("walk")
	else:
		transition.emit("idle")


func _on_enter() -> void:
	_resolve_references()
	if Character_body == null:
		return

	speed_min = Character_body.player_run_speed_min
	speed_max = Character_body.player_run_speed_max
	accelaration = Character_body.player_run_acceleration
	if sfx:
		sfx.play_start()


func _on_exit() -> void:
	if Character_body:
		Character_body.velocity = Vector2.ZERO
	if Animated_Sprite:
		Animated_Sprite.stop()
	if sfx:
		sfx.play_stop()
	speed = 0.0


func _resolve_references() -> void:
	var state_machine: NodeStateMachine = get_parent()
	if Character_body == null and state_machine:
		Character_body = state_machine.entity as npc_gone
	if Animated_Sprite == null and Character_body:
		Animated_Sprite = Character_body.get_node_or_null("AnimatedSprite") as AnimatedSprite2D
	if sfx == null and Character_body:
		sfx = Character_body.get_node_or_null("SFXManager/run") as SFXPlayer
