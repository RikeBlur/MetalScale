class_name NormalUIButton
extends MarginContainer

# 按钮节点引用（在场景中设置或通过代码查找）
@export var button: BaseButton

@export var back: Sprite2D = null

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
	
	# 初始化button的scale
	if button:
		button.scale = normal_scale

# 当按钮被悬浮时触发的方法
func _on_button_hover() -> void:
	if not back or not button:
		return
	
	# 创建tween实例
	var tween = create_tween()
	tween.set_parallel(true)  # 允许并行执行多个tween
	
	# 1. 播放back的子节点"dissolve_player"动画
	var dissolve_player = back.get_node_or_null("dissolve_player")
	if dissolve_player is AnimationPlayer:
		dissolve_player.play("dissolve_appear")
	
	# 2. button的scale，从normal_scale到bigger_scale
	tween.tween_property(button, "scale", bigger_scale, 0.1)

# 当按钮鼠标移出时触发的方法
func _on_button_exit() -> void:
	if not back or not button:
		return
	
	# 创建tween实例
	var tween = create_tween()
	tween.set_parallel(true)  # 允许并行执行多个tween
	
	# 1. 播放back的子节点"dissolve_player"动画
	var dissolve_player = back.get_node_or_null("dissolve_player")
	if dissolve_player is AnimationPlayer:
		dissolve_player.play("RESET")
	
	# 2. button的scale，从bigger_scale回到normal_scale
	tween.tween_property(button, "scale", normal_scale, 0.1)

# 当按钮被按下时触发的方法
func _on_button_pressed() -> void:
	if not back or not button:
		return
		
	# 创建tween实例
	var tween = create_tween()
	tween.set_parallel(true)  # 允许并行执行多个tween
	
	# 设置tween曲线类型（三角/正弦曲线）
	# TRANS_SINE: 正弦曲线（类似三角曲线）
	# EASE_IN_OUT: 开始和结束时慢，中间快
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# button的scale，通过tween到smaller_scale
	tween.tween_property(button, "scale", smaller_scale, 0.1)

# 当按钮被释放时触发的方法
func _on_button_released() -> void:
	if not back or not button:
		return
		
	# 创建tween实例
	var tween = create_tween()
	tween.set_parallel(true)  # 允许并行执行多个tween
	
	# 设置tween曲线类型（三角/正弦曲线）
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# button的scale，回归到normal_scale
	tween.tween_property(button, "scale", normal_scale, 0.1)
