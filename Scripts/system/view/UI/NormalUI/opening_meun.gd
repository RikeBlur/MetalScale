class_name OpeningMeun
extends Control

# 主菜单按钮列表（在编辑器中配置）
@export var menu_buttons: Array[Button] = []
#@export var canvas_animation_player : AnimationPlayer = null

@onready var hoven_sfx: SFXPlayer = $SFXManager/hoven
@onready var pressed_sfx: SFXPlayer = $SFXManager/pressed
const LOADGAMEWINDOW_SCENE = preload("res://System/RPG/UI/load_game.tscn")
const GAMECONFIG_SCENE = preload("res://System/RPG/UI/game_config.tscn")
var loadgame_window_inst: Node = null
var gameconfig_inst: Node = null


func _ready() -> void:
	"""
	初始化主菜单
	
	功能:
		- 连接所有菜单按钮的信号到对应的方法
	"""
	_connect_button_signals()

func _process(_delta: float) -> void:
	# 主菜单场景未初始化 UIManager 时，直接在本脚本里处理 quit 关闭读档窗口
	if loadgame_window_inst and is_instance_valid(loadgame_window_inst):
		if Input.is_action_just_pressed("quit"):
			loadgame_window_inst.queue_free()
			loadgame_window_inst = null
	elif loadgame_window_inst and not is_instance_valid(loadgame_window_inst):
		loadgame_window_inst = null
	
	# 主菜单场景未初始化 UIManager 时，直接在本脚本里处理 quit 关闭设置窗口
	if gameconfig_inst and is_instance_valid(gameconfig_inst):
		if Input.is_action_just_pressed("quit"):
			gameconfig_inst.queue_free()
			gameconfig_inst = null
	elif gameconfig_inst and not is_instance_valid(gameconfig_inst):
		gameconfig_inst = null


func _connect_button_signals() -> void:
	"""
	连接所有按钮的信号
	"""
	for i in range(menu_buttons.size()):
		var menu_button = menu_buttons[i]
		if menu_button:
			# 连接按钮的pressed信号
			menu_button.pressed.connect(_on_button_pressed.bind(i))
			# 连接按钮的hover信号
			menu_button.mouse_entered.connect(_on_button_hovered.bind(i))
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
	
	pressed_sfx.play_once()
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
	hoven_sfx.play_once()
	


# ====================================================================================================
# ======================================== 具体按钮响应方法 ============================================
# ====================================================================================================

func _on_button_0_pressed() -> void:
	"""按钮0的响应逻辑"""
	# TODO: 实现按钮0的功能
	print("START NEW GAME !")
	GameManager.start_new_game()
	#call_deferred("canvas_slide")


func _on_button_1_pressed() -> void:
	"""按钮1的响应逻辑"""
	# TODO: 实现按钮1的功能
	print("打开存档界面")
	call_deferred("loadgame")


func _on_button_2_pressed() -> void:
	"""按钮2的响应逻辑"""
	# TODO: 实现按钮2的功能
	print("打开设置界面")
	call_deferred("open_game_config")


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

func loadgame() -> void:
	# 防止重复打开
	if loadgame_window_inst and is_instance_valid(loadgame_window_inst):
		return

	var inst = LOADGAMEWINDOW_SCENE.instantiate()
	if not inst:
		push_error("OpeningMeun: 无法实例化 LOADGAMEWINDOW")
		return

	loadgame_window_inst = inst
	var target_parent: Node = get_parent() if get_parent() else self
	target_parent.add_child(loadgame_window_inst)

func open_game_config() -> void:
	# 防止重复打开
	if gameconfig_inst and is_instance_valid(gameconfig_inst):
		return

	var inst = GAMECONFIG_SCENE.instantiate()
	if not inst:
		push_error("OpeningMeun: 无法实例化 GAMECONFIG")
		return

	gameconfig_inst = inst
	var target_parent: Node = get_parent() if get_parent() else self
	target_parent.add_child(gameconfig_inst)

# ====================================================================================================
# ====================================================================================================
# ====================================================================================================
