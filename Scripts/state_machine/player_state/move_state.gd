class_name PlayerMoveState
extends State

func enter() -> void:
	if not entity:
		return

func physics_update(delta: float) -> void:
	if not entity:
		return
		
	# 获取移动输入
	var input_direction := Input.get_vector("left", "right", "up", "down")
	
	if input_direction == Vector2.ZERO:
		# 如果没有输入，使用减速度逐渐减速到静止
		entity.velocity.x = move_toward(entity.velocity.x, 0, delta * entity.deceleration)
		entity.velocity.y = move_toward(entity.velocity.y, 0, delta * entity.deceleration)
		
		# 如果速度接近零，切换到闲置状态
		if entity.velocity.length() == 0:
			state_machine.change_state("idle")
			return
	else:
		# 计算目标速度
		var target_velocity = input_direction * entity.speed
		
		# 使用加速度平滑过渡到目标速度
		entity.velocity.x = move_toward(entity.velocity.x, target_velocity.x, delta * entity.acceleration)
		entity.velocity.y = move_toward(entity.velocity.y, target_velocity.y, delta * entity.acceleration)
	
	if "animation_controller" in entity:
		entity.animation_controller.play_movement_animation(entity.velocity)
	
	entity.move_and_slide()

func handle_input(event: InputEvent) -> void:
	# 直接在handle_input中处理攻击输入
	state_machine.change_state("attack") 
