class_name AdvancedCamera
extends Camera2D

# 跟随目标
@export var target: Node2D = null
# 平滑插值参数，值越小移动越平滑
@export_range(0.001, 1.0) var smoothing: float = 0.1

# 摄像机边缘触发区域设置
@export_range(0.0, 0.5) var edge_margin_left: float = 0.3  # 左边缘触发区域（屏幕宽度的比例）
@export_range(0.0, 0.5) var edge_margin_right: float = 0.3  # 右边缘触发区域（屏幕宽度的比例）
@export_range(0.0, 0.5) var edge_margin_top: float = 0.3  # 上边缘触发区域（屏幕高度的比例）
@export_range(0.0, 0.5) var edge_margin_bottom: float = 0.3  # 下边缘触发区域（屏幕高度的比例）

# Y轴偏移设置（正值使角色位于屏幕下方）
@export var y_offset: float = 20.0

# 是否在X轴居中
@export var center_x: bool = true
# 是否使用Y轴偏移
@export var use_y_offset: bool = true

# 内部变量
var _screen_size: Vector2
var _left_bound: float
var _right_bound: float
var _top_bound: float
var _bottom_bound: float
var _last_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 确保有跟踪目标
	if target == null:
		# 尝试找到场景中的主角（假设主角在"player"组中）
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
		else:
			push_warning("AdvancedCamera: 没有设置跟踪目标且找不到player组")
			return
	
	# 设置初始摄像机位置
	var initial_pos = target.global_position
	if use_y_offset:
		initial_pos.y -= y_offset  # 负值，因为Godot中Y轴向下为正
	
	global_position = initial_pos
	_last_position = global_position
	
	# 计算边界区域
	_update_screen_size()
	get_viewport().size_changed.connect(_update_screen_size)

func _update_screen_size() -> void:
	_screen_size = get_viewport_rect().size / zoom
	_calculate_bounds()

func _calculate_bounds() -> void:
	# 计算边界触发区域
	_left_bound = global_position.x - _screen_size.x * 0.5 + _screen_size.x * edge_margin_left
	_right_bound = global_position.x + _screen_size.x * 0.5 - _screen_size.x * edge_margin_right
	_top_bound = global_position.y - _screen_size.y * 0.5 + _screen_size.y * edge_margin_top
	_bottom_bound = global_position.y + _screen_size.y * 0.5 - _screen_size.y * edge_margin_bottom

func _physics_process(delta: float) -> void:
	if not target:
		return
	
	var need_to_move = false
	var target_pos = global_position
	
	# 检查目标是否超出了边界
	# 检查X轴边界
	if target.global_position.x < _left_bound:
		target_pos.x = target.global_position.x + _screen_size.x * (0.5 - edge_margin_left)
		need_to_move = true
	elif target.global_position.x > _right_bound:
		target_pos.x = target.global_position.x - _screen_size.x * (0.5 - edge_margin_right)
		need_to_move = true
	
	# 检查Y轴边界
	if target.global_position.y < _top_bound:
		target_pos.y = target.global_position.y + _screen_size.y * (0.5 - edge_margin_top)
		if use_y_offset:
			target_pos.y -= y_offset
		need_to_move = true
	elif target.global_position.y > _bottom_bound:
		target_pos.y = target.global_position.y - _screen_size.y * (0.5 - edge_margin_bottom)
		if use_y_offset:
			target_pos.y -= y_offset
		need_to_move = true
	
	# 如果需要移动相机
	if need_to_move:
		# 平滑移动
		global_position = global_position.lerp(target_pos, smoothing)
		# 更新边界
		_calculate_bounds()
	
	# 确保摄像机限制在场景边界内
	if limit_left != 0 || limit_right != 0 || limit_top != 0 || limit_bottom != 0:
		force_update_scroll()

# 重置相机位置（场景切换或需要重置时调用）
func reset_camera() -> void:
	if target:
		var reset_pos = target.global_position
		if use_y_offset:
			reset_pos.y -= y_offset
		
		global_position = reset_pos
		_calculate_bounds()
