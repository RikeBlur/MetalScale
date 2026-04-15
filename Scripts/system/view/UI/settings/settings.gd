class_name Settings
extends Control

# 设置项容器节点路径（根据实际场景结构调整）
@onready var settings: HBoxContainer = $topoffset/PanelContainer/MarginContainer/settings

var setting_boxes: Array = []

var own_manager: UI_manager = null

@onready var hoven: SFXPlayer = $SFXManager/hoven
@onready var pressed: SFXPlayer = $SFXManager/pressed

func _ready():
	# 初始化所有容纳button的settingbox
	_initialize_setting_boxes()
	# 连接所有settingbox的按钮信号
	_connect_setting_signals()
	# 连接通用按钮音效
	_connect_button_sfx()

func _initialize_setting_boxes():
	"""初始化所有settingbox子组件"""
	setting_boxes.clear()
	if not settings:
		print("No Settings !!")
		return	
	for child in settings.get_children():
		if child is Settingbox:
			setting_boxes.append(child)

func _connect_setting_signals():
	"""连接所有settingbox的按钮信号"""
	for i in range(setting_boxes.size()):
		var setting_box = setting_boxes[i]
		var button = setting_box.button   # 检查settingbox的button存储变量
		if button:
			# 如果按钮已经连接过，先断开
			if button.pressed.is_connected(_on_setting_pressed):
				button.pressed.disconnect(_on_setting_pressed)
			# 连接按钮信号，传递index参数
			button.pressed.connect(_on_setting_pressed.bind(i))

func _on_setting_pressed(index: int):
	"""当某个设置项的按钮被按下时调用"""
	print("设置项 %d 被按下" % index)
	
	# 根据index调用对应的处理函数
	match index:
		0:
			_on_setting_0_pressed()
		1:
			_on_setting_1_pressed()
		2:
			_on_setting_2_pressed()
		3:
			_on_setting_3_pressed()
		4:
			_on_setting_4_pressed()
		_:
			push_warning("未处理的设置项index: %d" % index)

# ============ 以下是各个设置项的处理函数 ============

func _on_setting_0_pressed():
	"""设置项 0 的处理函数（例如：音量设置）"""
	print("执行设置项 0")
	call_deferred("try_to_player_info")

func _on_setting_1_pressed():
	"""设置项 1 的处理函数（例如：全屏切换）"""
	print("执行设置项 1")
	# 在这里添加具体的功能实现
	pass

func _on_setting_2_pressed():
	"""设置项 2 的处理函数（例如：分辨率设置）"""
	print("执行设置项 2")
	call_deferred("try_to_change_config")

func _on_setting_3_pressed():
	"""设置项 3 的处理函数"""
	print("执行设置项 3")
	# 在这里添加具体的功能实现
	call_deferred("try_to_loadgame")

func _on_setting_4_pressed():
	"""设置项 4 的处理函数"""
	print("执行设置项 4")
	# 在这里添加具体的功能实现
	call_deferred("try_to_quit_game")

# ============ 工具函数 ============

func get_setting_box(index: int) -> Settingbox:
	"""获取指定index的settingbox"""
	if index >= 0 and index < setting_boxes.size():
		return setting_boxes[index]
	return null

func refresh_settings():
	"""刷新设置显示"""
	_initialize_setting_boxes()
	_connect_setting_signals()
	_connect_button_sfx()

func try_to_player_info() -> void:
	own_manager.instantiate_ui(UI_manager.UI_component.PLAYERINFO)

func try_to_quit_game() -> void:
	own_manager.instantiate_ui(UI_manager.UI_component.EXITWINDOW)
	
func try_to_loadgame() -> void:
	own_manager.instantiate_ui(UI_manager.UI_component.LOADGAMEWINDOW)

func try_to_change_config() -> void:
	own_manager.instantiate_ui(UI_manager.UI_component.GAMECONFIG)

func _connect_button_sfx() -> void:
	for button in _collect_buttons(self):
		if not button.mouse_entered.is_connected(_on_any_button_hoven):
			button.mouse_entered.connect(_on_any_button_hoven)
		if not button.pressed.is_connected(_on_any_button_pressed):
			button.pressed.connect(_on_any_button_pressed)

func _on_any_button_hoven() -> void:
	if hoven:
		hoven.play_once()

func _on_any_button_pressed() -> void:
	if pressed:
		pressed.play_once()

func _collect_buttons(root: Node) -> Array[Button]:
	var result: Array[Button] = []
	for child in root.get_children():
		if child is Button:
			result.append(child)
		result.append_array(_collect_buttons(child))
	return result
