class_name PlayerAttackState
extends State

# 攻击状态持续时间（秒）
var attack_duration: float = 0.5
var attack_timer: float = 0.0
var attack_direction: String = "front"

# 攻击区域引用
var _attack_area: Area2D = null
var _attack_collision: CollisionShape2D = null
var _damage_amount: float = 30.0  # 攻击伤害值
var _attack_delay: float = 0.1    # 攻击延迟时间（秒）

func enter() -> void:
	if not entity:
		return
		
	# 攻击计时器归零
	attack_timer = 0.0
	
	# 获取并缓存攻击区域引用
	_setup_attack_area()
	
	# 获取攻击方向并旋转攻击区域
	_handle_attack_direction()
	
	# 启用攻击区域
	if _attack_collision:
		_attack_collision.disabled = false
	
	# 播放对应方向的攻击动画
	play_attack_animation()
	
	#重要！！！！！！！！
	# 设置延迟攻击检测，在0.1秒后检测，因为立即检测会检测不到。此句为实现攻击检测的关键
	get_tree().create_timer(_attack_delay).timeout.connect(_delayed_attack_check)
	#重要！！！！！！！！

func exit() -> void:
	# 禁用攻击区域
	if _attack_collision:
		_attack_collision.disabled = true
	
	# 确保在退出攻击状态时调用play_idle_animation
	if "animation_controller" in entity:
		entity.animation_controller.play_idle_animation()


func physics_update(delta: float) -> void:
	if not entity:
		return
		
	# 增加计时器
	attack_timer += delta
	
	# 如果攻击时间结束，返回到闲置状态
	if attack_timer >= attack_duration:
		state_machine.change_state("idle")
		return
	
	# 攻击期间减速，增加运动感
	entity.velocity.x = move_toward(entity.velocity.x, 0, delta * entity.deceleration)
	entity.velocity.y = move_toward(entity.velocity.y, 0, delta * entity.deceleration)
	entity.move_and_slide()


# 获取并缓存攻击区域引用
func _setup_attack_area() -> void:
	if not _attack_area and entity.has_node("AttackArea"):
		_attack_area = entity.get_node("AttackArea")
		if _attack_area.has_node("CollisionShape2D"):
			_attack_collision = _attack_area.get_node("CollisionShape2D")


# 处理攻击方向和旋转
func _handle_attack_direction() -> void:
	# 获取鼠标相对于角色位置的方向
	var mouse_pos = get_viewport().get_mouse_position()
	var player_screen_pos = entity.get_global_transform_with_canvas().origin
	var direction = mouse_pos - player_screen_pos

	# 判断攻击方向
	determine_attack_direction(direction)
	
	# 根据攻击方向旋转攻击区域
	rotate_attack_area()


func determine_attack_direction(direction: Vector2) -> void:
	# 将方向归一化，便于判断
	var normalized_dir = direction.normalized()
	
	# 判断水平方向和垂直方向的主导性
	if abs(normalized_dir.x) > abs(normalized_dir.y):
		# 水平方向为主
		attack_direction = "right" if normalized_dir.x > 0 else "left"
	else:
		# 垂直方向为主
		attack_direction = "back" if normalized_dir.y < 0 else "front"


# 根据攻击方向旋转攻击区域
func rotate_attack_area() -> void:
	if not _attack_area:
		return
	
	# 重置旋转
	_attack_area.rotation = 0
	
	# 根据方向设置旋转角度
	match attack_direction:
		"front":
			# 默认朝向，不需要旋转
			pass
		"back":
			# 向上攻击，旋转180度
			_attack_area.rotation = PI
		"left":
			# 向左攻击，旋转90度
			_attack_area.rotation = PI / 2
		"right":
			# 向右攻击，旋转270度
			_attack_area.rotation = 3 * PI / 2


# 延迟检测攻击
func _delayed_attack_check() -> void:
	if not is_instance_valid(_attack_area) or not _attack_area:
		return
	
	var areas = _attack_area.get_overlapping_areas()
	for area in areas:
		var parent = area.get_parent()
		var grandparent = parent.get_parent() if parent else null
		if parent and parent is hurted_component and grandparent and grandparent.is_in_group("enemy"):
			# 造成伤害
			parent._on_hurt(_damage_amount)


func play_attack_animation() -> void:
	if not "animation_controller" in entity:
		return
	
	var animation_name = attack_direction + "_attack"
	
	# 检查动画是否存在，如果不存在则使用默认的front_attack
	if entity.animation_controller.has_animation(animation_name):
		entity.animation_controller.play(animation_name)
	else:
		push_warning("攻击动画 '" + animation_name + "' 不存在，尝试使用front_attack")
		if entity.animation_controller.has_animation("front_attack"):
			entity.animation_controller.play("front_attack")
		else:
			push_error("没有可用的攻击动画")


func handle_input(event: InputEvent) -> void:
	# 攻击状态不处理输入
	pass
