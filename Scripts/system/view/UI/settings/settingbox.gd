class_name Settingbox
extends MarginContainer

# 按钮节点引用（在场景中设置或通过代码查找）
@export var button: BaseButton

@export var style: int = 0
@export var back: Sprite2D = null
@export var front: Sprite2D = null

@export var normal_color : Color = Color(1, 1, 1, 1)
@export var hightlight : Color = Color(15, 15, 15)
@export var shadow : Color = Color(0.5, 0.5, 0.5)

@export var normal_scale : Vector2 = Vector2(2,2)
@export var bigger_scale : Vector2 = Vector2(2.2,2.2)
@export var smaller_scale : Vector2 = Vector2(1.8,1.8)

func _ready() -> void:
	# 连接按钮的信号
	if button:
		button.mouse_entered.connect(_on_button_hover)
		button.mouse_exited.connect(_on_button_exit)
		button.button_down.connect(_on_button_pressed)
		button.button_up.connect(_on_button_released)
	
	# 初始化front的scale和modulate
	if front:
		front.scale = normal_scale
		front.modulate = normal_color

# 当按钮被悬浮时触发的方法
func _on_button_hover() -> void:
	match style:
		0:
			_style_0_hover()
		_:
			print("No this settingbox style!")

# 当按钮鼠标移出时触发的方法
func _on_button_exit() -> void:
	match style:
		0:
			_style_0_exit()
		_:
			print("No this settingbox style!")

# 当按钮被按下时触发的方法
func _on_button_pressed() -> void:
	match style:
		0:
			_style_0_pressed()
		_:
			print("No this settingbox style!")

# 当按钮被释放时触发的方法
func _on_button_released() -> void:
	match style:
		0:
			_style_0_released()
		_:
			print("No this settingbox style!")


func _style_0_hover() -> void:
	if not back or not front:
		return
	
	# 创建tween实例
	var tween = create_tween()
	tween.set_parallel(true)  # 允许并行执行多个tween
	
	# 1. 播放back的子节点"dissolve_player"动画
	var dissolve_player = back.get_node_or_null("dissolve_player")
	if dissolve_player is AnimationPlayer:
		dissolve_player.play("dissolve_appear")
	
	# 2. front的scale，从0.25到0.3
	tween.tween_property(front, "scale", bigger_scale, 0.1)
	
	# 3. front的modulate，从当前颜色变成纯白
	tween.tween_property(front, "modulate", hightlight, 0.1)


func _style_0_exit() -> void:
	if not back or not front:
		return
	
	# 创建tween实例
	var tween = create_tween()
	tween.set_parallel(true)  # 允许并行执行多个tween
	
	# 1. 播放back的子节点"dissolve_player"动画
	var dissolve_player = back.get_node_or_null("dissolve_player")
	if dissolve_player is AnimationPlayer:
		dissolve_player.play("RESET")
	
	# 2. front的scale，从0.3回到0.25
	tween.tween_property(front, "scale", normal_scale, 0.1)
	
	# 3. front的modulate，从纯白变回当前颜色
	tween.tween_property(front, "modulate", normal_color, 0.1)


func _style_0_pressed() -> void:
	if not back or not front:
		return
		
	# 创建tween实例
	var tween = create_tween()
	tween.set_parallel(true)  # 允许并行执行多个tween
	
	# 设置tween曲线类型（三角/正弦曲线）
	# TRANS_SINE: 正弦曲线（类似三角曲线）
	# EASE_IN_OUT: 开始和结束时慢，中间快
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# 1. front的scale，通过tween到(0.22, 0.22)
	tween.tween_property(front, "scale", smaller_scale, 0.1)
	
	# 2. front的modulate，通过tween到color(-5, -5, -5)
	tween.tween_property(front, "modulate", shadow, 0.1)

func _style_0_released() -> void:
	if not back or not front:
		return
		
	# 创建tween实例
	var tween = create_tween()
	tween.set_parallel(true)  # 允许并行执行多个tween
	
	# 设置tween曲线类型（三角/正弦曲线）
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# 1. front的scale，回归到(0.25, 0.25)
	tween.tween_property(front, "scale", normal_scale, 0.1)
	
	# 2. front的modulate，回归到(1, 1, 1)
	tween.tween_property(front, "modulate", normal_color, 0.1)
