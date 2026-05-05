extends NodeState

@export var Character_body : npc_gone
@export var Animated_Sprite : AnimatedSprite2D

var direction : Vector2 = Vector2.ZERO
var last_direction : Vector2 = Vector2.DOWN


func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	if Character_body == null:
		return

	Character_body.velocity = Vector2.ZERO
	direction = Character_body.player_last_direction
	last_direction = Character_body.player_last_direction
	if last_direction != Vector2.ZERO:
		_play_idle_animation(last_direction)


func _play_idle_animation(anim_direction: Vector2) -> void:
	if Animated_Sprite == null:
		return

	if anim_direction == Vector2.DOWN:
		Animated_Sprite.play("idle_front")
	elif anim_direction == Vector2.UP:
		Animated_Sprite.play("idle_back")
	elif anim_direction == Vector2.LEFT:
		Animated_Sprite.play("idle_left")
	elif anim_direction == Vector2.RIGHT:
		Animated_Sprite.play("idle_right")
	elif anim_direction.x > 0 and anim_direction.y > 0:
		Animated_Sprite.play("idle_front_right")
	elif anim_direction.x > 0 and anim_direction.y < 0:
		Animated_Sprite.play("idle_back_right")
	elif anim_direction.x < 0 and anim_direction.y > 0:
		Animated_Sprite.play("idle_front_left")
	elif anim_direction.x < 0 and anim_direction.y < 0:
		Animated_Sprite.play("idle_back_left")
	else:
		Animated_Sprite.play("idle_front")


func _on_next_transitions() -> void:
	if Character_body == null or not Character_body.can_move:
		return
	if not Character_body.is_moving():
		return
	if Character_body.is_running():
		transition.emit("run")
	else:
		transition.emit("walk")


func _on_enter() -> void:
	_resolve_references()


func _on_exit() -> void:
	if Animated_Sprite:
		Animated_Sprite.stop()


func _resolve_references() -> void:
	var state_machine: NodeStateMachine = get_parent()
	if Character_body == null and state_machine:
		Character_body = state_machine.entity as npc_gone
	if Animated_Sprite == null and Character_body:
		Animated_Sprite = Character_body.get_node_or_null("AnimatedSprite") as AnimatedSprite2D
