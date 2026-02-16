class_name GameConfig
extends Control

@export var configboxes: Array[ConfigBox] = []
# 与 configboxes 一一对应，填写 GameManager 里的变量名（例如: "BGM_gain", "SFX_gain"）
@export var bound_game_manager_properties: Array[String] = []

var values: Array[float] = []

@onready var hoven: SFXPlayer = $SFXManager/hoven
@onready var pressed: SFXPlayer = $SFXManager/pressed

func _ready() -> void:
	_initialize_configboxes()
	_ensure_array_lengths()
	_pull_values_from_game_manager()
	_apply_values_to_configboxes()
	_connect_configbox_signals()
	_connect_control_sfx()

func _initialize_configboxes() -> void:
	# 允许在编辑器手动配置；若未配置则自动搜集当前界面中的 ConfigBox
	if configboxes.size() > 0:
		return
	configboxes.clear()
	_collect_configboxes(self, configboxes)

func _collect_configboxes(root: Node, out: Array[ConfigBox]) -> void:
	for child in root.get_children():
		if child is ConfigBox:
			out.append(child)
		_collect_configboxes(child, out)

func _ensure_array_lengths() -> void:
	while values.size() < configboxes.size():
		values.append(0.0)
	while bound_game_manager_properties.size() < configboxes.size():
		bound_game_manager_properties.append("")

func _pull_values_from_game_manager() -> void:
	for i in range(configboxes.size()):
		var prop_name := bound_game_manager_properties[i]
		if prop_name.is_empty():
			values[i] = configboxes[i].get_value()
			continue

		if _has_property(GameManager, prop_name):
			var raw_value = GameManager.get(prop_name)
			if raw_value is float or raw_value is int:
				values[i] = float(raw_value)
			else:
				push_warning("GameConfig: GameManager.%s 不是数值类型" % prop_name)
				values[i] = configboxes[i].get_value()
		else:
			push_warning("GameConfig: GameManager 不存在属性 %s" % prop_name)
			values[i] = configboxes[i].get_value()

func _apply_values_to_configboxes() -> void:
	for i in range(configboxes.size()):
		if is_instance_valid(configboxes[i]):
			configboxes[i].set_value(values[i])

func _connect_configbox_signals() -> void:
	for i in range(configboxes.size()):
		var box := configboxes[i]
		if not is_instance_valid(box):
			continue
		var callable := _on_configbox_value_changed.bind(i)
		if not box.value_changed.is_connected(callable):
			box.value_changed.connect(callable)

func _on_configbox_value_changed(new_value: float, index: int) -> void:
	if index < 0 or index >= values.size():
		return
	values[index] = new_value

	var prop_name := bound_game_manager_properties[index]
	if prop_name.is_empty():
		return
	if _has_property(GameManager, prop_name):
		GameManager.set(prop_name, new_value)
	else:
		push_warning("GameConfig: GameManager 不存在属性 %s" % prop_name)

func _has_property(obj: Object, property_name: String) -> bool:
	for p in obj.get_property_list():
		if p.has("name") and p.name == property_name:
			return true
	return false

func _connect_control_sfx() -> void:
	for box in configboxes:
		if not is_instance_valid(box):
			continue
		if box.control:
			match box.box_type:
				ConfigBox.ConfigBoxType.HSLIDER:
					# HSlider 类只播放 hoven，不播放 pressed
					if not box.control.mouse_entered.is_connected(_on_any_control_hoven):
						box.control.mouse_entered.connect(_on_any_control_hoven)
				_:
					if not box.control.mouse_entered.is_connected(_on_any_control_hoven):
						box.control.mouse_entered.connect(_on_any_control_hoven)
					if box.control is BaseButton and not box.control.pressed.is_connected(_on_any_control_pressed):
						box.control.pressed.connect(_on_any_control_pressed)
					elif box.control is Range and not box.control.value_changed.is_connected(_on_any_control_value_changed):
						box.control.value_changed.connect(_on_any_control_value_changed)

func _on_any_control_hoven() -> void:
	if hoven:
		hoven.play_once()

func _on_any_control_pressed() -> void:
	if pressed:
		pressed.play_once()

func _on_any_control_value_changed(_value: float) -> void:
	if pressed:
		pressed.play_once()
