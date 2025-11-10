class_name botton_component
extends Area2D

# 信号定义
signal mouse_entered_signal()     # 鼠标悬停进入信号
signal mouse_exited_signal()      # 鼠标离开信号  
signal click_recover()            # 按键恢复信号
signal click_start_siganl()       # 鼠标按下信号
signal clicked_signal()           # 鼠标点击信号

# 状态变量
var is_mouse_over: bool = false
var is_pressed: bool = false
var is_recover: bool = false
var recover_timer: float = 0.0

@export var text: interactable_label_component = null
@export var recover_time: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 连接Area2D的内置信号到我们的处理函数
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)
	self.input_event.connect(_on_input_event)
	
	# 确保可以接收输入事件
	self.input_pickable = true

func _process(delta: float) -> void:
	if is_recover:
		recover_timer += delta
	if recover_timer >= recover_time:
		recover_timer = 0
		is_recover = false
		if is_mouse_over:
			click_recover.emit()
			print("按键恢复")

# 鼠标进入区域时的处理
func _on_mouse_entered() -> void:
	is_mouse_over = true
	mouse_entered_signal.emit()
	print("鼠标进入按钮区域")

# 鼠标离开区域时的处理  
func _on_mouse_exited() -> void:
	is_mouse_over = false
	is_pressed = false  # 重置按下状态
	mouse_exited_signal.emit()
	print("鼠标离开按钮区域")

# 处理输入事件（点击等）
func _on_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		
		# 只处理左键点击
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				# 鼠标按下
				is_pressed = true
				click_start_siganl.emit()
				is_recover = true
				recover_timer = 0
				print("鼠标按下")
			else:
				# 鼠标释放
				if is_pressed and is_mouse_over:
					# 只有在鼠标悬停且之前按下的情况下才算点击
					clicked_signal.emit()
					print("按钮被点击")
				is_pressed = false

# 公共方法：获取当前悬停状态
func is_hovered() -> bool:
	return is_mouse_over

# 公共方法：获取当前按下状态
func is_button_pressed() -> bool:
	return is_pressed

# 公共方法：模拟点击（程序化触发）
func simulate_click() -> void:
	if is_mouse_over:
		clicked_signal.emit()
		print("模拟点击触发")
