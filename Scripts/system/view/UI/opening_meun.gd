class_name OpeningMeun
extends Control

# 主菜单按钮列表（在编辑器中配置）
@export var menu_buttons: Array[NormalUIButton] = []
@export var canvas_animation_player : AnimationPlayer = null

func _ready() -> void:
	"""
	初始化主菜单
	
	功能:
		- 连接所有菜单按钮的信号到对应的方法
	"""
	_connect_button_signals()


func _connect_button_signals() -> void:
	"""
	连接所有按钮的信号
	"""
	for i in range(menu_buttons.size()):
		var menu_button = menu_buttons[i]
		if menu_button and menu_button.button:
			# 连接按钮的pressed信号
			menu_button.button.pressed.connect(_on_button_pressed.bind(i))
			# 连接按钮的hover信号
			menu_button.button.mouse_entered.connect(_on_button_hovered.bind(i))
			print("OpeningMeun: 按钮 %d 信号已连接" % i)


# ====================================================================================================
# ========================================== 按钮回调方法 ==============================================
# ====================================================================================================

func _on_button_pressed(button_index: int) -> void:
	"""
	当按钮被点击时触发
	
	参数:
		button_index: 按钮在数组中的索引
	"""
	print("OpeningMeun: 按钮 %d 被点击" % button_index)
	
	# TODO: 在此处添加按钮点击的具体逻辑
	match button_index:
		0:
			_on_button_0_pressed()
		1:
			_on_button_1_pressed()
		2:
			_on_button_2_pressed()
		3:
			_on_button_3_pressed()
		_:
			pass


func _on_button_hovered(button_index: int) -> void:
	"""
	当鼠标悬停在按钮上时触发
	
	参数:
		button_index: 按钮在数组中的索引
	"""
	print("OpeningMeun: 按钮 %d 被悬停" % button_index)
	
	# TODO: 在此处添加按钮悬停的具体逻辑


# ====================================================================================================
# ======================================== 具体按钮响应方法 ============================================
# ====================================================================================================

func _on_button_0_pressed() -> void:
	"""按钮0的响应逻辑"""
	# TODO: 实现按钮0的功能
	print("START NEW GAME !")
	GameManager.start_new_game()
	call_deferred("canvas_slide")


func _on_button_1_pressed() -> void:
	"""按钮1的响应逻辑"""
	# TODO: 实现按钮1的功能
	print("打开存档界面")
	pass


func _on_button_2_pressed() -> void:
	"""按钮2的响应逻辑"""
	# TODO: 实现按钮2的功能
	print("打开设置界面")
	pass


func _on_button_3_pressed() -> void:
	"""按钮3的响应逻辑"""
	# TODO: 实现按钮3的功能
	print("QUIT GAmE !")
	GameManager.quit_game()

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================

# ====================================================================================================
# ================================================ 功 能 函 数 ====================================
# ====================================================================================================

func canvas_slide() -> void:
	canvas_animation_player.play("slide")

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
