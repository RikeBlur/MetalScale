class_name PlayerIdleState
extends State

func enter() -> void:
	if entity and "animation_controller" in entity:
		entity.animation_controller.play_idle_animation()

func physics_update(_delta: float) -> void:
	if not entity:
		return
		
	# 检查移动输入
	var input_direction := Input.get_vector("left", "right", "up", "down")
	if input_direction != Vector2.ZERO:
		state_machine.change_state("move")
		return
		
	# 在闲置状态下，确保速度为零
	entity.velocity = Vector2.ZERO
	entity.move_and_slide()

func handle_input(event: InputEvent) -> void:
	# 直接在handle_input中处理攻击输入
	state_machine.change_state("attack") 
